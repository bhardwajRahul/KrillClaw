# Phase 4 Implementation Plan

## Context

Phase 3 shipped: WebSocket gateway, multi-channel bridge, skills/plugins. CI green. Site deployed.

Competitor landscape (Feb 28, 2026):
- **MimiClaw** (3,600 stars): Added WebSocket gateway, GPIO control, dual-provider (Claude+GPT). Still Telegram-only, no MCP, no plugins, no tests.
- **NanoClaw** (16,600 stars, explosive growth): MCP support, 5-channel messaging, skills framework, agent swarms. Server-only (can't do embedded).
- **OpenClaw** (236k+ stars): Shipped external secrets mgmt, thread-bound agents, WebSocket-first Codex transport, 11 security hardening fixes, multilingual stop phrases in last 2 weeks. Moving fast.

**Goal**: Close feature gaps on MCP, multi-channel, website KPIs, and add interactive demo. No agent swarms (Phase 5).

**Zig binary cost for all of Phase 4: ~100 bytes** (GPIO tool defs only). Everything else in Python bridge + site.

---

## Step 1: MCP Client Support

MCP is becoming table stakes. NanoClaw has it. MimiClaw doesn't yet — we beat them to it.

### Architecture

```
Zig agent  <--exec-tool-->  bridge.py  <--MCP SDK-->  MCP Server (stdio/HTTP)
                                |
                          mcp_bridge.py
                            |   |   |
                       GitHub  Filesystem  Google Calendar ...
```

### New file: `bridge/bridge/mcp_bridge.py`

- Uses official `mcp` Python SDK (`pip install mcp>=1.26.0`)
- `MCPBridge` class manages N server connections via `AsyncExitStack`
- Tools namespaced as `servername__toolname` to avoid collisions
- Config from `~/.krillclaw/mcp_servers.json` (Claude Desktop compatible format)
- Supports stdio (local) and streamable HTTP (remote) transports

### Config format (`~/.krillclaw/mcp_servers.json`)

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {"GITHUB_TOKEN": "ghp_..."}
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user"]
    },
    "calendar": {
      "transport": "http",
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

### Integration with bridge.py

- `--serve` mode: start MCP bridge alongside channels, inject MCP tools into LLM tool list
- `--exec-tool` mode: add `mcp_call` action that routes to the correct MCP server
- Tool discovery: `mcp_list_tools` action returns all connected MCP server tools

### Zig changes: None

Unknown tools already fall through to bridge (Phase 3). MCP tools route automatically.

**Files:** `bridge/bridge/mcp_bridge.py` (new), `bridge/bridge/bridge.py` (integrate), `bridge/bridge/requirements.txt` (add `mcp>=1.26.0`)
**QA:** Configure filesystem MCP server, invoke `filesystem__read_file` via agent, verify result.

---

## Step 2: More Channels (Discord, Slack, WhatsApp)

NanoClaw supports 5 channels. We have 4 (Telegram, MQTT, Webhook, WebSocket). Adding 3 more puts us at 7.

### Discord Channel (`channels/discord.py`)

- Uses `discord.py` library (lazy import)
- Bot token auth, guild/channel allowlist
- Slash commands for `/ask` interaction

### Slack Channel (`channels/slack.py`)

- Uses `slack-bolt` library (lazy import)
- Socket Mode (no public URL needed) or Events API
- App token + bot token auth

### WhatsApp Channel (`channels/whatsapp.py`)

- Uses official WhatsApp Business Cloud API (Meta)
- Webhook-based: receives messages via HTTP POST, sends via API
- Requires Meta business verification + phone number
- Note: NOT using unofficial Baileys library (NanoClaw's approach has legal risk)

### Channel count update

| Before | After |
|--------|-------|
| Telegram, MQTT, Webhook, WebSocket | + Discord, Slack, WhatsApp = **7 channels** |

**Files:** `bridge/bridge/channels/discord.py`, `slack.py`, `whatsapp.py`, update `bridge.py` channel registry
**Zig changes:** None
**QA:** Test each channel individually with `--serve --channels <name>`

---

## Step 3: GPIO / Hardware Tools

MimiClaw's killer feature is GPIO control from the AI. We can match this via bridge tools that work across boards (not just ESP32).

### New bridge tools

```python
# For Linux SBCs (Raspberry Pi, etc.) via sysfs/gpiod
"gpio_read":    {"pin": 17}                    -> {"value": 1}
"gpio_write":   {"pin": 17, "value": 0}        -> {"status": "ok"}
"gpio_list":    {}                              -> {"pins": [...]}
"i2c_read":     {"bus": 1, "addr": 0x48, ...}  -> {"data": [...]}
"spi_transfer": {"bus": 0, "data": [...]}       -> {"response": [...]}
```

### Implementation

- `bridge/bridge/hardware.py` — hardware abstraction
- Linux: `gpiod` library (libgpiod Python bindings)
- macOS: stub/simulator mode (log commands like robotics profile)
- Safety: pin allowlist in config, rate limiting

### Zig-side

- Add `gpio_read`, `gpio_write` to IoT profile tool definitions (~100 bytes)
- Route through existing bridge fallback mechanism

**Files:** `bridge/bridge/hardware.py` (new), `bridge/bridge/bridge.py` (register handlers)
**Zig changes:** ~100 bytes (tool definitions in `tools_iot.zig`)
**QA:** Test on Raspberry Pi if available, otherwise simulator mode

---

## Step 4: Website KPI Upgrades

Current site claims vs reality vs competitors:

| KPI | Site Says | Reality | MimiClaw | NanoClaw | Target |
|-----|-----------|---------|----------|----------|--------|
| LLM providers | 16 | 16 | 2 | 1 | **20+** |
| Channels | 8+ | 4 (Phase 3) | 2 | 5 | **7** (after Step 2) |
| Devices | 50+ | 44 validated | 1 | 0 | **50+** (true) |
| Tests | 40 | 60 | 0 | ? | **60** |
| Lines of code | ~3,500 | ~4,800 | ? | ~3,900 | Update to actual |
| Binary (Lite) | 49 KB | ~52 KB | N/A | N/A | Keep |
| MCP | Not mentioned | Not yet | No | Yes | **Add after Step 1** |
| Time to audit | Not mentioned | ~1 hour | N/A | 8 minutes | **Add claim** |

### Provider count: 16 → 20+

Add 4+ more confirmed providers to Docs/PROVIDERS.md:
- Perplexity AI (`https://api.perplexity.ai`)
- Cohere (`https://api.cohere.com/v2`)
- AI21 (`https://api.ai21.com/studio/v1`)
- Hyperbolic (`https://api.hyperbolic.xyz/v1`)
- Lepton AI (`https://api.lepton.ai/v1`)

These all have OpenAI-compatible endpoints — just need to verify tool calling works and add to docs.

### Site updates (`site/index.html`)

1. **Provider count**: "16 providers" → "20+ providers"
2. **Channel count**: "8+ channels" → "7 channels" (be honest, or add more to hit 8)
3. **Test count**: "40 tests" → "60 tests"
4. **Lines of code**: "~3,500" → "~4,800" (or recount)
5. **Add MCP badge/claim**: "MCP Compatible — connect 1000+ tools"
6. **Add "time to audit" counter**: "Read the entire codebase in under an hour" (already claimed, make more prominent)
7. **Add comparison row**: MCP support column in competitor table
8. **Add GPIO/hardware claim**: "Direct hardware control — GPIO, I2C, SPI"

### README updates

- Add MCP section
- Add new channels to transport table
- Update test count, LOC count
- Add GPIO tools to IoT profile description

**Files:** `site/index.html`, `README.md`, `Docs/PROVIDERS.md`
**QA:** Deploy site, verify all claims match reality

---

## Step 5: Provider Verification & Docs

Verify the 4+ new providers actually work with tool calling:

```bash
# Test each provider
KRILLCLAW_API_KEY=... ./zig-out/bin/krillclaw \
  --provider openai --base-url https://api.perplexity.ai \
  -m sonar-pro "what is 2+2"
```

For each: document in `Docs/PROVIDERS.md` with base URL, model names, tool calling support (yes/no/partial), and any quirks.

**Files:** `Docs/PROVIDERS.md`
**QA:** Each provider responds successfully

---

## Step 6: Interactive Terminal Demo on Website

Based on user feedback: "Give me a way to experience what KrillClaw does without hardware."

### Approach: Scripted Terminal Replay (asciinema-style)

Two embedded terminal demos on the site showing before/after scenarios:

#### Demo 1: "The 2018 Car" (Lite profile)
```
BEFORE: Dumb dashboard controller
> read_sensor temperature_engine
  Engine: 210°F [WARNING]
> ??? (no intelligence, just alarms)

AFTER: KrillClaw Lite on the same ECU
> krillclaw --profile iot "engine temp is 210°F, rising fast"
  [Agent] Reading sensor history... temp rose 40°F in 2 minutes.
  [Agent] Cross-referencing with coolant level... coolant LOW.
  [Agent] Recommendation: Reduce engine load immediately.
          Coolant leak probable. Navigate to nearest service.
  [Agent] Setting dashboard warning: COOLANT SERVICE REQUIRED
  [Agent] Logging event to fleet management system.
```

#### Demo 2: "Smart Elevator" (Full profile)
```
BEFORE: Fixed schedule, no awareness
> floor_request 3
  Moving to floor 3. ETA: 45 seconds.

AFTER: KrillClaw Full on elevator controller
> krillclaw --profile iot "optimize elevator for morning rush"
  [Agent] Analyzing usage patterns from KV store...
  [Agent] Peak: floors 1→8,12,15 between 8:30-9:15 AM.
  [Agent] Current time: 8:25 AM. Pre-positioning to lobby.
  [Agent] Setting express mode: lobby → 8, 12, 15.
  [Agent] Disabling door-hold on floors 2-7 during rush.
  [Agent] Estimated wait time reduction: 40%.
```

### Implementation

- Pure JavaScript, no backend needed
- Custom typing animation with terminal styling (matches site's monospace theme)
- Auto-plays on scroll-into-view, with replay button
- Two side-by-side panels: "Before" (grey/dim) and "After" (green/bright)
- Mobile: stacked vertically

### Technical approach

- `site/assets/terminal-demo.js` — ~150 lines of vanilla JS
- Typing effect at ~40ms/char for commands, ~15ms/char for output
- Pause between lines for readability
- No external dependencies (no asciinema player, no xterm.js — keep it simple)

**Files:** `site/assets/terminal-demo.js` (new), `site/index.html` (embed demos)
**QA:** Test on mobile + desktop, verify animations smooth

---

## Step 7: OpenClaw Compatibility Audit

OpenClaw shipped significant changes in the last 2 weeks. Check for relevant updates:

### Changes to track
- **Tool annotations** (`readOnly`, `destructive`) — MCP spec addition, worth supporting
- **Structured command approvals** — `commandArgv` binding pattern for exec tools
- **Multilingual stop phrases** — 9 languages (ES/FR/ZH/HI/AR/JP/DE/PT/RU)
- **WebSocket-first transport** — already built (Phase 3)
- **External secrets management** — bridge could mediate vault access

### Action items
- Review OpenClaw's latest tool schemas for any contract changes
- Ensure our tool definitions remain compatible with standard patterns
- Add tool annotations to bridge tool manifests (readOnly/destructive flags)
- Consider multilingual stop phrases in agent loop (minimal Zig cost)

**Files:** Audit only, changes folded into other steps or deferred to Phase 5
**QA:** Verify tool schemas match current conventions

---

## Step 8: QA & Ship

1. `zig build test` — all tests pass
2. `zig build -Doptimize=ReleaseSmall` — binary < 600KB
3. Python: all files compile, MCP integration test passes
4. Cross-compile spot check (aarch64-linux, x86_64-linux)
5. Push to GitHub, verify both CI workflows green
6. Site deployed with updated KPIs + terminal demos

---

## Verification Checklist

1. **MCP**: `mcp_servers.json` with filesystem server → agent can read files via MCP
2. **Discord**: Bot joins server, responds to messages
3. **Slack**: Bot responds in channel via Socket Mode
4. **WhatsApp**: Webhook receives message, sends response via Cloud API
5. **GPIO**: `gpio_read`/`gpio_write` work on RPi (or simulator mode elsewhere)
6. **Providers**: 20+ confirmed in PROVIDERS.md with test results
7. **Site**: All KPIs match reality, MCP badge visible, comparison table updated
8. **Terminal demos**: Both play smoothly on desktop and mobile
9. **CI**: Both workflows green
10. **Binary**: < 600KB

## Priority Order

| Step | Impact | Effort | Ship independently? |
|------|--------|--------|-------------------|
| 1. MCP | High (table stakes) | Medium | Yes |
| 2. Channels | High (KPI) | Medium | Yes |
| 4. Site KPIs | High (marketing) | Small | Yes |
| 6. Terminal Demo | High (conversion) | Small | Yes |
| 5. Providers | Medium (KPI) | Small | Yes |
| 3. GPIO | Medium (vs MimiClaw) | Medium | Yes |
| 7. OpenClaw Audit | Medium (compat) | Small | Yes |
| 8. QA | Required | Small | N/A |
