#!/bin/bash
# HARD BLOCK: forbids the agent from accessing a designated sensitive folder
# (credentials, passwords, keys). Matches across Read / Bash / Grep / Glob by scanning
# every path-ish field for the folder marker.
# EDIT: the "Resources/Sensitive" substring below is the customizable marker — set it to
# a distinctive path fragment of YOUR sensitive folder.
# exit 2 = block the tool call.
input=$(cat)
hits=$(echo "$input" | /usr/bin/python3 -c '
import sys, json
d = json.load(sys.stdin)
ti = d.get("tool_input", {}) or {}
# every field a tool could carry a path/command in
blob = " ".join(str(ti.get(k, "")) for k in ("file_path","command","path","pattern","glob","query"))
# also catch the whole tool_input as a fallback
blob += " " + json.dumps(ti)
print("BLOCK" if "Resources/Sensitive" in blob else "")
' 2>/dev/null)
if [[ "$hits" == "BLOCK" ]]; then
  echo "BLOCKED (hard block): the Sensitive folder holds credentials/passwords/keys — do NOT read, grep, glob, cat, or otherwise access anything under it. This folder is also excluded from all indexing/ingestion." >&2
  exit 2
fi
exit 0
