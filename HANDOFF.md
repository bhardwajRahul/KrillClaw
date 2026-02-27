# KrillClaw Development Handoff

**Date:** 2026-02-27
**Repo:** `git@github.com:krillclaw/KrillClaw.git`
**Local dir:** `TinyDancer/` (the folder name predates the product name)
**Current branch:** `main` at `3ec643c`

---

## 1. Repo Structure

```
TinyDancer/
├── src/                    # All Zig source (~3,873 LOC total)
│   ├── main.zig            # Entry point, CLI arg parsing, config loading
│   ├── api.zig             # HTTP client — builds requests, parses SSE streams
│   ├── agent.zig           # Single-turn agent loop (prompt → tool → response)
│   ├── react.zig           # ReAct multi-turn agent loop (think → act → observe)
│   ├── tools.zig           # Tool dispatch + base tool definitions
│   ├── tools_coding.zig    # Coding profile tools (read/write/list/search/bash/patch/tree)
│   ├── tools_iot.zig       # IoT profile tools (mqtt, http, kv_store)
│   ├── tools_robotics.zig  # Robotics profile tools (robot_cmd, estop, telemetry)
│   ├── config.zig          # Config struct + file/env/CLI layering
│   ├── context.zig         # Context window management + summarization
│   ├── stream.zig          # SSE stream parser
│   ├── json.zig            # Minimal JSON parser (no std.json dependency)
│   ├── types.zig           # Shared types: Provider enum, Config, Message, Tool
│   ├── transport.zig       # Transport abstraction (stdio, socket)
│   ├── arena.zig           # Fixed-size arena allocator for embedded use
│   ├── ble.zig             # BLE transport via BlueZ/CoreBluetooth (compile-gated)
│   └── serial.zig          # Serial/UART transport (compile-gated)
├── bridge/bridge/
│   ├── bridge.py           # Python sidecar for MQTT, ROS, BLE-to-API bridging
│   └── requirements.txt    # anthropic, bleak, pyserial
├── site/                   # Marketing website (deployed to Cloudflare Pages)
│   ├── index.html          # Main landing page
│   ├── v2.html             # A/B test alternative
│   ├── license.html, privacy.html, terms.html, press.html
│   ├── robots.txt
│   └── assets/             # PNG images
├── test/
│   ├── smoke-test.sh       # --version, --help, basic CLI checks
│   ├── integration.sh      # End-to-end with mock API (⚠️ still references yoctoclaw)
│   └── qemu-embedded-test.sh # Cross-compile + QEMU user-mode tests
├── Docs/                   # Strategy, marketing, launch docs
│   ├── ROADMAP.md          # Version roadmap (v0.1 → v1.0)
│   ├── FAQ.md, HARDWARE-COMMERCE-PLAN.md, LAUNCH-CHECKLIST.md
│   ├── gtm-handoff.md, gtm-instance-prompt.md
│   ├── hn-strategy.md, linkedin-posts.md, twitter-thread.md
│   └── code-audit.md, MARKETING-REVIEW.md
├── .reviews/               # Architecture reviews, audit responses, launch checklists
├── .github/workflows/
│   ├── test.yml            # CI: build, test, size gate (<300KB), cross-compile
│   └── deploy.yml          # Cloudflare Pages deploy on push to main (site/ dir)
├── build.zig               # Build system
├── build.zig.zon           # Package manifest (⚠️ still says .name = .yoctoclaw)
├── LICENSE                 # BSL 1.1 → Apache 2.0 after 3 years
├── README.md, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md
└── zig-out/bin/
    ├── krillclaw-lite       # 52KB — lite profile build artifact
    └── yoctoclaw            # 3.4MB — debug build artifact (stale name)
```

---

## 2. Build System

**Zig version:** 0.13.0 (CI), codebase has some 0.15 compatibility work on feature branches.

### Key Commands

```bash
# Debug build (native, coding profile)
zig build

# Release build
zig build -Doptimize=ReleaseSmall

# With profile selection
zig build -Dprofile=coding    # 7 tools (default)
zig build -Dprofile=iot       # MQTT, HTTP, KV tools
zig build -Dprofile=robotics  # ROS, e-stop, telemetry tools

# Feature flags
zig build -Dble=true          # Enable BLE transport
zig build -Dserial=true       # Enable serial/UART transport
zig build -Dembedded=true     # Use arena allocator, disable std allocator
zig build -Dsandbox=true      # Enable bash sandboxing

# Cross-compile
zig build -Dtarget=aarch64-linux -Dprofile=iot -Doptimize=ReleaseSmall
zig build -Dtarget=arm-linux -Dprofile=iot -Doptimize=ReleaseSmall
zig build -Dtarget=riscv64-linux -Doptimize=ReleaseSmall

# Run tests
zig build test

# Check binary size
zig build size

# Run
zig build run -- --provider claude --model claude-sonnet-4-5-20250929 "hello"
```

