module Pyleft.CLI.Options
  ( Options (..),
    parseOptions,
  )
where

import Options.Applicative

data Options = Options
  { optPaths :: [FilePath],
    optMaxDepth :: Int
  }
  deriving (Show)

parseOptions :: IO Options
parseOptions =
  execParser $
    info (optionsParser <**> helper) $
      fullDesc
        <> progDesc "Lint Python files and directories"

optionsParser :: Parser Options
optionsParser =
  Options
    <$> some
      ( strArgument
          ( metavar "PATHS..."
              <> help "Files or directories to lint"
          )
      )
    <*> option
      auto
      ( long "max-depth"
          <> short 'd'
          <> metavar "N"
          <> value 5
          <> showDefault
          <> help "Maximum recursive directory depth"
      )
