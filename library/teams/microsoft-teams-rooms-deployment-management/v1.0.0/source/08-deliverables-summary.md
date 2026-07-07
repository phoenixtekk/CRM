# 8. Deliverables Summary — Microsoft Teams Rooms Deployment & Management

Everything included in this solution, at a glance.

## Documentation

| Document | What it gives you |
| --- | --- |
| **1. Solution Overview** | What Teams Rooms is, the reference design (resource account + licensing + calendar processing + room policies + Pro Management + peripherals), the licensing model (Pro vs Basic), the naming convention, benefits, limitations, and the deployment model. |
| **2. Requirements** | The Teams Rooms–specific prerequisites (licensing, room-mailbox capability, directory rights, certified hardware, network readiness, Pro Management access, pilot scope), each with Description / Why / Verify / Implement — building on the shared category requirements. |
| **3. Implementation** | The ordered Assess → Design → Configure → Pilot → Validate → Expand procedure: create + license the resource account, tune calendar processing, grant room policies, onboard to Pro Management — pilot-first, every object named, with pass/fail gates and a rollback. |
| **5. Testing & Validation** | Seven tests (T1–T7) mapped to the validation gates, each with the exact command, expected pass, and fail signal. |
| **6. Troubleshooting** | The common Teams Rooms failure modes (won't join, no Join button on console, poor media, license won't assign, room signs out, double-booked, unhealthy in Pro Management) with root cause and resolution. |
| **7. Best Practices** | Durable practices for a fleet: accounts, calendar processing, policy/licensing, central management, hardware, change discipline, and documentation. |
| **Executive Summary** | The outcome, the approach, and why it is low-risk — for decision-makers. |

## PowerShell tools (5)

All tools use modern-auth `Connect-*` cmdlets, store **no credentials**, and are **read-only or dry-run (`-WhatIf`/no `-Commit`) by default**.

| Script | Purpose | Safe default |
| --- | --- | --- |
| **TEAMSROOMS-Discovery.ps1** | Read-only assessment: enumerates room mailboxes and reports each room's mailbox type, account state, Teams Rooms license, calendar-processing values, and granted meeting/calling policies — the baseline for the Assess phase. | Read-only |
| **TEAMSROOMS-Set-ResourceAccount.ps1** | Creates and configures a room resource account: room mailbox, enable + usage location, non-expiring password, and Teams Rooms license (SKU resolved at runtime). | Dry-run unless `-Commit` |
| **TEAMSROOMS-Set-RoomPolicy.ps1** | Applies the Teams Rooms calendar-processing standard and grants the room's Teams meeting and calling policies. | Dry-run unless `-Commit` |
| **TEAMSROOMS-HealthReport.ps1** | Fleet health/inventory report: evaluates every room against the standard, flags non-conformant rooms and their specific gaps, and writes CSV (and optional HTML). | Read-only |
| **TEAMSROOMS-Validation.ps1** | Validates one room, a room list, or an Entra group of rooms against gates V1–V4 (provisioned, licensed, calendar, policy); returns a non-zero exit code if any gate fails so it can gate an expansion pipeline. Doubles as the scope/readiness helper. | Read-only |

## How they fit the workflow

1. **Assess** — `TEAMSROOMS-Discovery.ps1` captures the baseline.
2. **Configure (pilot)** — `TEAMSROOMS-Set-ResourceAccount.ps1 -Commit` then `TEAMSROOMS-Set-RoomPolicy.ps1 -Commit`.
3. **Validate** — `TEAMSROOMS-Validation.ps1` for gates V1–V4; manual in-room and Pro Management checks for V5–V6.
4. **Operate & Expand** — `TEAMSROOMS-HealthReport.ps1` on a schedule; re-run the configure + validate pair per new room.
