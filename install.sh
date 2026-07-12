#!/usr/bin/env bash
# install.sh — one-command claude-optimization bootstrap. [no LLM needed — plain shell]
# Assembles this repo's generic pieces as a toggleable LOCAL PLUGIN (claude-optimization@local):
#   - hooks: wardrobe-discovery (UserPromptSubmit) + read-injection-scanner (PostToolUse:Read),
#     wired via the plugin's own hooks.json — nothing hand-edits your settings.json (which can
#     trip Claude Code's self-modification guard when an agent does it)
#   - skills: load-project + repackage-as-plugin
# plus: installs the equip-loadout.sh valet and seeds ~/Claude/sectors/ from the templates.
#
# The 4 EXAMPLE hooks (writing-rules, md-route-guard, save-at-80, sensitive-block) stay
# UNWIRED — they are patterns to adapt; INSTALL.md offers wiring.
# Re-runnable: plugin assembly refreshes in place; an existing marketplace.json or sectors
# dir is never clobbered.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== claude-optimization install =="

# --- 0. deps ------------------------------------------------------------------
command -v jq >/dev/null 2>&1   || echo "WARN: jq not found — the wardrobe-discovery hook needs it (brew install jq)."
command -v node >/dev/null 2>&1 || echo "WARN: node not found — the read-injection-scanner hook needs it."

# --- 1. assemble the plugin ------------------------------------------------------
PLUG="$HOME/.claude/local-plugins/claude-optimization"
mkdir -p "$PLUG/.claude-plugin" "$PLUG/hooks" "$PLUG/skills"

cat > "$PLUG/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "claude-optimization",
  "version": "1.0.0",
  "description": "Dressing-room core — wardrobe discovery hook, read-injection scanner, load-project + repackage-as-plugin skills, as a toggleable local plugin.",
  "author": {
    "name": "claude-optimization contributors"
  }
}
EOF

cat > "$PLUG/hooks/hooks.json" <<'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/wardrobe-discovery-hook.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/read-injection-scanner.js\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF

cp "$REPO/hooks/wardrobe-discovery-hook.sh" "$PLUG/hooks/"
cp "$REPO/hooks/read-injection-scanner.js"  "$PLUG/hooks/"
chmod +x "$PLUG/hooks/wardrobe-discovery-hook.sh"
cp -R "$REPO/skills/load-project"        "$PLUG/skills/"
cp -R "$REPO/skills/repackage-as-plugin" "$PLUG/skills/"
echo "plugin assembled at $PLUG"

# --- 2. local marketplace ----------------------------------------------------------
# NEVER clobber an existing marketplace.json (yours may already register other plugins).
MPDIR="$HOME/.claude/local-plugins/.claude-plugin"
MP="$MPDIR/marketplace.json"
ENTRY='{
      "name": "claude-optimization",
      "description": "Dressing-room core (discovery hook, injection scanner, load-project, repackage-as-plugin).",
      "source": "./claude-optimization"
    }'
if [ ! -f "$MP" ]; then
  mkdir -p "$MPDIR"
  cat > "$MP" <<EOF
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "local",
  "description": "Local plugin marketplace.",
  "owner": {
    "name": "$(id -F 2>/dev/null || echo "$USER")"
  },
  "plugins": [
    $ENTRY
  ]
}
EOF
  echo "marketplace created at $MP"
elif grep -q '"claude-optimization"' "$MP"; then
  echo "marketplace already lists claude-optimization — left untouched."
else
  echo ""
  echo "marketplace.json already exists ($MP) — NOT modifying it."
  echo "Add this entry to its \"plugins\" array by hand:"
  echo "$ENTRY"
fi

# --- 3. the valet -----------------------------------------------------------------------
mkdir -p "$HOME/.claude/scripts"
cp "$REPO/scripts/equip-loadout.sh" "$HOME/.claude/scripts/"
chmod +x "$HOME/.claude/scripts/equip-loadout.sh"
echo "valet installed: ~/.claude/scripts/equip-loadout.sh"

# --- 4. seed the sectors dir --------------------------------------------------------------
SECTORS="$HOME/Claude/sectors"
if [ -d "$SECTORS" ]; then
  echo "sectors dir already exists ($SECTORS) — left untouched."
else
  mkdir -p "$SECTORS"
  cp -R "$REPO/sectors-template/." "$SECTORS/"
  echo "sectors seeded from templates at $SECTORS — the INSTALL.md agent step replaces the"
  echo "templates with YOUR sectors/WARDROBE/TRIGGERS."
fi

# --- done -------------------------------------------------------------------------------------
cat <<'EOF'

== install.sh done ==
Run these two commands yourself (plugin registration goes through the CLI, not this script):
  claude plugin marketplace add ~/.claude/local-plugins
  claude plugin install claude-optimization@local --scope user

Then:
  1. Hand INSTALL.md to your agent — it inventories YOUR tools and authors your
     sectors/WARDROBE/TRIGGERS from the seeded templates (proposed + confirmed, never assumed).
  2. Check the install anytime:  bash verify-install.sh
EOF
