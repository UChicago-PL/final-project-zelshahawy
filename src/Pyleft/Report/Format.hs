module Pyleft.Report.Format
  ( formatDiagnosticPure,
  )
where

import Pyleft.Lint.Types

formatDiagnosticPure :: Bool -> Diagnostic -> String
formatDiagnosticPure useColor d =
  ansiRed (pepEight d) <> " " <> dim useColor (loc <> ": ") <> sevTag useColor (diagSeverity d) <> " " <> diagMessage d
  where
    loc =
      diagPath d <> ":" <> show (diagLine d) <> ":" <> show (diagCol d)

sevTag :: Bool -> Severity -> String
sevTag useColor s =
  "["
    <> case s of
      Warning -> colorWarning useColor "warning"
      Error -> colorError useColor "error"
      Info -> colorInfo useColor "info"
    <> "]"

-- Styling helpers

ansiReset :: String
ansiReset = "\ESC[0m"

ansiDim :: String -> String
ansiDim s = "\ESC[2m" <> s <> ansiReset

ansi256 :: Int -> String -> String
ansi256 n s = "\ESC[38;5;" <> show n <> "m" <> s <> ansiReset

ansiRed :: String -> String
ansiRed s = "\ESC[31m" <> s <> ansiReset

ansiBlue :: String -> String
ansiBlue s = "\ESC[34m" <> s <> ansiReset

dim :: Bool -> String -> String
dim False s = s
dim True s = ansiDim s

colorWarning :: Bool -> String -> String
colorWarning False s = s
colorWarning True s = ansi256 208 s -- orange-ish

colorError :: Bool -> String -> String
colorError False s = s
colorError True s = ansiRed s

colorInfo :: Bool -> String -> String
colorInfo False s = s
colorInfo True s = ansiBlue s