### Build Output
- Binary name: `krillclaw` (in build.zig)
- Output: `zig-out/bin/krillclaw`
- ReleaseSmall strips debug info + omits frame pointer
- CI size gate: <300KB for release build

---

## 3. api.zig — Custom Base URL Support

**Yes, the OpenAI provider fully supports custom base URLs.**

Config resolution order (highest priority first):
1. `--base-url <url>` CLI flag
2. `KRILLCLAW_BASE_URL` environment variable
3. `.krillclaw.json` file (`"base_url": "..."`)
4. Provider default:
   - Claude: `https://api.anthropic.com`
   - OpenAI: `https://api.openai.com`
   - Ollama: `http://localhost:11434`

Code path in api.zig:
```zig
const base = config.base_url orelse config.provider.baseUrl();
```

API paths appended:
- Claude: `/v1/messages`
- OpenAI: `/v1/chat/completions`
- Ollama: `/api/chat`

Auth headers:
- Claude: `x-api-key: {key}` + `anthropic-version: 2023-06-01`
- OpenAI: `Authorization: Bearer {key}`
- Ollama: none

Streaming: SSE for Claude/OpenAI, disabled for Ollama (forced off in config.zig:78).

---

## 4. QEMU / Emulator Tests

**Location:** `test/qemu-embedded-test.sh`

What it does:
1. Cross-compiles for aarch64-linux, arm-linux (32-bit), riscv64-linux, x86_64-linux
2. Attempts aarch64-freestanding (expected to skip — needs HAL layer)
3. If `qemu-aarch64` is installed, runs `--version` and `--help` via QEMU user-mode
4. Prints hardware testing guide for RPi, ESP32, RISC-V

**Status:** These tests have NOT been run on this machine (no QEMU installed). They're designed for CI or a Linux box. The script still references `yoctoclaw` binary name and version string.

**No actual "350+ edge devices" testing exists.** That's marketing copy on the website.

---

## 5. Known Issues, TODOs, and Debt

### Critical Issues
- **Website claims don't match code:** "17+ LLM Providers" (actual: 3), "49KB binary" (actual: ~52KB lite, ~180KB full), "350+ edge devices" (no test evidence)
- **License discrepancy:** README says "4-year conversion", LICENSE/commit say "3-year conversion"
- **README says 39 tests, website says 40** — neither is verified against current `zig build test` count

### Rename Incomplete (YoctoClaw → KrillClaw)
Files still containing `yoctoclaw`/`YoctoClaw`:
- `build.zig.zon` — `.name = .yoctoclaw`
- `test/integration.sh` — references `yoctoclaw` binary + version string
- `test/smoke-test.sh` — references `yoctoclaw`
- `test/qemu-embedded-test.sh` — references `yoctoclaw` throughout
- `bridge/bridge/bridge.py` — socket path `/tmp/yoctoclaw.sock`

Files renamed correctly:
- `build.zig` — binary name is `krillclaw`
- `src/*.zig` — all source files use KrillClaw
- `README.md`, `CHANGELOG.md`, all Docs/
- `site/index.html` and other website files
- `.github/workflows/deploy.yml` — project name `krillclaw`

### Source Code TODOs
1. `src/ble.zig:37` — Multi-packet BLE response reassembly not implemented (single-frame only)
2. `src/serial.zig:130` — Should use termios ioctl instead of current approach
3. `bridge/bridge/bridge.py:157` — `handle_robot_cmd` needs real ROS/hardware bindings
4. `bridge/bridge/bridge.py:183` — `handle_estop` needs real motor controller stop

