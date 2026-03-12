module Main (main) where

import Control.Exception
  ( SomeException,
    bracket,
    catch,
    displayException,
    evaluate,
    finally,
    throwIO,
    try,
  )
import Control.Monad (forM, unless)
import Data.Char (isLetter)
import Data.List (sort)
import GHC.IO.Handle (hDuplicate, hDuplicateTo)
import Pyleft.Driver.Run qualified as Run
import System.Directory
  ( createDirectoryIfMissing,
    doesFileExist,
    getCurrentDirectory,
    removePathForcibly,
    withCurrentDirectory,
  )
import System.Environment (withArgs)
import System.Exit (exitFailure)
import System.FilePath ((</>), takeDirectory)
import System.IO (Handle, hClose, hFlush, openTempFile, stdout)

data TestCase = TestCase
  { testName :: String,
    testAction :: IO ()
  }

main :: IO ()
main = do
  root <- findRepoRoot
  outcomes <- withCurrentDirectory root (forM tests runTest)
  let failedCount = length (filter not outcomes)
  if failedCount == 0
    then putStrLn ("All integration tests passed (" <> show (length tests) <> ").")
    else do
      putStrLn (show failedCount <> " integration test(s) failed.")
      exitFailure

tests :: [TestCase]
tests =
  [ TestCase "disables bare-except via pyleft.toml" testBareExceptDisabled,
    TestCase "reports expected diagnostics for examples/multiple.py" testMultipleDiagnostics,
    TestCase "reports expected diagnostics for examples/test_one.py" testTestOneDiagnostics,
    TestCase "deduplicates duplicate input paths" testDeduplicatesInputPaths,
    TestCase "respects --max-depth during directory traversal" testMaxDepthTraversal,
    TestCase "prints message when no Python files are discovered" testNoPythonFilesFound
  ]

runTest :: TestCase -> IO Bool
runTest tc = do
  putStrLn ("[integration] " <> testName tc)
  result <- try (testAction tc)
  case result of
    Right () -> do
      putStrLn "  PASS"
      pure True
    Left err -> do
      putStrLn ("  FAIL: " <> displayException (err :: SomeException))
      pure False

testBareExceptDisabled :: IO ()
testBareExceptDisabled = do
  actual <- runLinter ["examples/bare.py"]
  assertSameLines
    "examples/bare.py should be clean because bare-except is disabled in config"
    []
    actual

testMultipleDiagnostics :: IO ()
testMultipleDiagnostics = do
  actual <- runLinter ["examples/multiple.py"]
  assertSameLines
    "examples/multiple.py diagnostics do not match expected output"
    [ "F403 examples/multiple.py: 1:0: [error] Wildcard import detected (`from x import *`)",
      "P671 examples/multiple.py: 5:0: [info] Mutable default argument detected",
      "F401 examples/multiple.py: 2:24: [warning] Unused import: `deque`"
    ]
    actual

testTestOneDiagnostics :: IO ()
testTestOneDiagnostics = do
  actual <- runLinter ["examples/test_one.py"]
  assertSameLines
    "examples/test_one.py diagnostics do not match expected output"
    [ "F403 examples/test_one.py: 2:0: [error] Wildcard import detected (`from x import *`)",
      "F401 examples/test_one.py: 1:19: [warning] Unused import: `bisect_left`",
      "F841 examples/test_one.py: 4:0: [error] Unused local variable: `z`",
      "F841 examples/test_one.py: 15:4: [error] Unused local variable: `z`",
      "A001 examples/test_one.py: 7:25: [error] Name shadows Python built-in: `list`"
    ]
    actual

testDeduplicatesInputPaths :: IO ()
testDeduplicatesInputPaths = do
  actual <- runLinter ["examples/wildcard.py", "examples/wildcard.py"]
  assertSameLines
    "duplicate paths should only produce one set of diagnostics"
    [ "F403 examples/wildcard.py: 1:0: [error] Wildcard import detected (`from x import *`)"
    ]
    actual

