# Troubleshooting

Findings from sandbox-testing install.sh on a clean fake `$HOME` (macOS, stock bash 3.2),
plus the interpretation guide for `verify-install.sh` and the known failure modes of the
plugin machinery.

## install.sh

**"existing marketplace found — merge this entry by hand"** — deliberate, not an error.
If `~/.claude/local-plugins/.claude-plugin/marketplace.json` already exists (you have
other local plugins), install.sh will never rewrite it; it prints the
`claude-optimization` plugin entry for you to paste into the `plugins` array yourself.
A fresh machine gets the file created automatically.

**Running install.sh twice** — safe and tested. The assembly is idempotent: existing
files are refreshed, the marketplace never-clobber branch holds, and an existing
`~/Claude/sectors/` directory is left alone (seeding only happens when it's absent).

**jq / node warnings** — `jq` is needed by the wardrobe hook at runtime, `node` by the
read-injection scanner. install.sh warns but continues: the assembly is still correct,
the hooks just won't function until the dependency is installed.

**The two `claude plugin` commands** — install.sh prints them instead of running them
(marketplace add + user-scope install). Until you run them, the plugin directory exists
but Claude Code doesn't know about it — that's the "plugin not yet installed via CLI"
WARN in verify-install.sh.

## verify-install.sh — reading the output

A fresh, correct install prints **12 PASS / 0 FAIL / 2 WARN**. The two expected WARNs:

- **"sectors are still the shipped templates"** — correct until INSTALL.md Steps 2–3,
  where the agent authors YOUR sector taxonomy. Clears once real sectors replace the
  templates.
- **"claude-optimization not in `claude plugin list`"** — correct until you run the two
  printed CLI commands (or if the `claude` CLI isn't on PATH, where the check is
  best-effort and skipped).

Any FAIL names the broken piece: invalid JSON in plugin.json/hooks.json, a hook script
missing or not executable, a failed wardrobe fire-test, missing valet or skills. Fix and
re-run — the script is read-only.

## Hooks

**Discovery hook never fires** — in order: (1) no `TRIGGERS.tsv` at
`~/Claude/sectors/` — the hook exits cleanly (by design) when the file is missing, so
authoring rows is INSTALL.md Step 5; (2) `jq` missing; (3) your prompt genuinely matches
no row — test by hand:
`echo '{"prompt":"your test phrase"}' | bash ~/.claude/local-plugins/claude-optimization/hooks/wardrobe-discovery-hook.sh`
— matching rows print their hint, non-matching prints nothing, exit 0 either way.

**Hook fires but the hint is stale** (wrong path, renamed sector) — hints are data:
edit the row in TRIGGERS.tsv. No reload needed; UserPromptSubmit hooks read it fresh
each prompt.

**Example hooks (writing-rules, md-route-guard, save-at-80, sensitive-block-guard) do
nothing** — they ship deliberately unwired; they encode one author's workflow. INSTALL.md
Step 6 covers adapting their `EDIT:` blocks and registering them. `save-at-80.sh`
additionally requires an external statusline monitor writing
`$TMPDIR/claude-ctx-<session>.json` — without one it's a pattern to adapt, not a drop-in.

## Plugins and loadouts

**A sector's plugins don't load in a project ("dark window")** — the classic causes, in
order:

1. **Install scope ≠ enable scope.** The plugin was installed at project scope somewhere
   else. Reinstall at user scope (`claude plugin install <id> --scope user`), keep
   per-project control in `enabledPlugins`.
2. **The project's `enabledPlugins` map is missing the id.** Remember it overrides the
   global map in both directions — run the valet (`equip-loadout.sh <project-dir>`)
   rather than hand-editing.
3. **No relaunch.** Equip = reload; plugins resolve at launch, never mid-session.

Ground truth for any loadout question is the debug harness:
`claude --debug --debug-file /tmp/dbg.log -p "ok"` in the project directory, then grep
the log for `Loaded N skills` / the plugin names. Trust that over any settings-file
reading.

**Edits to plugin source don't take effect / only 1 of N skills loads** — plugin-cache
staleness. The `repackage-as-plugin` skill documents the cache layout and the fix
(version-bump or cache clear + relaunch).

**Global settings edits get blocked** — Claude Code's self-modification guard can block
an agent editing `~/.claude/settings.json` directly. This system avoids the problem by
design (hook wiring lives in the plugin's own hooks.json; the valet writes only *project*
settings). If an agent step ever needs a global change, have it hand you the one-liner to
run yourself.
