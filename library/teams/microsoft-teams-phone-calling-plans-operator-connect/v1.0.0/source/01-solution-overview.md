# 1. Solution Overview — Microsoft Teams Phone Enablement (Calling Plans & Operator Connect)

## What this solution is
This solution turns on **enterprise voice in Microsoft Teams Phone** using the **two non-SBC PSTN
connectivity paths — Microsoft Calling Plans and Operator Connect**. It is a repeatable, pilot-first
method to license users for Teams Phone, acquire and assign phone numbers, configure calling and
emergency-calling policy, build auto attendants and call queues, and validate that inbound and
outbound calls (including emergency calls) work — using only the **Microsoft Teams admin center**
(`https://admin.teams.microsoft.com`), the **Microsoft 365 admin center**, and the **MicrosoftTeams
PowerShell module** (with Microsoft Graph where noted). No third-party tooling is required.

> **Scope boundary.** This solution covers the **two Microsoft-hosted / operator-hosted PSTN paths**
> only. **Direct Routing (bring-your-own-carrier via a certified Session Border Controller)** is a
> separate PSTN model with its own trunks, voice routes, PSTN usages, and SBC lifecycle, and is
> **out of scope here** — it is delivered as a separate solution. Where a control (e.g. an Online
> Voice Routing Policy or an Emergency Call Routing Policy) exists **only** for Direct Routing, this
> document says so and does not apply it.

## The three PSTN options (and why this solution uses two of them)
Teams Phone needs a PSTN (public switched telephone network) connection to place and receive external
calls. Microsoft offers three ways to provide it:

