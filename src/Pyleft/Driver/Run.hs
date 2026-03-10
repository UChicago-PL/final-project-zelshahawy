module Pyleft.Driver.Run (main) where

import Data.Aeson (Value, eitherDecode)
import Pyleft.CLI.Options (Options (..), parseOptions)
import Pyleft.Driver.Discover (discoverPythonFiles)
import Pyleft.Frontend.Parse (parseFileToAstJson)
import Pyleft.Lint.Config (LintConfig, applyConfig, loadConfig)
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
    _ -> mapM_ (runOne cfg useColor) files

runOne :: LintConfig -> Bool -> FilePath -> IO ()
runOne cfg useColor path = do
  jsonBytes <- parseFileToAstJson path
  case eitherDecode jsonBytes :: Either String Value of
    Left e ->
      putStrLn (path <> ": Failed to decode AST JSON: " <> e)
    Right astVal -> do
      let diags = applyConfig cfg (runAllRules path astVal)
      mapM_ (putStrLn . formatDiagnosticPure useColor) diags
