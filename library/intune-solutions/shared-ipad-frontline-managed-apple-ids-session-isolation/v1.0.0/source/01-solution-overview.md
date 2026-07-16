# 1. Solution Overview — Shared iPad for Frontline Teams: Managed Apple IDs, ABM & Microsoft 365 Session Isolation

## The problem this solves

A frontline/field team runs a pool of iPads — typically 30–50 devices — that are **shared across
shifts**, not assigned one-to-one. Staff pick up whichever iPad is on the rack, use it for the shift
(a CMMS/work-order app, viewing schematics and drawings, taking photos, light Microsoft 365
collaboration), put it back, and someone else picks it up on the next shift.

The deployment is locked down and supervised — no App Store, no personal apps — and it still fails in
the one way that matters:

> **The next user opens Outlook and sees the previous user's mail.**

Teams keeps the prior chat. Photos taken by the day shift are in the camera roll of the night shift.
Sign-in fields autofill someone else's identity. On a device used by a dozen people a week, that is a
data-exposure problem, not an inconvenience.

## The root cause — stated plainly

**A supervised, single-user iPad that is passed between shifts has no per-user session boundary.**

iPadOS was configured for one owner. Handing the hardware to a different human does not tell the
operating system that the user changed — as far as the OS is concerned, every shift is the *same
user*. So:

- **Cached tokens and data stay put.** Microsoft 365 apps keep the refresh tokens, mailbox cache,
  chat history, and downloaded files of whoever signed in last, because nothing ever ended that
  user's session.
- **Signing out of one app does not sign out of the others.** Each Microsoft app holds its own
  session state. Outlook sign-out leaves Teams, OneDrive, and Word signed in.
- **App-level sign-out never removes on-device cached data.** Even a clean sign-out inside an app
  does not guarantee the local cache, attachments, or photo library are gone.
- **"Tell staff to sign out at the end of the shift" is not a fix.** It is a procedure that depends on
  a tired person performing an incomplete action, and even performed perfectly it does not deliver
  data separation. It is not an architecture.

**The fix is a real multi-user architecture.** There are exactly two supported ones. The deployment
described above is neither of them — it is a single-user device being used by many people, which is
why it leaks. Adding more restrictions to that profile will never fix it, because lockdown is not
isolation.

## The two supported architectures — the decision you must make

### Option A — Apple Shared iPad *(recommended for shift-based use, and what this solution deploys)*

**Shared iPad is Apple's native, OS-level multi-user feature for iPad.** Each user signs in to the
*device* with their own **Managed Apple ID** issued by **Apple Business Manager (ABM)** — ideally
federated to Microsoft Entra ID so staff sign in with their normal work credentials. iPadOS gives
each Managed Apple ID **its own data space on the device**. Signing out genuinely ends that user's
session; the next user signs in to a clean environment.

**What it requires:**
- The iPad is enrolled through **Automated Device Enrollment (ADE)** via **Apple Business Manager**
  and is **supervised**. Shared iPad is only available through ADE — you cannot switch an existing
  manually-enrolled iPad into Shared iPad without wiping and re-enrolling it.
- **Shared iPad is enabled in the ADE enrollment profile** in Intune.
- Every user has a **Managed Apple ID**. This is the hard part — see the reclamation workstream below.

**Trade-offs to state honestly:**
- **It requires ABM and Managed Apple IDs.** If your staff have personal Apple IDs on their work email
  address, Managed Apple ID creation is blocked until those conflicts are resolved. That is a
  people-and-comms project, not a checkbox.
- **Device storage sizing matters.** Each signed-in user consumes space on the device for their own
  data. More users resident on a device means more storage consumed, and an undersized iPad will
  refuse sign-ins or evict users. *(Apple publishes current minimum/recommended storage and maximum
  resident-user guidance — **verify the current figures against Apple's Shared iPad documentation
  before you size or buy hardware**. Do not assume the numbers from an older deployment still hold.)*
- **Converting an existing fleet means wipe and re-enroll.** Every iPad in the pool gets erased and
  re-enrolled through ADE. Plan the staging and the downtime.
- **Some apps and features behave differently under Shared iPad.** Not every app is designed for a
  multi-user iPad, and some iPadOS features are unavailable or altered in this mode. **Verify your
  specific app set (especially the CMMS app) against the vendor's documentation and a pilot device
  before committing the fleet.**
- **Devices must be in ABM.** iPads that were bought retail and never linked to ABM through a reseller
  or Apple cannot be ADE-enrolled — which means they cannot run Shared iPad. See Requirements R6.

### Option B — Microsoft 365 Shared Device Mode (SDM)

