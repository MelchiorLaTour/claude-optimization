# claude-optimization — the "dressing room" for Claude Code

A blueprint for scoping an AI coding agent's tools and context per project instead of
carrying everything always-on. Base Claude = a minimal constitution + only the tools useful
for ANY task (the "underwear"). Every other tool lives in a **sector** — a model-neutral
capability bundle — equipped per project (the "loadout"). An always-on **wardrobe** index +
a prompt-triggered **discovery hook** make sure nothing equipped-off is ever forgotten.

This is a working system extracted from the author's setup, published as a blueprint: the
scripts and hooks are real and scrubbed; the sector/wardrobe content is templated because
your tool inventory is not the author's. `INSTALL.md` walks an agent through generating
yours.

## Architecture

```mermaid
flowchart TD
    subgraph always-on
        C[global CLAUDE.md<br/>short constitution + @-imports]
        W[WARDROBE.md<br/>always-on tool index]
        H[wardrobe-discovery-hook.sh<br/>UserPromptSubmit, reads TRIGGERS.tsv]
    end
    subgraph per-project
        P[project CLAUDE.md<br/>@-imports sectors + FACTS]
        S[.claude/settings.json<br/>enabledPlugins]
    end
    T[TRIGGERS.tsv<br/>name / regex / hint rows]
    SEC[sectors/*.md<br/>neutral schema: context + tools]
    V[equip-loadout.sh<br/>the valet]

    H -->|prompt matches a row| T
    T -->|hint: equip sector X| SEC
    SEC -->|@-import| P
    V -->|reads sector cc: lines| SEC
    V -->|writes| S
    W -.->|nothing is forgotten| C
```

- **Sectors** (`sectors-template/`): one file per capability domain. Top = prose +
  `@`-imports of member memory/rule files (the context half). Bottom = a `## Tools
  (loadout)` block in a neutral schema (the tools half). See `example-sector.md`.
- **Valet** (`scripts/equip-loadout.sh`): reads a project CLAUDE.md's sector imports,
  unions the sectors' `cc: plugin` lines, writes the project's `enabledPlugins`. Equip =
  reload (plugins resolve at launch).
- **Discovery** (`hooks/wardrobe-discovery-hook.sh` + `TRIGGERS.tsv`): a data-driven
  UserPromptSubmit hook. Each row = name / `grep -Ei` pattern / ≤600-char hint. When a
  prompt reaches for an unequipped capability, the hook injects the hint. Adding a
  capability = adding a row — no code change.
- **Wardrobe** (`WARDROBE-TEMPLATE.md`): the always-on index of everything you own, so a
  tool can be unequipped without being forgotten.
- **Local plugin pattern** (`local-marketplace-example/` + `skills/repackage-as-plugin/`):
  repackage loose user-scope skills/agents/hooks into a `<name>@local` plugin, toggleable
  per project like any marketplace plugin.
- **Constitution + memory structure**: global CLAUDE.md as a short constitution (a few
  principles + folded rules) + `@`-imports of always-on rules; memory as one-fact-per-file
  "postits" (frontmatter: `name`/`description`/`type: user|feedback|project|reference`;
  body: the fact + **Why** + **How to apply**; `[[wikilinks]]`) indexed by a one-line-each
  `MEMORY.md`. INSTALL.md ships the structure; the content is yours.

## Philosophy

- **Lean base, discoverable everything.** Token floor stays small; capability stays total.
  The failure mode this prevents: disabling a tool and silently losing the ability to know
  it exists ("a dark window").
- **Discovery before disable.** Never move a tool off always-on until something
  deterministic (hook row, wardrobe line) will resurface it. Saved tokens that cost you a
  forgotten capability are a net loss — weight by value-per-token, not raw count.
- **Equip = reload.** Plugins resolve at launch; the valet writes settings, the relaunch
  loads them. No hot-swap pretense.
- **Install scope must match enable scope** (learned the hard way): install marketplace
  plugins at USER scope and toggle per project via `enabledPlugins`. Project-scope installs
  produced dark windows. Note `enabledPlugins` in a project **overrides** the global map in
  both directions — it is not an additive merge.
- **Identity vs usage placement.** Ask "what IS this thing?" before "where will I read it
  from?". Personal facts → always-on memory; capability bundles → sectors; project state →
  that project's FACTS file. Mixed-nature: identity sets placement, usage sets the loading
  mechanism (pointer, hook, sector-pull).

## What's in the repo

