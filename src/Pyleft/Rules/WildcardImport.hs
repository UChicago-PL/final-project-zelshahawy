{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.WildcardImport
  ( wildcardImportDiagnostics,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Vector qualified as V
import Pyleft.Lint.Types (Diagnostic, Severity (..))
import Pyleft.Rules.MakeDiag (mkDiag)

wildcardImportDiagnostics :: FilePath -> Value -> [Diagnostic]
wildcardImportDiagnostics path = go
  where
    go :: Value -> [Diagnostic]
    go (Object o) =
      let here =
            case KM.lookup (K.fromString "_type") o of
              Just (String "ImportFrom")
                | hasStar o -> [diag o]
              _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    diag :: KM.KeyMap Value -> Diagnostic
    diag =
      mkDiag
        "wildcard-import"
        path
        Warning
        "Wildcard import detected (`from x import *`)"
        "F403"

    hasStar :: KM.KeyMap Value -> Bool
    hasStar o =
      case KM.lookup (K.fromString "names") o of
        Just (Array arr) -> any isStarAlias (V.toList arr)
        _ -> False

    isStarAlias :: Value -> Bool
    isStarAlias (Object a) =
      KM.lookup (K.fromString "_type") a == Just (String "alias")
        && KM.lookup (K.fromString "name") a == Just (String "*")
    isStarAlias _ = False
