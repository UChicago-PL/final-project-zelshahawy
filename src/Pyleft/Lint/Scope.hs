{-# LANGUAGE OverloadedStrings #-}

module Pyleft.Lint.Scope
  ( BindingKind (..),
    Binding (..),
    ScopeKind (..),
    ScopeInfo (..),
    buildScopeTree,
    allScopes,
    subtreeUses,
    pythonBuiltins,
  )
where

import Data.Aeson (Value (..))
import Data.Aeson.Key qualified as K
import Data.Aeson.KeyMap qualified as KM
import Data.Map.Strict qualified as M
import Data.Set qualified as S
import Data.Text qualified as T
import Data.Vector qualified as V

data BindingKind
  = ImportBinding
  | LocalBinding
  | ParamBinding
  | FunctionBinding
  | ClassBinding
  deriving (Eq, Show)

data Binding = Binding
  { bindingName :: String,
    bindingKind :: BindingKind,
    bindingLine :: Int,
    bindingCol :: Int
  }
  deriving (Eq, Show)

data ScopeKind
  = ModuleScope
  | FunctionScope
  | ClassScope
  deriving (Eq, Show)

data ScopeInfo = ScopeInfo
  { scopeKind :: ScopeKind,
    scopeBindings :: M.Map String Binding,
    scopeUses :: S.Set String,
    scopeChildren :: [ScopeInfo]
  }
  deriving (Eq, Show)

data Collected = Collected
  { collectedBindings :: M.Map String Binding,
    collectedUses :: S.Set String,
    collectedChildren :: [ScopeInfo]
  }

instance Semigroup Collected where
  Collected b1 u1 c1 <> Collected b2 u2 c2 =
    Collected
      (M.union b1 b2)
      (S.union u1 u2)
      (c1 <> c2)

instance Monoid Collected where
  mempty = Collected M.empty S.empty []

buildScopeTree :: Value -> ScopeInfo
buildScopeTree v =
  case v of
    Object o
      | nodeType o == Just "Module" ->
          fromCollected ModuleScope $
            maybe mempty collectInCurrentScope (field "body" o)
    _ ->
      fromCollected ModuleScope (collectInCurrentScope v)

allScopes :: ScopeInfo -> [ScopeInfo]
allScopes s = s : concatMap allScopes (scopeChildren s)

subtreeUses :: ScopeInfo -> S.Set String
subtreeUses s =
  S.unions (scopeUses s : map subtreeUses (scopeChildren s))

pythonBuiltins :: S.Set String
pythonBuiltins =
  S.fromList
    [ "abs",
      "all",
      "any",
      "bool",
      "dict",
      "enumerate",
      "filter",
      "float",
      "id",
      "input",
      "int",
      "len",
      "list",
      "map",
      "max",
      "min",
      "print",
      "range",
      "reversed",
      "round",
      "set",
      "sorted",
      "str",
      "sum",
      "tuple",
      "type",
      "zip"
    ]

fromCollected :: ScopeKind -> Collected -> ScopeInfo
fromCollected kind c =
  ScopeInfo
    { scopeKind = kind,
      scopeBindings = collectedBindings c,
      scopeUses = collectedUses c,
      scopeChildren = collectedChildren c
    }

collectInCurrentScope :: Value -> Collected
collectInCurrentScope (Object o) =
  case nodeType o of
    Just "FunctionDef" -> collectFunctionLike o
    Just "AsyncFunctionDef" -> collectFunctionLike o
    Just "Lambda" -> collectLambda o
    Just "ClassDef" -> collectClass o
    Just "Import" -> Collected (importBindings o) S.empty []
    Just "ImportFrom" -> Collected (importBindings o) S.empty []
    Just "Name" -> collectName o
    _ -> collectChildren (KM.elems o)
collectInCurrentScope (Array a) =
  collectChildren (V.toList a)
collectInCurrentScope _ =
  mempty

collectChildren :: [Value] -> Collected
collectChildren = foldMap collectInCurrentScope

collectFunctionLike :: KM.KeyMap Value -> Collected
collectFunctionLike o =
  nameBinding <> outerUses <> childScope
  where
    nameBinding =
      case textField "name" o of
        Just n ->
          Collected
            (M.singleton n (bindingFromNode FunctionBinding n o))
            S.empty
            []
        Nothing ->
          mempty

    -- These expressions are evaluated in the outer scope.
    outerUses =
      collectChildren (maybeToList (field "decorator_list" o) ++ maybeToList (field "returns" o))

    childScope =
      Collected
        M.empty
        S.empty
        [buildFunctionScope o]

collectLambda :: KM.KeyMap Value -> Collected
collectLambda o =
  Collected
    M.empty
    S.empty
    [buildLambdaScope o]

collectClass :: KM.KeyMap Value -> Collected
collectClass o =
  nameBinding <> outerUses <> childScope
  where
    nameBinding =
      case textField "name" o of
        Just n ->
          Collected
            (M.singleton n (bindingFromNode ClassBinding n o))
            S.empty
            []
        Nothing ->
          mempty

    -- Bases / decorators are evaluated in the outer scope.
    outerUses =
      collectChildren $
        concat
          [ maybeToList (field "bases" o),
            maybeToList (field "keywords" o),
            maybeToList (field "decorator_list" o)
          ]

    childScope =
      Collected
        M.empty
        S.empty
        [buildClassScope o]

collectName :: KM.KeyMap Value -> Collected
collectName o =
  case (textField "id" o, nameContext o) of
    (Just n, Just "Load") ->
      Collected M.empty (S.singleton n) []
    (Just n, Just "Store") ->
      Collected
        (M.singleton n (bindingFromNode LocalBinding n o))
        S.empty
        []
    _ ->
      mempty

buildFunctionScope :: KM.KeyMap Value -> ScopeInfo
buildFunctionScope o =
  fromCollected FunctionScope (paramBindings <> bodyCollected)
  where
    paramBindings =
      Collected (functionParamBindings o) S.empty []

    bodyCollected = maybe mempty collectInCurrentScope (field "body" o)

buildLambdaScope :: KM.KeyMap Value -> ScopeInfo
buildLambdaScope o =
  fromCollected FunctionScope (paramBindings <> bodyCollected)
  where
    paramBindings =
      Collected (lambdaParamBindings o) S.empty []

    bodyCollected = maybe mempty collectInCurrentScope (field "body" o)

buildClassScope :: KM.KeyMap Value -> ScopeInfo
buildClassScope o =
  case field "body" o of
    Just bodyVal -> fromCollected ClassScope (collectInCurrentScope bodyVal)
    Nothing -> fromCollected ClassScope mempty

functionParamBindings :: KM.KeyMap Value -> M.Map String Binding
functionParamBindings o =
  case field "args" o of
    Just (Object argsObj) -> argBindingsFromArgsObj argsObj
    _ -> M.empty

lambdaParamBindings :: KM.KeyMap Value -> M.Map String Binding
lambdaParamBindings = functionParamBindings

argBindingsFromArgsObj :: KM.KeyMap Value -> M.Map String Binding
argBindingsFromArgsObj argsObj =
  foldr addArg M.empty allArgNodes
  where
    allArgNodes =
      concat
        [ arrayField "posonlyargs" argsObj,
          arrayField "args" argsObj,
          maybeToList (field "vararg" argsObj),
          arrayField "kwonlyargs" argsObj,
          maybeToList (field "kwarg" argsObj)
        ]

    addArg :: Value -> M.Map String Binding -> M.Map String Binding
    addArg (Object a) acc =
      case textField "arg" a of
        Just n -> M.insert n (bindingFromNode ParamBinding n a) acc
        Nothing -> acc
    addArg _ acc = acc

importBindings :: KM.KeyMap Value -> M.Map String Binding
importBindings o =
  case field "names" o of
    Just (Array arr) ->
      foldr addAlias M.empty (V.toList arr)
    _ ->
      M.empty
  where
    addAlias :: Value -> M.Map String Binding -> M.Map String Binding
    addAlias (Object aliasObj) acc =
      case importBoundName aliasObj of
        Just n -> M.insert n (bindingFromNode ImportBinding n aliasObj) acc
        Nothing -> acc
    addAlias _ acc = acc

importBoundName :: KM.KeyMap Value -> Maybe String
importBoundName aliasObj =
  case textField "asname" aliasObj of
    Just n ->
      Just n
    Nothing ->
      case textField "name" aliasObj of
        Just n -> Just (takeWhile (/= '.') n)
        Nothing -> Nothing

bindingFromNode :: BindingKind -> String -> KM.KeyMap Value -> Binding
bindingFromNode kind name o =
  Binding
    { bindingName = name,
      bindingKind = kind,
      bindingLine = intField "lineno" o,
      bindingCol = intField "col_offset" o
    }

nameContext :: KM.KeyMap Value -> Maybe String
nameContext o = do
  ctxVal <- field "ctx" o
  case ctxVal of
    Object ctxObj -> nodeType ctxObj
    _ -> Nothing

nodeType :: KM.KeyMap Value -> Maybe String
nodeType = textField "_type"

field :: String -> KM.KeyMap Value -> Maybe Value
field k = KM.lookup (K.fromString k)

textField :: String -> KM.KeyMap Value -> Maybe String
textField k o =
  case field k o of
    Just (String t) -> Just (T.unpack t)
    _ -> Nothing

arrayField :: String -> KM.KeyMap Value -> [Value]
arrayField k o =
  case field k o of
    Just (Array arr) -> V.toList arr
    _ -> []

intField :: String -> KM.KeyMap Value -> Int
intField k o =
  case field k o of
    Just (Number n) -> floor n
    _ -> 1

maybeToList :: Maybe a -> [a]
maybeToList (Just x) = [x]
maybeToList Nothing = []
