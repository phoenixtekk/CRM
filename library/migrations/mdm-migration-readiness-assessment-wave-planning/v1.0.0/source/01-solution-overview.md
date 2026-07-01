# 1. Solution Overview — MDM Migration Readiness Assessment & Wave Planning

## What this solution is
This is a **vendor-neutral, pre-migration assessment and wave plan** for moving a managed device
estate from one Mobile Device Management (MDM) platform to another — for example Workspace ONE,
MobileIron/Ivanti, Jamf, Kandji, ManageEngine, SOTI, Configuration Manager, or Group Policy moving to
Microsoft Intune. It is the *planning* discipline that runs **before** a single device is touched:
inventory the estate, score readiness and risk, find dependencies and blockers, then design a
sequenced set of migration waves with explicit entry and exit criteria.

It does not perform the cutover. It produces the plan the cutover runs to.

## Why this matters (the why lives here, only here)
Most MDM migrations fail in planning, not execution. The recurring pattern is the same every time:
- **No clean inventory.** Nobody can say exactly how many devices, which OS/platform mix, which apps,
  which configuration profiles, which enrollment types, or which dependencies are in scope.
- **Waves aren't thought through.** Devices are moved in an ad-hoc order, so high-risk or
  high-dependency devices migrate before anyone has validated the approach on safe ones.
- **Risks surface mid-cutover.** A blocker that should have been a line in a risk register on day one
  instead becomes an outage during a change window with users watching.

The repeatable way fixes this by front-loading the discovery and the decision-making. When the estate
is inventoried, readiness and risk are scored, and the waves are sequenced with entry/exit gates, the
actual migration runs to a script instead of by surprise — and it is validated against a pilot wave
before it scales.

## How it works
1. **Inventory the estate.** Collect every in-scope device with its OS/platform, ownership and
   enrollment type, installed/required apps, assigned configuration profiles, compliance state, and
   the user/department/region it belongs to — from the current MDM and from generic CSV inputs for any
   source platform. The artifact is the `Estate Inventory – MDM Migration – Assess`.
2. **Score readiness.** Each device is scored against objective readiness criteria (supported OS,
   reachable, enrolled, app coverage understood, no unsupported profile). The artifact is the
   `Readiness Scorecard – MDM Migration – Assess`.
3. **Score risk.** Each device/app/profile is scored for migration risk (executive or
   shared/critical device, kiosk/single-purpose, certificate or VPN dependency, unsupported
   configuration). The artifact is the `Risk Register – MDM Migration – Assess`.
4. **Map dependencies and blockers.** Identify what must move together or in a fixed order —
   certificates, Wi-Fi/VPN profiles, line-of-business apps, conditional-access bindings, shared-device
   relationships. The artifact is the `Dependency Map – MDM Migration – Assess`.
5. **Design the waves.** Sequence devices into ordered waves from lowest risk/highest readiness to
   highest risk/lowest readiness, each with entry and exit criteria. The artifacts are the
   `Wave Plan – MDM Migration – Configure` and the `Wave Cohorts – MDM Migration – Configure`.
6. **Validate against a pilot.** The first wave is the `Pilot Wave – MDM Migration – Pilot`; it proves
   the plan and the entry/exit gates before any broad expansion.

## What you inventory and score
- **Devices** — count, hardware, ownership (corporate/BYOD), last check-in.
- **OS / platform mix** — Windows / iOS / iPadOS / macOS / Android and version spread.
- **Apps** — installed and required apps per device, including line-of-business and store apps.
- **Configuration profiles** — Wi-Fi, VPN, email, certificates, restrictions, kiosk/single-purpose.
- **Compliance** — current compliant/non-compliant state and the policy that sets it.
- **Enrollment types** — corporate ADE/automatic, user-driven, BYOD, shared/kiosk.
- **Dependencies** — certificate authorities, VPN, app dependencies, conditional access, shared-device.

## The named artifacts (use these exact names everywhere)
| Artifact | Stage |
|---|---|
| `Estate Inventory – MDM Migration – Assess` | Assess |
| `Readiness Scorecard – MDM Migration – Assess` | Assess |
| `Risk Register – MDM Migration – Assess` | Assess |
| `Dependency Map – MDM Migration – Assess` | Assess |
| `Wave Plan – MDM Migration – Configure` | Configure |
| `Wave Cohorts – MDM Migration – Configure` | Configure |
| `Cohort Group – Per Wave – Configure` | Configure |
| `Pilot Wave – MDM Migration – Pilot` | Pilot |
| `Entry/Exit Criteria – Per Wave – Pilot` | Pilot |

## What this is not
- It is **not** the cutover itself — no devices are re-enrolled or unenrolled by this solution.
- It is **not** vendor-specific tooling — it stays neutral about the source MDM and reads generic
  CSV/inventory exports so it works regardless of where you are migrating from.
- It does **not** assume the target is Intune, though the optional Microsoft Graph helpers light up
  when the current or target MDM is Intune-adjacent.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand.** Inventory and score (Assess), build the wave
> plan and cohorts (Configure), run the first wave (Pilot), prove the entry/exit gates and the plan
> against that pilot (Validate), then sequence the remaining waves (Expand). The plan is always
> validated against a pilot wave before it scales — that gate is non-negotiable.
