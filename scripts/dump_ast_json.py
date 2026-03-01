#!/usr/bin/env python3
from __future__ import annotations

import ast
import json
import sys
from pathlib import Path
from typing import Any


def to_obj(n: Any) -> Any:
    """
    Convert Python's ast.AST nodes into a JSON-serializable structure.

    Returns only JSON-friendly types:
      - dict[str, Any]
      - list[Any]
      - str / int / float / bool / None
    """
    if isinstance(n, ast.AST):
        d: dict[str, Any] = {"_type": type(n).__name__}

        for k, v in ast.iter_fields(n):
            d[k] = to_obj(v)

        for attr in ("lineno", "col_offset", "end_lineno", "end_col_offset"):
            val = getattr(n, attr, None)
            if val is not None:
                d[attr] = val

        return d

    if isinstance(n, list):
        return [to_obj(x) for x in n]

    return n


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: dump_ast_json.py <file.py>", file=sys.stderr)
        return 2

    p = Path(sys.argv[1])
    src = p.read_text(encoding="utf-8")
    tree = ast.parse(src, filename=str(p))

    print(json.dumps(to_obj(tree), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