**Shared Device Mode is Microsoft's app-level feature.** The device is marked as shared, and
participating Microsoft apps use the **Microsoft Authenticator broker** for a global sign-in/sign-out:
signing out of one participating app signs the user out of all of them.

**Trade-offs to state honestly:**
- **It is app-level, not OS-level.** SDM does **not** give you per-user operating-system data
  separation. The camera roll, the Files app, Safari state, and anything outside the participating
  apps are still one shared pool.
- **It only covers apps that participate in SDM.** An app that does not implement shared device mode
  is unaffected by it and behaves exactly as it does today.
- **The set of Microsoft apps that support shared device mode on iOS/iPadOS changes over time.**
  **Verify the current supported-app list against Microsoft's documentation before you design around
  it.** This solution does not assert which Microsoft apps do or do not support SDM on iPadOS,
  because that list moves and a stale list will produce a design that fails validation.

### How to choose

| | **A — Apple Shared iPad** | **B — Microsoft 365 SDM** |
|---|---|---|
| Isolation level | **OS-level** — per-user data space | **App-level** — participating apps only |
| Photos / Files / Safari separated | **Yes** | **No** |
| Requires Managed Apple IDs | **Yes** | No |
| Requires ABM + ADE + supervision | **Yes** | No (device just needs to be marked shared) |
| Requires wipe of existing fleet | **Yes** | No |
| Fixes "next user sees prior mail" | **Yes** | Partly — only for participating apps |

**Choose A when** the device is genuinely shift-shared, the workload includes photos/files/browser
state, and the organization can adopt ABM and Managed Apple IDs. **That is this scenario, and it is
what this solution deploys.**

**Choose B when** Shared iPad is not viable — Managed Apple IDs cannot be adopted, the devices cannot
be brought into ABM, or the fleet cannot be wiped — and accept that you are buying a partial fix that
covers participating Microsoft apps only.

**They are not mutually exclusive.** A and B can be complementary: Shared iPad gives the OS boundary,
and SDM (where the apps support it) tightens the sign-out behaviour of the Microsoft app suite on top
of it. Deploy A first; layer B only after verifying app support.

## How this solution works

