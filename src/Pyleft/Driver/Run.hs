module Pyleft.Driver.Run (main) where

import Data.Aeson (Value, eitherDecode)
import Pyleft.CLI.Options (Options (..), parseOptions)
import Pyleft.Driver.Discover (discoverPythonFiles)
import Pyleft.Frontend.Parse (parseFileToAstJson)
import Pyleft.Lint.Registry (runAllRules)
import Pyleft.Report.Format (formatDiagnosticPure)
import System.IO (hIsTerminalDevice, stdout)

main :: IO ()
main = do
  opts <- parseOptions
  runPaths (optMaxDepth opts) (optPaths opts)

runPaths :: Int -> [FilePath] -> IO ()
runPaths maxDepth paths = do
  files <- discoverPythonFiles maxDepth paths
  useColor <- hIsTerminalDevice stdout

  case files of
    [] -> putStrLn "No Python files found."
    _ -> mapM_ (runOne useColor) files

runOne :: Bool -> FilePath -> IO ()
runOne useColor path = do
  jsonBytes <- parseFileToAstJson path
  case eitherDecode jsonBytes :: Either String Value of
    Left e ->
      putStrLn (path <> ": Failed to decode AST JSON: " <> e)
    Right astVal -> do
      let diags = runAllRules path astVal
      mapM_ (putStrLn . formatDiagnosticPure useColor) diags
