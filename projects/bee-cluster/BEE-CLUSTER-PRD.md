# Bee Cluster PRD — April 2026

## Architecture

```
WhatsApp/Claude Chat (Yonatan)
         │
         ▼
   ┌─────────────────────────────────────────┐
   │         VPS (Primary Brain)             │
   │  Hetzner CX22 · 2CPU · 3.7GB · 38GB   │
   │  bee-backend · n8n · vault · PostgreSQL  │
   │  65.109.230.136 / Tailscale 100.127.x  │
   └──────────┬──────────────┬───────────────┘
              │ Rev SSH :2222 │ Tailscale
    ┌─────────▼──┐    ┌──────▼────────┐
    │   bee-1    │    │   sparta-1    │
    │  Desktop   │    │   Notebook    │
    │  Windows   │    │   Windows     │
    │ R9 5900X   │    │  100.116.x    │
    │  64GB RAM  │    │              │
    └────────────┘    └───────────────┘
              │              │
              └──────┬───────┘
                     │
         ┌───────────▼────────────┐
         │      Storage           │
         │  B2: hot (0-30 days)  │
         │  GDrive 2TB: cold      │
         └────────────────────────┘
```

## Machines
| Machine | Role | CPU | RAM | OS | Tailscale |
|---------|------|-----|-----|----|-----------|
| VPS | Primary brain, always-on | 2 | 3.7GB | Linux | 100.127.175.67 |
| bee-1 | Desktop powerhouse, heavy tasks | AMD Ryzen 9 5900X (12-core) | 64GB | Windows | Reverse SSH tunnel :2222 |
| sparta-1 | Mobile compute | AMD Ryzen 7 5825U | 13.8GB | Windows 11 | 100.116.216.124 |
| iPhone | WhatsApp control, monitoring | - | - | iOS | 100.80.234.102 |

## Clustering Rules
- DEFAULT: VPS only (always on, zero latency)
- USE CLUSTER WHEN: task > 80% VPS RAM, or needs GPU, or parallel jobs > 4
- NEVER cluster: simple CRUD, API calls, vault reads, webhooks
- TRIGGER: auto-detect or explicit "run on bee-1/sparta-1" WhatsApp command

## Storage Strategy
- B2 hot: PostgreSQL dumps + vault (daily 3am) — last 30 days
- GDrive cold: monthly archive snapshots — unlimited retention
- NO duplication of same data in both unless required for security
- rclone: VPS → GDrive sync on 1st of month (to implement)

## WhatsApp Commands
- `cluster status` — all machine status
- `cluster costs` — monthly cost report
- `run on vps [cmd]` — execute on VPS
- `whoop` — today's health data
- `sync whoop` — force WHOOP sync
- `bee status` — full system status

## Cost Policy
- Every new subscription/cost → Bee logs it automatically
- Monthly report on 1st via WhatsApp + Telegram
- All costs in Vault: Finance/costs/YYYY-MM.md

## Implementation Phases
- Phase 1 (now): PRD + cost tracker + WhatsApp commands + SSH setup scripts
- Phase 2 (bee-1 online): Full SSH mesh + Claude CLI on bee-1
- Phase 3 (sparta-1 SSH fixed): Complete 3-node cluster
- Phase 4: rclone GDrive cold archive automation
