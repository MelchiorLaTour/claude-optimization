---
name: load-project
description: Use when the user says "start", "pick up", "continue", "resume", "load", or "open" a named project (e.g. "pick up the website project", "continue the research work") in any session from any directory. Loads that project's full context — prose + sector capability bundles + FACTS — by walking its CLAUDE.md @-import chain, no cd or project-locked terminal required.
---

# Load Project

Loads a project's context into the current session on demand, by reading its project `CLAUDE.md` and walking the `@`-import chain. Projects live in your projects folder (default `~/Claude/<project>/` — adjust the globs below if yours differs). This is the prompt-to-load path: the user says the trigger phrase from any session, any cwd — they never have to `cd` into the project folder or open a session locked to it.

## When this fires

Trigger phrases (the `<name>` is fuzzy, match generously):
- "start / pick up / continue / resume / load / open the **<name>** project"
- "let's get back to **<name>**"
- "continue the **<name>** work"

`<name>` examples → folder: "website redesign" / "the site" → `website-redesign`; "job search" → `job_search`; "research" → `research-notes`. Match on stems, not exact folder names.

Do NOT fire for: one-off questions, single-tool tasks, or work in a directory that already has a `CLAUDE.md` the harness loaded at launch (context is already present).

## Steps

1. **Find the project.** Glob `~/Claude/*/CLAUDE.md` (or your projects folder). Fuzzy-match `<name>` against the directory names (case-insensitive, ignore separators `-` `_` and spaces, match on word stems). New projects with a `CLAUDE.md` are supported automatically — no edit to this skill needed.
   - If two dirs match comparably, pick the one whose `CLAUDE.md` is non-trivial / most recently modified, and say which you chose in the confirmation line.
   - If nothing matches, list the candidate project dirs (`ls -d ~/Claude/*/`) and ask which one — do not guess blindly.

2. **Read the project root.** `Read` the matched project `CLAUDE.md`. It contains a prose description plus `@`-import lines (sector files + `@FACTS.md`).

3. **Walk the @-import chain via Read.** For each `@`-path in the project CLAUDE.md:
   - Resolve it (`@FACTS.md` → the project's `FACTS.md`; `@~/Claude/sectors/<x>.md` → that file).
   - `Read` it. Sector files contain their own `@`-imports of memory files — read those members too (one more hop).
   - **Skip any file already in context.** Main always-on memory (the files imported by the global `~/.claude/CLAUDE.md`) is already loaded every session — do not re-read those. Only read project/sector members not already present.
   - Read each file at most once even if multiple sectors import it.

4. **Read the live state pointer if one exists.** Many projects keep a working-state file (`FACTS.md`, `PICKUP.md`, `BUILD-PROMPT.md`, `SESSION_STATE.md`, `NEXT_STEPS.md`, `.planning/STATE.md`). FACTS is loaded via the import chain; if the project's memory index or CLAUDE.md names a separate pickup/state doc, read it too so you resume at the right point. Do not blindly trust a dated pointer as canonical — if several candidate state files exist, name them and confirm which is current.

5. **Confirm in ONE line.** Format:
   `<project> loaded: prose + N sectors (writing, research, …) + FACTS + <state-doc if any>. Resuming at <one-phrase next step>.`
   Then proceed with whatever the project's state doc says is next.

## Known limitation (accepted trade)

The skill loads context via mid-session `Read` calls, not harness-startup inlining. Same content, but it lands after the first message of the session rather than being pre-loaded. That is the deliberate trade for "trigger by talking, from anywhere" instead of `cd` + launch.

## Companion rule — mid-task PICKUP prompts

Every mid-task handoff prompt this project (or any project) produces must be ONE paste-able block that BOTH loads the project AND resumes the task. Shape:

```
Pick up the <name> project, then resume: <the specific in-flight task + where it stopped + the next concrete action>.
```

The first clause triggers this skill (loads context); the second clause is the task. Never hand the user a `cd` ritual or a multi-step "first do X, then do Y" loader. One block, paste, go.
