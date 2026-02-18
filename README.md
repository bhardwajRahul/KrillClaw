<p align="center">
  <img src="https://krillclaw.com/assets/krillclaw-logo.svg" alt="KrillClaw" width="120" />
</p>

<h1 align="center">KrillClaw</h1>
<p align="center"><strong>The AI agent runtime that fits on a microcontroller.</strong></p>

<p align="center">
  <a href="https://github.com/krillclaw/KrillClaw/actions"><img src="https://img.shields.io/github/actions/workflow/status/krillclaw/KrillClaw/test.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-BSL_1.1-blue?style=flat-square" alt="License: BSL 1.1"></a>
  <img src="https://img.shields.io/badge/language-Zig_0.13+-f7a41d?style=flat-square&logo=zig&logoColor=white" alt="Zig 0.13+">
  <img src="https://img.shields.io/github/languages/code-size/krillclaw/KrillClaw?style=flat-square&color=green" alt="Code size">
  <img src="https://img.shields.io/badge/binary-~180KB-00ff88?style=flat-square" alt="Binary size">
  <img src="https://img.shields.io/badge/dependencies-0-brightgreen?style=flat-square" alt="Zero deps">
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#why-krillclaw">Why KrillClaw?</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#profiles">Profiles</a> •
  <a href="#embedded-mode">Embedded</a> •
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

180KB binary. 0 dependencies. 17 source files. Runs on a $3 microcontroller or a cloud server.

KrillClaw is an autonomous AI agent runtime written in Zig. It connects to any LLM (Claude, OpenAI, Ollama), executes tools, and loops until the task is done — in under 200KB of compiled code.

```
 ┌──────────────────────────────────────────────────────┐
 │                                                      │
 │   ~180 KB.  Zero deps.  Boots in <10ms.              │
 │   The entire agent runtime — LLM client, tool        │
 │   executor, JSON parser, SSE streaming, context      │
 │   management — in 3,873 lines of Zig.                │
 │                                                      │
 └──────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Install Zig 0.13+ → https://ziglang.org/download/
# 2. Clone and build (takes ~1 second)
git clone https://github.com/krillclaw/KrillClaw.git
cd KrillClaw
zig build -Doptimize=ReleaseSmall

# 3. Set your API key and go
export ANTHROPIC_API_KEY=sk-ant-...
./zig-out/bin/krillclaw "create a REST API in Go with user auth"
```

That's it. No npm install. No pip. No Docker. Just Zig and a binary.

## Why KrillClaw?

**Every AI agent runtime is massive.** Desktop coding agents ship as 50–500MB bundles with hundreds of dependencies. The actual logic — "call LLM, parse response, execute tools, repeat" — shouldn't need any of that.

KrillClaw proves it doesn't. The same agentic loop that powers desktop tools, compiled to a binary smaller than a JPEG, running on hardware that costs less than a coffee.

**KrillClaw exists because AI agents should run everywhere** — not just on machines with Node.js and 8GB of RAM.

### The Numbers

| | KrillClaw | Typical Edge Runtime | Desktop Agent |
|---|:---:|:---:|:---:|
| **Binary** | **~180 KB** | 2–8 MB | 50–500 MB |
| **RAM** | **~2 MB** | 10–512 MB | 150 MB – 1 GB |
| **Source** | **3,873 LOC** | 5–30K LOC | 30–100K+ LOC |
| **Dependencies** | **0** | 10–100+ | 100–1000+ |
| **Boot time** | **<10 ms** | <1s | 2–5s |
| **Embedded/BLE** | **Yes** | Sometimes | No |

### vs Embedded/Edge Runtimes

| Feature | KrillClaw | MimiClaw | PicoClaw |
|---------|:---------:|:--------:|:--------:|
| **Language** | Zig | Python | Go |
| **Binary size** | ~180 KB | ~2 MB | ~8 MB |
| **RAM usage** | ~2 MB | ~512 KB* | ~10 MB |
| **Dependencies** | 0 | pip | Go modules |
| **BLE transport** | ✅ | ❌ | ❌ |
| **Serial transport** | ✅ | ❌ | ❌ |
| **Multi-provider** | 3 (Claude, OpenAI, Ollama) | 1 | 1 |
| **SSE streaming** | ✅ | ❌ | ❌ |
| **Inline tests** | 39 | 0 | Limited |
| **Sandbox mode** | ✅ | ❌ | ❌ |
| **License** | BSL 1.1 | MIT | MIT |

