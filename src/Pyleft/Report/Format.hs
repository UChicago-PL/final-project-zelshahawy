module Pyleft.Report.Format
  ( Theme (..),
    formatDiagnosticPure,
  )
where

import Pyleft.Lint.Types

data Theme
  = DarkMode
  | LightMode
  deriving (Eq, Show)

formatDiagnosticPure :: Bool -> Theme -> Diagnostic -> String
formatDiagnosticPure useColor theme d =
  ruleTag theme (pepEight d)
    <> " "
    <> locPart theme loc
    <> ": "
    <> sevTag useColor theme (diagSeverity d)
    <> " "
    <> diagMessage d
  where
    loc =
      pathColor theme (diagPath d <> ": ")
        <> lineColColor theme (show (diagLine d))
        <> ":"
        <> lineColColor theme (show (diagCol d))

sevTag :: Bool -> Theme -> Severity -> String
sevTag useColor theme s =
  "["
    <> case s of
      Warning -> colorWarning useColor theme "warning"
      Error -> colorError useColor theme "error"
      Info -> colorInfo useColor theme "info"
    <> "]"

locPart :: Theme -> String -> String
locPart DarkMode = id
locPart LightMode = id

pathColor :: Theme -> String -> String
pathColor LightMode = ansiMintGreen
pathColor DarkMode = ansiGreen

lineColColor :: Theme -> String -> String
lineColColor LightMode = ansiYellow
lineColColor DarkMode = ansiBlue

ruleTag :: Theme -> String -> String
ruleTag LightMode = ansiRed
ruleTag DarkMode = ansiMagenta

ansiReset :: String
ansiReset = "\ESC[0m"

ansi256 :: Int -> String -> String
ansi256 n s = "\ESC[38;5;" <> show n <> "m" <> s <> ansiReset

ansiRed :: String -> String
ansiRed s = "\ESC[31m" <> s <> ansiReset

ansiBlue :: String -> String
ansiBlue s = "\ESC[34m" <> s <> ansiReset

ansiYellow :: String -> String
ansiYellow s = "\ESC[33m" <> s <> ansiReset

ansiGreen :: String -> String
ansiGreen s = "\ESC[32m" <> s <> ansiReset

ansiMagenta :: String -> String
ansiMagenta s = "\ESC[35m" <> s <> ansiReset

ansiMintGreen :: String -> String
ansiMintGreen s = "\ESC[38;5;49m" <> s <> ansiReset

colorWarning :: Bool -> Theme -> String -> String
colorWarning False _ s = s
colorWarning True LightMode s = ansi256 208 s
colorWarning True DarkMode s = ansiYellow s

colorError :: Bool -> Theme -> String -> String
colorError False _ s = s
colorError True _ s = ansiRed s

colorInfo :: Bool -> Theme -> String -> String
colorInfo False _ s = s
colorInfo True LightMode s = ansiBlue s
colorInfo True DarkMode s = ansiMagenta s
