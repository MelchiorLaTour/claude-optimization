#!/bin/bash
# writing-rules-hook.sh — UserPromptSubmit (pointer pattern)
# EXAMPLE hook: detects outward-facing document tasks and injects a SHORT pointer at your
# full writing-rules file, instead of injecting the full rules payload on every fire.
# The agent reads the rules file in full only when the task is real. In the author's setup
# this cut the false-fire cost ~95% (8,590 -> 637 chars per fire, author-measured, N=1);
# true-fire total cost is unchanged (the read happens on demand).
# EDIT: point RULES at your own rules file.
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)

RULES="$HOME/.claude/writing-rules.md"   # EDIT: your writing-rules file

ctx=''

if printf '%s' "$prompt" | grep -qiE 'e-?mail|letter|cover ?letter|motivation|essay|application|\bcv\b|resume|r[eé]sum[eé]|\bbio\b|biograph|personal statement|statement of purpose|linkedin|outreach|cover note|(draft|write|polish|edit) (a|an|the|my|this)?.*(letter|email|essay|message|note|post|bio|statement)'; then
  ctx="WRITING TASK DETECTED (maybe) — if this turn actually produces an outward-facing document (email, letter, essay, CV, application, bio, outreach), you MUST first Read the rules file IN FULL before drafting a single line: $RULES. If the prompt only MENTIONS writing but the turn is conversation/planning/code, skip the read — that is the boolean check working."
fi

# A second detector branch can hook here with the same shape (grep the prompt, append to
# $ctx) — e.g. a deliverable-handoff detector that points at a verification checklist.

if [ -n "$ctx" ]; then
  printf '%s' "$ctx" | jq -Rs '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:.}}'
fi
