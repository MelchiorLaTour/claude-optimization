# INSTALL — hybrid bootstrap

Install is **hybrid**: one shell script does everything deterministic (plugin assembly, hook
wiring, valet, template seeding), and the agent steps handle the one thing that genuinely
needs judgment — YOUR tool taxonomy. Steps marked **[no LLM needed]** are plain shell you can
run yourself. Human: run Step 0, then open your agent in this repo's directory and say
"follow INSTALL.md from Step 1".

Rules for the agent executing the agent steps:
- Every taxonomy (sectors, wardrobe rows, trigger rows) is **PROPOSED from the user's real
  inventory and CONFIRMED with them — never assumed.**
- Do not skip acceptance checks. A step is done when its check passes.
- **Session-state convention:** after finishing each step, append one line to
  `INSTALL-STATE.md` at the repo root — `step N — done — next: <step>`. If your session
  compacts or dies, the next session reads `INSTALL-STATE.md` and resumes from there.

---

## Step 0 — run the installer  [no LLM needed]

```
./install.sh
```

It assembles the two generic hooks (wardrobe-discovery, read-injection-scanner) plus the
load-project and repackage-as-plugin skills into a local plugin,
`~/.claude/local-plugins/claude-optimization/`. Hook wiring lives in the plugin's own
`hooks.json`, so **no hand-edits to `~/.claude/settings.json`** are needed (and none of
Claude Code's self-modification guards are tripped). It also copies the valet
(`equip-loadout.sh`) to `~/.claude/scripts/` and seeds `~/Claude/sectors/` from
`sectors-template/` if you don't have a sectors directory yet.

If you already have a local marketplace (`~/.claude/local-plugins/.claude-plugin/
marketplace.json`), install.sh will NOT touch it — it prints the plugin entry for you to
merge by hand. Finish by running the two `claude plugin` commands it prints (marketplace
add + install at user scope).

The four EXAMPLE hooks in `hooks/` (writing-rules, md-route-guard, save-at-80,
sensitive-block-guard) are deliberately left unwired — they encode one author's workflow.
Step 6 offers them.

- **ACCEPTANCE:** `bash verify-install.sh` — all PASS except (expectedly) the
  sectors-still-templates WARN, which Steps 2–3 clear.

## Step 1 — Inventory the user's tools

**GOAL:** Know everything the user owns before proposing any structure.

**DISCOVER:**
- Plugins: `claude plugin list` (note install scope per plugin) and the `enabledPlugins`
  maps in `~/.claude/settings.json` and any project `.claude/settings.json`.
- User skills: `ls ~/.claude/skills/`.
- MCP servers: `claude mcp list` and/or `~/.claude.json`.
- Hooks already configured: the `hooks` block of `~/.claude/settings.json` plus any
  plugin-provided hooks.

**OUTPUTS:** A table shown to the user: tool | kind (plugin/skill/MCP/hook) | scope |
one-line purpose. Ask the user to correct anything misdescribed.

**ACCEPTANCE:** User confirms the inventory is complete and correct.

## Step 2 — Propose the sector taxonomy

**GOAL:** Group the non-universal tools into a handful of sectors (capability domains).

**DISCOVER:** From the Step-1 inventory plus the user's actual work (ask: "what kinds of
projects do you run?"), draft 3–7 sectors. Universal tools (memory, all-task skills) stay
at base — they get no sector.

**OUTPUTS:** A proposed list: sector name → member tools → member rule/memory files (if the
user has any). Confirm with the user; iterate until they approve.

**ACCEPTANCE:** User approves the sector list.

## Step 3 — Write the sectors

**GOAL:** One file per sector at `~/Claude/sectors/<name>.md`. (Step 0 already seeded the
directory with the templates — replace them with the real thing.)

**DISCOVER:** For each tool, its `enabledPlugins` id (from Step 1) and, where applicable,
its MCP stdio command and any official multi-model skill install pointer.

**OUTPUTS:**
- `~/Claude/sectors/<name>.md` per sector, following `example-sector.md`:
  description line, `@`-imports of member files, `## Tools (loadout)` block in the neutral
  schema (`tool:` / `what:` / `cc:` / `mcp:` / `skills:` / `portable:`).
- `~/Claude/sectors/MANIFEST.md` from `MANIFEST-TEMPLATE.md`, listing the real sectors.
- `ADAPTERS.md` + `adapters/` scripts: already seeded by Step 0; leave as-is.

**ACCEPTANCE:** Every non-base tool from Step 1 appears in exactly the sectors it belongs
to; every `cc:` id matches a real installed plugin id.

## Step 4 — Write the wardrobe

**GOAL:** The always-on index so nothing is ever forgotten.

**OUTPUTS:** `~/Claude/sectors/WARDROBE.md` from `WARDROBE-TEMPLATE.md`, filled with the
user's real rows across all five sections (base / sector-gated / MCP-deferred / bash-tool /
memory-only). Add a one-line pointer to it in the user's global `~/.claude/CLAUDE.md`.

