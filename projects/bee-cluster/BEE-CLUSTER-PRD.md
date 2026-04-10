# Bee Cluster Infrastructure PRD

**Version:** 1.0
**Date:** 2026-04-10
**Owner:** Yonatan Perlin
**Status:** Active Implementation

---

## 1. Architecture Overview

```
                          ┌─────────────────────────────────┐
                          │        INTERNET / CLOUD          │
                          │                                  │
                          │  Backblaze B2    Google Drive 2TB │
                          │  (hot backup)    (cold archive)   │
                          │  bee-backups     manual/rclone    │
                          │  bee-media                        │
                          └──────────┬──────────┬────────────┘
                                     │          │
                          ┌──────────┴──────────┴────────────┐
                          │     Hetzner VPS (CONTROL PLANE)   │
                          │     workitulife-prod              │
                          │     Public: 65.109.230.136        │
                          │     Tailscale: 100.127.175.67     │
                          │                                   │
                          │  ┌─────────────────────────────┐  │
                          │  │ Bee Backend (PM2, port 3001) │  │
                          │  │ Vault API (port 3003)        │  │
                          │  │ MCP Server (port 3004)       │  │
                          │  │ n8n (port 5678)              │  │
                          │  │ WhatsApp Bridge (port 3010)  │  │
                          │  │ nginx (80/443)               │  │
                          │  └─────────────────────────────┘  │
                          └──────────┬───────────────────────┘
                                     │
                          ┌──────────┴──────────┐
                          │   Tailscale Mesh     │
                          │   (WireGuard VPN)    │
                          └──┬─────┬─────┬──────┘
                             │     │     │
              ┌──────────────┘     │     └──────────────┐
              │                    │                     │
    ┌─────────┴──────────┐  ┌─────┴───────────┐  ┌─────┴──────────┐
    │  bee-1 (Desktop)    │  │ sparta-1 (Laptop)│  │ iPhone 15 Pro  │
    │  Windows            │  │ Windows          │  │ iOS            │
    │  TS: 100.94.167.24  │  │ TS:100.116.216.124│ │ TS:100.80.234.102│
    │  Status: OFFLINE    │  │ Status: IDLE     │  │ Status: ONLINE │
    │  Heavy compute      │  │ Light compute    │  │ WhatsApp ctrl  │
    │  Claude CLI ready   │  │ Claude CLI ready │  │                │
    └─────────────────────┘  └─────────────────┘  └────────────────┘
```

## 2. Machine Specs

| Machine | OS | CPU | RAM | Disk | Tailscale IP | Role | Status |
|---|---|---|---|---|---|---|---|
| VPS (workitulife-prod) | Ubuntu Linux | 2 vCPU | 3.7 GB | 38 GB (74% used) | 100.127.175.67 | Control plane, always-on | ONLINE |
| bee-1 | Windows | Desktop-class | High | Large | 100.94.167.24 | Heavy compute, builds | OFFLINE (4d) |
| sparta-1 | Windows | Notebook | Medium | Medium | 100.116.216.124 | Light compute, testing | IDLE |
| iPhone 15 Pro | iOS | A17 Pro | 8 GB | — | 100.80.234.102 | WhatsApp control | ONLINE |

## 3. Network Topology

**Tailscale Mesh (100.x.x.x)**
- All machines connected via WireGuard tunnels
- VPS = always-on hub (routes, DNS, control)
- bee-1 and sparta-1 = SSH-accessible worker nodes (once pubkey deployed)
- iPhone = control interface only (WhatsApp)

**Ports (VPS public)**
- 80/443: nginx → Bee Brain (Next.js), Vault API
- 3001: Bee Backend (internal only)
- 3003: Vault API (internal only)
- 3004: MCP Server (internal only)
- 3010: WhatsApp Bridge (internal only)
- 5678: n8n (internal only)

## 4. Storage Strategy

**Principle: No redundancy unless security requires it.**

| Tier | Provider | Purpose | Retention | Cost |
|---|---|---|---|---|
| Hot | Backblaze B2 | Active backups, media | Last 30 days | ~$0.006/GB/mo |
| Cold | Google Drive 2TB | Archive, old projects | Permanent | Included in Google One |
| Local | VPS /var/www/bee-brain/vault/ | Active vault, configs | Always current | $0 |

**Data Flow:**
1. VPS vault = source of truth for active data
2. B2 syncs daily (hot backup, 30-day rolling)
3. Monthly: rclone moves B2 files >30 days → Google Drive
4. Never duplicate same data in B2 AND GDrive (pick one tier)

**rclone:** Installed at `/usr/bin/rclone`. Configure remotes for B2 + GDrive.

## 5. Clustering Strategy

**Rule: Cluster ONLY when there is real gain.**