1. **Apple Business Manager is stood up and verified** — the organization's ABM account, the domains
   it will issue Managed Apple IDs on, and the devices (either purchased through a linked reseller or
   added by Apple's supported method).
2. **The personal-Apple-ID conflicts are resolved — this is a gate, not a step.** Staff who created a
   personal Apple ID using their **work email address** block Managed Apple ID creation on that
   address. Nothing downstream works until this campaign runs. See below.
3. **ABM is federated to Microsoft Entra ID** so a Managed Apple ID signs in with the staff member's
   normal work credentials rather than a second password to remember.
4. **An ADE enrollment profile with Shared iPad enabled** (`SHARED IPAD – ADE Profile – Shared`) is
   created in Intune and assigned to the iPad serial numbers on the ADE token.
5. **The field lockdown profile** (`SHARED IPAD – Restrictions – Field Lockdown`) strips the device to
   its job: no App Store, no personal apps, no adding personal accounts.
6. **The field app allowlist** (`SHARED IPAD – Apps – Field Allowlist`) deploys and exposes only the
   CMMS app, the schematics/document viewer, Camera, and the limited Microsoft 365 set the shift
   actually needs.
7. **A compliance policy** (`SHARED IPAD – Compliance – iPadOS`) reports the health of the fleet.
8. **The existing iPads are wiped and re-enrolled through ADE** in staged waves.
9. **The session-isolation test is run** — User A signs in, uses the device, signs out; User B signs
   in and must see **nothing** of A's. That test is the acceptance gate for the whole project.

## The Managed Apple ID reclamation workstream — the real blocker

This is the part that sinks projects, and it is not technical.

Over the years, staff created **personal Apple IDs using their organization email address** — to buy
apps, set up a personal iPhone, use iCloud. **Apple Business Manager cannot issue a Managed Apple ID
at an address that is already in use by a personal Apple ID.** Every affected staff member is a
blocked Shared iPad user until their conflict is resolved.

**What you need to understand about it:**
- **It reaches every Apple device that person owns**, not just the work iPad. Their personal iPhone,
  their home Mac, their iCloud photo library, their App Store purchase history — all of it is tied to
  that Apple ID. Resolving the conflict touches their personal life. This needs executive sponsorship
  and a genuine communications plan, not a technical push and a hope.
- **Apple provides a supported conflict-resolution path** built around verifying ownership of your
  domain, after which affected personal Apple IDs must be changed to a personal email address (or are
  otherwise handled by Apple's process). **The exact flow names, portal navigation, notification
  timelines, and mechanics are Apple's and they change — verify every specific against current Apple
  Business Manager documentation before you plan dates or write user comms.** This solution gives you
  the concept, the decision points, and the sequencing; Apple's documentation gives you the clicks.
- **The scripts in this package build the *candidate* list, not the authoritative one.**
  `SHAREDIPAD-AppleIDConflict.ps1` reads Entra ID and tells you which staff have work addresses that
  would need a Managed Apple ID and therefore *may* collide. **Only Apple Business Manager knows which
  addresses actually collide.** Use the script's CSV to plan and track the campaign; use ABM for
  truth.

**This is a decision, not a configuration.** Whether to require staff to rename or surrender a
personal Apple ID that carries their photos and purchases is an **identity, HR, legal, and
communications decision**. This solution presents the options and their impact. **The customer's HR,
legal, and identity owners make the call — never make it for them, and never let the technical team
make it by default.**

## Benefits

- **The leak stops.** Per-user OS data separation means the next user gets a clean device — not a
  procedure that hopes they signed out.
- **Sign-out actually means sign-out.** Ending a Shared iPad session ends the session, across every
  app, at the OS layer.
- **Staff use their normal work credentials** when ABM is federated to Entra ID — no second password.
- **The fleet is interchangeable.** Any staff member can pick up any iPad and get their own
  environment.
- **The device stays locked to its job** — no App Store, no personal accounts, only the field
  workload.
- **It is auditable.** The included scripts report Shared iPad readiness and state per device across
  the fleet.

## Limitations — be honest with the buyer

- **Shared iPad requires ABM + ADE + supervision. There is no shortcut.** No configuration profile,
  no restriction, and no app setting delivers OS-level multi-user on a non-ADE iPad.
- **Existing devices must be wiped and re-enrolled.** Budget the staging time and the shift downtime.
- **Devices not in ABM cannot be ADE-enrolled** — and therefore cannot run Shared iPad at all. If part
  of your fleet was bought retail, that part of the fleet is out of scope until it is brought into ABM
  (or replaced).
- **The Apple ID reclamation campaign is the long pole**, and it is a people project with a technical
  tail.
- **Storage sizing is a real constraint.** Under-specced iPads will run out of room for resident
  users. *(Verify Apple's current guidance — see Requirements R8.)*
- **Some apps behave differently under Shared iPad.** Pilot your actual CMMS and viewer apps before
  committing the fleet.
- **This solution does not assert the Microsoft SDM iOS app-support list** — verify it against
  Microsoft's current documentation if you layer Option B.

## The standard deployment model

Every step in this solution follows the standard pattern:

> **Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — ABM state, ADE token, device eligibility, storage, and the Apple ID conflict exposure.
- **Configure** — federation, ADE profile with Shared iPad, lockdown, compliance, app allowlist.
- **Pilot** — one iPad, two real users (`PILOT – Shared iPad Users`), `SHARED IPAD – FMD – Pilot`.
- **Validate** — the session-isolation A/B test with explicit PASS/FAIL criteria (Testing §5).
- **Expand** — staged waves into `SHARED IPAD – FMD – Production`.

## What this solution covers, and what the catalog already covers

This solution is deliberately scoped to the gap. It **cross-references** — and does **not**
reproduce — three existing catalog solutions:

| Existing solution | What it covers | Why it is not this |
|---|---|---|
| **Implement iOS Lock Down Profile for iOS iPhones in Microsoft Intune for Shared Devices** | Supervised **single-user iPhone** lockdown — restrictions and kiosk-style hardening on a pooled handset. | It hardens a **single-user** device. It contains no multi-user architecture, so it cannot separate sessions. Use it for iPhone lockdown; use *this* for iPad session isolation. |
| **iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling in Microsoft Intune** | Microsoft **app-level** shared device mode on iPhone, plus kiosk lockdown to a calling app. | That is **Option B** applied to iPhone. It is app-level, not OS-level, and it is not Shared iPad. |
| **Implement Entra ID Integration with ABM for Account Auto Provisioning for Microsoft Intune** | **ABM account auto-provisioning** from Entra ID — getting accounts into ABM. | It provisions accounts into ABM. It does **not** cover Shared iPad, Managed Apple ID conflict resolution, or session isolation. It is a useful companion once ABM is stood up. |

**This solution covers: Apple Shared iPad (OS-level multi-user) + Managed Apple IDs + the personal
Apple ID reclamation workstream + field lockdown + the session-isolation validation gate.** That is
net-new — no existing catalog solution delivers per-user session isolation on iPad.
