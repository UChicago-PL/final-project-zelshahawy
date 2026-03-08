module Pyleft.Rules.UnusedLocals
  ( unusedLocalDiagnostics,
  )
where

import Data.Aeson (Value)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Pyleft.Lint.Scope
  ( Binding (..),
    BindingKind (..),
    ScopeInfo (..),
    allScopes,
    buildScopeTree,
    subtreeUses,
  )
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

unusedLocalDiagnostics :: FilePath -> Value -> [Diagnostic]
unusedLocalDiagnostics path ast =
  concatMap scopeDiagnostics (allScopes (buildScopeTree ast))
  where
    scopeDiagnostics :: ScopeInfo -> [Diagnostic]
    scopeDiagnostics scope =
      let usedNames = subtreeUses scope
       in map mkDiag $
            filter (isUnusedLocal usedNames) (M.elems (scopeBindings scope))

    isUnusedLocal :: S.Set String -> Binding -> Bool
    isUnusedLocal usedNames b =
      bindingKind b == LocalBinding
        && not (isIgnoredName (bindingName b))
        && bindingName b `S.notMember` usedNames

    isIgnoredName :: String -> Bool
    isIgnoredName "_" = True
    isIgnoredName ('_' : _) = True
    isIgnoredName _ = False

    mkDiag :: Binding -> Diagnostic
    mkDiag b =
      Diagnostic
        { diagPath = path,
          diagLine = bindingLine b,
          diagCol = bindingCol b,
          diagSeverity = Warning,
          diagMessage =
            "Unused local variable: `" <> bindingName b <> "`"
        }
