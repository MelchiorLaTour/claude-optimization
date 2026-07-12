#!/usr/bin/env bash
# equip-loadout.sh — the valet.
# Equip a project's sector plugins (or one sector ad-hoc) into a project-local
# .claude/settings.json. Reads sectors from a project's CLAUDE.md @-imports,
# greps each sector's "## Tools (loadout)" plugin: lines, unions them, and turns
# them on (true). Base plugins are inherited from user settings; this never
# writes false and never touches the global settings.json. Equip = reload —
# plugins resolve at launch, not mid-session.
set -euo pipefail

SECTORS_DIR="$HOME/Claude/sectors"

usage() {
  cat <<'EOF'
Usage:
  equip-loadout.sh [project-dir]       Equip all sectors from the project's CLAUDE.md (default: cwd)
  equip-loadout.sh add <sector>...     One-off: add a sector's plugins to ./.claude/settings.json
  equip-loadout.sh remove <sector>...  One-off: drop a sector's plugins from ./.claude/settings.json

Equip = reload. Plugins resolve at launch, not mid-session.
EOF
}

# Print the plugin ids (name@marketplace) a sector file lists under its loadout.
sector_plugins() {
  local sector="$1" file="$SECTORS_DIR/$1.md"
  if [ ! -f "$file" ]; then
    echo "no such sector: $sector (looked in $SECTORS_DIR)" >&2
    return 1
  fi
  # A memory-only sector lists no plugins — that is valid, not an error.
  # Neutral schema (Phase 5): the CC impl line inside a tool block is `  cc: plugin <id>`.
  grep -oE '^[[:space:]]*cc:[[:space:]]*plugin[[:space:]]+[^[:space:]]+' "$file" | awk '{print $NF}' || true
}

# Merge plugin ids into <dir>/.claude/settings.json. action=enable sets true;
# action=remove deletes the key (reverts to inherited base). Preserves all other keys.
apply() {
  local dir="$1" action="$2"; shift 2
  local settings="$dir/.claude/settings.json"
  mkdir -p "$dir/.claude"
  [ -f "$settings" ] || echo '{}' > "$settings"
  PLUGINS="$*" ACTION="$action" python3 - "$settings" <<'PY'
import json, os, sys
path = sys.argv[1]
plugins = os.environ["PLUGINS"].split()
action = os.environ["ACTION"]
with open(path) as f:
    data = json.load(f)
ep = data.setdefault("enabledPlugins", {})
for p in plugins:
    if action == "remove":
        ep.pop(p, None)
    else:
        ep[p] = True
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

# Collect deduped plugin ids for a list of sector names (from stdin, one per line).
collect_sectors() {
  while read -r s; do
    [ -n "$s" ] && sector_plugins "$s"
  done | sort -u
}

main() {
  local cmd="${1:-}"

  case "$cmd" in
    -h|--help)
      usage; exit 0 ;;

    add|remove)
      shift
      [ $# -ge 1 ] || { usage; exit 1; }
      local target="$PWD" action="enable"
      [ "$cmd" = "remove" ] && action="remove"
      local plugins
      plugins="$(printf '%s\n' "$@" | collect_sectors)"
      if [ -z "$plugins" ]; then
        echo "Sector(s) '$*' list no plugins (memory-only?). Nothing to $cmd."
        exit 0
      fi
      apply "$target" "$action" $plugins
      if [ "$cmd" = "add" ]; then
        echo "Equipped sector(s) '$*' into $target/.claude/settings.json:"
      else
        echo "Removed sector(s) '$*' from $target/.claude/settings.json:"
      fi
      printf '  %s\n' $plugins
      echo "Equip = reload."
      ;;

    *)
      # Project mode. cmd (if given) is the project dir; default cwd.
      local project_dir
      project_dir="$(cd "${cmd:-$PWD}" 2>/dev/null && pwd)" \
        || { echo "no such directory: $cmd" >&2; exit 1; }
      local claude_md="$project_dir/CLAUDE.md"
      [ -f "$claude_md" ] || {
        echo "no CLAUDE.md in $project_dir — not a project. Use 'add <sector>' for a one-off." >&2
        exit 1
      }
      local sectors plugins
      sectors="$(grep -oE '@[^[:space:]]*/sectors/[A-Za-z0-9_-]+\.md' "$claude_md" \
                  | sed -E 's#.*/([A-Za-z0-9_-]+)\.md#\1#' | sort -u)"
      if [ -z "$sectors" ]; then
        echo "no sectors @-imported in $claude_md — nothing to equip." >&2
        exit 1
      fi
      plugins="$(printf '%s\n' "$sectors" | collect_sectors)"
      apply "$project_dir" "enable" $plugins
      echo "Equipped $project_dir/.claude/settings.json"
      echo "Sectors: $(printf '%s ' $sectors)"
      if [ -z "$plugins" ]; then
        echo "Plugins: (none — all sectors memory-only)"
      else
        echo "Plugins enabled:"
        printf '  %s\n' $plugins
      fi
      echo "Equip = reload."
      ;;
  esac
}

main "$@"
