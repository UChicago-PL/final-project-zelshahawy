{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.MutableDefaults
  ( mutableDefaultDiagnostics,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Vector qualified as V
import Pyleft.Lint.Types (Diagnostic, Severity (..))
import Pyleft.Rules.MakeDiag (mkDiag)

mutableDefaultDiagnostics :: FilePath -> Value -> [Diagnostic]
mutableDefaultDiagnostics path = go
  where
    go :: Value -> [Diagnostic]
    go (Object o) =
      let here =
            case KM.lookup (K.fromString "_type") o of
              Just (String "FunctionDef")
                | hasMutableDefault o -> [diag o]
              _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    diag :: KM.KeyMap Value -> Diagnostic
    diag =
      mkDiag
        path
        Warning
        "Mutable default argument detected"
        "P671"

    hasMutableDefault :: KM.KeyMap Value -> Bool
    hasMutableDefault o =
      case KM.lookup (K.fromString "args") o of
        Just (Object argsObj) ->
          case KM.lookup (K.fromString "defaults") argsObj of
            Just (Array defs) -> any isMutableLiteral (V.toList defs)
            _ -> False
        _ -> False

    isMutableLiteral :: Value -> Bool
    isMutableLiteral (Object x) =
      case KM.lookup (K.fromString "_type") x of
        Just (String "List") -> True
        Just (String "Dict") -> True
        Just (String "Set") -> True
        _ -> False
    isMutableLiteral _ = False
