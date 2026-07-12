#!/bin/bash
# Blocks the agent from writing .md files onto the Desktop (keeps Spotlight/search clean).
# Routing: agent's working files -> your notes dir ; reader deliverables -> ~/Downloads/ ; ASK if unsure.
input=$(cat)
fp=$(echo "$input" | /usr/bin/python3 -c "import sys,json;print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
case "$fp" in
  "$HOME"/Desktop/*.md)
    echo "BLOCKED: never write .md to the Desktop. Route instead - agent working files (notes, audits, PICKUP, plans) -> your notes dir; files FOR THE USER to read (essays, copy-paste deliverables) -> ~/Downloads/. If unsure which, ASK; do not guess." >&2
    exit 2 ;;
esac
exit 0