*Competitor data as of Feb 2026. Check their repos for current numbers.*

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        KrillClaw                             │
│                                                              │
│  ┌─────────┐    ┌──────────┐    ┌────────────┐              │
│  │  main    │───▶│  agent   │───▶│  tools     │              │
│  │  (CLI)   │    │  (loop)  │    │  (dispatch)│              │
│  └─────────┘    └────┬─────┘    └─────┬──────┘              │
│                      │                │                      │
│                 ┌────▼─────┐    ┌─────▼──────────────┐      │
│                 │   api    │    │  tools_coding.zig   │      │
│                 │ (client) │    │  tools_iot.zig      │      │
│                 └────┬─────┘    │  tools_robotics.zig │      │
│                      │          └────────────────────┘      │
│               ┌──────▼──────┐                                │
│               │  transport  │  ◀── vtable dispatch           │
│               └──┬────┬──┬──┘                                │
│                  │    │  │                                    │
│              ┌───▼┐ ┌▼──▼┐                                   │
│              │HTTP│ │BLE │ │Serial│                           │
│              └────┘ └────┘ └──────┘                           │
│                                                              │
│  Support: json.zig │ stream.zig │ context.zig │ config.zig  │
│           types.zig │ arena.zig                              │
└─────────────────────────────────────────────────────────────┘

17 files. 3,873 lines. Zero dependencies.
```

### Source Map

| File | Lines | Role |
|------|------:|------|
| `main.zig` | 153 | CLI, REPL, entry point |
| `agent.zig` | 215 | Agent loop + FNV-1a stuck-loop detection |
| `api.zig` | 341 | Multi-provider HTTP client (Claude/OpenAI/Ollama) |
| `stream.zig` | 362 | SSE streaming parser |
| `json.zig` | 501 | Hand-rolled JSON parser/builder — zero deps |
| `tools.zig` | 183 | Tool dispatcher — comptime profile selection |
| `tools_coding.zig` | 447 | Coding profile: bash, read/write/edit, search, list, patch |
| `tools_iot.zig` | 241 | IoT profile: MQTT, HTTP, KV store, device info |
| `tools_robotics.zig` | 153 | Robotics profile: commands, e-stop, telemetry |
| `context.zig` | 226 | Token estimation + priority-based truncation |
| `config.zig` | 184 | Config: file → env → CLI precedence |
| `transport.zig` | 129 | Abstract vtable transport + RPC protocol |
| `types.zig` | 151 | Core types: Provider, Message, Config, ToolDef |
| `ble.zig` | 159 | BLE GATT transport (protocol + simulation) |
| `serial.zig` | 142 | UART/serial transport (Linux/macOS) |
| `arena.zig` | 182 | Fixed arena allocator for embedded targets |
| `react.zig` | 104 | ReAct reasoning loop |

## Profiles

Compile-time profiles select different tool sets. Only the selected profile's code ships in the binary — zero runtime overhead.

```bash
# Coding agent (default)
zig build -Dprofile=coding -Doptimize=ReleaseSmall

# IoT agent — MQTT, HTTP, KV store, device info
zig build -Dprofile=iot -Doptimize=ReleaseSmall

# Robotics agent — motion commands, e-stop, telemetry
zig build -Dprofile=robotics -Doptimize=ReleaseSmall
```

| Profile | Tools | Binary Size | Security Policy |
|---------|-------|:-----------:|-----------------|
| **coding** | bash, read/write/edit, search, list, patch | ~180 KB | bash behind approval gate, writes restricted to cwd |
| **iot** | MQTT pub/sub, HTTP, KV store, device info | ~150 KB | no bash, no file writes, 30 req/min rate limit |
| **robotics** | robot_cmd, estop, telemetry | ~160 KB | no bash, bounds checking, 10 cmd/s, e-stop |

All profiles support sandbox mode: `zig build -Dsandbox=true`

## Providers

| Provider | Models | Auth |
|----------|--------|------|
| **Claude** | claude-sonnet-4-5, claude-opus-4, etc. | `ANTHROPIC_API_KEY` |
| **OpenAI** | gpt-4o, gpt-4-turbo, etc. | `OPENAI_API_KEY` |
| **Ollama** | llama3, codellama, mistral, etc. | None (local) |

```bash
# Claude (default)
./zig-out/bin/krillclaw "fix the tests"

# OpenAI
export OPENAI_API_KEY=sk-...
./zig-out/bin/krillclaw --provider openai -m gpt-4o "fix the tests"

# Local Ollama
./zig-out/bin/krillclaw --provider ollama -m llama3 "explain this code"
```

## Embedded Mode

KrillClaw targets microcontrollers. The device runs the agent brain. A phone or laptop bridges to the internet.

```
┌─────────────┐       BLE/UART       ┌──────────────┐      HTTPS      ┌─────────┐
│  KrillClaw  │ ◄──────────────────► │    Bridge     │ ◄────────────► │  LLM    │
│  (device)   │                      │  (phone/PC)   │                │  API    │
│             │  "call bash ls"      │               │                └─────────┘
│ Agent loop  │ ────────────────►    │ Execute tools │
│ JSON parse  │                      │ Return result │
│ State mgmt  │ ◄────────────────   │               │
│    ~50 KB   │  "file1 file2..."    │  bridge.py    │
└─────────────┘                      └───────────────┘
```

### Build for Hardware

```bash
# BLE transport
zig build -Dble=true -Doptimize=ReleaseSmall