testMaxDepthTraversal :: IO ()
testMaxDepthTraversal =
  withFixtureDir
    "max-depth"
    [ ("top.py", "from math import *\n"),
      ("nested/deeper.py", "def f(x=[]):\n    return x\n")
    ]
    $ \dir -> do
      let topLine =
            "F403 "
              <> dir
              <> "/top.py: 1:0: [error] Wildcard import detected (`from x import *`)"
      let nestedLine =
            "P671 "
              <> dir
              <> "/nested/deeper.py: 1:0: [info] Mutable default argument detected"

      depthZero <- runLinter [dir, "--max-depth", "0"]
      assertSameLines
        "max-depth=0 should include only direct child files"
        [topLine]
        depthZero

      depthOne <- runLinter [dir, "--max-depth", "1"]
      assertSameLines
        "max-depth=1 should include diagnostics from one nested directory level"
        [topLine, nestedLine]
        depthOne

testNoPythonFilesFound :: IO ()
testNoPythonFilesFound =
  withFixtureDir
    "no-python"
    [("notes.txt", "not python\n")]
    $ \dir -> do
      actual <- runLinter [dir]
      assertSameLines
        "expected a no-files-found message when directory has no .py files"
        ["No Python files found."]
        actual

runLinter :: [String] -> IO [String]
runLinter args = do
  output <- captureStdout (withArgs args Run.main)
  pure (normalizeOutput output)

captureStdout :: IO () -> IO String
captureStdout action =
  bracket
    (openTempFile "." "pyleft-test-stdout-")
    cleanupTempFile
    $ \(tmpPath, tmpHandle) -> do
      originalStdout <- hDuplicate stdout
      result <- try $ do
        hDuplicateTo tmpHandle stdout
        action
      hFlush stdout
      hDuplicateTo originalStdout stdout
      hClose originalStdout
      hClose tmpHandle
      output <- readFile tmpPath
      _ <- evaluate (length output)
      case result of
        Left err -> throwIO (err :: SomeException)
        Right () -> pure output
  where
    cleanupTempFile :: (FilePath, Handle) -> IO ()
    cleanupTempFile (tmpPath, tmpHandle) = do
      hClose tmpHandle `catch` ignoreAny
      removePathForcibly tmpPath `catch` ignoreAny

withFixtureDir :: FilePath -> [(FilePath, String)] -> (FilePath -> IO a) -> IO a
withFixtureDir suffix files action = do
  let dir = "test" </> ".integration-tmp" </> suffix
  removePathForcibly dir `catch` ignoreAny
  createDirectoryIfMissing True dir
  mapM_ (writeFixtureFile dir) files
  action dir `finally` (removePathForcibly dir `catch` ignoreAny)

writeFixtureFile :: FilePath -> (FilePath, String) -> IO ()
writeFixtureFile root (relativePath, contents) = do
  let path = root </> relativePath
  createDirectoryIfMissing True (takeDirectory path)
  writeFile path contents

normalizeOutput :: String -> [String]
normalizeOutput =
  filter (not . null)
    . lines
    . stripAnsi

stripAnsi :: String -> String
stripAnsi [] = []
stripAnsi ('\ESC' : '[' : xs) = stripAnsi (dropAnsiSeq xs)
  where
    dropAnsiSeq :: String -> String
    dropAnsiSeq [] = []
    dropAnsiSeq (c : rest)
      | isLetter c = rest
      | otherwise = dropAnsiSeq rest
stripAnsi (x : xs) = x : stripAnsi xs

assertSameLines :: String -> [String] -> [String] -> IO ()
assertSameLines context expected actual =
  unless (sort expected == sort actual) $
    fail $
      context
        <> "\nExpected lines:\n"
        <> formatLines (sort expected)
        <> "Actual lines:\n"
        <> formatLines (sort actual)

formatLines :: [String] -> String
formatLines [] = "  <none>\n"
formatLines ls = unlines (map ("  " <>) ls)

findRepoRoot :: IO FilePath
findRepoRoot = do
  cwd <- getCurrentDirectory
  walkUp cwd
  where
    walkUp :: FilePath -> IO FilePath
    walkUp dir = do
      hasCabal <- doesFileExist (dir </> "pyleft.cabal")
      hasScript <- doesFileExist (dir </> "scripts" </> "dump_ast_json.py")
      if hasCabal && hasScript
        then pure dir
        else do
          let parent = takeDirectory dir
          if parent == dir
            then fail "Could not find project root containing pyleft.cabal"
            else walkUp parent

ignoreAny :: SomeException -> IO ()
ignoreAny _ = pure ()
