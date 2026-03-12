module Pyleft.Rules.MakeDiag
  ( mkDiag,
    intField,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

mkDiag :: String -> FilePath -> Severity -> String -> String -> KM.KeyMap Value -> Diagnostic
mkDiag ruleId path sev msg code o =
  Diagnostic
    { diagPath = path,
      diagLine = intField (K.fromString "lineno") o,
      diagCol = intField (K.fromString "col_offset") o,
      diagSeverity = sev,
      diagMessage = msg,
      pepEight = code,
      diagRule = ruleId
    }

intField :: K.Key -> KM.KeyMap Value -> Int
intField k o =
  case KM.lookup k o of
    Just (Number n) -> floor n
    _ -> 1
