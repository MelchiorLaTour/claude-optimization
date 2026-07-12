Example sector — one-line description of what this capability bundle covers and when a
project should equip it. This first line is the sector's summary; keep it short.

@~/.claude/projects/<your-memory-dir>/memory/feedback_example_rule.md
@~/.claude/projects/<your-memory-dir>/memory/reference_example_fact.md

## Tools (loadout)
- tool: superpowers
  what: TDD, systematic-debugging, plans, code-review workflow
  cc: plugin superpowers@claude-plugins-official
  skills: official multi-model installs — https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
- tool: context7
  what: live library/framework docs lookup
  cc: plugin context7@claude-plugins-official
  mcp: stdio `npx -y @upstash/context7-mcp` — works in Codex config.toml, Hermes MCP config
- tool: your-local-plugin
  what: your repackaged skill/agent/hook bundle
  cc: plugin your-local-plugin@local
  portable: not yet (describe honestly what ports and what doesn't)

<!-- Neutral schema, one block per tool:
  - tool:      display name
    what:      one-line purpose
    cc:        plugin <enabledPlugins id>          (Claude Code mechanism)
    mcp:       stdio `<command>`                   (any MCP-capable model)
    skills:    <pointer to official multi-model installs, if any>
    portable:  <honest note on what ports as plain markdown, or doesn't>
  A tool with only a cc: line does not port; adapters skip it and say so. -->
