# Phase 5 Plan (Draft)

## Context

Phase 4 closes the feature gap with MimiClaw/NanoClaw on MCP, channels, GPIO, and website KPIs.
Phase 5 focuses on differentiation: live sandbox demo, agent swarms, and features from OpenClaw's recent evolution.

---

## Step 1: Live Web Sandbox

Upgrade from Phase 4's scripted demo to a real interactive sandbox on the website.

### Architecture

```
Browser (xterm.js)  <--WebSocket-->  Hosted Bridge  <--subprocess-->  KrillClaw (sandboxed)
                                         |
                                    Simulated GPIO / sensors
```

### Implementation

- **Frontend**: xterm.js terminal component embedded on krillclaw.com
- **Backend**: WebSocket gateway (Phase 3) running on a small VPS or Cloudflare Worker
- **Sandbox**: KrillClaw binary running in sandbox mode (`-Dsandbox=true`) with simulated hardware
- **Scenarios**: Pre-configured environments visitors can choose:
  - "Smart Elevator" — simulated floor sensors, usage patterns in KV store
  - "2018 Car ECU" — simulated engine sensors, coolant, OBD-II data
  - "Greenhouse Monitor" — temperature, humidity, soil moisture sensors
- **Session limits**: 60-second sessions, rate limited per IP, no real API keys exposed
- **Fallback**: If backend is down, fall back to scripted demo (Phase 4)

### Cost consideration

- Small VPS (~$5/mo) or serverless function
- API calls are the real cost — use Ollama/local model or heavily cached responses
- Alternative: pre-recorded responses with realistic delays (hybrid approach)

**Files:** `site/assets/sandbox.js`, `site/sandbox.html`, `bridge/bridge/sandbox_server.py`
**Effort:** Medium-Large

---

## Step 2: Agent Swarms / Multi-Agent Coordination

Multiple KrillClaw instances working together on complex tasks.

### Protocol: A2A (Agent-to-Agent)

IBM's ACP merged into Google's A2A under the Linux Foundation. This is the emerging standard:
- **Agent Cards**: JSON discovery documents describing capabilities
- **Task lifecycle**: JSON-RPC over HTTP/WebSocket
- Complementary to MCP (MCP = tool access, A2A = agent-to-agent)

### Architecture

```
                    ┌─────────────────────┐
                    │   Swarm Coordinator  │  (bridge/bridge/swarm.py)
                    │   (orchestrator)     │
                    └──────┬──────┬───────┘
                           │      │
              ┌────────────┘      └────────────┐
              │                                │
    ┌─────────▼──────────┐          ┌──────────▼─────────┐
    │  KrillClaw Agent 1 │          │  KrillClaw Agent 2 │
    │  (coding profile)  │          │  (iot profile)     │
    │  "fix the bug"     │          │  "deploy to device"|
    └────────────────────┘          └────────────────────┘
```

### MVP Scope

- **Coordinator** in Python (bridge layer) manages N agent subprocesses
- **Agent Cards** for capability advertisement (JSON file per profile)
- **Task delegation**: coordinator splits work, assigns to specialized agents
- **Result aggregation**: coordinator collects results, reports to user
- **No A2A networking yet** — MVP is single-machine, multi-process

### Post-MVP

- A2A HTTP endpoints for cross-machine agent discovery
- Ripple Effect Protocol for resource-constrained coordination (MIT research)
- Fleet management: OTA + swarm coordination for device clusters

**Files:** `bridge/bridge/swarm.py`, `bridge/bridge/agent_card.py`
**Effort:** Large

---

## Step 3: Advanced Features from OpenClaw's Evolution

Features OpenClaw recently shipped that are worth adopting:

### Tool Annotations
- Tools declare `readOnly: true` or `destructive: true`
- Informs the LLM about risk level before calling
- Trivial to add to bridge tool manifests and MCP integration
- **Effort:** Small

### External Secrets Management
- `~/.krillclaw/secrets.json` with encrypted values
- Bridge decrypts at runtime, injects into tool calls / MCP server env
- No plaintext API keys in config files
- **Effort:** Medium

### Structured Command Approvals
- For exec-style tools (bash, etc.), require structured approval matching
- Versioned binding: match command, args, cwd before allowing execution
- Fail-closed on mismatch
- **Effort:** Medium

### Multilingual Stop Phrases
- Agent loop recognizes stop commands in 9+ languages
- ES/FR/ZH/HI/AR/JP/DE/PT/RU
- Minimal Zig cost (~200 bytes for string table)
- **Effort:** Small

### Thread-Bound Agent State
- Pin agent execution to conversation threads
- State isolation between threads
- Important for production multi-user deployments
- **Effort:** Medium

---

## Step 4: Fleet Management

Unique differentiator — no competitor has this for edge agents.

### Concept

- Device registry: track N KrillClaw instances across hardware
- Staged OTA rollouts: update 10% → 50% → 100%
- Health monitoring: heartbeat aggregation, failure detection
- Remote configuration: push config changes to fleet
- Dashboard: web UI showing fleet status (builds on WebSocket gateway)

### Implementation

- `bridge/bridge/fleet.py` — fleet coordinator
- SQLite database for device registry + health data
- Existing OTA mechanism (Phase 2) as the update primitive
- Web dashboard via existing webhook channel

**Effort:** Large

---

## Step 5: Marketing Launch

### Announcement Strategy (from marketing research)

**Week 1:**
- Tuesday 9:30 AM ET: Show HN post
- Wednesday: r/embedded + r/zig (different angles)
- Thursday: r/LocalLLaMA + r/programming, Twitter thread
- Friday: Newsletter submissions (TLDR, Console.dev, Changelog)

**Week 2:**
- Monday: Technical blog post (Dev.to cross-post)
- Tuesday: Product Hunt launch
- Wednesday: Lobsters

**Week 3:**
- YouTube demo video (3-5 min, real hardware)
- Awesome-list submissions (awesome-zig, awesome-embedded, awesome-selfhosted)

### Content Assets Needed
- [ ] README optimized (comparison table above fold, GIF, <5 command quickstart)
- [ ] Show HN draft + first comment
- [ ] Twitter thread with screenshots/GIFs
- [ ] Tailored Reddit posts (4 subreddits, different angles)
- [ ] Technical blog post
- [ ] 2-sentence newsletter pitch
- [ ] Demo video (even rough)
- [ ] CONTRIBUTING.md + good-first-issue labels

### Messaging by Audience
- **Embedded engineers**: "450KB. Bare-metal. 50+ targets. No cloud required."
- **AI/LLM crowd**: "Local-first AI agent. Self-hosted. 20+ providers including Ollama."
- **Zig community**: "Real-world Zig: arena allocation, comptime profiles, cross-compilation to 50+ targets."
- **General devs**: "Most AI agents are 100MB+. This one is 450KB. Runs on a $3 chip."

---

## Priority Order

| Step | Impact | Effort | Phase 5A (ship first) |
|------|--------|--------|----------------------|
| 5. Marketing Launch | Very High | Medium | Yes |
| 1. Live Sandbox | High | Medium-Large | Yes |
| 3. Tool Annotations | Medium | Small | Yes |
| 3. Multilingual Stop | Medium | Small | Yes |
| 2. Agent Swarms (MVP) | High | Large | Phase 5B |
| 3. Secrets Management | Medium | Medium | Phase 5B |
| 4. Fleet Management | High (unique) | Large | Phase 5C |
