#!/usr/bin/env bash
# save-at-80.sh — PostToolUse hook
# Fires when context usage reaches 80%. Injects a strong directive telling
# the agent to save in-progress research to a known location and stop.
#
# Reads the same /tmp/claude-ctx-{session_id}.json that gsd-context-monitor
# writes via the statusline. Output goes back to the agent as additionalContext.

set -u

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

# Reject path-traversal session IDs
case "$SESSION_ID" in
  */*|*\\*|*..*) exit 0 ;;
esac

# macOS resolves os.tmpdir() to $TMPDIR (/var/folders/...), not /tmp.
# Fall back to /tmp on Linux where TMPDIR is often unset.
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
METRICS="${TMP}/claude-ctx-${SESSION_ID}.json"
[ ! -f "$METRICS" ] && exit 0

USED=$(jq -r '.used_pct // 0' "$METRICS" 2>/dev/null)
# Bash arithmetic only handles ints — coerce
USED_INT=${USED%.*}
[ -z "$USED_INT" ] && exit 0

# Only fire at 80% or higher
if [ "$USED_INT" -lt 80 ]; then
  exit 0
fi

# Debounce: only fire once per session at 80%+
SENTINEL="${TMP}/claude-ctx-${SESSION_ID}-saved80.flag"
[ -f "$SENTINEL" ] && exit 0
touch "$SENTINEL"

MSG="🛑 CONTEXT 80% REACHED (used: ${USED_INT}%). STOP CURRENT WORK IMMEDIATELY. \
Your next 3 tool calls MUST be: \
(1) Write all unsaved research/notes from your context to \
the active project's raw/ or research/ dir, \
(2) Update or create PICKUP.md in the same project dir with: what was done, what's left, exact resume prompt, raw note paths, \
(3) End the turn with one summary sentence telling the user to /clear and paste the resume prompt. \
Do NOT start new research. Do NOT spawn agents. Do NOT WebFetch. Save first, stop second."

# Emit as PostToolUse additionalContext
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}' \
  "$(echo "$MSG" | jq -Rs .)"
