# Final Project Proposal for CMSC 22300

# Project Title: Pyleft: A Pyright replacement, 

## Author: Ziad Elshahawy

## Email: [zelshahawy@uchicago.edu](mailto:zelshahawy@uchicago.edu)

### Concept Overview

For my final project, I will build **Pyleft**, a Python linter written in **Haskell** that performs **AST-based static analysis** on Python source files.
The core idea is to parse Python into an abstract syntax tree, then walk that tree to enforce a set of correctness and style rules that require *semantic structure* (not just regex scanning).
The tool will run from the command line, analyze one or more `.py` files, and report warnings/errors with file, line, and column information.

To keep the project focused and robust, I will use Python’s built-in `ast` module as a front-end parser: Haskell will then decode that JSON into typed data structures and run the linter rules in a mostly pure pipeline.
This may not be the cleanest solution though, so I will look for alternatives that would not need any python modules.

This design should help me place emphasis on Haskell data modeling, traversal, and scope tracking, rather than on implementing a full Python grammar from scratch.

### Goals and Milestones

#### Easy

* Support linting a single `.py` file from the command line (and print diagnostics).
* Parse Python into an AST (via JSON) and decode it into Haskell types.
* Implement a basic rule set that clearly requires AST structure:

  * Flag **bare `except:`** clauses.
  * Flag **wildcard imports** (`from x import *`).
  * Flag **mutable default arguments** (`def f(x=[]): ...`).
* Print diagnostics in a standard format: `path:line:col: [severity] message`.

#### Medium

* Add **scope-aware analysis** (per module / function / class):

  * Detect **unused imports**.
  * Detect **unused local variables** (simple version).
  * Detect **shadowing built-ins** (`list`, `dict`, `id`, etc.).
* Support linting multiple files / directories recursively.
* Add configuration (minimal, optional): allow disabling rules or setting severity levels.

#### Challenge

* Add threading support for single and multiple files usage.
* Improve precision and reduce false positives:

  * Track “read vs assigned” for variables more accurately.
  * Handle `global` / `nonlocal` cases reasonably.
  * Handle comprehensions and exception bindings (`except E as x`) correctly.
* Add a “fix suggestion” mode (no auto-edit required) that prints recommended rewrites for certain rules:

  * `except:` → `except Exception:`
  * Mutable defaults → `None` pattern with initialization in body
* If time permits: implement a small **control-flow aware** rule (basic unreachable code after `return` in the same block, or always-true conditions for a limited set).

### Additional Topics and Resources

I expect to learn most of this through Python documentation for `ast`, Haskell library docs, and prior course material on algebraic data types, recursion, and monadic/applicative organization.

### Inspiration and Collaboration

I was inspired by the Readers/Writers Lecture. I have also been inspired by my deep hate for pyright (long story), and I would be immeasurably happy to replace it. Even though I have been aware of the theory behind it,
This is the first time I interact with AST's so I expect to have a lot of fun with this.
