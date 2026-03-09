module Pyleft.Rules.ShadowBuiltins
  ( shadowBuiltinsDiagnostics,
  )
where

import Data.Aeson (Value)
import Data.Map.Strict qualified as M
import Data.Set qualified as S
import Pyleft.Lint.Scope
  ( Binding (..),
    ScopeInfo (..),
    allScopes,
    buildScopeTree,
    pythonBuiltins,
  )
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

shadowBuiltinsDiagnostics :: FilePath -> Value -> [Diagnostic]
shadowBuiltinsDiagnostics path ast =
  concatMap scopeDiagnostics (allScopes (buildScopeTree ast))
  where
    scopeDiagnostics :: ScopeInfo -> [Diagnostic]
    scopeDiagnostics scope =
      map mkDiag $
        filter shadowsBuiltin (M.elems (scopeBindings scope))

    shadowsBuiltin :: Binding -> Bool
    shadowsBuiltin b =
      bindingName b `S.member` pythonBuiltins

    mkDiag :: Binding -> Diagnostic
    mkDiag b =
      Diagnostic
        { diagPath = path,
          diagLine = bindingLine b,
          diagCol = bindingCol b,
          diagSeverity = Warning,
          diagMessage =
            "Name shadows Python built-in: `" <> bindingName b <> "`",
          pepEight = "A001"
        }