### Other Debt
- `zig-out/bin/yoctoclaw` — stale 3.4MB debug binary (should delete, it's gitignored)
- Bridge path is `bridge/bridge/bridge.py` (double-nested) but README says `cd bridge && python bridge.py`
- Ollama streaming disabled — SSE format compatibility not fully implemented
- 7 git stashes on various feature branches (see §6)

---

## 6. Feature Branches and Stashes

### Active Feature Branches (all local, none pushed to remote)

| Branch | Last Commit | Status |
|--------|------------|--------|
| `feature/react-agent-loop` | ReAct agent loop + Zig 0.15 migration | **Merged to main** via emulator-tests |
| `feature/emulator-tests` | QEMU test script + Zig 0.15 compat | **Merged to main** |
| `feature/lite-full-profiles` | Lite/Full profile split | **Merged to main** |
| `feature/multi-provider-llm` | OpenAI streaming, multi-tool | **Merged to main** |
| `feature/ci-testing` | CI workflow + TESTING.md | Needs manual push |
| `feature/config-management` | Runtime config manager | WIP, has memory leaks fixed |
| `feature/error-recovery` | Retry module with exp backoff + jitter | WIP |
| `feature/persistent-memory` | Filesystem abstraction for agent memory | WIP, bounds-check fixes |
| `feature/readme-rebrand` | README rewrite for KrillClaw | Superseded by main |

### Stashes (oldest to newest)
| # | Base Branch | Contents |
|---|------------|----------|
| 6 | error-recovery | api.zig auth_buf security fix + build.zig.zon |
| 5 | config-management | main.zig refactor (56 lines) |
| 4 | config-management | api.zig fix + config_manager deletion |
| 3 | persistent-memory | Deletes most Docs/ + memory store fixes |
| 2 | config-management | build.zig tweaks + config_manager deletion |
| 1 | config-management | config_manager deletion + runtime config |
| 0 | error-recovery | retry.zig improvements + build.zig.zon |

**Recommendation:** Stashes 1-4 likely contain overlapping work. Review before applying. Stash 6 has a security fix for `auth_buf` stack lifetime in OpenAI header construction — may be important.

---

## 7. Architectural Decisions

1. **Zig over C/Rust** — Zero-dependency cross-compilation, built-in allocator control, comptime feature gating. Binary stays small without libc.

2. **Profile system (coding/iot/robotics)** — Compile-time tool selection via `-Dprofile=`. Each profile only links the tools it needs. Keeps binary small for constrained devices.

3. **Arena allocator for embedded** — `-Dembedded=true` swaps std.heap for a fixed-size arena (`arena.zig`). No malloc at runtime. Overflow checked with `len > size or aligned_offset > size - len`.

4. **Custom JSON parser** — `json.zig` avoids `std.json` to keep binary small and control allocations. Parses SSE streams incrementally.

5. **Transport abstraction** — `transport.zig` abstracts stdio vs socket vs BLE vs serial. Agent code doesn't know how it's connected.

6. **Python bridge as sidecar** — Heavy integrations (MQTT, BLE scanning, ROS) live in Python (`bridge.py`) rather than Zig. Communicates via Unix socket or stdin/stdout. Keeps Zig binary pure and small.

7. **BSL 1.1 license** — Prevents competitors from hosting KrillClaw-as-a-service while allowing hobbyist/startup use. Converts to Apache 2.0 after 3 years. Use grant: <$1M revenue or <10K devices.

8. **ReAct loop** — `react.zig` implements think → act → observe cycle with stuck-loop detection and configurable `max_turns`.

9. **SSE streaming** — Claude and OpenAI use server-sent events. `stream.zig` parses incrementally. Ollama streaming disabled (format differences not fully resolved).

---

## 8. Website Claims — Sources and Accuracy

| Claim | Source | Accurate? |
|-------|--------|-----------|
| "49KB binary" | Lite profile ReleaseSmall build | **Approximately** — lite is 52KB on disk |
| "Full: ≤500KB" | CI gate is 300KB; full release ~180KB | **Conservative estimate, actual is smaller** |
| "350+ edge devices" | Marketing copy, no test matrix exists | **Unsubstantiated** |
| "17+ LLM Providers" | Unknown origin | **False** — code supports 3 (Claude, OpenAI, Ollama). OpenAI-compatible endpoints (Groq, Together, etc.) work via `--base-url` but aren't distinct providers |
| "3 providers" (README) | Code inspection | **Accurate** |
| "39 unit tests" (README) | `zig build test` count at time of writing | **Approximately accurate** |
| "~3,500 LOC" (README) | `wc -l src/*.zig` = 3,873 | **Close enough** |
| "7 tools" (coding profile) | tools_coding.zig | **Accurate** — read, write, list, search, bash, patch, tree |

The "17+ providers" claim likely counts every OpenAI-compatible API (Groq, Together, Fireworks, Mistral, etc.) that works via `--base-url`. This is technically true but misleading — it's one code path.

---

## 9. bridge.py — Current State

**Location:** `bridge/bridge/bridge.py` (note double nesting)

### Two Operating Modes

**Mode 1: Tool Executor** (no API key needed)
```bash
python bridge.py --exec-tool '{"action":"mqtt_publish","topic":"test","payload":"hello"}'
```
Dispatches to handlers: `mqtt_publish`, `mqtt_subscribe`, `http_request`, `robot_cmd`, `estop`, `telemetry`. The `robot_cmd` and `estop` handlers are stubs with TODO comments.

**Mode 2: BLE/Serial/Socket Bridge** (needs `ANTHROPIC_API_KEY`)
```bash
python bridge.py --transport ble    # BLE central
python bridge.py --transport serial --port /dev/ttyUSB0
python bridge.py --transport socket  # Unix socket at /tmp/yoctoclaw.sock
```
Uses `anthropic` Python SDK, default model `claude-sonnet-4-5-20250929`. Reads from transport, sends to Claude API, writes response back.

### BLE UUIDs
- Service: `0000pc01-0000-1000-8000-00805f9b34fb`
- TX: `0000pc02-...`
- RX: `0000pc03-...`

### Issues
- Socket path hardcoded to `/tmp/yoctoclaw.sock` (needs rename)
- `robot_cmd` and `estop` are stubs
- No error handling for BLE disconnects
- Uses old Anthropic model name

---

## 10. Things That Will Save You Time

1. **The folder is called `TinyDancer`** — that's just the local directory name. The project is KrillClaw. Don't be confused.

2. **Don't trust the website copy.** Cross-reference everything against actual code. The site was written aspirationally.

3. **`zig build test` is your truth.** Run it first thing. If tests pass, you're on solid ground.

4. **The security audit found real issues.** `AUDIT-REPORT.md` and `.reviews/CODEX-AUDIT-REPORT.md` list 23 issues (4 critical). The critical fixes (JSON injection via `writeEscaped`, path traversal via `realpathAlloc`, arena overflow bounds check) are claimed fixed in `FINAL-REVIEW-CONSENSUS.md`. Verify.

5. **Stash 6 has a security fix** for `auth_buf` stack lifetime in the OpenAI header construction. Check if this was merged to main or is still only in the stash.

6. **Feature branches are all local.** None are pushed to origin. The `ci-testing` branch has a note "needs manual push" — the CI workflow may not be active on GitHub yet.

7. **Config file is `.krillclaw.json`** in the working directory. Env vars: `KRILLCLAW_API_KEY`, `KRILLCLAW_BASE_URL`, `KRILLCLAW_PROVIDER`.

8. **To test with Ollama** (free, no API key): `ollama serve` then `zig build run -- --provider ollama --model llama3.2 "hello"`. Streaming is disabled for Ollama.

9. **The `yoctoclaw-store/` directory** is an e-commerce experiment (Snipcart/Stripe integration mockup). Not part of the main product. Appears gitignored.

10. **No project-level CLAUDE.md exists.** If you want to set one up for the new session, create `TinyDancer/CLAUDE.md` with project-specific instructions.

11. **Memory directory is empty.** No Claude Code memory files exist at the project level. This session's context is being captured in this handoff doc instead.

12. **The CI workflow (`test.yml`) uses Zig 0.13.0.** Some feature branches have 0.15 compatibility work. If you upgrade Zig, check for breaking changes in `std.http` and allocator APIs.

13. **Binary in `zig-out/bin/yoctoclaw` is 3.4MB** — that's a debug build. Don't be alarmed. Release builds are 52KB (lite) to ~180KB (full).

---

## Quick Start for New Session

```bash
cd TinyDancer
git status                    # Should be clean on main
zig build test                # Run all tests
zig build -Doptimize=ReleaseSmall  # Release build
ls -la zig-out/bin/krillclaw  # Check binary size
./zig-out/bin/krillclaw --version
./zig-out/bin/krillclaw --help
```

### Priority TODO for Next Session
1. Finish YoctoClaw → KrillClaw rename (build.zig.zon, test scripts, bridge.py socket path)
2. Reconcile website claims with reality (especially "17+ providers" and "350+ devices")
3. Verify security audit fixes are on main (especially stash 6 auth_buf fix)
4. Push `feature/ci-testing` branch to enable GitHub Actions
5. Clean up stashes (review, apply what's needed, drop the rest)
6. Fix README license claim (says 4 years, should say 3)
