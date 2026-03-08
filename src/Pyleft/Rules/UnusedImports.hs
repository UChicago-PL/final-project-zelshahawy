module Pyleft.Rules.UnusedImports
  ( unusedImportDiagnostics,
  )
where

import Data.Aeson (Value)
import Data.Map.Strict qualified as M
import Data.Set qualified as S
import Pyleft.Lint.Scope
  ( Binding (..),
    BindingKind (..),
    ScopeInfo (..),
    allScopes,
    buildScopeTree,
    subtreeUses,
  )
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

unusedImportDiagnostics :: FilePath -> Value -> [Diagnostic]
unusedImportDiagnostics path ast =
  concatMap scopeDiagnostics (allScopes (buildScopeTree ast))
  where
    scopeDiagnostics :: ScopeInfo -> [Diagnostic]
    scopeDiagnostics scope =
      let usedNames = subtreeUses scope
       in map mkDiag $
            filter (isUnusedImport usedNames) (M.elems (scopeBindings scope))

    isUnusedImport :: S.Set String -> Binding -> Bool
    isUnusedImport usedNames b =
      bindingKind b == ImportBinding
        && bindingName b `S.notMember` usedNames
        && (bindingName b /= "*")

    mkDiag :: Binding -> Diagnostic
    mkDiag b =
      Diagnostic
        { diagPath = path,
          diagLine = bindingLine b,
          diagCol = bindingCol b,
          diagSeverity = Warning,
          diagMessage =
            "Unused import: `" <> bindingName b <> "`"
        }
