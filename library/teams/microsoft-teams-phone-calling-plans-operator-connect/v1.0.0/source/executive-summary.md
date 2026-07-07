# Executive Summary — Microsoft Teams Phone Enablement (Calling Plans & Operator Connect)

## Outcome
Enterprise voice runs in **Microsoft Teams Phone**: the right PSTN path is chosen per number, phone
numbers are assigned, dial plans and calling policies are in place, **emergency calling is configured
and tested**, and auto attendants and call queues route callers correctly — so users get reliable
inbound and outbound calling directly in Teams, with no separate telephony platform.

## Approach
The solution enables Teams Phone via the **two non-SBC PSTN paths — Microsoft Calling Plans (Microsoft
is the carrier) and Operator Connect (an integrated operator is the carrier)** — using only the Teams
admin center, the Microsoft 365 admin center, and the MicrosoftTeams PowerShell module. It follows the
house model — **Assess → Design → Configure → Pilot → Validate → Expand** — enabling a small named pilot
ring first, validating every gate (including a coordinated **live emergency-call test**), then expanding
in waves under change control. Five PowerShell tools handle discovery, safe number/policy assignment,
auto attendant/call queue build-out, validation, and scope/health — all read-only or `-WhatIf` by
default, with no stored credentials. *(Direct Routing via a customer-run SBC is a distinct PSTN model
and is delivered as a separate solution.)*

## Why it's low-risk
- **Pilot-first with explicit pass/fail gates** — voice never goes wide before it is proven on a small
  ring, and a documented rollback (`Remove-CsPhoneNumberAssignment` + re-grant global policies) is
  ready at every step.
- **Emergency calling is treated first-class** — civic addresses and dynamic locations are registered
  *before* numbers are assigned, security-desk notifications are configured, and a live emergency test
  is a mandatory gate. (For these PSTN paths, PSAP routing is Microsoft's/the operator's
  responsibility — confirmed and tested with them, not assumed.)
- **Safe-by-default automation** — every write runs `-WhatIf` first; modern-auth sign-in; no hardcoded
  secrets; least-privilege roles.
- **Honest about boundaries** — plan-, country-, operator-, and cloud-dependent behavior (Calling Plan
  vs Operator Connect availability, pay-as-you-go billing, GCC High/DoD differences) is flagged "verify
  in your tenant," and legal/records determinations for emergency addresses are deferred to
  facilities/EHS/compliance. You get a proven method, delivered at a fraction of typical consulting
  cost.
