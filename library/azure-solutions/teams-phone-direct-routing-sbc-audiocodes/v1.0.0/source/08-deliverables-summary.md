# 8. Deliverables Summary — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

This solution is delivered as a complete, productized package: a set of customer-facing implementation documents, a suite of Microsoft Teams PowerShell scripts, and a hero image. Everything is white-labeled and uses the consistent `<Purpose> – <Scope> – <Stage>` object naming so the configuration is auditable end to end.

## Documents

| File | Purpose |
| --- | --- |
| `executive-summary.md` | One-page outcome, scope, and value summary for decision-makers. |
| `01-solution-overview.md` | What the solution delivers, why Direct Routing + SBC, scope, phase model, and naming convention. |
| `02-requirements.md` | Requirements R1–R13 (Description / Why / Verify / Implement if missing). |
| `global-requirements-azure-solutions.md` | Category-wide Azure Solutions baseline (tenant, roles, licensing, network, change control, test users, rollback). |
| `03-implementation.md` | Step-by-step build across all seven phases with full navigation paths and exact cmdlets; AudioCodes SBC checklist deferred to vendor docs. |
| `05-testing.md` | Eight pass/fail validation gates (OPTIONS/Active, outbound, inbound, caller ID, emergency, and more). |
| `06-troubleshooting.md` | Symptom-driven diagnosis for the common failure modes. |
| `07-best-practices.md` | Operational, security, and design best practices by phase. |
| `08-deliverables-summary.md` | This inventory. |

## Scripts (Microsoft Teams PowerShell — MicrosoftTeams module)

All scripts carry a standard header block and a neutral `.NOTES` ("Azure Solutions — read-only." where applicable). Discovery, validation, and reporting are read-only; remediation and configuration default to a safe dry-run (`-WhatIf`) and require an explicit `-Apply` to make changes.

| Script | Purpose |
| --- | --- |
| `TEAMSSBC-Discovery.ps1` | Read current PSTN gateways, voice routes, PSTN usages, voice routing policies, and voice-enabled users (read-only baseline). |
| `TEAMSSBC-Validation.ps1` | Verify the named gateway exists and is healthy (SIP OPTIONS/Active), the routing chain is consistent, and pilot users are assigned — PASS/FAIL. |
| `TEAMSSBC-Report.ps1` | Export the voice configuration and per-user assignment report to CSV. |
| `TEAMSSBC-Remediation.ps1` | Safe fixes — (re)grant the voice routing policy or assign a number to a named user; `-WhatIf` by default, `-Apply` to execute. |
| `TEAMSSBC-Set-VoiceRouting.ps1` | Create the PSTN gateway, usages, voice route, and voice routing policy from parameters; `-WhatIf` to preview. |

## Hero image

| Asset | Purpose |
| --- | --- |
| `TEAMSSBC-hero.png` | Product hero image for the marketplace listing. |

## How the deliverables fit together

1. Run **`TEAMSSBC-Discovery.ps1`** in **Assess** to capture the baseline.
2. Use **`TEAMSSBC-Set-VoiceRouting.ps1`** (preview with `-WhatIf`, then `-Apply`) to build the routing stack in **Configure Voice Routing**, following `03-implementation.md`.
3. Assign users per `03-implementation.md`; use **`TEAMSSBC-Remediation.ps1`** to fix any missing grants/numbers.
4. Run **`TEAMSSBC-Validation.ps1`** in **Validate** against the gates in `05-testing.md`.
5. Produce the as-built with **`TEAMSSBC-Report.ps1`** and attach it to the change record.
6. Repeat discovery → validation → report after each change in **Expand**.
