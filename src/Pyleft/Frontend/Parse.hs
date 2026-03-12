module Pyleft.Frontend.Parse
  ( parseFileToAstJson,
  )
where

import Data.ByteString.Lazy qualified as BL
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import System.Directory (doesFileExist)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)

parseFileToAstJson :: FilePath -> IO BL.ByteString
parseFileToAstJson path = do
  let script = "scripts" </> "dump_ast_json.py"
  ok <- doesFileExist script
  if not ok
    then fail ("Missing script: " <> script <> " (run from repo root?)")
    else do
      (ec, out, err) <- readProcessWithExitCode "python3" [script, path] ""
      case ec of
        ExitSuccess ->
          pure (BL.fromStrict (TE.encodeUtf8 (T.pack out)))
        ExitFailure _ ->
          fail ("python3 " <> script <> " failed:\n" <> err)
