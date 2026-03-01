module Pyleft.Lint.Types
  ( Severity (..),
    Diagnostic (..),
  )
where

data Severity = Warning | Error
  deriving (Eq, Ord, Show)

data Diagnostic = Diagnostic
  { diagPath :: FilePath,
    diagLine :: Int,
    diagCol :: Int,
    diagSeverity :: Severity,
    diagMessage :: String
  }
  deriving (Eq, Show)
