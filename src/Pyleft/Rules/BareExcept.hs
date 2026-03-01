{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.BareExcept
  ( bareExceptDiagnostics,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Vector qualified as V
import Pyleft.Lint.Types (Diagnostic, Severity (..))
import Pyleft.Rules.MakeDiag (mkDiag)

bareExceptDiagnostics :: FilePath -> Value -> [Diagnostic]
bareExceptDiagnostics path = go
  where
    go :: Value -> [Diagnostic]
    go (Object o) =
      let here =
            case (KM.lookup (K.fromString "_type") o, KM.lookup (K.fromString "type") o) of
              (Just (String "ExceptHandler"), Just Null) -> [diag o]
              (Just (String "ExceptHandler"), Nothing) -> [diag o]
              _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    diag :: KM.KeyMap Value -> Diagnostic
    diag =
      mkDiag
        path
        Warning
        "Bare except detected (use `except Exception:` or a specific exception)"
