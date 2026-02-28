# KrillClaw — Project Instructions

## What This Is
KrillClaw is the world's smallest AI agent runtime, written in Zig. Zero dependencies. Targets $3 microcontrollers up to cloud servers.

## Architecture: Lite vs Full
- **Lite** (~52KB target): BLE/Serial transport, embedded arena allocator, minimal tools. Must stay under 60KB.
- **Full** (~450-520KB): HTTP transport, all tools, streaming. Budget: under 600KB on Linux aarch64.
- Feature selection is **compile-time** via `-Dprofile=` and `-Dembedded=`. No runtime overhead for unused features.

## Binary Size Discipline
This is the #1 engineering constraint. Every LOC added to src/ must justify its binary cost.
- Run `/size-check` after any source change
- CI gate: <600KB for full release build
- Lite gate: <60KB
- Before adding code to Zig, ask: "Can this live in bridge.py instead?"
- No external Zig dependencies. Ever.

## Build Commands
```bash
zig build                                    # Debug, coding profile
zig build -Doptimize=ReleaseSmall            # Release, coding profile
zig build -Dprofile=iot -Doptimize=ReleaseSmall  # IoT profile
zig build -Dble=true -Dserial=true           # Enable transports
zig build -Dembedded=true                    # Embedded arena allocator
zig build -Dsandbox=true                     # Sandbox mode
zig build test                               # Run all tests
zig build -Dtarget=aarch64-linux -Doptimize=ReleaseSmall  # Cross-compile
```

## Key Files
- `src/api.zig` — HTTP client, supports custom base URL via `--base-url` for OpenAI-compatible providers
- `src/agent.zig` — Agent loop with FNV-1a stuck-loop detection
- `src/tools.zig` — Comptime profile-selected tool dispatcher + shared tools
- `src/tools_shared.zig` — Shared tools (get_current_time, kv_*) available to all profiles
- `src/cron.zig` — Cron/heartbeat scheduler for daemon mode
- `src/arena.zig` — Fixed arena allocator for embedded (4K-256K presets)
- `src/transport.zig` — vtable transport abstraction (HTTP/BLE/Serial)
- `bridge/bridge/bridge.py` — Python sidecar for MQTT, BLE-to-API bridging, Telegram, tool execution

## Security Audit Status
See `.reviews/FINAL-REVIEW-CONSENSUS.md` for P0 security items. These must be resolved before new features.

## Naming
Project was originally "YoctoClaw" / "TinyDancer" (local dir name on MBP). Rename to KrillClaw is complete.

## Provider Support
OpenAI provider in api.zig accepts any OpenAI-compatible base URL. 16 providers confirmed working via `--base-url`. See `Docs/PROVIDERS.md`.

## QA Gates
- `/size-check` — Binary size regression check (run before commits)
- `/cross-check` — Cross-architecture compilation validation
- `/security-audit` — Security regression checks from audit findings
