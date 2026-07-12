#!/bin/bash
# wardrobe-discovery-hook.sh — UserPromptSubmit
# Generic discovery doorman. Reads ~/Claude/sectors/TRIGGERS.tsv (name<TAB>pattern<TAB>hint),
# greps the prompt against each row (case-insensitive ERE), injects matching hints.
# Add a capability = add a TSV row; never edit this script. The always-on pointer in
# CLAUDE.md + WARDROBE.md is the other half of the discovery layer. Equip = reload
# (plugins only; bash tools and memory-only sectors work cold).
TRIGGERS="$HOME/Claude/sectors/TRIGGERS.tsv"
input=$(cat)

# optional: staleness-triggered background refresh jobs can hook here (check an index mtime,
# nohup the refresher with all fds detached so the prompt is never blocked)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
[[ -z "$prompt" || ! -f "$TRIGGERS" ]] && exit 0

hits=""
while IFS=$'\t' read -r name pattern hint; do
  [[ -z "$name" || "$name" == \#* || -z "$pattern" ]] && continue
  if printf '%s' "$prompt" | grep -qiE "$pattern" 2>/dev/null; then
    hits+="- **${name}** — ${hint}"$'\n'
  fi
done < "$TRIGGERS"

[[ -z "$hits" ]] && exit 0

{
  printf 'WARDROBE DISCOVERY — this prompt may reach for these capabilities:\n'
  printf '%s' "$hits"
  printf '\nFull index: ~/Claude/sectors/WARDROBE.md. Sector-gated PLUGINS need equip (outside a project, ASK the user "project or one-off?"; equip = load-project context + equip-loadout.sh + reload). Bash tools and memory-only sectors work cold, no equip.\n'
} | jq -Rs '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:.}}'
exit 0
