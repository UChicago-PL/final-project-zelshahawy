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
import Data.Text qualified as T
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))
import System.Directory (doesFileExist)
import TOML
  ( DecodeTOML (..),
    decodeFile,
    getFieldOpt,
  )

data RawConfig = RawConfig
  { rawDisable :: Maybe [String],
    rawSeverity :: Maybe (M.Map String String)
  }
  deriving (Eq, Show)

data LintConfig = LintConfig
  { cfgDisabledRules :: S.Set String,
    cfgSeverityMap :: M.Map String Severity
  }
  deriving (Eq, Show)

defaultConfig :: LintConfig
defaultConfig =
  LintConfig
    { cfgDisabledRules = S.empty,
      cfgSeverityMap = M.empty
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
        M.mapMaybe parseSeverity (Data.Maybe.fromMaybe M.empty (rawSeverity raw))
    }

parseSeverity :: String -> Maybe Severity
parseSeverity s =
  case s of
    "info" -> Just Info
    "warning" -> Just Warning
    "error" -> Just Error
    _ -> Nothing

instance DecodeTOML RawConfig where
  tomlDecoder =
    RawConfig
      <$> getFieldOpt (T.pack "disable")
      <*> getFieldOpt (T.pack "severity")
