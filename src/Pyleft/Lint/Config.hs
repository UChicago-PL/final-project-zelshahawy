{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Lint.Config
  ( LintConfig (..),
    defaultConfig,
    loadConfig,
    applyConfig,
  )
where

import Data.Map.Strict qualified as M
import Data.Maybe qualified
import Data.Set qualified as S
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))
import Pyleft.Report.Format (Theme (..))
import System.Directory (doesFileExist)
import TOML
  ( DecodeTOML (..),
    decodeFile,
    getFieldOpt,
  )

data RawConfig = RawConfig
  { rawDisable :: Maybe [String],
    rawSeverity :: Maybe (M.Map String String),
    rawTheme :: Maybe String
  }
  deriving (Eq, Show)

data LintConfig = LintConfig
  { cfgDisabledRules :: S.Set String,
    cfgSeverityMap :: M.Map String Severity,
    cfgTheme :: Theme
  }
  deriving (Eq, Show)

defaultConfig :: LintConfig
defaultConfig =
  LintConfig
    { cfgDisabledRules = S.empty,
      cfgSeverityMap = M.empty,
      cfgTheme = DarkMode
    }

loadConfig :: IO LintConfig
loadConfig = do
  let path = "pyleft.toml"
  exists <- doesFileExist path
  if not exists
    then pure defaultConfig
    else do
      result <- decodeFile path
      case result of
        Left err ->
          fail ("Failed to parse pyleft.toml:\n" <> show err)
        Right rawCfg ->
          pure (fromRawConfig rawCfg)

applyConfig :: LintConfig -> [Diagnostic] -> [Diagnostic]
applyConfig cfg =
  map applySeverity . filter isEnabled
  where
    isEnabled :: Diagnostic -> Bool
    isEnabled d =
      diagRule d `S.notMember` cfgDisabledRules cfg

    applySeverity :: Diagnostic -> Diagnostic
    applySeverity d =
      case M.lookup (diagRule d) (cfgSeverityMap cfg) of
        Just sev -> d {diagSeverity = sev}
        Nothing -> d

fromRawConfig :: RawConfig -> LintConfig
fromRawConfig raw =
  LintConfig
    { cfgDisabledRules = S.fromList (Data.Maybe.fromMaybe [] (rawDisable raw)),
      cfgSeverityMap =
        M.mapMaybe parseSeverity (Data.Maybe.fromMaybe M.empty (rawSeverity raw)),
      cfgTheme =
        maybe DarkMode parseTheme (rawTheme raw)
    }

parseSeverity :: String -> Maybe Severity
parseSeverity s =
  case s of
    "info" -> Just Info
    "warning" -> Just Warning
    "error" -> Just Error
    _ -> Nothing

parseTheme :: String -> Theme
parseTheme s =
  case s of
    "light" -> LightMode
    _ -> DarkMode

instance DecodeTOML RawConfig where
  tomlDecoder =
    RawConfig
      <$> getFieldOpt "disable"
      <*> getFieldOpt "severity"
      <*> getFieldOpt "theme"
