# Pyleft Report

## Overview

Pyleft is a Python linter written in Haskell. It parses Python files into an AST, runs a set of lint rules on that structure,
and prints diagnostics with file and source location information. The project supports linting single files or directories recursively,
optional configuration through `pyleft.toml`, and parallel processing for multiple files.

## Code Organization

- `app/Main.hs`  
  Entry point. Starts the executable and calls the main driver.

- `src/Pyleft/Driver/Run.hs`  
  Main runtime flow. Loads config, discovers files, runs linting, and prints diagnostics.

- `src/Pyleft/Driver/Discover.hs`  
  Finds Python files from user-supplied paths, including recursive directory traversal.

- `src/Pyleft/Frontend/Parse.hs`  
  Calls the Python helper script to parse Python source into AST JSON.

- `scripts/dump_ast_json.py`  
  Uses Python’s built-in `ast` module to generate JSON for a Python file.

- `src/Pyleft/Lint/Types.hs`  
  Defines shared diagnostic and severity types.

- `src/Pyleft/Lint/Registry.hs`  
  Collects all lint rules and runs them together.

- `src/Pyleft/Lint/Scope.hs`  
  Builds scope information used by the scope-aware rules.

- `src/Pyleft/Lint/Config.hs`  
  Loads optional configuration from `pyleft.toml`.

- `src/Pyleft/Report/Format.hs`  
  Formats diagnostics for terminal output, including theme/color handling.

- `src/Pyleft/Rules/`  
  Contains the individual lint rules, including:
  - `BareExcept.hs`
  - `WildcardImport.hs`
  - `MutableDefaults.hs`
  - `UnusedImports.hs`
  - `UnusedLocals.hs`
  - `ShadowBuiltins.hs`
  - `MakeDiag.hs` for shared diagnostic helpers

Run it on a file:

```bash
pyleft path/to/file.py
```

Run it on a directory:

```bash
pyleft path/to/project
```

Optional configuration can be placed in pyleft.toml to disable rules, change severities, or choose a light/dark output theme.

Example

```toml
theme = "light"
disable = []

[severity]
unused-import = "warning"
unused-local = "info"
mutable-defaults = "warning"
wildcard-import = "warning"
shadow-builtins = "error"
```

## Proposal Implemented

I did all the easy and medium stuff. And the Challenge: Add threading support for single and multiple files usage.
