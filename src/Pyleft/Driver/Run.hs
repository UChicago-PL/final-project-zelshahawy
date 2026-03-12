module Pyleft.Driver.Run (main) where

import Control.Concurrent.Async (mapConcurrently)
import Control.Concurrent.QSem
import Control.Exception (bracket_)
import Data.Aeson (Value, eitherDecode)
import Pyleft.CLI.Options (Options (..), parseOptions)
import Pyleft.Driver.Discover (discoverPythonFiles)
import Pyleft.Frontend.Parse (parseFileToAstJson)
import Pyleft.Lint.Config (LintConfig (..), applyConfig, loadConfig)
import Pyleft.Lint.Registry (runAllRules)
import Pyleft.Report.Format (formatDiagnosticPure)
import System.IO (hIsTerminalDevice, stdout)

main :: IO ()
main = do
  opts <- parseOptions
  cfg <- loadConfig
  runPaths cfg (optMaxDepth opts) (optPaths opts)

runPaths :: LintConfig -> Int -> [FilePath] -> IO ()
runPaths cfg maxDepth paths = do
  files <- discoverPythonFiles maxDepth paths
  useColor <- hIsTerminalDevice stdout

  case files of
    [] -> putStrLn "No Python files found."
    _ -> do
      outputs <- mapConcurrentlyBoundedIO 8 (runOne cfg useColor) files
      mapM_ putStr outputs

runOne :: LintConfig -> Bool -> FilePath -> IO String
runOne cfg useColor path = do
  jsonBytes <- parseFileToAstJson path
  case eitherDecode jsonBytes :: Either String Value of
    Left e ->
      pure (path <> ": Failed to decode AST JSON: " <> e <> "\n")
    Right astVal -> do
      let diags = applyConfig cfg (runAllRules path astVal)
      pure $
        unlines (map (formatDiagnosticPure useColor (cfgTheme cfg)) diags)

mapConcurrentlyBoundedIO :: Int -> (a -> IO b) -> [a] -> IO [b]
mapConcurrentlyBoundedIO maxThreads action xs = do
  sem <- newQSem maxThreads
  mapConcurrently (withSem sem . action) xs
  where
    withSem :: QSem -> IO b -> IO b
    withSem sem =
      bracket_
        (waitQSem sem)
        (signalQSem sem)
