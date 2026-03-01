{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Rules.WildcardImport
  ( wildcardImportDiagnostics,
  )
where

import Data.Aeson (Value (..))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import Pyleft.Lint.Types (Diagnostic (..), Severity (..))

wildcardImportDiagnostics :: FilePath -> Value -> [Diagnostic]
wildcardImportDiagnostics path = go
  where
    go (Object o) =
      let here =
            case KM.lookup "_type" o of
              Just (String "ImportFrom")
                | hasStar o -> [mkDiag o]
              _ -> []
       in here <> foldMap go (KM.elems o)
    go (Array a) = foldMap go (V.toList a)
    go _ = []

    hasStar :: KM.KeyMap Value -> Bool
    hasStar o =
      case KM.lookup "names" o of
        Just (Array arr) ->
          any isStarAlias (V.toList arr)
        _ -> False

    isStarAlias :: Value -> Bool
    isStarAlias (Object a) =
      KM.lookup "_type" a == Just (String "alias")
        && KM.lookup "name" a == Just (String "*")
    isStarAlias _ = False

    mkDiag :: KM.KeyMap Value -> Diagnostic
    mkDiag o =
      Diagnostic
        { diagPath = path,
          diagLine = intField "lineno" o,
          diagCol = intField "col_offset" o,
          diagSeverity = Warning,
          diagMessage = "Wildcard import detected (`from x import *`)"
        }

    intField :: K.Key -> KM.KeyMap Value -> Int
    intField k o =
      case KM.lookup k o of
        Just (Number n) -> floor n
        _ -> 1
