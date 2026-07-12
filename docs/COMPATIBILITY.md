# Compatibility

**This is a Claude Code system, for now.** Unlike the companion NewBrain repo (whose bash
engine runs anywhere), almost everything here is built from Claude Code's own constructs —
plugins, `enabledPlugins` maps, UserPromptSubmit/PostToolUse hooks, `@`-imported CLAUDE.md
files, skills. The *ideas* port; the implementation is Claude Code's.

## Agent platforms

| Platform | Status | What works / what doesn't |
|---|---|---|
| **Claude Code — CLI** | ✅ Supported, live-tested | Everything: sectors, wardrobe, discovery hook, valet, local-plugin packaging, constitution + memory structure. The author's daily setup. |
| **Claude Code — desktop app / IDE extensions** | ✅ Supported | Same harness, same settings/hooks/plugin machinery as the CLI. |
| **Claude Desktop (the chat app)** | ❌ N/A | No hooks, no plugins, no settings.json, no filesystem — there is nothing for this system to manage. (Its Projects feature is the closest analogue to a sector, but nothing here installs into it.) |
| **ChatGPT desktop app** | ❌ No | No local shell, no comparable extension surface. |
| **Codex CLI (OpenAI)** | 🔶 Adapter built-to-spec, UNTESTED | `sectors-template/ADAPTERS.md` is the contract; `adapters/equip-codex.sh` translates a sector into AGENTS.md + config.toml against researched formats. No live test has ever run (the author has no Codex install). Treat as a starting point, not a product. |
| **Other MCP-capable / open-weights harnesses** | 🔶 Pattern ports, wiring doesn't | `adapters/compile-sector.sh` emits a self-contained markdown payload any model can load as context. Sector `mcp:` lines carry stdio commands for any MCP-capable runtime. Hooks, plugins, and the valet stay behind. |

The multi-model story is honest by design: the neutral sector schema and ADAPTERS.md exist
so the system *can* port later, and the per-model test status is stated in ADAPTERS.md
rather than implied. Today, **Claude Code is the supported target.**

## Operating systems

| OS | Status | Notes |
|---|---|---|
| **macOS** | ✅ Supported, live-tested | Development and sandbox-test platform (stock bash 3.2 supported). |
| **Linux** | 🔶 Should work, untested | All shell is POSIX bash; no macOS-only calls in the shipped scripts. Claude Code itself runs on Linux. |
| **Windows — WSL** | 🔶 Should work, code-read only | Same reasoning as Linux; run Claude Code inside WSL. Not live-tested. |
| **Windows — Git Bash / native** | ⚠️ / ❌ | The hooks assume a POSIX shell environment; native cmd/PowerShell is out. Use WSL. |

## Dependencies

- `jq` — required by `wardrobe-discovery-hook.sh` (JSON prompt parsing). install.sh warns
  if missing.
- `node` — required by `read-injection-scanner.js`. install.sh warns if missing.
- `python3` *or* `node` — used by verify-install.sh for JSON validation.
- The `claude` CLI — for the two plugin commands install.sh prints (marketplace add +
  install). The assembly itself is plain file copying and works without it.
