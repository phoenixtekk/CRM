# 8. Deliverables Summary — Teams Phone (Calling Plans & Operator Connect)

Everything included in this solution, on one page.

## Documentation
- **01 — Solution Overview:** what Teams Phone enablement via Calling Plans and Operator Connect is, the
  three PSTN options (and why Direct Routing is separate), how it works end to end, the reference
  design, benefits, limitations, the naming convention, and the deployment model.
- **02 — Requirements:** solution-specific prerequisites (Teams Phone licensing, chosen PSTN path,
  numbers, emergency addresses/LIS, emergency-routing responsibility, admin roles, network readiness,
  resource-account service numbers) — each with Description / Why / Verify / Implement — building on the
  shared Teams Global Requirements.
- **03 — Implementation Guide:** exact ordered steps — assess/inventory, pilot scope, acquire numbers,
  register emergency addresses/locations, build policies + dial plan, dry-run, enable the pilot, build
  auto attendants/call queues, validate (incl. emergency test), and expand — every artifact named, with
  pass/fail gates and a rollback.
- **05 — Testing & Validation:** eight procedures (voice enablement, policies, emergency location,
  inventory, outbound/inbound calls, the mandatory live emergency test, and auto attendant/call queue)
  each with an expected pass/fail signal and pilot exit criteria.
- **06 — Troubleshooting:** common failure modes (number won't assign, user not voice-enabled, no
  emergency location, dial-plan normalization, call quality, auto attendant/queue routing, Operator
  Connect provisioning, government-cloud differences) and their resolutions.
- **07 — Best Practices:** durable practices for PSTN-path choice, emergency-calling discipline,
  pilot-first rollout, artifact standardization, number inventory, licensing, call quality, and safe
  automation.
- **Executive Summary:** the outcome, approach, and why the rollout is low-risk.

## PowerShell scripts (5) — MicrosoftTeams module; read-only or `-WhatIf` by default; no stored credentials
1. **`TEAMSPHONE-Discovery.ps1`** — *Readiness & inventory (read-only).* Reports enterprise-voice state,
   current number assignments, assigned voice policies, spare number inventory, and licensing signals;
   writes `Number Inventory – Teams Phone – Discovery`. Makes no changes.
2. **`TEAMSPHONE-Set-NumbersAndPolicy.ps1`** — *Number-assignment + voice-policy helper (defaults to
   `-WhatIf`).* From a user→number→path mapping, assigns numbers (`Set-CsPhoneNumberAssignment`),
   attaches the emergency location, and grants the named dial plan, calling policy, and emergency
   calling policy. `-Execute` applies; `-Rollback` reverses. Safe by default.
3. **`TEAMSPHONE-Set-VoiceApps.ps1`** — *Auto attendant / call queue config helper (defaults to
   `-WhatIf`).* Creates/associates resource accounts, call queues (`New-CsCallQueue`), and auto
   attendants (`New-CsAutoAttendant`) with a business-hours schedule and menu routing to the queue.
   Previews by default; `-Execute` applies.
4. **`TEAMSPHONE-Validation.ps1`** — *Calling + emergency-calling validation report.* Confirms, per
   user, enterprise-voice enablement, correct number/type, assigned policies, and attached emergency
   location; flags gaps. Writes `Voice Validation – Teams Phone – Report`. Read-only.
5. **`TEAMSPHONE-Scope.ps1`** — *Scope / health helper (read-only).* Lists a pilot/target group's
   members with their licensing and voice-readiness state, and surfaces tenant PSTN/health signals so
   you know who is ready to enable before you touch anything.

> Every script starts with comment-based help (`.SYNOPSIS` / `.DESCRIPTION` / `.EXAMPLE` / `.NOTES`),
> connects with modern-auth `Connect-MicrosoftTeams` (no stored credentials), and defaults to
> read-only or `-WhatIf`. Write actions require an explicit `-Execute`.