### When to cluster:
| Task | Cluster? | Machines | Why |
|---|---|---|---|
| Heavy code builds | YES | bee-1 | Desktop has more RAM/CPU |
| ML/AI batch jobs | YES | bee-1 | GPU if available |
| Parallel test suites | YES | bee-1 + sparta-1 | Split test matrix |
| Web scraping batch | YES | sparta-1 | Offload from VPS |
| Always-on services | NO | VPS only | Reliability requires always-on |
| Quick scripts | NO | VPS only | Latency to Windows > local exec |
| Vault/DB operations | NO | VPS only | Data locality |
| WhatsApp processing | NO | VPS only | Bridge is on VPS |

### Thresholds for clustering:
- Task duration >5 minutes on VPS → consider bee-1
- VPS CPU >80% sustained → offload to bee-1/sparta-1
- Task is embarrassingly parallel → split across machines
- Task needs Windows-specific tools → route to bee-1/sparta-1

### Execution model:
```
WhatsApp/Chat → VPS (Bee Backend) → Decision Engine
                                      ├── Execute locally (default)
                                      ├── SSH to bee-1 (heavy compute)
                                      └── SSH to sparta-1 (light compute)
```

## 6. WhatsApp Control Commands

| Command | Action | Response |
|---|---|---|
| `cluster status` | Ping all machines via Tailscale | Machine status table |
| `cluster costs` | Return monthly cost breakdown | Cost summary |
| `run on vps <cmd>` | Execute bash command on VPS | Command output (truncated) |
| `health` / `whoop` | Return today's WHOOP data | Recovery, HRV, sleep |
| `sync whoop` | Trigger WHOOP data sync | Sync result |
| `/status` | VPS + tasks + budget (existing) | Compact status |
| `/money` | Revenue summary (existing) | Finance data |
| `/btl` | BTL deadlines (existing) | Task list |
| `/week` | Weekly review (existing) | Session summary |

## 7. Cost Tracking Spec

### Known Monthly Costs

| Service | Cost | Type | Notes |
|---|---|---|---|
| Hetzner VPS CX22 | €4.51/mo (~$4.90) | Fixed | 2 CPU, 3.7GB RAM |
| Backblaze B2 | ~$0.006/GB/mo | Variable | bee-backups + bee-media |
| Anthropic Claude API | Variable | Variable | Track from logs |
| Tailscale | $0 | Free | Free tier (3 users/100 devices) |
| Cloudflare | $0 | Free | Free tier |
| Domain workitu.com | $1/mo | Fixed | ~$12/year |
| LemonSqueezy | % of revenue | Variable | Payment processing |
| Brevo | $0 | Free | Free tier email |
| FAL.AI | Variable | Variable | Per image generation |
| WHOOP | ~$30/mo | Fixed | If active subscription |

### Cost API Endpoints
- `GET /api/bee/costs` → Current month costs + totals
- `POST /api/bee/costs/add` → Add/update a cost entry
- `GET /api/bee/costs/report` → Formatted monthly report

### Automated Reporting
- 1st of each month: WhatsApp message with cost summary
- Alert if any variable cost exceeds 2x previous month

## 8. Implementation Phases

### Phase 1: Foundation (NOW - 2026-04-10) ✅
- [x] Create PRD document
- [x] Create Windows SSH setup scripts
- [x] Implement cost tracking API
- [x] Add WhatsApp cluster commands
- [x] Commit and push to GitHub

### Phase 2: Machine Onboarding (Next time bee-1/sparta-1 are online)
- [ ] Run setup-windows-ssh.ps1 on bee-1
- [ ] Run setup-windows-ssh.ps1 on sparta-1
- [ ] Verify SSH from VPS → bee-1 and sparta-1
- [ ] Install Claude CLI on both machines
- [ ] Test `run on bee-1` and `run on sparta-1` WhatsApp commands

### Phase 3: Storage Automation (Week of 2026-04-14)
- [ ] Configure rclone remotes (B2 + Google Drive)
- [ ] Set up daily B2 sync cron job
- [ ] Set up monthly B2 → GDrive archive job
- [ ] Implement storage usage tracking in cost API

### Phase 4: Smart Clustering (Week of 2026-04-21)
- [ ] Implement task routing decision engine
- [ ] Add `run on bee-1 <cmd>` WhatsApp command
- [ ] Add `run on sparta-1 <cmd>` WhatsApp command
- [ ] Implement parallel task splitting
- [ ] Load monitoring and auto-routing

### Phase 5: Full Automation (May 2026)
- [ ] Auto-wake bee-1 via Wake-on-LAN (if supported)
- [ ] Predictive clustering based on task patterns
- [ ] Cost optimization recommendations
- [ ] Full monthly automated reporting

---

## Appendix: SSH Key Distribution

**VPS Public Key:**
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod
```

**Manual instructions:** See `/opt/claude-workspace/scripts/setup-windows-ssh.md`
**Automated script:** See `/opt/claude-workspace/scripts/setup-windows-ssh.ps1`
