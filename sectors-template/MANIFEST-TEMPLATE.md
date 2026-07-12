# Sectors (TEMPLATE)

<!-- TEMPLATE: replace the example sector list with YOUR taxonomy. The INSTALL bootstrap
     proposes sectors from your actual tools and memory files, then confirms with you. -->

Peer capability bundles. Each sector is ONE file (`~/Claude/sectors/<name>.md`) that
`@`-imports its member memory files. A project pulls a sector by putting
`@~/Claude/sectors/<name>.md` in its own `CLAUDE.md`; the harness inlines everything
mechanically at launch (no hook, no frontmatter).

Example sector list:

- **writing** — voice rules, edit discipline, drafting conventions (memory-only)
- **coding** — the software-build loadout — tools: superpowers, context7, your dev-suite plugin
- **research** — comparison/search-loop/verification rules — tools: context7
- **references** — stable lookup facts (memory-only)
- **design** — aesthetic rules — tools: frontend-design

Each sector file also carries a `## Tools (loadout)` block of `- tool:` / `cc: plugin`
entries (the neutral schema — see `example-sector.md` and `ADAPTERS.md`). The always-on
tool index lives at `WARDROBE.md`. Some sectors are memory-only (no tools block needed).

Toggling a member: comment out its `@` line in the sector file (or exclude via
`claudeMdExcludes` in settings).

This file is documentation only — it does not drive loading. It is the canonical list of
available sectors, used when deciding what to attach to a new project.
