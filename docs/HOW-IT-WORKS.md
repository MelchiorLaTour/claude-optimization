# How it works

The problem this system solves: every tool you add to an AI coding agent — plugins,
skills, MCP servers, memory files — costs always-on context tokens, whether or not today's
session needs it. Left alone, the floor creeps up until half your window is gone before
you type a word. The obvious fix, disabling things, creates a worse failure: a **dark
window** — a tool you own, silently forgotten, because nothing in context knows it exists.

The dressing room resolves that tension with one principle: **lean base, discoverable
everything.** Carry almost nothing; forget absolutely nothing. This page walks the six
pieces end-to-end.

## The pieces

### 1. Base (the "underwear")

The global `~/.claude/CLAUDE.md` is a short constitution — a few principles, folded
operational rules, `@`-imports of only the always-on rule files — plus the handful of
tools useful for ANY task. Memory is one-fact-per-file "postits" (frontmatter + Why + How
to apply) indexed one line each in `MEMORY.md`, so a session loads an index, not an
archive. Everything else is off at base.

### 2. Sectors (the "loadout")

A sector is one markdown file per capability domain at `~/Claude/sectors/` — `coding.md`,
`research.md`, `writing.md`, whatever matches *your* work. Top half: prose + `@`-imports
of the member rule/memory files (the context half). Bottom half: a `## Tools (loadout)`
block in a neutral schema — `tool:` / `what:` / `cc: plugin <id>` / `mcp:` / `skills:` /
`portable:` — machine-readable enough for the valet, honest enough to state what doesn't
port. A project's `CLAUDE.md` `@`-imports the sectors it needs; that's the whole equip
contract.

### 3. Wardrobe (the index)

`WARDROBE.md` is the always-on, one-line-per-tool index of everything you own — base,
sector-gated, MCP-deferred, bash tools, memory-only. It costs a few hundred tokens and
buys the guarantee: nothing can be disabled *and* forgotten, because the index is never
disabled. A pointer to it lives in the global CLAUDE.md.

### 4. Discovery hook (the tap on the shoulder)

`wardrobe-discovery-hook.sh` runs on UserPromptSubmit and reads `TRIGGERS.tsv` — one row
per capability: name, `grep -Ei` pattern, ≤600-char hint. When your prompt reaches for
something unequipped ("let's design the UI…" in a session without the design sector), the
matching row's hint is injected: what the capability is, how to equip it. Adding a
capability = adding a row. No code changes, and misses cost nothing.

### 5. Valet (the equip mechanism)

`equip-loadout.sh <project-dir>` reads the project CLAUDE.md's sector imports, unions the
sectors' `cc: plugin` lines, and writes the project's `.claude/settings.json`
`enabledPlugins`. **Equip = reload**: plugins resolve at launch, so the valet writes and
the relaunch loads. No hot-swap pretense.

### 6. Local plugin pattern (the packaging)

Loose user-scope hooks/skills can't be toggled per project — plugins can. The
`repackage-as-plugin` skill (and this repo's own install.sh, which uses the exact same
pattern) bundles them as `<name>@local`: a directory under `~/.claude/local-plugins/` with
a `plugin.json`, its own `hooks.json` for hook wiring (no hand-edits to settings.json),
and a marketplace entry. From then on it toggles like any marketplace plugin.

## A worked session

1. You `cd ~/projects/webapp && claude`. The project `CLAUDE.md` imports
   `sectors/coding.md`; the valet ran once when the project was set up, so
   `enabledPlugins` already lists the coding sector's plugins — they load at launch.
   Base floor plus one sector, nothing else.
2. Mid-session you type "let's mock up the settings screen." The discovery hook matches
   the design row in TRIGGERS.tsv and injects: *design sector exists — equip with
   `equip-loadout.sh add design`, then relaunch.*
3. You run the valet's `add`, relaunch, and the design tools are live. The project's
   settings now remember the grown loadout for every future session.
4. Next week in an unrelated directory, nothing design- or coding-related is loaded — but
   WARDROBE.md still lists all of it, and the hook still watches every prompt.

## The install-scope lesson (learned the hard way)

Marketplace plugins must be installed at **user scope** and toggled per project via
`enabledPlugins`. Installing at project scope produced actual dark windows in the
author's setup — plugins present in one project's install map and invisible everywhere
else, including places that had them "enabled." Two rules fall out:

- **Install scope must match enable scope.** User-scope install, project-scope toggle.
- **A project's `enabledPlugins` overrides the global map in both directions.** It is not
  an additive merge: a plugin globally on but absent from the project map is OFF in that
  project.

The valet encodes both rules so you don't have to remember them.

## Why it works

Every mechanism is the cheap half of a trade the always-on world gets wrong. The wardrobe
is a few hundred tokens against tens of thousands of unequipped-tool definitions. A
trigger row is one TSV line against a permanently-loaded plugin. The discovery hint fires
only when matched, so its cost is near-zero on the sessions that don't need it. The
measured effect on the author's setup (N=1, stated in the README) was roughly a 20k-token
drop in the session floor — with zero capabilities lost, because *discovery before
disable* is the gate every move has to pass: nothing goes off always-on until something
deterministic will resurface it.
