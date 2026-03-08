module Pyleft.Rules.ShadowBuiltins
  ( shadowBuiltinsDiagnostics,
  )
where

import Data.Aeson (Value)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
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
            "Name shadows Python built-in: `" <> bindingName b <> "`"
        }
