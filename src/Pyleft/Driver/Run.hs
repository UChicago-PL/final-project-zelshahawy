module Pyleft.Driver.Run (main) where

import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [path] -> putStrLn ("pyleft: got file " ++ path)
    _ -> putStrLn "usage: pyleft <file.py>"
