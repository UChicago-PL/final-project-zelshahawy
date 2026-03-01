{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.BareExcept
  ( bareExceptDiagnostics,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Vector qualified as V
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

bareExceptDiagnostics :: FilePath -> Value -> [Diagnostic]
bareExceptDiagnostics path = go
  where
    go :: Value -> [Diagnostic]
    go (Object o) =
      let here = case (KM.lookup "_type" o, KM.lookup "type" o) of
            (Just (String "ExceptHandler"), Just Null) ->
              [mkDiag o]
            (Just (String "ExceptHandler"), Nothing) ->
              [mkDiag o]
            _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    mkDiag :: KM.KeyMap Value -> Diagnostic
    mkDiag o =
      Diagnostic
        { diagPath = path,
          diagLine = intField "lineno" o,
          diagCol = intField "col_offset" o,
          diagSeverity = Warning,
          diagMessage =
            "Bare except detected (use `except Exception:` or a specific exception)"
        }

    intField :: K.Key -> KM.KeyMap Value -> Int
    intField k o =
      case KM.lookup k o of
        Just (Number n) -> floor n
        _ -> 1
