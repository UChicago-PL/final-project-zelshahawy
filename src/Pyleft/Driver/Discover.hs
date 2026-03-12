module Pyleft.Driver.Discover
  ( discoverPythonFiles,
  )
where

import Data.List (nub, sort)
import System.Directory
  ( doesDirectoryExist,
    doesFileExist,
    listDirectory,
  )
import System.FilePath (takeExtension, takeFileName, (</>))

discoverPythonFiles :: Int -> [FilePath] -> IO [FilePath]
discoverPythonFiles maxDepth paths = do
  nested <- mapM (discoverPath maxDepth) paths
  pure (sort (nub (concat nested)))

discoverPath :: Int -> FilePath -> IO [FilePath]
discoverPath depthLeft path = do
  isFile <- doesFileExist path
  isDir <- doesDirectoryExist path

  if isFile
    then
      pure ([path | takeExtension path == ".py"])
    else
      if isDir
        then
          if shouldSkipDir path || depthLeft < 0
            then pure []
            else do
              names <- listDirectory path
              let children = map (path </>) names
              nested <- mapM (discoverPath (depthLeft - 1)) children
              pure (concat nested)
        else
          pure []

shouldSkipDir :: FilePath -> Bool
shouldSkipDir path =
  takeFileName path
    `elem` [ ".git",
             ".venv",
             "venv",
             "__pycache__",
             "node_modules",
             "dist-newstyle"
           ]
