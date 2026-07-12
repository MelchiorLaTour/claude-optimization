#!/usr/bin/env bash
# compile-sector.sh — sector(s) → one self-contained portable markdown payload.
# Inlines each @-imported member file so any model (Codex AGENTS.md, Hermes context
# file, Perplexity paste) can consume the sector without Claude Code's @-import
# mechanism. Everything else passes through verbatim (the Tools loadout lines are
# useful to other models' adapters). Contract: ~/Claude/sectors/ADAPTERS.md
set -euo pipefail

SECTORS_DIR="$HOME/Claude/sectors"

[ $# -ge 1 ] || { echo "Usage: compile-sector.sh <sector>... (writes markdown to stdout)" >&2; exit 1; }

for sector in "$@"; do
  file="$SECTORS_DIR/$sector.md"
  [ -f "$file" ] || { echo "no such sector: $sector (looked in $SECTORS_DIR)" >&2; exit 1; }

  echo "# Sector: $sector"
  echo
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      @*)
        target="${line#@}"
        target="${target/#\~/$HOME}"
        if [ -f "$target" ]; then
          echo "## $(basename "$target" .md)"
          echo
          cat "$target"
          echo
        else
          echo "<!-- member file missing, skipped: $target -->"
        fi
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done < "$file"
  echo
done
