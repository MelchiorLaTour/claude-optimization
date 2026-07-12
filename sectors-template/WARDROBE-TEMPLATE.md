# Wardrobe — the always-on tool index (TEMPLATE)

<!-- TEMPLATE: replace the example rows with YOUR tools. The INSTALL bootstrap proposes
     rows from your actual plugin/skill/MCP inventory. Keep the section structure. -->

Carried every session so the agent never forgets a capability exists. This is the discovery
layer that makes per-project tool-scoping safe: a tool can be *unequipped* without being
*forgotten*. If a task needs something listed here as sector-gated, equip its sector and
reload (`equip = reload`).

**Equip mechanism (Claude Code):** add the sector's `@~/Claude/sectors/<name>.md` to the
project `CLAUDE.md` (context) and enable the sector's `cc: plugin` lines in the project
`.claude/settings.json enabledPlugins` (tools), then reload. `scripts/equip-loadout.sh`
does the settings half. Other models (Codex / Hermes / manual): see
`ADAPTERS.md` + `adapters/` scripts.

Columns: **tool** | **purpose** | **base?** | **sector** | **cc impl**

## Base — always equipped (the "underwear")

| Tool | Purpose | Base | cc impl |
|---|---|---|---|
| cross-session memory | Search past session work (e.g. a memory plugin) | yes | e.g. `claude-mem@<marketplace>` |
| Built-in skills | code-review, simplify, verify, run, deep-research, schedule, update-config, … | yes | shipped with CLI |
| Core user skills | load-project, repackage-as-plugin, plus your own all-task skills | yes | `~/.claude/skills/` |

## Sector-gated plugins (the "loadout")

| Plugin | Purpose | Sector | cc impl (enabledPlugins id) |
|---|---|---|---|
| superpowers | TDD, systematic-debugging, plans, code-review workflow | coding | `superpowers@claude-plugins-official` |
| context7 | Live library/framework docs lookup | coding, research | `context7@claude-plugins-official` |
| frontend-design | Distinctive production-grade UI generation | design | `frontend-design@claude-plugins-official` |
| your-dev-suite | Your locally-repackaged skill/agent/hook bundle | coding | `<name>@local` (local plugin) |

## MCP servers — deferred, always available on-demand (no equip needed)

Their tool schemas load only when called, so they cost ~0 floor. Listed so the agent
remembers they exist. Reach them via ToolSearch / direct call.

| Server | Purpose |
|---|---|
| e.g. Gmail | Read/search threads, create drafts, labels |
| e.g. playwright | Browser automation (navigate, evaluate, screenshot) |

## Bash-tool sectors — no equip needed (work cold)

| Tool | Purpose | Sector | Impl |
|---|---|---|---|
| e.g. a notes search engine | Query your notes index before answering questions about your own knowledge | brain | pure bash scripts — no plugins, no relaunch, ever |

## Memory-only sectors (no tools, payload is context)

e.g. `writing` · `references` — rule/reference bundles. Equip for the rules, not for any plugin.
