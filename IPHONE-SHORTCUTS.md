# iPhone Shortcuts for Bee

**API key:** vk_32ca4c9e2620e8e11c808cd077f7dd733177c5a46df16f24
**Base URL:** https://api.workitu.com

## ntfy Setup (do first)
1. App Store → install **ntfy** (free)
2. Open → + → Subscribe → topic: `bee-yonatan-2026` → ntfy.sh
3. Done — you'll get push for health alerts, reminders, security

## Shortcut 1: Bee Status
URL: GET https://api.workitu.com/api/bee/cluster/status
Header: x-api-key → [key above]
Show Result. Siri: "Bee status"

## Shortcut 2: Log Expense
Ask Input: amount → Ask Input: category (food/health/tools/transport)
URL: POST https://api.workitu.com/api/bee/budget/track
Body: {"amount":"[1]","category":"[2]","note":"iPhone"}
Headers: x-api-key + Content-Type: application/json

## Shortcut 3: Quick Note (voice)
Dictate Text → 
URL: POST https://api.workitu.com/api/bee/action
Body: {"action":"note","content":"[dictated]","source":"iphone"}

## Shortcut 4: Today's WHOOP
URL: GET https://api.workitu.com/whoop/status → Show Result

## Shortcut 5: Log Pain
Ask Input: level (1-10) → Ask Input: location
URL: POST https://api.workitu.com/api/bee/health/pain
Body: {"level":"[1]","location":"[2]"}

## Automations
- Morning alarm dismissed → WHOOP sync
- Arrive home → Bee Status check