```
scripts/equip-loadout.sh          the valet (project | add | remove modes)
hooks/wardrobe-discovery-hook.sh  data-driven discovery (reads TRIGGERS.tsv)
hooks/read-injection-scanner.js   PostToolUse scanner: flags prompt-injection patterns in Read content
hooks/writing-rules-hook.sh       EXAMPLE pointer-pattern hook (short pointer instead of full rules payload)
hooks/md-route-guard.sh           EXAMPLE PreToolUse guard (blocks .md writes to Desktop)
hooks/save-at-80.sh               EXAMPLE PostToolUse guard (save-and-stop directive at 80% context)
hooks/sensitive-block-guard.sh    EXAMPLE hard block on a sensitive folder
skills/load-project/              resume a project from anywhere by walking its @-import chain
skills/repackage-as-plugin/       turn loose user-scope tools into a toggleable local plugin
sectors-template/                 example sector, WARDROBE/MANIFEST templates, TRIGGERS example,
                                  ADAPTERS.md (multi-model contract) + adapters/ scripts
local-marketplace-example/        marketplace.json skeleton for <name>@local plugins
install.sh                        one-command bootstrap: assembles the local plugin, wires hooks, seeds templates
verify-install.sh                 machine-checked PASS/FAIL acceptance gates for the install
INSTALL.md                        hybrid install: install.sh does the deterministic work; agent authors YOUR taxonomy
```

Note: `save-at-80.sh` depends on a statusline/monitor process writing
`$TMPDIR/claude-ctx-<session>.json` with a `used_pct` field — it is a pattern to adapt, not
a drop-in, unless you have such a monitor.

## Use cases

- You run many projects with different tool needs and your always-on context has bloated.
- You want per-project plugin loadouts without forgetting what exists.
- You want your setup portable across models (Claude Code today, Codex/other CLIs later).
- You want a memory architecture that stays small: constitution + indexed postits.

## When NOT to use this

- **Small tool set.** If you run a handful of plugins and your context floor doesn't hurt,
  sectors are overhead. This pays off at dozens of tools across several domains.
- **Single-project users.** If every session is the same project, just enable what that
  project needs globally.
- **No appetite for reload cycles.** Equip = reload is a real workflow cost; if you'd
  rather pay tokens than relaunches, keep things always-on.

## Security notes

- **Hooks run YOUR shell with YOUR permissions. Review every hook before installing it.**
  That applies to this repo's hooks too.
- `read-injection-scanner.js` scans content returned by Read-type tools for
  prompt-injection patterns (spoofed system-reminder blocks, instruction overrides) and
  flags them. It is a tripwire, not a guarantee.
- `sensitive-block-guard.sh` shows the hard-block pattern for a credentials folder —
  matched across Read/Bash/Grep/Glob path fields.
- Everything here is local: no network calls, no telemetry, no API keys.

## Multi-model portability

Sectors are model-neutral by construction; `sectors-template/ADAPTERS.md` is the contract.
Each tool block carries the lines an adapter needs (`cc:` for Claude Code, `mcp:` for any
MCP-capable model, `skills:` for official multi-model installs, `portable:` for an honest
statement of what doesn't port). `adapters/compile-sector.sh` emits a self-contained
markdown payload for ANY model; `adapters/equip-codex.sh` targets the Codex CLI
(AGENTS.md + config.toml). Test status is stated honestly per model in ADAPTERS.md — only
the Claude Code path is live-tested; the Codex adapter is built-to-spec against researched
formats.

## Measured results (author-measured, N=1, his machine — your numbers will differ)

- Always-on memory: 34k → 14.3k tokens after the constitution + postit redesign.
- Session context floor: ~55.5k → ~35.7k tokens.
- One project's memory payload: 27.7k → 16.2k after splitting archival history out of the
  live FACTS file.
- Discovery hook cost: 560–833 chars injected per fire; the pointer-pattern writing hook
  dropped 8,590 → 637 chars per false fire.

These are single-user measurements on one setup, quoted for scale, not as benchmarks.

## Install

Install is two layers:

1. **`./install.sh`** [no LLM needed] — assembles the two generic hooks + two skills as a
   local plugin (`claude-optimization@local`), wired through the plugin's own `hooks.json`
   so there are **no hand-edits to `~/.claude/settings.json`**; copies the valet to
   `~/.claude/scripts/`; seeds `~/Claude/sectors/` from the templates if absent. It never
   clobbers an existing local marketplace — it prints the entry to merge instead.
2. **Hand `INSTALL.md` to your agent** — the judgment steps: inventory your tools, then
   author YOUR sectors, WARDROBE, and TRIGGERS rows from the templates. Each step states a
   GOAL, what the agent must DISCOVER on your machine, the exact OUTPUTS, and an ACCEPTANCE
   check; taxonomy is proposed from your real inventory and confirmed with you, never assumed.

Run `bash verify-install.sh` anytime for a machine-checked PASS/FAIL of the whole install.

## License

MIT — see `LICENSE`.
