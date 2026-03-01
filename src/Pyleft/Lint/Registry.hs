module Pyleft.Lint.Registry
  ( runAllRules,
  )
where

import Data.Aeson (Value)
import Pyleft.Lint.Types (Diagnostic)
import Pyleft.Rules.BareExcept (bareExceptDiagnostics)
import Pyleft.Rules.MutableDefaults (mutableDefaultDiagnostics)
import Pyleft.Rules.WildcardImport (wildcardImportDiagnostics)

runAllRules :: FilePath -> Value -> [Diagnostic]
runAllRules path ast =
  concat
    [ bareExceptDiagnostics path ast,
      wildcardImportDiagnostics path ast,
      mutableDefaultDiagnostics path ast
    ]
