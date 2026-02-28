# Competitive Comparison

## Technical Comparison Table (for Twitter/social)

```
┌──────────────────┬────────────┬────────────┬────────────┬────────────┐
│                  │ KrillClaw  │ MimiClaw   │ NanoClaw   │ OpenClaw   │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Binary size      │ 450 KB     │ ~3 MB      │ ~50 MB+    │ ~100 MB+   │
│ RAM usage        │ ~2 MB      │ ~512 KB*   │ ~100 MB+   │ ~200 MB+   │
│ Language         │ Zig        │ C          │ TypeScript │ TypeScript │
│ Dependencies     │ 0          │ ESP-IDF    │ <10        │ 70+        │
│ Boot time        │ <10ms      │ ~2s        │ ~3s        │ ~3s        │
│ LLM providers    │ 20+        │ 2          │ 1          │ 3+         │
│ Device targets   │ 50+        │ 1          │ 0          │ 0          │
│ Channels         │ 7          │ 2          │ 5          │ N/A        │
│ MCP support      │ ✅         │ ❌         │ ✅         │ ✅         │
│ Bare-metal       │ ✅         │ ✅         │ ❌         │ ❌         │
│ BLE/Serial       │ ✅         │ ❌         │ ❌         │ ❌         │
│ Sandbox mode     │ ✅         │ ❌         │ ✅ (Docker)│ ✅         │
│ GPIO/hardware    │ ✅         │ ✅         │ ❌         │ ❌         │
│ Inline tests     │ 60         │ 0          │ ?          │ ✅         │
│ Offline capable  │ ✅         │ Partial    │ ❌         │ ❌         │
│ Runs on $3 chip  │ ✅         │ $5         │ ❌         │ ❌         │
│ License          │ BSL 1.1    │ MIT        │ MIT        │ Apache 2.0 │
└──────────────────┴────────────┴────────────┴────────────┴────────────┘

* MimiClaw runs on ESP32-S3 with 8MB PSRAM required
```

## Plain-text version (copy-paste for Twitter)

```
AI Agent Runtimes — The Numbers

                KrillClaw  MimiClaw  NanoClaw  OpenClaw
Binary          450 KB     ~3 MB     ~50 MB+   ~100 MB+
Dependencies    0          ESP-IDF   <10       70+
LLM Providers   20+        2         1         3+
Device Targets  50+        1         0         0
Channels        7          2         5         N/A
MCP             ✅         ❌        ✅        ✅
Bare-metal      ✅         ✅        ❌        ❌
Tests           60         0         ?         ✅
Boot            <10ms      ~2s       ~3s       ~3s

KrillClaw: krillclaw.com
```

## Product/Business Talking Points (less technical)

### Why KrillClaw wins — the pitch

**1. Runs where others can't.**
Other AI agents need a laptop or a server. KrillClaw runs on a $3 microcontroller. Same intelligence, 1/200th the hardware cost. That's not incremental — it opens entirely new markets: automotive, agriculture, industrial, wearables.

**2. No vendor lock-in.**
20+ LLM providers. Switch from Claude to GPT to Ollama to a local model with a flag. MimiClaw locks you to 2 providers. NanoClaw locks you to 1. When your provider raises prices or goes down, KrillClaw users switch in seconds.

**3. Zero dependency risk.**
Zero external dependencies. No npm. No pip. No Docker. No supply chain attacks. No "left-pad" moments. The entire runtime is auditable in an hour. In a world where software supply chain attacks are the #1 security threat, this matters.

**4. Hardware-agnostic.**
50+ validated device targets. MimiClaw only runs on one board (ESP32-S3). KrillClaw runs on ARM, RISC-V, x86, MIPS, PowerPC, s390x — from a smart ring to a server rack. Build once, deploy anywhere.

**5. Production-ready, not a toy.**
60 inline tests. CI on every commit. Binary size gate. Cross-architecture validation. Sandbox mode. Stuck-loop detection. Most competitors ship with zero tests. KrillClaw ships with more tests than some companies have for their entire product.

**6. Bridge architecture = best of both worlds.**
The agent brain runs in 450KB of Zig. Heavy infrastructure (Telegram, MCP, MQTT, web search) lives in a Python bridge. You get embedded performance AND ecosystem access. No other runtime does this.

**7. MCP compatible = future-proof.**
Connect to 1000+ MCP tool servers. The same protocol used by Claude Desktop, Cursor, and Windsurf. Your agent isn't an island — it plugs into the entire AI tool ecosystem.

### One-liners for different contexts

- **Responding to MimiClaw posts**: "Love the ESP32 work. We took a different approach — 450KB Zig binary that runs on 50+ architectures, not just ESP32. Same AI, 50x more hardware. krillclaw.com"

- **Responding to NanoClaw posts**: "NanoClaw is great for server-side agents. We built for the edge — same MCP support, same channels, but in 450KB with zero dependencies. Runs on hardware NanoClaw can't touch. krillclaw.com"

- **Responding to "AI agents are bloated" takes**: "Agreed. We proved the entire agent loop — LLM client, tool executor, JSON parser, streaming, cron — fits in 450KB of Zig. Zero dependencies. Runs on a $3 chip. krillclaw.com"

- **Responding to embedded/IoT threads**: "We built an AI agent runtime that actually fits on a microcontroller. 450KB. BLE + Serial transports. GPIO control. 50+ device targets. Not a cloud proxy — the agent brain runs on the device. krillclaw.com"

- **Responding to Zig threads**: "Real-world Zig project: 4,800 LOC, comptime profiles for zero-overhead feature selection, arena allocation, cross-compiles to 50+ targets from one codebase. Binary: 450KB. krillclaw.com"
