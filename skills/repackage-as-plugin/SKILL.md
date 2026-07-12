---
name: repackage-as-plugin
description: Use when moving user-scope skills, agents, or hooks from ~/.claude/ into a toggleable local plugin, when creating a local plugin marketplace, or when a local plugin misloads skills (only 1 of N skills loading, plugin skills shadowed, edits to plugin source not taking effect, stale plugin cache).
---

# Repackage as Plugin

Convert loose `~/.claude/` skills + agents + hooks into a plugin under a directory-source local marketplace, so the whole suite toggles per-project (off at lean base, on where equipped). Proven by the gsd repackaging (67 skills + 33 agents + 8 hooks, 2026-07).

## Layout

```
~/.claude/local-plugins/
  .claude-plugin/marketplace.json     # {"name":"local", plugins:[...]}
  <plugin>/
    .claude-plugin/plugin.json        # name, version — BUMP version on every edit
    skills/<skill-name>/SKILL.md      # one dir per skill, NOTHING at skills/ root
    agents/<agent>.md
    hooks/hooks.json                  # script paths absolute ($HOME-rooted); scripts can stay outside the plugin
```

## Steps

1. **Scaffold + copy.** Write both manifests; copy skill dirs and agent files in. `claude plugin validate` both.
2. **Transform `@`-imports.** Plugin SKILL.md files do NOT support `@`-imports (CLAUDE.md-only feature) — they silently kill loading. Replace each `@<path>` line with `` !`cat "<path>" 2>/dev/null` `` and add `Bash` to that skill's `allowed-tools`. Referenced runtime files can stay where they are.
3. **BUILD GATE — run before any load test, every rebuild:**
   ```bash
   find <plugin>/skills -maxdepth 1 -name SKILL.md   # MUST print nothing
   grep -rl '^@' <plugin>/skills --include=SKILL.md  # MUST print nothing (inspect any hit: code-block lines like @property are false positives)
   find <plugin>/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l  # == skill count in the ORIGINAL source you copied from
   claude plugin validate <plugin>
   ```
   A stray `SKILL.md` at the `skills/` root makes the loader treat the entire folder as ONE skill and skip every subdirectory — 1/N loads, and no amount of marketplace rebuilding fixes it (this cost a full debugging session).
4. **Register + scope.** `claude plugin marketplace add <dir>` (source schema `{"source":"directory","path":...}`), `claude plugin install <plugin>@local`, then `claude plugin disable` for global-off; enable per-project in the project's `.claude/settings.json` (project true beats global false). Never edit global settings.json via Edit — it trips the self-modification classifier; use the CLI or hand the user a command.
5. **Deploy edits.** The runtime loads from a VERSION-KEYED cache (`~/.claude/plugins/cache/<mkt>/<plugin>/<version>/`). Editing source without bumping `plugin.json` version + `claude plugin update <plugin>@local` means the old cache keeps loading. Those two actions are the fix; optionally delete stale version dirs afterward to keep the cache clean.
6. **Verify with the real loader — no relaunch needed:**
   ```bash
   cd <project> && claude --debug-file /tmp/p.log --debug -p ok
   grep "from plugin <plugin>" /tmp/p.log
   # expect exactly: "Loaded N skills from plugin <plugin> default directory"
   #             and "Loaded M agents from plugin <plugin> default directory"
   # zero hits = the plugin never loaded at all (check enablement/scope), not a format issue
   claude plugin details <plugin>@local     # Skills(N)/Agents(M) — matches runtime
   ```
7. **Gate before delete.** Stage user-scope originals aside (`mv` to a staging dir, never `rm`) — identically-named user-scope skills SHADOW plugin skills, so counts lie until originals are out of the way. Then a two-launch `/context` test: base dir = plugin absent, project dir = all N present. Only after both pass, delete staged originals.

## Failure → cause

| Symptom | Cause |
|---|---|
| 1 of N skills loads, agents fine | Stray `SKILL.md` at `skills/` root (step 3) |
| Skills silently missing | `@`-import lines in SKILL.md (step 2) |
| Fix deployed but behavior unchanged | Version-keyed cache stale (step 5) |
| Plugin "works" but wrong copies run | User-scope originals shadowing (step 7) |
| Global settings edit blocked | Self-modification classifier (step 4) |
