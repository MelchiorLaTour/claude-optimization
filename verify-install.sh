#!/usr/bin/env bash
# verify-install.sh — machine-checked acceptance gates for a claude-optimization install.
# [no LLM needed] Run anytime: bash verify-install.sh
# Exit 0 = all hard checks PASS (warnings allowed); exit 1 = at least one FAIL.
set -uo pipefail

pass=0; fail=0; warn=0
ok()   { echo "PASS  $1"; pass=$((pass+1)); }
bad()  { echo "FAIL  $1"; fail=$((fail+1)); }
note() { echo "WARN  $1"; warn=$((warn+1)); }

PLUG="$HOME/.claude/local-plugins/claude-optimization"

# 1. plugin assembly
[ -d "$PLUG" ] && ok "plugin dir assembled ($PLUG)" || bad "plugin dir missing — run ./install.sh"
for j in "$PLUG/.claude-plugin/plugin.json" "$PLUG/hooks/hooks.json"; do
  if [ -f "$j" ]; then
    if python3 -m json.tool "$j" >/dev/null 2>&1 || node -e "JSON.parse(require('fs').readFileSync('$j'))" >/dev/null 2>&1; then
      ok "valid JSON: ${j#"$HOME"/}"
    else
      bad "invalid JSON: $j"
    fi
  else
    bad "missing: $j — run ./install.sh"
  fi
done

# 2. hook scripts present + runnable
if [ -x "$PLUG/hooks/wardrobe-discovery-hook.sh" ]; then
  ok "wardrobe-discovery-hook.sh present + executable"
  if echo '{"prompt":"test"}' | bash "$PLUG/hooks/wardrobe-discovery-hook.sh" >/dev/null 2>&1; then
    ok "wardrobe hook fire-test exits 0"
  else
    bad "wardrobe hook fire-test failed (is jq installed?)"
  fi
else
  bad "wardrobe-discovery-hook.sh missing/not executable — run ./install.sh"
fi
if [ -f "$PLUG/hooks/read-injection-scanner.js" ]; then
  ok "read-injection-scanner.js present"
  command -v node >/dev/null 2>&1 && ok "node present for the scanner" || note "node not found — scanner hook cannot run"
else
  bad "read-injection-scanner.js missing — run ./install.sh"
fi

# 3. skills packaged
for s in load-project repackage-as-plugin; do
  [ -f "$PLUG/skills/$s/SKILL.md" ] && ok "skill packaged: $s" || bad "skill missing: $s — run ./install.sh"
done

# 4. marketplace registration
MP="$HOME/.claude/local-plugins/.claude-plugin/marketplace.json"
if [ -f "$MP" ] && grep -q '"claude-optimization"' "$MP"; then
  ok "marketplace.json lists claude-optimization"
else
  bad "claude-optimization not in $MP — run ./install.sh (or merge the printed entry by hand)"
fi

# 5. valet
[ -x "$HOME/.claude/scripts/equip-loadout.sh" ] && ok "valet present + executable (~/.claude/scripts/equip-loadout.sh)" || bad "equip-loadout.sh missing/not executable — run ./install.sh"

# 6. sectors dir (WARN-level — authoring them is the INSTALL.md agent step)
SECTORS="$HOME/Claude/sectors"
if [ -d "$SECTORS" ]; then
  ok "sectors dir exists ($SECTORS)"
  if [ -f "$SECTORS/TRIGGERS.tsv" ] && [ -f "$SECTORS/WARDROBE.md" ]; then
    ok "TRIGGERS.tsv + WARDROBE.md authored"
  else
    note "sectors dir still template-only — the INSTALL.md agent step authors your WARDROBE/TRIGGERS/sectors"
  fi
else
  bad "sectors dir missing — run ./install.sh"
fi

# 7. plugin installed in Claude Code (best-effort — CLI may not be on PATH here)
if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -q "claude-optimization"; then
    ok "claude plugin list shows claude-optimization"
  else
    note "plugin not (yet) installed in Claude Code — run: claude plugin marketplace add ~/.claude/local-plugins && claude plugin install claude-optimization@local --scope user"
  fi
else
  note "claude CLI not on PATH — skipped plugin-list check"
fi

echo ""
echo "== verify-install: $pass PASS, $fail FAIL, $warn WARN =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
