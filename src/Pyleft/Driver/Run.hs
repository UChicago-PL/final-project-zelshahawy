module Pyleft.Driver.Run (main) where

import Data.Aeson (Value, eitherDecode)
import Pyleft.Frontend.Parse (parseFileToAstJson)
import Pyleft.Lint.Registry (runAllRules)
import Pyleft.Report.Format (formatDiagnosticPure)
import System.Environment (getArgs)
import System.IO (hIsTerminalDevice, stdout)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [path] -> runOne path
    _ -> putStrLn "usage: pyleft <file.py>"

runOne :: FilePath -> IO ()
runOne path = do
  jsonBytes <- parseFileToAstJson path
  case eitherDecode jsonBytes :: Either String Value of
    Left e -> putStrLn ("Failed to decode AST JSON: " <> e)
    Right astVal -> do
      let diags = runAllRules path astVal
      useColor <- hIsTerminalDevice stdout
      mapM_ (putStrLn . formatDiagnosticPure useColor) diags
