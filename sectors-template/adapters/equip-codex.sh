#!/usr/bin/env bash
# equip-codex.sh — the Codex adapter (contract: ~/Claude/sectors/ADAPTERS.md).
# 1. Compiles the project's sectors into a self-contained payload and writes it
#    into <project>/AGENTS.md between markers (idempotent re-runs).
# 2. Merges each sector `mcp:` line into ~/.codex/config.toml as an
#    [mcp_servers.<tool>] block (backup first; skips blocks already present).
# 3. Prints the sectors' `skills:` install pointers for manual follow-up.
# Built-to-spec 2026-07-02; NOT live-tested (no Codex install yet).
set -euo pipefail

SECTORS_DIR="$HOME/Claude/sectors"
ADAPTERS_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_TOML="$HOME/.codex/config.toml"
BEGIN_MARK='<!-- BEGIN sectors (equip-codex) -->'
END_MARK='<!-- END sectors (equip-codex) -->'

usage() {
  cat <<'EOF'
Usage:
  equip-codex.sh [project-dir]     Equip all sectors from the project's CLAUDE.md (default: cwd)
  equip-codex.sh add <sector>...   One-off: equip named sectors into ./AGENTS.md
EOF
}

# --- resolve target dir + sector list (mirrors equip-loadout.sh) ---
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  add)
    shift
    [ $# -ge 1 ] || { usage; exit 1; }
    target="$PWD"
    sectors="$*"
    ;;
  *)
    target="$(cd "${1:-$PWD}" 2>/dev/null && pwd)" \
      || { echo "no such directory: $1" >&2; exit 1; }
    claude_md="$target/CLAUDE.md"
    [ -f "$claude_md" ] || {
      echo "no CLAUDE.md in $target — not a project. Use 'add <sector>' for a one-off." >&2
      exit 1
    }
    sectors="$(grep -oE '@[^[:space:]]*/sectors/[A-Za-z0-9_-]+\.md' "$claude_md" \
                | sed -E 's#.*/([A-Za-z0-9_-]+)\.md#\1#' | sort -u | tr '\n' ' ')"
    [ -n "$sectors" ] || { echo "no sectors @-imported in $claude_md — nothing to equip." >&2; exit 1; }
    ;;
esac

for s in $sectors; do
  [ -f "$SECTORS_DIR/$s.md" ] || { echo "no such sector: $s" >&2; exit 1; }
done

# --- 1. AGENTS.md: compiled payload between markers ---
payload="$("$ADAPTERS_DIR/compile-sector.sh" $sectors)"
agents_md="$target/AGENTS.md"
PAYLOAD="$payload" BEGIN="$BEGIN_MARK" END="$END_MARK" python3 - "$agents_md" <<'PY'
import os, sys
path = sys.argv[1]
begin, end = os.environ["BEGIN"], os.environ["END"]
block = f"{begin}\n{os.environ['PAYLOAD']}\n{end}\n"
if os.path.exists(path):
    text = open(path).read()
    if begin in text and end in text:
        pre = text.split(begin)[0]
        post = text.split(end, 1)[1].lstrip("\n")
        text = pre + block + ("\n" + post if post else "")
    else:
        text = text.rstrip("\n") + "\n\n" + block
else:
    text = block
open(path, "w").write(text)
PY
echo "Wrote sector payload into $agents_md (between equip-codex markers)"

# --- 2. ~/.codex/config.toml: [mcp_servers.<tool>] from sector mcp: lines ---
# Sector schema: an `mcp: stdio `cmd args...`` line inside a `- tool:` block.
mcp_lines="$(for s in $sectors; do
  awk '/^- tool:/ {tool=$3}
       /^[[:space:]]+mcp:[[:space:]]*stdio/ {
         if (match($0, /`[^`]+`/)) print tool "\t" substr($0, RSTART+1, RLENGTH-2)
       }' "$SECTORS_DIR/$s.md"
done | sort -u)"

if [ -n "$mcp_lines" ]; then
  mkdir -p "$HOME/.codex"
  if [ -f "$CODEX_TOML" ]; then
    cp "$CODEX_TOML" "$CODEX_TOML.pre-equip-codex.bak"
  else
    touch "$CODEX_TOML"
  fi
  while IFS=$'\t' read -r tool cmd; do
    [ -n "$tool" ] || continue
    if grep -q "^\[mcp_servers\.$tool\]" "$CODEX_TOML"; then
      echo "config.toml: [mcp_servers.$tool] already present, skipped"
      continue
    fi
    set -- $cmd
    command_word="$1"; shift
    args_toml=""
    for a in "$@"; do args_toml="$args_toml\"$a\", "; done
    args_toml="${args_toml%, }"
    {
      echo ""
      echo "[mcp_servers.$tool]"
      echo "command = \"$command_word\""
      echo "args = [$args_toml]"
    } >> "$CODEX_TOML"
    echo "config.toml: added [mcp_servers.$tool] ($cmd)"
  done <<< "$mcp_lines"
else
  echo "No mcp: lines in sector(s) ${sectors} - config.toml untouched"
fi

# --- 3. skills: pointers (manual installs) ---
skills_lines="$(for s in $sectors; do
  awk '/^- tool:/ {tool=$3}
       /^[[:space:]]+skills:/ {sub(/^[[:space:]]+skills:[[:space:]]*/, ""); print "  " tool ": " $0}' \
      "$SECTORS_DIR/$s.md"
done)"
if [ -n "$skills_lines" ]; then
  echo "Skills to install manually (Codex reads SKILL.md folders at ~/.codex/skills/ or .agents/skills/):"
  printf '%s\n' "$skills_lines"
fi

echo "Sectors equipped for Codex: $sectors"
echo "NOT live-tested against a real Codex install — see ADAPTERS.md test-status column."
