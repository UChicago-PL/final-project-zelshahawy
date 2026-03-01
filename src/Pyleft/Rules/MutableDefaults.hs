{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.MutableDefaults
  ( mutableDefaultDiagnostics,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Vector qualified as V
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

mutableDefaultDiagnostics :: FilePath -> Value -> [Diagnostic]
mutableDefaultDiagnostics path = go
  where
    go (Object o) =
      let here =
            case KM.lookup "_type" o of
              Just (String "FunctionDef")
                | hasMutableDefault o -> [mkDiag o]
              _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    hasMutableDefault :: KM.KeyMap Value -> Bool
    hasMutableDefault o =
      case KM.lookup "args" o of
        Just (Object argsObj) ->
          case KM.lookup "defaults" argsObj of
            Just (Array defs) -> any isMutableLiteral (V.toList defs)
            _ -> False
        _ -> False

    isMutableLiteral :: Value -> Bool
    isMutableLiteral (Object x) =
      case KM.lookup "_type" x of
        Just (String "List") -> True
        Just (String "Dict") -> True
        Just (String "Set") -> True
        _ -> False
    isMutableLiteral _ = False

    mkDiag :: KM.KeyMap Value -> Diagnostic
    mkDiag o =
      Diagnostic
        { diagPath = path,
          diagLine = intField "lineno" o,
          diagCol = intField "col_offset" o,
          diagSeverity = Warning,
          diagMessage = "Mutable default argument detected"
        }

    intField :: K.Key -> KM.KeyMap Value -> Int
    intField k o =
      case KM.lookup k o of
        Just (Number n) -> floor n
        _ -> 1