**ACCEPTANCE:** Every tool in the Step-1 inventory appears exactly once in WARDROBE.md.

## Step 5 — Write the trigger rows

**GOAL:** Deterministic discovery: prompts that reach for an unequipped capability get a
hint injected. (The discovery hook itself is already wired — Step 0's plugin registered it
as a UserPromptSubmit hook; it just needs rows to read.)

**DISCOVER:** For each sector, the natural phrasings a user would type when a task needs it
(look at `sectors-template/TRIGGERS-example.tsv` for the row shape).

**OUTPUTS:** `~/Claude/sectors/TRIGGERS.tsv`: one row per capability — name, `grep -Ei`
pattern, ≤600-char hint saying what the capability is and how to equip it.

**ACCEPTANCE:** Test 3–5 sample prompts through the hook by hand
(`echo '{"prompt":"..."}' | bash ~/.claude/local-plugins/claude-optimization/hooks/wardrobe-discovery-hook.sh`):
matching prompts print their hint, non-matching prompts print nothing.

## Step 6 (optional) — Wire the example hooks / repackage loose tools

**GOAL:** Adopt whichever of the four EXAMPLE hooks fit the user's workflow, and make any
of their own always-on skill/agent/hook clusters toggleable.

**OUTPUTS:** For example hooks: edit the `EDIT:`-marked paths/messages, then register them
(same plugin-hooks.json pattern install.sh used, or hand the user the settings.json snippet
to paste). For loose tool clusters: follow `skills/repackage-as-plugin/SKILL.md` — the exact
pattern install.sh already used to package this repo's tools as `claude-optimization@local`.

**ACCEPTANCE:** Base session loads without the new plugin; a project whose sector includes
it loads it (debug-harness check as in Done below).

## Step 7 (optional) — Adopt the constitution + memory structure

**GOAL:** Shrink always-on memory without losing rules.

**OUTPUTS:** Rewrite the user's global `~/.claude/CLAUDE.md` as a short constitution: a few
core principles, folded operational rules, `@`-imports of only the always-on rule files.
Convert memory to one-fact-per-file postits (frontmatter `name`/`description`/
`type: user|feedback|project|reference`; body = fact + **Why** + **How to apply**), indexed
one line each in `MEMORY.md`. Regeneration prompt per rule: "state the rule, the incident
that created it (why), and how to apply it — one file per rule."
Move project-specific facts to each project's `FACTS.md`, out of global memory.

**ACCEPTANCE:** `/context` (or equivalent) shows the memory payload dropped; every rule the
user cares about is either always-on or reachable via a sector/hook — none silently lost.
Archive the old files; do not delete them.

---

## Done

Two final checks:
1. `bash verify-install.sh` — **ALL PASS** (the sectors WARN should now be gone).
2. The two-launch test: (1) a base session in `~` — lean floor, wardrobe pointer present;
   (2) a project session whose `CLAUDE.md` imports a sector, after
   `equip-loadout.sh <project-dir>` — the sector's plugins load
   (`claude --debug --debug-file /tmp/dbg.log -p "ok"` then grep the log for
   `Loaded N skills` / plugin names).

If a needed tool ever fails to surface, the fix is a TRIGGERS.tsv row or a WARDROBE line —
data, not code.
