# Solution Overview

## What this solution is

A focused **root-cause-and-remediation** package for one specific, common iOS/iPadOS enrollment
failure: the user starts **Device Management** enrollment into Microsoft Intune and hits an
**"Access Denied — You are not authorized to view this page. Your IT department may be able to help"**
screen, with a block of **Diagnostic information for IT** (Activity Id, Session Id, Timestamp). It is
not a device fault — it is a **tenant-side authorization gate** (licensing, MDM scope, enrollment
restrictions, or Conditional Access) refusing the enrollment. This guide turns the diagnostic IDs into
the exact reason and fixes it.

## What the screen actually means

The "Access Denied / not authorized" page is returned by the Intune **enrollment authorization**
service when the signed-in user is **not permitted to enroll**. The **Session Id** and **Activity Id**
on the screen are correlation identifiers you look up in the **Entra sign-in logs** and the Intune
troubleshooting portal to see precisely which gate blocked the enrollment — so this is a *deterministic*
diagnosis, not guesswork.

## The gates that produce it (in order of likelihood)

1. **No Intune license on the user.** Enrollment authorizes against the user's license; without an
   **Intune / EMS** service plan the user is "not authorized." This is the most common cause.
2. **User outside the MDM user scope.** In Entra → **Mobility (MDM and WIP) → Microsoft Intune**, the
   **MDM user scope** must be **All** or a group that includes the user. If it is **None** or a group
   they are not in, enrollment is denied.
3. **An enrollment restriction blocks it.** A device-platform restriction disallowing **iOS/iPadOS** or
   **personally-owned** devices, or the **device-limit** restriction (the user is already at their
   enrolled-device cap).
4. **A Conditional Access policy blocks the sign-in.** A CA policy scoped to the **Microsoft Intune
   Enrollment** or **Microsoft Intune** cloud apps that blocks, or imposes a grant the device cannot yet
   meet — the classic *"require compliant device to enroll"* chicken-and-egg.
5. **An account problem.** A **guest / B2B** account (guests cannot enroll), a blocked/disabled sign-in,
   or missing a required group membership.

## How you diagnose it — the deterministic path

The IDs on the screen are the fast path:

1. Take the **Session Id** and **Activity Id** with the **timestamp** and open **Entra admin center →
   Monitoring → Sign-in logs**; filter to the user/time and the correlation/request ID. The failed
   sign-in's **failure reason** and its **Conditional Access** tab name the exact gate.
2. Then confirm the specific gate — **license**, **MDM user scope**, **enrollment restriction**, or
   **CA** — with the included scripts, and remediate it.

## The standard deployment model

**Capture (the diagnostic IDs) → Read the failed enrollment sign-in → Check the four gates (license,
MDM scope, restrictions, CA) → Remediate the identified gate → Re-enroll and validate.** Every step is
evidence-led, and the scripts turn each gate into a yes/no answer.

## Benefits

- **Two-minute root cause** from the on-screen IDs instead of trial-and-error re-enrollment.
- **Covers every common gate** — license, MDM scope, enrollment restrictions, Conditional Access,
  account — in one ordered runbook.
- **Evidence for the ticket** — the failed sign-in, the license/scope/restriction/CA findings, and the
  successful re-enrollment.
- **Prevention** — fix the class of problem (scope/restriction misconfiguration) so the next user
  doesn't hit it.

## Limitations & scope

- Scope is the **enrollment authorization "Access Denied / not authorized"** failure on iOS/iPadOS.
  General Intune iOS enrollment setup (ADE/ABM, Company Portal, enrollment profiles) and enrollment-time
  device grouping are covered by the companion Intune enrollment solutions and referenced, not rebuilt.
- Some checks (the MDM user scope, enrollment-restriction and CA reads) rely on Graph endpoints that
  evolve; where an API is beta the guide says so and points to the portal as the source of truth.
- **Sovereign clouds:** the gates and method are identical in GCC / GCC High / DoD; portals are
  `entra.microsoft.us` / `intune.microsoft.us` — called out inline. A single deliverable covers both.
