# ADAPTERS — the multi-model contract

*Phase 5, 2026-07-02. Sectors are model-neutral; adapters make them land in each model.*

## The contract

An adapter for model X does exactly two things, using X's **native mechanism**:

1. **Inject the sector context payload** — the sector's prose + its member memory files,
   compiled into self-contained markdown (no `@`-imports; other models can't resolve them).
   `adapters/compile-sector.sh <sector>...` produces this payload for ANY model.
2. **Enable the sector's tools** — translate each tool block in `## Tools (loadout)` into
   X's config. The neutral schema gives each tool the lines an adapter needs:
   - `cc: plugin <id>` — Claude Code enabledPlugins id (read by `equip-loadout.sh`)
   - `mcp: stdio \`<command>\`` — an MCP stdio server any MCP-capable model can run
   - `skills: <pointer>` — official multi-model skill installs where they exist
   - `portable: <note>` — honest statement of what ports as plain markdown (or doesn't)

A tool with only a `cc:` line does not port; the adapter skips it and says so.

## Per-model table

| Model | Context payload mechanism | Tools mechanism | Adapter | Test status |
|---|---|---|---|---|
| **Claude Code** | project `CLAUDE.md` `@~/Claude/sectors/<name>.md` imports | `equip-loadout.sh` → project `.claude/settings.json` enabledPlugins | BUILT (Phase 3) | **LIVE-TESTED** (gates passed 2026-06-28 → 2026-07-02) |
| **Codex (OpenAI CLI)** | `AGENTS.md` in project dir (root→cwd walk; `AGENTS.override.md` also honored) | MCP: `~/.codex/config.toml` `[mcp_servers.<name>]` blocks. Skills: SKILL.md folders at `~/.codex/skills/` or project `.agents/skills/` (same shape as CC) | BUILT: `adapters/equip-codex.sh` | **Built-to-spec, NOT live-tested** — no Codex install in the author's environment yet. Output formats verified against 2026-07-02 research only. |
| **Hermes (Nous Hermes Agent CLI)** | context files + `SOUL.md` | Skills: agentskills.io SKILL.md standard (same folder shape). MCP: Hermes MCP server config | MANUAL, compile-assisted: run `compile-sector.sh`, drop output into a Hermes context file; add MCP servers from the sectors' `mcp:` lines by hand | **Not built, not tested** — no Hermes install; mechanism from 2026-07-02 research. Promote to a script if/when Hermes lands. |
| **Perplexity Comet** | NONE — no file mechanism; memory/personalize only | none | MANUAL ONLY: `compile-sector.sh` output pasted into the conversation | Weakest target, documented honestly. Nothing to build. |

## Usage

```bash
# Universal payload (any model): one self-contained md from one or more sectors
~/Claude/sectors/adapters/compile-sector.sh coding research > payload.md

# Codex: equip a project (reads sectors from its CLAUDE.md, like equip-loadout.sh)
~/Claude/sectors/adapters/equip-codex.sh ~/Claude/some-project
# Codex: one-off sectors into cwd
~/Claude/sectors/adapters/equip-codex.sh add coding
```

`equip-codex.sh` writes the compiled payload into the project's `AGENTS.md` between
`<!-- BEGIN sectors (equip-codex) -->` / `<!-- END -->` markers (idempotent re-runs),
merges each sector `mcp:` line into `~/.codex/config.toml` (backup first, skip if the
server block already exists), and prints the `skills:` install pointers for manual follow-up.

## Honest caveats (locked in plan)

- Codex/Hermes adapters are verified **as far as this environment allows** (output files
  valid, formats match researched specs) — not live-tested against real installs.
- First live Codex run: check that AGENTS.md is picked up from the project root and that
  `codex mcp list` (or equivalent) shows the merged servers. Update the table's test-status
  column when that happens.