| PSTN path | Who provides the carrier service | Where numbers come from | In scope here |
|---|---|---|---|
| **Microsoft Calling Plan** | Microsoft is your telephony carrier | Microsoft (get new numbers or port in via the Teams admin center) | **Yes** |
| **Operator Connect** | A participating telecom operator you already use, integrated into Teams | The operator (provisioned into your tenant via the operator's portal) | **Yes** |
| **Direct Routing** | Your own carrier via an SBC you (or a partner) run | Your carrier | No — separate solution |

- **Calling Plan** is the fastest path: Microsoft is the carrier, numbers and minutes are bought in
  the admin center, and there is no infrastructure to run. Availability, number types, and the
  billing model (fixed calling plan vs pay-as-you-go) are **country/region- and plan-dependent — verify
  what is offered for your tenant and country in the Teams admin center**.
- **Operator Connect** keeps your existing operator relationship and contract while delivering calling
  natively in Teams: the operator provisions numbers directly into your tenant and you assign them in
  Teams. Which operators are available is **region-dependent — verify in the Teams admin center
  (`Voice → Operators`) for your tenant**.
- Both paths share the **same downstream configuration** in Teams (licensing, number assignment,
  dial plans, calling policy, emergency calling, auto attendants, call queues). This solution treats
  the choice of Calling Plan vs Operator Connect as a per-number decision and configures everything
  after that point identically.

## How it works (end to end)
1. **License.** Each calling user needs a **Teams Phone** license, plus — for Calling Plans — a
   **Microsoft Calling Plan** (or pay-as-you-go add-on). Operator Connect needs the Teams Phone
   license but **no** Microsoft Calling Plan (the operator bills the PSTN service). Resource accounts
   that back auto attendants and call queues need a **Teams Phone Resource Account** license. (Exact
   SKU names and the pay-as-you-go / Communications Credits model are **plan-dependent — verify current
   SKUs and billing in the M365 admin center**.)
2. **Acquire numbers.** For **Calling Plans**, get new numbers or submit a port order in the Teams
   admin center (`Voice → Phone numbers`). For **Operator Connect**, the operator provisions numbers
   into the tenant (via the operator portal / `Voice → Operators`); they then appear in `Phone numbers`
   ready to assign.
3. **Assign numbers + enable voice.** Assign a number to each pilot user with
   `Set-CsPhoneNumberAssignment` (specifying the correct `-PhoneNumberType` of `CallingPlan` or
   `OperatorConnect`), which also enables enterprise voice for the user.
4. **Normalize dialing.** Apply a **Tenant Dial Plan** so user-dialed strings (extensions, local
   formats) normalize to E.164. (The Tenant Dial Plan applies to all PSTN paths; the **Online Voice
   Routing Policy** is Direct-Routing-only and is *not* used here.)
5. **Calling policy.** Grant a **Teams Calling Policy** that sets the calling features users get
   (call forwarding, delegation, call park, busy-on-busy, etc.).
6. **Emergency calling.** Configure **civic addresses and dynamic emergency locations (LIS)** and a
   **Teams Emergency Calling Policy** (security-desk notifications). For Calling Plans and Operator
   Connect, **emergency-call routing to the correct PSAP is handled by Microsoft / the operator** —
   the **Emergency Call *Routing* Policy** is a Direct-Routing control and is **not** used here.
7. **Voice apps.** Create **resource accounts**, then **auto attendants** and **call queues**, assign
   service numbers to the resource accounts, and connect them.
8. **Validate.** Confirm each user is enterprise-voice-enabled with the right number, that calls flow
   in and out, that the emergency address/notification is correct, and that auto attendants and queues
   answer and route.
9. **Expand.** After the pilot passes every gate, repeat number assignment and policy grants for the
   broader population under change control.

## Reference design
- **One pilot ring first.** A small named user set (`Teams Phone Pilot – Voice – Pilot`) is fully
  enabled and validated — including a live emergency-call test coordinated with the carrier/operator —
  before any broad rollout.
- **A small number of reusable policies**, named once and reused: a standard calling policy, an
  emergency calling policy per notification scope, and a tenant dial plan per country/dialing habit.
- **Resource accounts back every voice app.** Auto attendants and call queues are always fronted by a
  licensed resource account holding the service number.
- **Emergency location is data-driven.** Civic addresses and network identifiers (subnets / Wi-Fi
  access points / switches / ports) are registered in the Location Information Service so a user's
  emergency location follows where they actually connect.

## Benefits
- **The right PSTN path, deliberately chosen** — Calling Plan where speed and simplicity win,
  Operator Connect where an existing operator relationship and contract should be kept, without
  standing up SBC infrastructure.
- **Numbers assigned cleanly and reversibly**, with a full before/after inventory and safe,
  `-WhatIf`-gated automation.
- **Emergency calling configured correctly**, with dynamic locations and security-desk notifications —
  the highest-risk part of any voice rollout, treated first-class.
- **Auto attendants and call queues** that route callers to the right people with published business
  hours and holidays.
- **Pilot-first, with explicit pass/fail gates and a documented rollback**, so a voice change never
  goes wide before it is proven on a small ring.

## Limitations (be honest with buyers)
- **Direct Routing is not covered** — if you must bring your own carrier via an SBC, use the separate
  Direct Routing solution.
- **Calling Plan and Operator Connect availability, number types, and pricing are
  country/region- and operator-dependent.** Toll-free numbers, international dialing, and pay-as-you-go
  vs fixed-plan billing vary — **verify what is available for your country and tenant** in the Teams
  admin center; this solution provides the method, not a guarantee of availability.
- **Government clouds differ.** In **GCC High / DoD**, Calling Plan and Operator Connect availability,
  admin portals, and some cmdlet behavior are **different from Commercial — verify in your cloud/tenant**
  before assuming a feature or URL applies.
- **Emergency-call *routing* for Calling Plans/Operator Connect is Microsoft's / the operator's
  responsibility.** This solution configures locations and notifications, but the actual PSAP routing
  and any test-call capability depend on the carrier/operator — **coordinate a validated emergency test
  with them**, do not assume 911/112 works until tested.
- **Number porting takes time** and is carrier-driven; port orders can take days to weeks and require
  accurate account/billing details. Plan cutover accordingly.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and admin center. The standard set:

| Artifact | Name |
|---|---|
| Number/license inventory export | `Number Inventory – Teams Phone – Discovery` |
| Pilot user group | `Teams Phone Pilot – Voice – Pilot` |
| Tenant dial plan | `Dial Plan – US – Prod` |
| Calling policy | `Calling Policy – Standard – Prod` |
| Emergency calling policy | `Emergency Calling Policy – HQ – Prod` |
| Emergency civic address | `Emergency Address – HQ` |
| Emergency dynamic location | `Emergency Location – HQ-Floor1` |
| Resource account (auto attendant) | `Resource Account – AA-MainLine` |
| Resource account (call queue) | `Resource Account – CQ-Support` |
| Auto attendant | `Auto Attendant – MainLine – Prod` |
| Call queue | `Call Queue – Support – Prod` |
| Validation report export | `Voice Validation – Teams Phone – Report` |

## The standard deployment model
> Assess readiness and choose the PSTN path per number → design the policies, dial plan, emergency
> locations, and voice apps → configure them → enable a small **pilot** ring → validate every gate
> (including a live emergency test) → expand to the broader population under change control, with a
> documented rollback at every step.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
