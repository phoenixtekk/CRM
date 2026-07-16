# Executive Summary — Shared iPad for Frontline Teams

## The situation

A frontline field team runs a pool of iPads — typically 30–50 devices — shared across shifts rather
than assigned one-to-one. Staff take whichever iPad is on the rack, use it for work orders, drawings,
photos, and Microsoft 365 collaboration, and return it for the next shift.

The devices are locked down. They are supervised. No App Store, no personal apps. And they still fail
in the way that matters most:

> **The next user opens Outlook and sees the previous user's mail.**

Teams keeps the prior chat. The day shift's photos are in the night shift's camera roll. On a device
used by a dozen people a week, this is a data-exposure problem — one that is visible to staff, obvious
to an auditor, and impossible to explain away.

## The root cause

**A single-user iPad passed between shifts has no per-user session boundary.** The operating system was
never told the user changed, so Microsoft 365 apps keep the previous user's cached tokens and data.
Signing out of one app does not sign out of the others, and app-level sign-out never clears on-device
cached data.

**"Tell staff to sign out" is not a fix.** It is a procedure that depends on a tired person performing
an incomplete action — and even performed perfectly, it does not produce data separation. Adding more
restrictions will not help either: **lockdown is not isolation**.

The fix is a real multi-user architecture. There are exactly two supported ones, and the current
deployment is neither.

## The decision

| | **Apple Shared iPad** *(recommended)* | **Microsoft 365 Shared Device Mode** |
|---|---|---|
| Isolation | **OS-level** — each user gets their own data space | **App-level** — participating apps only |
| Photos, files, browser separated | **Yes** | **No** |
| Requires Managed Apple IDs + ABM + wipe | **Yes** | No |
| Fixes the reported problem | **Yes** | **Partly** |

**Apple Shared iPad is the right answer for shift-based devices**, and it is what this solution
deploys. Each staff member signs in to the *device* with a **Managed Apple ID** — federated to
Microsoft Entra ID so they use their normal work credentials — and iPadOS gives each user their own
data space. Sign-out genuinely ends the session. The next user gets a clean device, by architecture
rather than by procedure.

Microsoft 365 Shared Device Mode is the fallback where Shared iPad is not viable. It is honest about
what it delivers: app-level sign-out across participating Microsoft apps, with no OS-level separation
of photos, files, or browser state.

## The real blocker — and it is not technical

Over the years, staff created **personal Apple IDs using their work email address**. **Apple Business
Manager cannot issue a Managed Apple ID at an address already in use by a personal Apple ID.** Every
affected staff member is a blocked Shared iPad user until that conflict is resolved.

**This is the constraint that determines your timeline**, and it reaches beyond the iPads — a staff
member's personal Apple ID carries their personal iPhone, their home Mac, their photo library, and
their App Store purchases. Resolving it touches their personal life.

**It is therefore an identity, HR, legal, and communications decision — not a technical one.** This
solution surfaces the exposure, presents the options and their impact, and sequences the campaign. The
organization's HR, legal, and identity owners make the call. Executive sponsorship and a real
communications plan are prerequisites, not nice-to-haves.

There is a second constraint worth knowing on day one: **iPads not present in Apple Business Manager
cannot be enrolled through Automated Device Enrollment, and therefore cannot run Shared iPad at all.**
On a fleet accumulated over several years, this can turn a configuration project into a procurement
conversation. This solution establishes that number in the first phase, before any date is promised.

## What this solution delivers

- **The architecture decision**, framed with honest trade-offs, so the organization chooses knowingly.
- **Click-by-click implementation** — ABM setup, conflict resolution as an explicit gate, Entra
  federation, the ADE enrollment profile with Shared iPad enabled, supervision, field lockdown,
  compliance, the app allowlist, and staged wipe-and-re-enroll of the existing fleet.
- **Five PowerShell scripts** — four read-only (readiness discovery, PASS/FAIL validation, fleet
  reporting, and the Apple ID reclamation worklist), and one state-changing helper that **defaults to
  `-WhatIf`**.
- **The validation gate** — an explicit, reproducible **session-isolation A/B test** with exact
  PASS/FAIL criteria: User A signs in, works, signs out; User B signs in on the same device and must
  see no mailbox, no cached mail, no chat, no photos, no autofill, and no signed-in state belonging to
  A. Plus a diagnostic table mapping every failure back to the architecture step that caused it.
- **A shift-handover runbook** for the field team and a **staged fleet plan** for ~40 devices.

## The outcome

**The leak stops.** The next user gets a clean device — because the operating system separates them,
not because someone remembered to sign out. Staff sign in with their normal work credentials. Any
iPad works for any person. The device stays locked to its job.

And critically: **you can prove it.** The session-isolation test is the acceptance gate. It either
passes or it does not, and this solution tells you exactly which architecture step to fix when it does
not.

## Honest limitations

- **Shared iPad requires ABM, ADE, and supervision. There is no shortcut** — no profile or restriction
  delivers OS-level multi-user on a non-ADE iPad.
- **Existing devices must be wiped and re-enrolled.** Budget the staging time and the shift downtime.
- **Devices not in ABM are out of scope** until they are brought in or replaced.
- **The Apple ID reclamation campaign is the long pole**, and it is a people project.
- **Storage sizing is a real constraint** — undersized iPads will fail sign-ins at scale.
- **Some apps behave differently under Shared iPad** — pilot the CMMS and viewer apps before
  committing the fleet.
- **Apple's and Microsoft's specifics change.** Current iPadOS floors, storage and user-count guidance,
  ABM navigation and conflict-resolution mechanics, federation specifics, and the Microsoft SDM
  supported-app list are all flagged in this guide as **verify against current vendor documentation** —
  and are deliberately not asserted here. A guide that invents them is a guide that fails at step 12.