# Serial/UART transport
zig build -Dserial=true -Doptimize=ReleaseSmall

# Bare-metal (no OS)
zig build -Dembedded=true -Dtarget=thumb-none-eabi -Doptimize=ReleaseSmall
```

### Target Hardware

| Device | SoC | RAM | Flash | Cost |
|--------|-----|-----|-------|-----:|
| **ESP32-C3** | RISC-V | 400 KB | 4 MB | $3 |
| **Raspberry Pi Pico W** | RP2040 | 264 KB | 2 MB | $6 |
| **Colmi R02** (smart ring) | BlueX RF03 | ~32 KB | ~256 KB | $20 |
| **nRF52840-DK** | nRF52840 | 256 KB | 1 MB | $40 |
| **nRF5340-DK** | nRF5340 | 512 KB | 1 MB | $50 |

### Fixed Arena Allocator

For devices with no OS heap:

```zig
var mem = arena.Arena32K.init();  // 32KB — fits on nRF5340
const alloc = mem.allocator();
// ... use alloc for everything ...
mem.reset();  // Frees everything at once between agent turns
```

Preset sizes: `Arena4K`, `Arena16K`, `Arena32K`, `Arena128K`, `Arena256K`.

## Transport Layers

| Transport | Use Case | Status |
|-----------|----------|--------|
| **HTTP** | Desktop — direct HTTPS to API | Stable |
| **BLE** | Embedded — GATT protocol + desktop simulation via Unix socket | Experimental |
| **Serial** | Dev boards — UART to host machine | Experimental |

> **BLE note:** The BLE transport implements framing and GATT service UUIDs with desktop simulation via Unix sockets. Real hardware integration requires linking against the platform BLE SDK (e.g., Nordic SoftDevice). See `ble.zig` for integration points.

## Configuration

```bash
# Environment variables
export KRILLCLAW_MODEL=claude-opus-4-6
export KRILLCLAW_PROVIDER=claude
export KRILLCLAW_BASE_URL=https://my-proxy.com
export KRILLCLAW_SYSTEM_PROMPT="You are a Go expert..."
```

```json
// .krillclaw.json (project-level config)
{
  "model": "claude-sonnet-4-5-20250929",
  "provider": "claude",
  "max_tokens": 8192,
  "streaming": true
}
```

Config precedence: CLI flags → environment variables → config file.

## REPL Commands

| Command | Description |
|---------|-------------|
| `/help` | Show help |
| `/quit` `/exit` `/q` | Exit |
| `/model <name>` | Switch model |
| `/provider <name>` | Switch provider |

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Hand-rolled JSON** | `std.json` adds unnecessary code. KrillClaw only needs key extraction + body building. 501 lines, zero deps. |
| **Vtable transports** | Same binary works over HTTP, BLE, or Serial. Swap physical layer without touching agent logic. |
| **FNV-1a loop detection** | Detect stuck LLM loops in constant memory (128 bytes). Critical for embedded. |
| **Priority-based truncation** | When context fills, drop assistant text first, keep tool results. Keeps working memory functional. |
| **Substring search, not regex** | Regex engines are ~10K+ lines. `std.mem.indexOf` covers 90%+ of agent search use cases. |

## Testing

```bash
zig build test        # 39 inline unit tests
bash test/integration.sh  # 9 integration tests
```

Tests cover JSON parsing, SSE streaming, arena allocation, context truncation, tool execution, glob matching, and security injection attempts.

CI runs on every push with a binary size gate (<300KB).

## Building

```bash
zig build                              # Debug build
zig build -Doptimize=ReleaseSmall      # Smallest binary
zig build test                         # Run all tests
zig build size                         # Report binary size
```

## Security

KrillClaw executes tools with the permissions of the running user. **Do not run with elevated privileges.** Use profiles and sandbox mode to restrict tool access.

BLE and Serial transports do not currently include encryption or authentication. Use only on trusted networks.

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## Known Limitations

- **JSON parser is flat** — finds first matching key at any depth (works for LLM API responses where keys are unambiguous)
- **Token estimation is heuristic** — ~4 chars/token approximation, not billing-accurate
- **No conversation persistence** — sessions start fresh, context is in-memory only
- **BLE transport is protocol-only** — real hardware needs platform BLE SDK linking
- **Serial baud uses `stty`** — Linux/macOS only
- **Requires Zig 0.13+**

## License

[BSL 1.1](LICENSE) — Business Source License. Converts to Apache 2.0 after 4 years (Change Date: 2029-02-17).

KrillClaw is **source-available**, not open source. You can read, build, and modify the code. Commercial use above the license thresholds requires a commercial license. See [LICENSE](LICENSE) for full terms.

## Contributing

Contributions welcome under BSL 1.1. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

<p align="center">
  <sub>Built with Zig. No frameworks were harmed in the making of this runtime.</sub>
</p>
