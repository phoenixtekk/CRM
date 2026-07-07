# 7. Best Practices — Teams Phone (Calling Plans & Operator Connect)

Durable practices for a reliable Teams Phone rollout on the non-SBC PSTN paths.

## Choose the PSTN path deliberately, per number
- Use **Calling Plans** when you want Microsoft as the carrier with the least infrastructure and fast
  provisioning, and the plan is available for your country.
- Use **Operator Connect** when you want to keep an existing operator relationship/contract and have
  the operator manage PSTN, without running an SBC.
- You can mix both in one tenant. Record the path per number so `-PhoneNumberType` is always correct at
  assignment. **Availability and pricing are country/operator-dependent — verify in your tenant.**

## Treat emergency calling as first-class, not a footnote
- Register and validate emergency **civic addresses** and build **dynamic locations (LIS)** *before*
  assigning numbers at a site — never enable users at a location with no dispatchable location data.
- Map every site's **subnets, Wi-Fi access points, and (for wired) switches/ports** to a location so a
  user's emergency location follows where they actually connect.
- Configure **security-desk notifications** in the emergency calling policy so someone on-site is
  alerted when an emergency call is placed.
- Remember: for Calling Plans/Operator Connect, **PSAP routing is Microsoft's/the operator's
  responsibility** — the Emergency Call *Routing* Policy is Direct-Routing-only. Confirm and **test**
  emergency behavior with the carrier/operator; treat the emergency test as a hard gate.
- **The legal/records determination of required addresses is deferred to facilities/EHS/compliance** —
  implement what they specify; you provide the technical method and evidence.

## Pilot first, always, with a rollback
- Enable a small named ring (`Teams Phone Pilot – Voice – Pilot`) and validate every gate — including a
  live emergency test — before any broad wave.
- Keep the documented rollback ready (`Remove-CsPhoneNumberAssignment` + re-grant global policies) and
  practice it once in the pilot so cutover is low-risk.
- Expand in waves under change control, re-validating after each wave.

## Standardize and reuse a small set of named artifacts
- One calling policy, one emergency calling policy per notification scope, one dial plan per
  country/dialing habit — named `<Purpose> – <Scope> – <Stage>` and reused verbatim across docs,
  scripts, and the admin center.
- Avoid per-user bespoke policies; assign the named policy to groups so scope is membership-driven and
  auditable.
- **Note the naming caveat:** PowerShell policy *identities* cannot contain the en-dash; use the ASCII
  `-` form in cmdlets (`Calling Policy - Standard - Prod`) and the en-dash display name in the admin
  center — treat them as the same artifact and keep them in lockstep.

## Manage numbers as inventory
- Keep an authoritative export (`Number Inventory – Teams Phone – Discovery`) and reconcile it
  regularly: no double-assignments, spare numbers tracked, service numbers separated from user numbers.
- Plan **port orders** early — they are carrier-driven and can take days to weeks; never schedule a
  cutover assuming an instant port.
- Reclaim numbers from leavers promptly (`Remove-CsPhoneNumberAssignment`) so inventory stays clean.

## Right-size licensing and voice apps
- Assign **Teams Phone** to users who actually need PSTN calling; use **Teams Phone Resource Account**
  licenses for auto attendant/call queue resource accounts (do not consume user licenses for them).
- Front every auto attendant/call queue with a **licensed resource account** holding the service
  number; keep resource-account naming (`Resource Account – AA-MainLine` / `– CQ-Support`) consistent.
- Confirm the current billing model for toll-free/pay-as-you-go (**Communications Credits /
  pay-as-you-go is plan-dependent — verify in your tenant**).

## Design for call quality and support
- Verify network readiness (bandwidth, latency/jitter, required Microsoft 365 endpoints, optional QoS)
  before enabling users at a site — voice quality is a network property, not a licensing one.
- Give users a short "what changed" guide (their new number, how to dial internationally, how call
  queues/attendants work) and a support path for the first weeks.

## Automate safely
- Run every write with **`-WhatIf` first**; only `-Execute` after reviewing the dry run.
- Use **modern-auth `Connect-MicrosoftTeams`** (MFA) — **never** hardcode credentials or secrets in
  scripts; scope automation accounts to the least-privilege Teams role.
- Keep the discovery/validation scripts read-only and run them on a schedule to catch drift (users who
  lost a policy, orphaned numbers, missing emergency locations).

## Mind the cloud and the boundary
- In **GCC High / DoD**, availability, portals, and some behavior differ from Commercial — **verify in
  your cloud/tenant** before assuming a feature or URL.
- Keep **Direct Routing** work in its own solution — do not mix SBC/voice-route/Emergency-Call-Routing
  configuration into this non-SBC path.
