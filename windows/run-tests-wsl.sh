#!/usr/bin/env bash
# WSL-only test entry point. Core Cynthia files are not changed.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
grep -qi microsoft /proc/version 2>/dev/null || {
  echo "Run this command from WSL 2." >&2
  exit 2
}
cd "$ROOT"
exec python3 -m unittest discover -s cynthia/tests -p 'test_*.py'
