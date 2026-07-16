# Shared iPad for Frontline Teams — Managed Apple IDs, ABM & Microsoft 365 Session Isolation

> **Version 1.0.0** · Category: Intune · Solution code: SHAREDIPAD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


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


---


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


---


# 2. Requirements — Shared iPad for Frontline Teams

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.**

Category-wide prerequisites (Entra tenant, Intune licensing, admin roles, pilot group, supported OS,
network) are covered once in the **Global Requirements — Intune Solutions** document. The items here
are specific to **Apple Shared iPad with Managed Apple IDs**.

> **Verification discipline.** Several requirements below depend on **Apple-published specifics**
> (iPadOS version floors, storage minimums, maximum resident users, ABM portal navigation, federation
> and conflict-resolution mechanics). Those change. Where you see a **VERIFY WITH APPLE** flag, go to
> current Apple Business Manager / Shared iPad documentation and confirm the figure or flow **before**
> you buy hardware, publish a date, or write user communications. Do not carry a number forward from
> an older project.

---

## R1. Microsoft Intune licensing and an Intune-managed tenant

**Description:** An Intune-bearing licence plan (Microsoft 365 E3/E5, Business Premium, or standalone
Intune Plan 1) covering every staff member who will sign in to a Shared iPad.
**Why required:** Intune delivers the ADE enrollment profile that enables Shared iPad, plus the
restrictions, compliance, and app assignments.
**How to verify:** Sign in to `https://intune.microsoft.com` → **Tenant administration → Tenant
status**; confirm an active subscription. Then Entra → **Users → (a pilot user) → Licenses**; confirm
an Intune-bearing licence.
**How to implement if missing:** Purchase and assign the licence to the pilot users, then to the full
frontline population before Expand.

## R2. Microsoft 365 licensing for the field workload

**Description:** Microsoft 365 licences covering the mail/collaboration apps the shift actually uses
(e.g. Exchange Online for Outlook, Teams).
**Why required:** The session-isolation test signs a user in to Outlook and Teams and requires a
working mailbox and chat. An unlicensed pilot user produces a false FAIL.
**How to verify:** Entra → **Users → (pilot user) → Licenses**; confirm the service plans for the apps
in the allowlist are **On**.
**How to implement if missing:** Assign the appropriate Microsoft 365 licence to the pilot users
before Testing §5.

## R3. Microsoft Entra ID tenant with the frontline staff present

**Description:** An Entra ID tenant containing accounts for every staff member who will use a Shared
iPad.
**Why required:** Federating ABM to Entra ID means the Managed Apple ID signs in with the Entra
account. No Entra account, no federated sign-in. It is also the source for the Apple ID
conflict-candidate list (`SHAREDIPAD-AppleIDConflict.ps1`).
**How to verify:** Entra → **Users**; confirm the frontline staff exist with correct, current UPNs and
mail addresses on the domain you intend to federate.
**How to implement if missing:** Create or synchronise the accounts before starting the reclamation
campaign — the campaign is built from this list.

## R4. Apple Business Manager (ABM) account

**Description:** An Apple Business Manager account for the organization, at `https://business.apple.com`.
**Why required:** ABM is what issues **Managed Apple IDs** and what holds the **ADE token**. Both are
mandatory for Shared iPad. There is no path to Shared iPad without ABM.
**How to verify:** Sign in to `https://business.apple.com` with an ABM administrator account and
confirm the organization is enrolled and active.
**How to implement if missing:** Enrol the organization in Apple Business Manager. **VERIFY WITH
APPLE** — the enrolment process, the roles required, and the verification Apple performs are Apple's
and change; follow Apple's current ABM documentation. This is typically a multi-day process involving
an organizational verification contact, so start it early.

## R5. Verified domain(s) in Apple Business Manager

**Description:** The email domain(s) on which you will issue Managed Apple IDs (e.g. `contoso.com`),
verified in ABM.
**Why required:** ABM will only issue Managed Apple IDs on a domain the organization has proven it
owns. Domain verification is also the entry point to Apple's **personal Apple ID conflict-resolution**
path (R11).
**How to verify:** In ABM, review the organization's domain settings and confirm the intended domain
shows as verified.
**How to implement if missing:** Verify the domain in ABM. **VERIFY WITH APPLE** — the exact ABM
navigation, the DNS record type/value Apple asks you to publish, and the timing are Apple's and change.
Follow Apple's current ABM documentation, then publish the record in your DNS (Cloudflare, Route 53,
or wherever the zone lives).

## R6. iPads present in Apple Business Manager (this constrains an existing fleet)

**Description:** Every iPad that will run Shared iPad must appear in **ABM → Devices**, either because
it was purchased through a reseller linked to your ABM organization, or because it was added by an
Apple-supported method.
**Why required:** **Shared iPad is only available on devices enrolled via Automated Device Enrollment
(ADE), and ADE is only available for devices that are in ABM.** This is the single hardest constraint
on an existing fleet.

> **Read this before you plan.** If your ~40 iPads were bought retail — from a store, from a
> non-linked online seller, or as a mixed bag over several years — **they are not in ABM and cannot be
> ADE-enrolled**, which means **they cannot run Shared iPad at all**, no matter what you configure in
> Intune. There is no Intune setting that fixes this. Your options are to bring them into ABM by an
> Apple-supported route, or to replace the ineligible devices with iPads purchased through an
> ABM-linked reseller. **VERIFY WITH APPLE** — which routes exist for adding already-owned devices to
> ABM, the eligibility rules, and any provisional/opt-out window are Apple's and change. Establish
> this **before** you promise the customer a date, because it determines whether the project is a
> configuration exercise or a hardware purchase.

**How to verify:** In ABM → **Devices**, search for the serial numbers of your existing iPads. Serials
that return no result are not in ABM. Run `SHAREDIPAD-Discovery.ps1` to export the Intune-side serial
inventory to compare against.
**How to implement if missing:** Link your reseller to ABM and have them add the devices they sold you;
or bring the devices in by Apple's current supported method; or purchase replacement iPads through an
ABM-linked reseller. **VERIFY WITH APPLE.**

## R7. Apple MDM Push certificate (APNs)

**Description:** A valid **Apple MDM Push certificate** uploaded to Intune.
**Why required:** Every iOS/iPadOS enrollment and all ongoing MDM communication runs over APNs. An
expired APNs certificate silently breaks the entire fleet.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; status shows
**Active** with a future expiry. `SHAREDIPAD-Discovery.ps1` reports the expiry date.
**How to implement if missing:** Create it (Implementation §Step 5) using a **company-owned Apple ID**
that you record and reuse every year. **Never use a staff member's personal Apple ID** — when they
leave, the certificate cannot be renewed and every managed device must be re-enrolled.

## R8. Automated Device Enrollment (ADE) token connected to Intune

**Description:** An **enrollment program token** downloaded from ABM and uploaded to Intune, linking
the two.
**Why required:** The ADE token is how Intune sees your ABM devices and how it delivers the enrollment
profile that **enables Shared iPad**. No token, no ADE, no Shared iPad.
**How to verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens**; a token is
listed with a **future** expiry, and opening it shows your iPad serials under **Devices**.
`SHAREDIPAD-Discovery.ps1` reports token presence and expiry.
**How to implement if missing:** Create the MDM server in ABM and upload the token to Intune
(Implementation §Step 6). **The token expires annually — put the renewal in the operational calendar.**
An expired token stops new enrollments dead.

## R9. Supervision

**Description:** The iPads must be **supervised**.
**Why required:** Supervision is what unlocks the deeper iPadOS restrictions the field lockdown relies
on (blocking the App Store, blocking account modification, blocking app install/removal). ADE
enrollment supervises the device.
**How to verify:** Intune → **Devices → All devices → (device) → Properties**; **Supervised = Yes**.
`SHAREDIPAD-Discovery.ps1` reports supervision per device.
**How to implement if missing:** Enrol through ADE with **Supervised** enabled in the enrollment
profile (Implementation §Step 7). A device that is not supervised must be wiped and re-enrolled.

## R10. A supported iPadOS version on every device

**Description:** A current, Apple-supported iPadOS release on each iPad, and hardware that Apple lists
as Shared iPad-capable.
**Why required:** Shared iPad has a minimum iPadOS version and a supported-hardware list. An iPad below
the floor, or a model Apple does not list, will not run Shared iPad regardless of your enrollment
profile.
**How to verify:** On the device, **Settings → General → About**; or Intune → **Devices → All devices**
(the OS version column). `SHAREDIPAD-Discovery.ps1` exports model + iPadOS version per device.
**How to implement if missing:** Update iPadOS before enrollment and set the floor in
`SHARED IPAD – Compliance – iPadOS`. **VERIFY WITH APPLE** — the current minimum iPadOS version for
Shared iPad and the supported iPad models are Apple's and change with each release. Check Apple's
current Shared iPad documentation; do not assume an older floor still applies.

## R11. Device storage sized for Shared iPad's per-user data

**Description:** Enough on-device storage for the number of users you expect to be resident on each
iPad simultaneously.
**Why required:** Under Shared iPad, **each signed-in user consumes storage on the device** for their
own data space. This is the requirement teams get wrong. Buy iPads sized for one user and put twelve
shift workers on them and you will get sign-in failures, aggressive eviction of users' data, and a
support queue.
**How to verify:** Intune → **Devices → (device) → Hardware** shows total and free storage. Compare
against Apple's published guidance for your intended user count.
**How to implement if missing:** Size or replace the hardware. **VERIFY WITH APPLE** — Apple publishes
current **minimum and recommended storage** for Shared iPad and a **maximum number of resident users**;
both have changed across iPadOS releases. **Get these figures from Apple's current Shared iPad
documentation before you specify or purchase hardware.** Getting this wrong is a hardware purchase, not
a reconfiguration.

## R12. Managed Apple IDs available for every Shared iPad user

**Description:** A **Managed Apple ID**, issued by ABM, for every staff member who will sign in to a
Shared iPad.
**Why required:** **Shared iPad sign-in is by Managed Apple ID.** It is the identity the OS uses to
create and separate the per-user data space. No Managed Apple ID, no Shared iPad session — the user
simply cannot sign in.
**How to verify:** In ABM → **Users**, confirm the pilot users hold Managed Apple IDs on your verified
domain. Run `SHAREDIPAD-AppleIDConflict.ps1` to produce the Entra-side candidate list to reconcile
against.
**How to implement if missing:** Create Managed Apple IDs in ABM — manually, by federation (R13), or by
the account auto-provisioning covered in the catalog's *Implement Entra ID Integration with ABM for
Account Auto Provisioning for Microsoft Intune* solution. **R14 is a gate on this** — a conflicted
address will not issue.

## R13. ABM federated to Microsoft Entra ID *(strongly recommended)*

**Description:** ABM federation configured against Microsoft Entra ID, so Managed Apple ID sign-in
authenticates against the staff member's normal Entra credentials.
**Why required:** Without federation, every staff member gets a **second, separate password** for their
Managed Apple ID. On a frontline team that shares devices across shifts, a second password is a support
burden and a security regression (it gets written on the rack). Federation also means disabling the
Entra account disables Shared iPad access.
**How to verify:** In ABM, review the organization's federated-authentication settings and confirm the
Entra ID connection is active for your verified domain; then sign a pilot user in to a Shared iPad and
confirm they are prompted by the Microsoft sign-in page.
**How to implement if missing:** Configure ABM federation to Entra ID (Implementation §Step 4).
**VERIFY WITH APPLE AND MICROSOFT** — the ABM federation flow, the ABM navigation, the Entra
consent/permissions it requests, the behaviour for accounts that already exist, and the handling of
domains with existing Apple IDs are Apple's and Microsoft's, and they change. **Follow Apple's current
ABM federation documentation for the exact steps.** This solution covers the concept, the sequencing,
and the decision points.

## R14. Personal Apple ID conflicts resolved — **this is a prerequisite, not a step**

**Description:** No staff member who needs a Managed Apple ID may have a **personal Apple ID** already
using that work email address.
**Why required:** **ABM cannot issue a Managed Apple ID at an address that is already in use by a
personal Apple ID.** Every conflicted staff member is a blocked Shared iPad user. On a fleet where
staff historically tied their org email to a personal Apple ID, this is the largest single blocker in
the project, and it is not solved in Intune.
**How to verify:**
1. Run `SHAREDIPAD-AppleIDConflict.ps1` to build the **candidate** worklist from Entra ID — every user
   whose work address would need a Managed Apple ID and therefore *may* collide. **The script cannot
   query Apple.** It produces a planning and tracking list.
2. Get the **authoritative** list from **Apple Business Manager** — ABM is the only source that knows
   which addresses actually conflict. Reconcile the two.
**How to implement if missing:** Run the reclamation campaign (Implementation §Step 3). Apple provides
a supported conflict-resolution path built around domain verification, in which affected personal Apple
IDs must be changed to a personal email address (or are otherwise captured by Apple's process).
**VERIFY WITH APPLE** — the flow names, the ABM navigation, the notification wording Apple sends, the
grace period Apple allows, and the outcome for users who do not act are **all Apple's and all change**.
**Get them from current Apple Business Manager documentation before you communicate any date to staff.**

> **Scope warning — this reaches beyond the iPads.** A staff member's personal Apple ID carries their
> personal iPhone, their home Mac, their iCloud photo library, and their App Store purchases. Resolving
> the conflict touches all of it. This requires executive sponsorship and a real communications plan
> with a grace period — not a technical push.

> **This is a decision for the customer, not for you.** Whether to require staff to rename or
> surrender a personal Apple ID tied to their work address is an **identity, HR, legal, and
> communications decision**. Present the options and the impact to the customer's **HR, legal, and
> identity owners** and let them decide. Do not make the call, and do not let it be made by default by
> the person running the script.

## R15. Administrative roles

**Description:** **Intune Administrator** (or Global Administrator for connector/federation setup) in
Microsoft, **plus** an **Administrator** role in Apple Business Manager.
**Why required:** The ADE token exchange, federation, and enrollment profile creation all require
elevated rights on **both** sides. A project stalls fast when the person with Intune rights has no ABM
account.
**How to verify:** Entra → **Roles and administrators** → confirm **Intune Administrator**. In ABM →
review the account's role.
**How to implement if missing:** Assign **Intune Administrator** in Entra; have the ABM organization
owner grant the appropriate ABM role. **Identify a named ABM administrator on the customer side before
you start** — this is a common project stall.

## R16. Network access to Apple and Microsoft endpoints

**Description:** Outbound HTTPS from the field network to **Apple's** device-management, activation,
and Managed Apple ID sign-in endpoints **and** Microsoft's Entra/Intune/Microsoft 365 service URLs.
**Why required:** ADE enrollment contacts Apple at Setup Assistant; Managed Apple ID sign-in and
per-user data setup contact Apple on every shift change; policy sync and Microsoft 365 contact
Microsoft. A proxy that blocks Apple's endpoints produces an iPad that will not enrol and sign-ins that
hang — and it looks exactly like a policy problem.
**How to verify:** From a device on the field Wi-Fi, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`. For Apple, confirm the endpoints Apple publishes for
enterprise networks are reachable.
**How to implement if missing:** Allow Microsoft's published Office 365/Intune URL & IP ranges and
Apple's published enterprise network requirements through the proxy/firewall. **VERIFY WITH APPLE** —
Apple's published network requirements list for enterprise/education device management changes; use
Apple's current list rather than an older allowlist.

## R17. Wi-Fi coverage across the field working area

**Description:** Reliable Wi-Fi wherever a shift starts and ends.
**Why required:** A Shared iPad user sign-in and sign-out are **network operations** — the device
authenticates and syncs the user's data space. A user signing in at a dead spot in the yard gets a
failure that looks like a Managed Apple ID problem.
**How to verify:** Walk the shift-handover locations with a device and confirm signal and successful
sign-in.
**How to implement if missing:** Fix coverage at the handover points at minimum, or designate a
handover station with known-good coverage and put it in the shift runbook (Testing §5).

## R18. Executive sponsorship and a communications plan for the reclamation campaign

**Description:** A named executive sponsor and an agreed communications plan before the Apple ID
reclamation campaign starts.
**Why required:** You are about to ask staff to change something on their **personal** devices. Without
sponsorship and clear comms, the campaign produces a helpdesk flood, a union conversation, or a stalled
project — and the technical work sits idle waiting for it.
**How to verify:** A named sponsor, agreed messaging, an agreed grace period, and an agreed support
path exist in writing before the first notification is sent.
**How to implement if missing:** Escalate. **Do not start the reclamation campaign without it.** This
is a genuine prerequisite, and it is the one most often skipped.

---

## Requirements checklist

Run `SHAREDIPAD-Discovery.ps1` for the Microsoft-side items; confirm the Apple-side items in ABM.

| # | Requirement | Blocking? |
|---|---|---|
| R1 | Intune licensing | Yes |
| R2 | Microsoft 365 licensing for the field workload | Yes (for the validation test) |
| R3 | Entra ID tenant with frontline staff | Yes |
| R4 | Apple Business Manager account | Yes |
| R5 | Verified domain in ABM | Yes |
| R6 | iPads present in ABM | **Yes — determines feasibility** |
| R7 | Apple MDM Push certificate | Yes |
| R8 | ADE token connected to Intune | Yes |
| R9 | Supervision | Yes |
| R10 | Supported iPadOS version + model | Yes |
| R11 | Storage sized for per-user data | Yes |
| R12 | Managed Apple IDs for every user | Yes |
| R13 | ABM federated to Entra ID | Strongly recommended |
| R14 | Personal Apple ID conflicts resolved | **Yes — the gate** |
| R15 | Admin roles in Intune *and* ABM | Yes |
| R16 | Network access to Apple + Microsoft | Yes |
| R17 | Wi-Fi at the handover points | Yes |
| R18 | Sponsorship + comms plan | **Yes — for R14** |


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level on the marketplace so individual
solution listings stay small. Confirm these are in place before deploying *any* Intune solution.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, enrollment, and security policies.
**Verify:** `https://intune.microsoft.com` loads and **Tenant administration → Tenant status** shows an active subscription.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies, enrollment connectors, and configuration profiles requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or Global Administrator for connector setup).
**Implement:** Assign **Intune Administrator** to the operator; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable in Intune.
**Why:** Policies only reach enrolled (or app-managed) devices, regardless of platform.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Configure the appropriate enrollment method for the platform and ownership model, then enroll the device.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported, current operating system
**Description:** A supported OS baseline with current updates for the targeted platform.
**Why:** Modern Intune features and security settings assume a patched, vendor-supported OS.
**Verify:** Check the device's OS version or Intune → device → **Hardware**.
**Implement:** Deploy update policies or upgrade to a supported release.

## G7. Network access to required cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — Shared iPad for Frontline Teams

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**.

**The design:** iPads enrolled through **Automated Device Enrollment (ADE)** from **Apple Business
Manager**, **supervised**, with **Shared iPad enabled in the enrollment profile**; each staff member
signs in with a **Managed Apple ID** federated to Microsoft Entra ID; the device is locked to the field
workload. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

**Consoles used:**
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Apple-portal steps carry a VERIFY WITH APPLE flag.** Apple changes ABM's navigation, flow names,
> and mechanics without notice. Where you see the flag, this guide gives you **what to do and why, and
> the decision you must make** — get the **exact current clicks** from Apple's live ABM documentation.
> Do not follow a screenshot from an older project.

> **Objects created by this solution** — reuse these names **verbatim** everywhere:
>
> | Object | Type | Where |
> |---|---|---|
> | `PILOT – Shared iPad Users` | Entra security group (Assigned, **users**) | Step 1 |
> | `SHARED IPAD – FMD – Pilot` | Entra security group (Assigned, **devices**) | Step 2 |
> | `SHARED IPAD – FMD – Production` | Entra security group (Assigned, **devices**) | Step 2 |
> | `SHARED IPAD – ADE Profile – Shared` | Intune ADE enrollment profile | Step 7 |
> | `SHARED IPAD – Restrictions – Field Lockdown` | Intune device configuration profile | Step 9 |
> | `SHARED IPAD – Compliance – iPadOS` | Intune compliance policy | Step 10 |
> | `SHARED IPAD – Apps – Field Allowlist` | Intune app assignments (the app set) | Step 11 |

---

## Phase 1 — Assess & prepare identity

### Step 1. Create the pilot user group

1. Go to `https://entra.microsoft.com` → **Identity → Groups → All groups → New group**.
2. **Group type:** `Security`. **Group name:** **`PILOT – Shared iPad Users`**.
3. **Membership type:** `Assigned`.
4. **Members → No members selected** → add the **two** real staff members who will run the
   session-isolation test (Testing §5). You need exactly two humans, not one — the test is A-then-B.
5. Click **Create**.

### Step 2. Create the device groups

1. Entra → **Identity → Groups → All groups → New group**.
2. **Group type:** `Security`. **Group name:** **`SHARED IPAD – FMD – Pilot`**.
3. **Membership type:** `Assigned`. Click **Create**.
4. Repeat and create a second group named **`SHARED IPAD – FMD – Production`**, also **`Assigned`**.

> **Both groups must be `Assigned`, never `Dynamic`.** These groups target devices **at enrollment**
> (no user affinity is involved at the device layer under Shared iPad), and enrollment-time device
> grouping only works against an **Assigned** group. Continue to Step 2b.

### Step 2b. Add the Intune Provisioning Client as an owner of each device group

*(Do this for **both** `SHARED IPAD – FMD – Pilot` and `SHARED IPAD – FMD – Production`.)*

1. Entra → **Identity → Groups → All groups →** open **`SHARED IPAD – FMD – Pilot`**.
2. Select **Owners → Add owners**.
3. In the search box, paste the **AppId** **`f1346770-5b25-470b-88bd-d5744ab7952c`**. Select the
   result and click **Select**.
   - **Search by the AppId, not by the display name.** The display name varies by tenant — many
     tenants show it as **`Intune Autopilot ConfidentialClient`**, others show something else.
   - **If the principal does not appear:** open the Intune portal (`https://intune.microsoft.com`)
     once as a **Global Administrator** to provision it into the tenant, then repeat this step.
4. Confirm the principal is now listed under **Owners**.
5. **Repeat steps 1–4 for `SHARED IPAD – FMD – Production`.**

> **Verify this owner is present before every pilot and every expansion wave.** Enrollment-time device
> grouping works by this principal *owning* the Assigned group. Without the owner, the group stays
> **empty at enrollment** and **nothing deploys** — no restrictions, no compliance, no apps — and the
> failure looks exactly like a policy problem.

### Step 3. Resolve the personal Apple ID conflicts — **THIS IS A GATE**

**Do not proceed past this step for a given user until their conflict is resolved.** A conflicted
address cannot be issued a Managed Apple ID, and a user without a Managed Apple ID cannot sign in to a
Shared iPad. You can configure everything downstream, but you cannot pilot.

**3a. Build the candidate worklist (Microsoft side, read-only).**
1. On an admin workstation, run:
   ```
   .\SHAREDIPAD-AppleIDConflict.ps1 -GroupName 'PILOT – Shared iPad Users' -CsvPath .\appleid-candidates.csv
   ```
2. This exports every user whose work address would need a Managed Apple ID and therefore **may**
   collide with a personal Apple ID. **It cannot query Apple.** It is your planning and tracking list.
3. For the pilot, scope it to `PILOT – Shared iPad Users`. For the campaign, re-run it across the full
   frontline population.

**3b. Get the authoritative conflict list (Apple side).**
1. Sign in to `https://business.apple.com` as an ABM administrator.
2. Confirm your domain (e.g. `contoso.com`) is **verified** (Requirements R5). Domain verification is
   what gives you visibility of, and a path to resolve, personal Apple IDs on your domain.
3. Use ABM's conflict-resolution capability to obtain the list of addresses on your verified domain
   that are already in use by a **personal** Apple ID.
4. Reconcile against `appleid-candidates.csv` from 3a. **ABM is the truth. The CSV is the tracker.**

> **VERIFY WITH APPLE.** Apple's domain-verification and conflict-resolution capability, its exact
> name, where it appears in ABM, what it reports, what notification Apple sends the affected user, the
> **grace period** Apple allows, and **what happens to a user who does not act within it** are **all
> Apple's and all subject to change**. **Get every one of these specifics from current Apple Business
> Manager documentation before you plan dates or write a word of user communication.** This guide gives
> you the concept and the sequence, deliberately and on purpose — an invented timeline here would
> become a broken promise to staff.

**3c. Make the decision — escalate it, do not make it.**

The concept is: affected staff must **change their personal Apple ID to a personal email address**, so
the work address is released and ABM can issue a Managed Apple ID on it. That request reaches the
staff member's **personal iPhone, personal Mac, iCloud photo library, and App Store purchase history**.

**This is an identity, HR, legal, and communications decision. It is not yours.**

1. Present to the customer's **HR, legal, and identity owners**:
   - **Option 1 — Mandate.** All affected staff must move their personal Apple ID to a personal address
     within an agreed window. *Impact:* fastest path to Shared iPad; touches personal devices and
     personal data; needs HR/legal sign-off and probably a consultation process; will generate
     helpdesk volume and some genuine upset.
   - **Option 2 — Voluntary with a deadline.** Staff are asked to move, with support, ahead of an
     announced date after which Apple's process applies. *Impact:* better received; slower; leaves a
     tail of non-responders you must still handle.
   - **Option 3 — Scope down.** Issue Managed Apple IDs only to staff with no conflict, and defer or
     exclude the rest. *Impact:* no personal-device impact for the excluded; those staff cannot use a
     Shared iPad, so the fleet is only partly usable and you carry two operating models.
   - **Option 4 — Alternative addressing.** Issue Managed Apple IDs on a **different verified
     subdomain** the staff member has never used personally (e.g. `staff.contoso.com`). *Impact:* may
     sidestep many conflicts entirely; adds a second domain to verify and federate, and a second
     address for staff to understand. **VERIFY WITH APPLE** that this fits your ABM/federation
     configuration before proposing it as a solution — it is a genuine option worth raising, not a
     guaranteed escape.
2. **Record their decision in writing.** Then execute it.
3. **Do not send a single staff notification until Requirement R18 is satisfied** — a named executive
   sponsor, agreed messaging, an agreed grace period, and an agreed support path.

**3d. Run the campaign and track it.**
1. Send the agreed communication to the affected staff, with the support path.
2. Track each user's state in `appleid-candidates.csv` (the script emits a `Status` column for this).
3. Re-check ABM as staff act; a released address becomes eligible for a Managed Apple ID.
4. **Gate:** your two `PILOT – Shared iPad Users` must be **clear of conflict** before Step 12. If they
   are not, the pilot cannot run — pick two clear users or resolve theirs first.

### Step 4. Federate ABM to Microsoft Entra ID

1. Sign in to `https://business.apple.com` as an ABM administrator.
2. Configure **federated authentication** against **Microsoft Entra ID** for your verified domain
   (e.g. `contoso.com`).
3. Complete the Microsoft-side consent when ABM redirects you — sign in with a **Global
   Administrator** and grant the requested permissions.
4. Confirm ABM shows federation as active for the domain.

> **VERIFY WITH APPLE AND MICROSOFT.** The ABM navigation for federation, the flow name, the exact
> Microsoft permissions requested, how ABM handles a domain that still contains unresolved personal
> Apple IDs, and the behaviour for accounts that already have a Managed Apple ID are **Apple's and
> Microsoft's, and they change**. **Follow Apple's current ABM federation documentation for the exact
> steps.**

> **Sequencing matters:** federate **after** Step 3 has cleared conflicts on the domain, or at minimum
> after you understand which addresses are conflicted. Federating a domain full of unresolved personal
> Apple IDs is how a project acquires a surprise.

> **Related catalog solution:** if you want Managed Apple IDs created automatically from Entra ID
> rather than by hand, see *Implement Entra ID Integration with ABM for Account Auto Provisioning for
> Microsoft Intune*. It covers the provisioning of accounts into ABM; it does not cover Shared iPad.

---

## Phase 2 — Configure the Apple connection

### Step 5. Create the Apple MDM Push (APNs) certificate

*(Skip if Intune already shows an **Active** certificate with a future expiry — do **not** create a
second one, it will break your existing fleet.)*

1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, then **Download your CSR**.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`.
4. Sign in with a **company-owned Apple ID**. **Record this Apple ID** — you must reuse the exact same
   one to renew every year. Never use a staff member's personal Apple ID.
5. **Create a Certificate**, upload the CSR, then **Download** the `.pem`.
6. Back in Intune, enter the **Apple ID** you used, **Browse** to the `.pem`, and click **Upload**.
7. Confirm the status reads **Active** with an expiry ~1 year out. Put the renewal in the operational
   calendar.

### Step 6. Connect Apple Business Manager (upload the ADE token)

1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → Add**.
2. Check **I agree**, then **Download your public key** (the `.pem`).
3. Go to `https://business.apple.com` and create a new **MDM server** entry; **name it
   `Intune – Shared iPad`**; upload the Intune public key; save it; then **download the token**
   (`.p7m`). **VERIFY WITH APPLE** — the ABM navigation to MDM server management changes; get the
   current path from Apple's ABM documentation.
4. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, and click **Upload**.
5. Confirm the token appears under **Enrollment program tokens** with a **future** expiry.
   **This token expires annually — calendar the renewal now.**

### Step 7. Create the ADE enrollment profile with **Shared iPad enabled**

**This is the step that delivers session isolation. Everything else is supporting work.**

1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens**.
2. **Open the token** you uploaded in Step 6 (click its name — you must drill into the token; the
   Profiles tab does not exist anywhere else).
3. Select **Profiles → Create profile → iOS/iPadOS**.
4. **Name:** **`SHARED IPAD – ADE Profile – Shared`**. **Description:** `Shared iPad, supervised,
   field frontline fleet.`
5. **Platform:** confirm **iOS/iPadOS**. Click **Next**.
6. On the **Management settings** page:
   - **User Affinity:** select **`Enroll with user affinity`**, then select **`Shared iPad`** as the
     enrollment mode. *(Shared iPad is presented under the user-affinity choice — it is a multi-user
     model, so it is not "without user affinity". If you cannot see the Shared iPad option, the token
     or the platform selection is wrong; see Troubleshooting §6.)*
   - **Maximum number of cached users** (or the equivalent resident-user setting): set it to the
     number of shift users you need resident on the device. **VERIFY WITH APPLE** — the maximum Apple
     supports, and the storage each resident user consumes, are Apple's published figures and they
     change; confirm against Apple's current Shared iPad documentation and against Requirement R11
     **before** you set this. Setting it above what the hardware can carry produces sign-in failures,
     not a warning.
   - **Supervised:** **`Yes`**. *(Required — Requirement R9.)*
   - **Locked enrollment:** **`Yes`**. *(Users cannot remove management. Essential for a field fleet.)*
7. Click **Next** to the **Setup Assistant customization** page. Hide every pane the field team does
   not need — **Restore**, **Apple ID** *(the Managed Apple ID sign-in is the Shared iPad sign-in
   screen, not this pane)*, **Siri**, **Privacy**, **Screen Time**, **App Analytics**, **Terms and
   conditions**, **Display Zoom** — so the iPad comes up straight at the Shared iPad sign-in screen.
8. Click **Next → Review + Create → Create**.
9. Confirm the profile appears in the token's **Profiles** list.

### Step 8. Assign the iPads and the profile

1. In **ABM → Devices**, select the iPad **serial numbers** for the pilot.
2. Assign them to the MDM server **`Intune – Shared iPad`** (Step 6), and confirm. **VERIFY WITH
   APPLE** — the ABM device-assignment navigation changes; get the current path from Apple's docs.
3. In Intune, open the token → **Devices** → click **Sync**. **Apple rate-limits this sync** — allow
   several minutes and do not click it repeatedly.
4. When the serials appear, select them → **Assign profile** → choose **`SHARED IPAD – ADE Profile –
   Shared`** → confirm.
5. Verify each serial's **Profile status** shows the assignment.

> **Devices that do not appear here are not in ABM** and cannot be ADE-enrolled — see Requirements R6
> and Troubleshooting §6. This is where an existing retail-bought fleet reveals itself. Establish the
> real number now, before you commit to a rollout date.

---

## Phase 3 — Configure the device

### Step 9. Create the field lockdown restrictions profile

1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** `iOS/iPadOS`. **Profile type:** `Templates` → **`Device restrictions`** → **Create**.
3. **Name:** **`SHARED IPAD – Restrictions – Field Lockdown`**. **Description:** `Field frontline
   Shared iPad lockdown.` Click **Next**.
4. On the **Configuration settings** page, set the following. *(Each of these applies **only** to a
   supervised device — Requirement R9. On an unsupervised iPad most of them are silently ignored, which
   is a common source of "restrictions not applying" — see Troubleshooting §6.)*

   **App Store, Doc Viewing, Gaming**
   - **App Store:** **`Block`** — staff cannot browse or install personal apps.
   - **Installing apps:** **`Block`**.
   - **Removing apps:** **`Block`** — staff cannot uninstall the CMMS app.
   - **In-app purchases:** **`Block`**.
   - **Explicit content in media:** **`Block`**.

   **Built-in apps**
   - **Safari:** **`Block`** *(unless the CMMS or schematics workflow needs the browser — confirm with
     the field team before blocking; a blocked Safari that the CMMS app relies on for SSO breaks the
     workload).*
   - **Camera:** **`Allow`** — the field team photographs assets. This is part of the workload.
   - **FaceTime:** **`Block`**.
   - **Apple Music / Podcasts / News / Game Center:** **`Block`**.

   **Cloud and storage**
   - **Backup to iCloud:** **`Block`**.
   - **iCloud Photo Library / iCloud Drive:** **`Block`** *(prevents field photos leaving to a personal
     library).*
   - **Managed apps syncing to cloud:** **`Block`**.

   **Connected devices and sharing**
   - **AirDrop:** **`Block`** — a shared field device should not be a data-exfiltration path.
   - **Bluetooth modification:** **`Block`** *(unless the field workload pairs a Bluetooth accessory —
     confirm first).*
   - **Pairing with a host computer / Apple Configurator:** restrict per your management model.

   **Accounts and identity — this is the group that matters most**
   - **Account modification:** **`Block`** — **staff cannot add personal accounts to the device.** This
     is the setting that stops a shift worker signing their personal Apple ID or personal mail into the
     field iPad.
   - **Modifying the passcode:** **`Block`**.
   - **Modifying the device name:** **`Block`**.
   - **Erase all content and settings:** **`Block`**.
   - **Modifying restrictions:** **`Block`**.

   **Keyboard and dictation**
   - **Predictive keyboard / auto-fill:** **`Block`** — reduces cross-shift leakage of typed identity
     and text into shared keyboard state.

5. Click **Next** through **Scope tags**.
6. On **Assignments**, click **Add groups** and select **`SHARED IPAD – FMD – Pilot`**. Click **Next**.
   *(Add `SHARED IPAD – FMD – Production` at Expand, Step 14 — not now.)*
7. **Review + create → Create**.

> **App allowlisting vs app blocking — which to use.** A **blocklist** ("hidden apps") names the apps
> to remove and lets everything else through — it fails the moment a new app exists. An **allowlist**
> ("allowed apps") names the apps permitted and hides everything else — it is the correct model for a
> locked-down field device and it is what this solution uses (Step 11). **The restrictions profile
> above blocks the *capabilities*; the allowlist controls the *app inventory*.** You need both:
> restrictions stop the App Store and account modification; the allowlist decides what is on the home
> screen. Do not try to do the job with only one of them.

### Step 10. Create the compliance policy

1. Intune → **Devices → Compliance → Create policy**.
2. **Platform:** `iOS/iPadOS` → **Create**.
3. **Name:** **`SHARED IPAD – Compliance – iPadOS`**. Click **Next**.
4. **Compliance settings:**
   - **Device Health → Jailbroken devices:** **`Block`**.
   - **Device Properties → Minimum OS version:** set your supported floor. **VERIFY WITH APPLE** — set
     this to the current Shared iPad minimum from Apple's documentation (Requirement R10), not a
     remembered number.
   - **System Security → Require a password to unlock mobile devices:** set per the customer's policy
     for a shared field device. *(Under Shared iPad each user authenticates at sign-in; discuss the
     device-passcode requirement with the customer's security owner rather than assuming.)*
5. Click **Next**. On **Actions for noncompliance**, keep the default **Mark device noncompliant →
   Immediately**.
6. **Assignments → Add groups →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
7. **Review + create → Create**.

### Step 11. Deploy the field app allowlist

**`SHARED IPAD – Apps – Field Allowlist`** is the app set below. Deploy each app as **Required** to
**`SHARED IPAD – FMD – Pilot`**, then hide everything else.

**11a. Add each app.**

For each app in the field workload:
1. Intune → **Apps → All apps → Add**.
2. **App type:** **`iOS/iPadOS store app`** *(or **`iOS/iPadOS volume purchased program app`** if you
   license it through ABM — VPP is preferred for a fleet, since it does not depend on a user's App
   Store identity, which a Shared iPad does not have).*
3. **Search the App Store** and select the app.

   > **Identify every app by its exact publisher string and bundle ID — never by name alone.** App
   > Store search returns multiple near-identical results, and deploying the wrong one to 40 locked
   > devices is a re-staging exercise. Record the exact publisher and bundle ID for each app in your
   > build sheet before you search:
   >
   > | App | Publisher (exact string) | Bundle ID | Notes |
   > |---|---|---|---|
   > | Your CMMS app | *(from the vendor — confirm in writing)* | *(from the vendor)* | Confirm the vendor supports **Shared iPad**. Ask explicitly; do not assume. |
   > | Schematics / document viewer | *(from the vendor)* | *(from the vendor)* | Must render your drawing formats offline. |
   > | Microsoft Outlook | `Microsoft Corporation` | `com.microsoft.Office.Outlook` | Not "Outlook Lite", not a third-party mail client. |
   > | Microsoft Teams | `Microsoft Corporation` | `com.microsoft.skype.teams` | Not "Teams for Life" / personal Teams. |
   > | Microsoft Authenticator | `Microsoft Corporation` | `com.microsoft.azureauthenticator` | Required if you later layer Option B (SDM broker) — see the note below. |
   >
   > **Get the CMMS and viewer publisher/bundle ID from the vendor in writing.** Do not guess them
   > from search results.

4. Click **Select** → **Next** through the app information.
5. **Assignments → Required → Add group →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
6. **Review + create → Create**.
7. Repeat for every app in the table.

**11b. Restrict the home screen to the allowlist.**
1. Intune → **Devices → Configuration → Create → New policy** → **`iOS/iPadOS`** → `Templates` →
   **`Device restrictions`** → **Create**.
2. **Name:** **`SHARED IPAD – Apps – Field Allowlist`**. Click **Next**.
3. Find the **Show or hide apps** settings group.
4. Select the **allowlist** control (**`Allowed apps`** / "Apps visible") — **not** the hidden-apps
   blocklist.
5. Add **each** app by its **bundle ID** from the table in 11a, **plus** the system apps the workload
   genuinely needs (Camera; Settings only if the field team must join Wi-Fi themselves — otherwise
   leave it out). Everything not listed is hidden.
6. **Assignments → Add groups →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
7. **Review + create → Create**.

> **Do not lock the iPad to a single app.** Single-app (kiosk) mode is the right answer for a
> single-purpose appliance and the **wrong** answer here — this fleet runs a CMMS app **and** a viewer
> **and** the camera **and** Microsoft 365, and each shift user needs to reach the Shared iPad sign-out
> control. Use the **allowlist**, which is a lockdown that still permits the workload.

> **If you are layering Option B (Microsoft 365 Shared Device Mode) on top of Shared iPad:** SDM
> requires the **Microsoft Authenticator** broker and per-app configuration, and it only affects apps
> that **participate** in SDM. **The set of Microsoft apps supporting shared device mode on
> iOS/iPadOS changes over time — verify the current supported-app list against Microsoft's
> documentation before designing around it.** This solution does not assert that list. Deploy and
> validate **Option A (Shared iPad) first**; it is what delivers the OS-level isolation the test in
> §5 measures. Layer SDM afterwards, and re-run the §5 test after you do.

---

## Phase 4 — Pilot

### Step 12. Wipe and enroll the pilot iPad

> **Gate check before you touch a device:** the two members of `PILOT – Shared iPad Users` hold
> **Managed Apple IDs** and are **clear of Apple ID conflict** (Step 3). If not, stop — the pilot will
> fail at sign-in and you will spend a day debugging a policy that is fine.

1. On the pilot iPad, back up anything the field team needs off it. **This step erases the device.**
2. **Settings → General → Transfer or Reset iPad → Erase All Content and Settings.** Confirm.
3. The iPad restarts into **Setup Assistant**. Choose language and region, and connect to the field
   Wi-Fi (Requirement R17 — use a location with known-good signal).
4. Setup Assistant displays **Remote Management** naming your organization. Continue.
5. The iPad enrolls, supervises, and lands on the **Shared iPad sign-in screen** asking for a **Managed
   Apple ID**.
   - **If it lands on a normal personal-iPad home screen instead, it is not in Shared iPad mode.** Stop
     and go to Troubleshooting §6 — this is the #1 failure and the entire solution depends on getting
     it right. Do not proceed and do not "fix it later".
6. In Intune → **Devices → All devices**, confirm the iPad appears; open it → **Properties** and
   confirm **Supervised = `Yes`** and the enrollment profile is **`SHARED IPAD – ADE Profile –
   Shared`**.
7. Confirm the device is now a member of **`SHARED IPAD – FMD – Pilot`**. *(If the group is empty, the
   Step 2b owner is missing — go to Troubleshooting §6.)*
8. Allow the device to sync. Confirm the restrictions, compliance, and the allowlist apps arrive.

### Step 13. Run the validation gate

1. Run **`SHAREDIPAD-Validate.ps1`** and confirm an overall **PASS**.
2. **Run the session-isolation A/B test in Testing §5 with two real humans.** That test — not the
   script — is the acceptance gate for this project. It is what the customer is buying.
3. **Do not proceed to Step 14 until the session-isolation test PASSES.** Expanding a broken isolation
   model across 40 devices means wiping 40 devices twice.

---

## Phase 5 — Expand

### Step 14. Stage the fleet

1. **Confirm the eligible device count first.** In ABM → **Devices**, confirm **every** iPad serial in
   the fleet is present. Serials that are absent are **not in ABM**, cannot be ADE-enrolled, and
   **cannot run Shared iPad** (Requirement R6). Establish this number before you schedule anything —
   it is the difference between a configuration project and a hardware purchase.
2. **Confirm storage eligibility.** Run `SHAREDIPAD-Report.ps1` and check the model and storage
   columns against Apple's current guidance for your resident-user count (Requirement R11). Under-specced
   iPads must be re-sized or excluded — not hoped over.
3. **Assign the remaining eligible serials** to the `Intune – Shared iPad` MDM server in ABM, then in
   Intune assign them the **`SHARED IPAD – ADE Profile – Shared`** profile (Step 8). *(Alternatively,
   set it as the token's **default** profile so newly added serials inherit it automatically.)*
4. **Extend the policy assignments to production.** For each of **`SHARED IPAD – Restrictions – Field
   Lockdown`**, **`SHARED IPAD – Compliance – iPadOS`**, **`SHARED IPAD – Apps – Field Allowlist`**,
   and each app in the allowlist: open it → **Properties → Assignments → Edit → Add groups →**
   **`SHARED IPAD – FMD – Production`** → **Review + save**.
5. **Verify the Step 2b owner is on `SHARED IPAD – FMD – Production`** before the first wave enrolls.
   Check it; do not assume it carried over.
6. **Stage in waves, not in one weekend.** Wipe and re-enroll in batches of 8–10 (Step 12) so a shift
   is never without devices. After each wave, run `SHAREDIPAD-Validate.ps1` and spot-check the
   session-isolation test on one device from the wave **before** starting the next.
7. **Brief the field team** on the shift-handover runbook (Testing §5) before their devices are staged.
   A user who does not know to sign out is the one operational gap Shared iPad still leaves you.
8. Run `SHAREDIPAD-Report.ps1` after the final wave and keep the CSV as the as-built record.


---


# 5. Testing & Validation — Shared iPad for Frontline Teams

This section is the point of the whole project. Everything in Implementation §3 exists so that
**Test 5 — the session-isolation A/B test** passes. Run it with two real humans on a real pilot iPad
before a single production device is staged.

Each test has an explicit **PASS / FAIL** gate. A FAIL is not a warning — it is a stop.

---

## Test 1 — Tenant and Apple readiness

**Procedure:** Run `SHAREDIPAD-Discovery.ps1`.

**PASS:** The Apple MDM Push certificate is **Active** with a future expiry; an **ADE token** is
present with a future expiry; an enrollment profile **`SHARED IPAD – ADE Profile – Shared`** exists and
**Shared iPad is enabled** on it; **`SHARED IPAD – FMD – Pilot`** and **`SHARED IPAD – FMD –
Production`** exist; **`SHARED IPAD – Restrictions – Field Lockdown`** and **`SHARED IPAD – Compliance
– iPadOS`** exist; the allowlist apps are present.

**FAIL:** Any item missing → resolve it before piloting (Requirements §2, Implementation §3).

## Test 2 — Enrollment-time grouping owner

**Procedure:** Entra → **Groups → `SHARED IPAD – FMD – Pilot` → Owners**. Repeat for
**`SHARED IPAD – FMD – Production`**.

**PASS:** The Intune Provisioning Client service principal — matched by **AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`**, not by display name — is listed as an **Owner** of **both**
groups, and both groups are **Assigned** (not Dynamic).

**FAIL:** Missing owner, or a Dynamic group → Implementation §3 Step 2b. **The group will stay empty at
enrollment and nothing will deploy.** Verify this before every wave.

## Test 3 — The pilot iPad is actually in Shared iPad mode

**This is the test that predicts Test 5.** If this fails, Test 5 will fail, and you will waste an hour
looking at Outlook.

**Procedure:**
1. On the enrolled pilot iPad, observe the screen it lands on after Setup Assistant.
2. In Intune → **Devices → All devices → (the pilot iPad) → Properties**.
3. Run `SHAREDIPAD-Validate.ps1`.

**PASS:** The device presents a **Shared iPad sign-in screen requesting a Managed Apple ID** — *not* a
normal iPad home screen. In Intune, **Supervised = `Yes`**, the enrollment profile is
**`SHARED IPAD – ADE Profile – Shared`**, and the device is enrolled via **ADE**. The device is a member
of **`SHARED IPAD – FMD – Pilot`**.

**FAIL:** The device shows a normal home screen, or **Supervised = `No`**, or the device did not enroll
via ADE → **the device is not in Shared iPad mode**. Go to Troubleshooting §6 — this is the #1 cause of
the session leak, and no amount of app configuration will fix it. The device must be wiped and
re-enrolled once the enrollment profile is correct.

## Test 4 — Managed Apple ID sign-in works

**Procedure:** On the pilot iPad's Shared iPad sign-in screen, have **User A** (a member of
`PILOT – Shared iPad Users`) sign in with their **Managed Apple ID**.

**PASS:** User A signs in. With federation (Requirement R13) they are prompted by the **Microsoft**
sign-in page and use their normal work credentials. The device sets up their data space and lands on the
home screen showing **only** the `SHARED IPAD – Apps – Field Allowlist` apps.

**FAIL:** Sign-in is rejected → the Managed Apple ID does not exist, or the address is still conflicted
by a personal Apple ID (Requirement R14 / Implementation §3 Step 3). Sign-in hangs → check network
(R16) and Wi-Fi at this location (R17). Sign-in reports the device is full → storage (R11). See
Troubleshooting §6.

---

## Test 5 — **THE SESSION-ISOLATION A/B TEST** *(the acceptance gate)*

**This is the test the customer is buying. It is the reason the project exists.** Run it with **two
real people**, on a **real pilot iPad**, in the **field Wi-Fi environment**. Do not simulate it, do not
run it with one person signing in twice, and do not sign the assessment off without it.

**You need:** the pilot iPad (Test 3 PASSED), **User A** and **User B** — two different members of
`PILOT – Shared iPad Users`, both with working mailboxes (Requirement R2) and Managed Apple IDs
(Test 4 PASSED).

### Part 1 — User A creates a session with real data

1. **User A** signs in to the iPad with their **Managed Apple ID**.
2. Open **Microsoft Outlook**. Sign in if prompted. Wait for the mailbox to sync.
3. **Send an email** from User A to themselves with the subject **`ISOLATION TEST A`**. Confirm it
   arrives in their inbox. *(Now there is unmistakable, identifiable data on the device.)*
4. Open **Microsoft Teams**. Sign in if prompted. **Send a chat message** to a colleague containing the
   text **`ISOLATION TEST A`**. Confirm it appears in the chat list.
5. Open the **Camera** and **take a photo** of something identifiable. Confirm it appears in Photos.
6. Open the **CMMS app**. Sign in and open any work order. *(This is your real workload — test it.)*
7. Open the **schematics / document viewer** and open a drawing.
8. **User A signs out of the Shared iPad session** — use the Shared iPad sign-out control (the user
   picker / Sign Out), **not** the app-level sign-out inside Outlook. *(App-level sign-out is exactly
   the thing that does not work. Test the real mechanism.)*
9. Confirm the device returns to the **Shared iPad sign-in screen**.

### Part 2 — User B signs in on the SAME device

**User B now signs in on the same physical iPad and must observe *nothing* of User A's.**

Check each of the following. **Every single one must pass.**

| # | Check | **PASS** | **FAIL** |
|---|---|---|---|
| 5.1 | **Outlook mailbox** — open Outlook | Outlook prompts for sign-in, **or** opens **User B's** mailbox. There is **no** mailbox belonging to User A. | User A's mailbox is present. |
| 5.2 | **Cached mail** — search for `ISOLATION TEST A` in Outlook | **Zero results.** The message does not exist on this device for User B. | The message is visible or cached. |
| 5.3 | **Teams chat** — open Teams | Teams prompts for sign-in, **or** opens **User B's** chats. `ISOLATION TEST A` is **not** present. | User A's chat history is visible. |
| 5.4 | **Photos** — open Photos / Camera roll | **Empty**, or contains only User B's own photos. User A's photo is **not** present. | User A's photo is visible. |
| 5.5 | **Identity autofill** — open Outlook / Teams / the CMMS sign-in and tap the username field | No suggestion of **User A's** address. The field is empty or offers only User B's. | User A's address is offered by autofill or is pre-filled. |
| 5.6 | **Signed-in state** — check every app in the allowlist, including the **CMMS app** and the **viewer** | **Nothing** is silently signed in as User A. Each app is signed out or signed in as User B. | Any app opens already signed in as User A. |
| 5.7 | **Files / documents** — open the viewer's recent documents and the Files app | No document User A opened is present or accessible to User B. | User A's documents are listed or openable. |
| 5.8 | **Safari** *(only if Safari is allowed in your build)* — open it and check history and autofill | No history or saved identity from User A's session. | User A's browsing state persists. |

### The verdict

- **PASS = every one of 5.1 through 5.8 passes.** Not most. Every one. A single leak means the
  architecture is not delivering isolation, and one leaked mailbox is the whole problem you were
  hired to fix.
- **Now reverse it.** Sign User B out, sign **User A** back in, and confirm A gets **their own** data
  back (their mail, their photo) and **none** of B's. Isolation must work in both directions —
  a device that gives everyone a blank slate but loses each user's own data is also broken.

### What a FAIL means — read this before you debug

**A FAIL is almost never an app problem.** Diagnose in this order:

| Symptom | Which architecture step is wrong | Fix |
|---|---|---|
| **Everything leaks** — mail, photos, chat, all of it | **The device is not in Shared iPad mode.** It is a single-user iPad being handed between people — the original problem, unchanged. This is the #1 cause. | Re-run **Test 3**. Check the device is **ADE-enrolled**, **Supervised = Yes**, and the enrollment profile is `SHARED IPAD – ADE Profile – Shared` **with Shared iPad enabled** (Implementation §3 Step 7). Wipe and re-enroll (Step 12). |
| **The device never asked for a Managed Apple ID** — it went to a home screen | Same as above — Shared iPad was never enabled, or the device did not enroll via ADE. | Implementation §3 Steps 7–8, then Step 12. Confirm the serial is in ABM (R6). |
| **Photos leak but mail is clean** | The device **is** in Shared iPad mode, but something outside the per-user data space is being written — or you are looking at an app that stores outside it. | Confirm iCloud Photo Library is **Blocked** (Step 9) and re-test. Escalate to the app vendor if it persists. |
| **Only the CMMS app leaks** — Microsoft apps are clean | **The CMMS app is not honouring the Shared iPad user boundary.** Shared iPad is working; that one app is not designed for it. | Take it to the vendor with this test as evidence. Ask explicitly whether the app supports **Apple Shared iPad**. This is a vendor gap, not a configuration gap — and you cannot configure around it. |
| **Only Microsoft apps leak** — photos and files are clean | Shared iPad is working at the OS layer. This is unexpected and is worth a support case. | Re-verify Test 3, then raise it with Microsoft. Do **not** reach for Shared Device Mode as a patch until you understand why — layering B on a broken A hides the real fault. |
| **User B sees a sign-in prompt but User A's address is pre-filled** | Keyboard/autofill state, not session state. Minor but real — it is a data disclosure. | Confirm **predictive keyboard / auto-fill** is **Blocked** in `SHARED IPAD – Restrictions – Field Lockdown` (Step 9) and re-test. |

---

## Test 6 — Field lockdown is enforced

**Procedure:** As User B, on the pilot iPad, attempt each of the following.

**PASS:** The **App Store** is not present and cannot be reached. Apps **cannot** be installed or
removed. **Adding an account** (personal Apple ID, personal mail) is **blocked**. **Erase All Content
and Settings** is unavailable. **AirDrop** is unavailable. Only the `SHARED IPAD – Apps – Field
Allowlist` apps appear on the home screen. **Camera works** (the field team needs it).

**FAIL:** Any restriction not enforced → confirm **Supervised = `Yes`** (Test 3 — unsupervised devices
silently ignore most of these), confirm the profile assignment to `SHARED IPAD – FMD – Pilot`, and
force a sync. See Troubleshooting §6.

## Test 7 — Compliance reports correctly

**Procedure:** Intune → **Devices → Compliance → `SHARED IPAD – Compliance – iPadOS` → Device status**.

**PASS:** The pilot iPad reports **Compliant** against the policy.

**FAIL:** Not evaluated → the device is not in `SHARED IPAD – FMD – Pilot` (Test 2). Non-compliant →
read the reason; a minimum-OS failure means the device needs an iPadOS update (R10).

## Test 8 — The field workload actually works

**Procedure:** As User B, complete a genuine shift task end-to-end: open a work order in the **CMMS
app**, open a **schematic** in the viewer, **take a photo** and attach it to the work order, and send a
**Teams** message about it.

**PASS:** The complete workload succeeds on a locked-down Shared iPad.

**FAIL:** A step is blocked → a restriction in `SHARED IPAD – Restrictions – Field Lockdown` is too
tight (Safari and Bluetooth are the usual culprits), or an app is missing from
`SHARED IPAD – Apps – Field Allowlist`. Fix and re-test — **and then re-run Test 5**, because loosening
a restriction can reopen a leak.

## Test 9 — Storage holds under multiple resident users

**Procedure:** Sign three or four different pilot users into the same iPad in sequence, each doing a
short real task. Then check Intune → **Devices → (device) → Hardware** for free storage, and run
`SHAREDIPAD-Report.ps1`.

**PASS:** All users sign in successfully and free storage remains healthy against Apple's current
guidance for your resident-user count.

**FAIL:** A sign-in fails for lack of space, or users are being evicted → the hardware is undersized
(Requirement R11) or the cached-user setting exceeds what the device can carry (Implementation §3 Step
7). **VERIFY WITH APPLE** — check the current storage and maximum-user guidance in Apple's Shared iPad
documentation. **Find this out at the pilot, not at device 30 of 40.**

---

## Acceptance gate

**Do not stage a single production device until:**

- Tests **1, 2, 3, 4** PASS *(the architecture is real)*
- Test **5** PASSES **completely — all of 5.1 to 5.8, in both directions** *(the leak is fixed — this
  is the gate)*
- Tests **6, 7, 8, 9** PASS *(the device is locked down, healthy, usable, and sized)*

If Test 5 fails, **nothing else matters**. Fix the architecture and re-run it.

---

## Shift-handover runbook — for the field team

Print this. Put it on the iPad rack. Brief the team before their devices are staged.

**Shared iPad gives you a clean device — but only after you sign out.** A user who walks away without
signing out leaves their session open on the rack for the next person to walk into.

### At the END of your shift
1. **Close what you are working on.** Save and submit any open work order in the CMMS app.
2. **Sign out of the iPad session.** Tap your name / user picker → **Sign Out**.
   - **This is not the same as signing out of Outlook.** Signing out of an app does not end your
     session. Use the **iPad's** sign-out.
3. **Wait for the sign-in screen to appear** before you put the iPad down. Sign-out has work to do —
   walking away mid-way can leave your session open.
4. **Return the iPad to the rack and put it on charge.** A dead iPad is an iPad the next shift cannot
   use.

### At the START of your shift
1. **Take any iPad from the rack.** They are interchangeable — you will get your own environment.
2. **Check the sign-in screen is showing.** If you see **someone else's** home screen or name, the
   previous user did not sign out — sign them out via the user picker, or report it. **Do not use the
   device inside their session.**
3. **Sign in with your work account** (your Managed Apple ID). You will get your own mail, your own
   photos, and your own work orders.
4. **Stand where the Wi-Fi is good** when you sign in. Sign-in needs the network.

### Report it if
- You sign in and see **anyone else's** mail, messages, photos, or work orders. **Report it
  immediately** — that is exactly what this system exists to prevent, and it means something is
  broken.
- The iPad says it is full, or will not let you sign in.
- Your own mail or photos are missing after you sign in.


---


# 6. Troubleshooting — Shared iPad for Frontline Teams

Symptom → cause → fix. Work top-down: the first entry is the cause of the overwhelming majority of
failures in this solution, and almost every other symptom in this section is a downstream consequence
of it.

---

## 1. "The next user still sees the prior user's mail" — **THE #1 CAUSE**

**Symptom:** User B signs in (or picks up the iPad) and sees User A's mailbox, Teams chat, photos, or
documents. Test 5 fails. This is the original problem, unchanged.

**Cause — in order of likelihood:**

### 1a. The device is not actually in Shared iPad mode *(the cause ~90% of the time)*

The iPad is a **single-user device being handed between people**. The OS has no per-user boundary, so
there is nothing to isolate. Everything you configured downstream is irrelevant — restrictions,
compliance, and app settings cannot create a session boundary that the OS does not have.

**Diagnose:**
1. **Look at the device.** After enrollment, does it present a **Shared iPad sign-in screen asking for
   a Managed Apple ID**? If it lands on a **normal iPad home screen**, it is **not** in Shared iPad
   mode. Stop here — this is your answer.
2. Intune → **Devices → All devices → (the iPad) → Properties**. Check:
   - **Supervised = `Yes`**? If `No`, the device did not go through ADE.
   - **Enrollment profile = `SHARED IPAD – ADE Profile – Shared`**?
   - **Enrollment type** — is it an Apple/ADE (DEP) enrollment type, or a manual/user enrollment?
3. Run `SHAREDIPAD-Validate.ps1`. Look specifically at **"Shared iPad ENABLED on that profile"**.
4. Run `SHAREDIPAD-Report.ps1` and check the device's **ProfileIsShared** and **SharedIPadReady**
   columns.

**Fix — depending on what you found:**

| What you found | What it means | Fix |
|---|---|---|
| The enrollment profile does **not** have Shared iPad enabled | The profile is wrong. Every device enrolled with it is single-user. | Fix the profile (Implementation §3 Step 7), **then wipe and re-enroll every affected device** (Step 12). Changing the profile does **not** convert already-enrolled devices. |
| The profile is correct but the device didn't get it | The serial was never assigned the profile. | Assign it on the token (Step 8), then **wipe and re-enroll** the device (Step 12). |
| **Supervised = `No`** / the device enrolled manually | The device never went through ADE. | **Wipe and re-enroll via ADE** (Step 12). There is no in-place conversion — you cannot make an enrolled iPad supervised or Shared without erasing it. |
| The serial isn't on the ADE token at all | The device is not in ABM. | See §6 below. This may be a procurement problem. |

> **The critical fact: you cannot convert a device into Shared iPad mode in place.** Shared iPad is
> established **at enrollment**. Fixing the profile and waiting for a policy sync does nothing. The
> device must be **erased and re-enrolled** through ADE. If you take one thing from this section, take
> this.

### 1b. The device *is* in Shared iPad mode, but users aren't signing out

**Diagnose:** Watch a real handover. Does the outgoing user use the **iPad's** sign-out (the user
picker → Sign Out), or do they just put the iPad down? Does the device show the sign-in screen when
it's on the rack, or someone's home screen?

**Fix:** Brief the field team on the shift-handover runbook (Testing §5) and put it on the rack. Shared
iPad gives a clean device **after** sign-out. A user who walks away leaves an open session — the one
gap the architecture does not close for you. Also confirm the handover point has good Wi-Fi (R17): a
sign-out attempted on a dead spot may not complete.

### 1c. It's one specific app leaking, not the device

**Diagnose:** Run the Test 5 checklist item by item. If Outlook, Teams, and Photos are clean and only
the **CMMS app** (or the viewer) leaks, Shared iPad is working — that app is not honouring the per-user
boundary.

**Fix:** This is a **vendor gap and you cannot configure around it**. Take the Test 5 results to the app
vendor as evidence and ask explicitly: *does this app support Apple Shared iPad?* Do not spend days in
Intune on it — there is no setting.

---

## 2. Managed Apple ID sign-in fails

**Symptom:** A user cannot sign in at the Shared iPad sign-in screen.

| Symptom detail | Cause | Fix |
|---|---|---|
| The account is not recognised / rejected | **The user has no Managed Apple ID.** Usually because their address is still conflicted by a personal Apple ID (R14). | Confirm in ABM → **Users** that the Managed Apple ID exists. If not, resolve the conflict (§3 below / Implementation Step 3). **This is a gate — pick a clear user for the pilot rather than fighting it mid-test.** |
| Sign-in hangs or times out | Network. Apple's endpoints are unreachable, or the Wi-Fi at this location is poor (R16/R17). | Test from the same spot: reach `https://login.microsoftonline.com`. Confirm Apple's published enterprise endpoints are allowed through the proxy. **VERIFY WITH APPLE** — use Apple's current published network requirements list, not an older allowlist. Retry at a known-good location to isolate it. |
| "Device is full" / sign-in refused for space | Storage (R11). See §7 below. | §7. |
| The wrong sign-in page appears, or none | Federation is not configured or not active for the domain. | §4 below. |
| Password rejected but the account exists | If **not** federated, the Managed Apple ID has its own separate password — the user is typing their work password. | Either federate (R13, Implementation Step 4) or issue the Managed Apple ID password. **Federate.** A second password on a shared frontline device ends up written on the rack. |

---

## 3. ABM says "address already in use" / the Managed Apple ID cannot be created

**Symptom:** ABM will not issue a Managed Apple ID at a staff member's work address.

**Cause:** **A personal Apple ID is already using that address.** ABM cannot issue a Managed Apple ID at
an address in use by a personal Apple ID. This is expected, it is Requirement R14, and it is the single
largest blocker in this project.

**Fix:**
1. Run `SHAREDIPAD-AppleIDConflict.ps1` to build the **candidate** worklist from Entra ID.
   **Remember what this list is and is not:** it tells you who *would need* a Managed Apple ID and at
   which address. **It cannot query Apple and cannot tell you which addresses actually conflict.**
2. **Get the authoritative conflict list from Apple Business Manager.** ABM is the only source that
   knows. Reconcile it into the CSV's `ABMConflict` column.
3. Resolve the conflicts via Apple's supported path, which is built around **verifying your domain** in
   ABM; affected personal Apple IDs must then be changed to a personal email address (or are otherwise
   handled by Apple's process).

> **VERIFY WITH APPLE.** The exact flow name, where it lives in ABM, what ABM reports, the notification
> Apple sends the affected user, the **grace period**, and **what happens to a user who does not act**
> are **all Apple's and all change**. **Get every one of these from current Apple Business Manager
> documentation before you plan a date or write user communications.** A wrong timeline here is a broken
> promise to staff.

> **Before you act on any of this:** whether to require staff to rename or surrender a personal Apple ID
> tied to their work address is an **identity, HR, legal, and communications decision** — it reaches
> their personal iPhone, personal Mac, iCloud photo library, and App Store purchases. **Present the
> options and their impact to the customer's HR, legal, and identity owners and let them decide**
> (Implementation Step 3c). Do not make the call. Do not send a staff notification without executive
> sponsorship and an agreed comms plan and grace period (R18).

**Tactical workarounds while the campaign runs:**
- **For the pilot:** pick two `PILOT – Shared iPad Users` who are **clear of conflict**. Do not burn the
  pilot on a blocked user — you will end up debugging a configuration that is fine.
- **Worth raising early:** issuing Managed Apple IDs on a **verified subdomain** the staff have never
  used personally (e.g. `staff.contoso.com`) may sidestep many conflicts entirely. **VERIFY WITH APPLE**
  that this fits your ABM and federation configuration before proposing it — but raise it *before* the
  campaign starts, because switching to it later is expensive.

---

## 4. Federation sign-in loop, or the Microsoft sign-in page never appears

**Symptom:** Signing in with a Managed Apple ID loops between Apple and Microsoft, returns to the
sign-in screen repeatedly, or never presents the Microsoft page at all.

**Cause / fix:**

| Cause | Fix |
|---|---|
| Federation is not active for that domain | In ABM, confirm federated authentication is configured **and active** for the exact domain of the address being used (e.g. `contoso.com`). |
| The address is on a domain you never federated | Users on a second domain or a subdomain need that domain verified and federated too. Check the exact address the user is typing. |
| The Entra account is disabled, blocked, or has no licence | Entra → **Users → (the user)**: account enabled, and licensed (R1/R2). A disabled account cannot complete federated sign-in. |
| Conditional Access is blocking the sign-in | Entra → **Sign-in logs**, filter to the user, and read the **Conditional Access** tab. A CA policy requiring a compliant device can block the sign-in that is *establishing* the session on that device. Move the offending policy to **report-only** to confirm, then fix the policy — do not leave it off. |
| The Microsoft consent was never completed | Re-run the ABM federation setup and complete the Microsoft-side consent as a **Global Administrator** (Implementation Step 4). |
| The user still has an unresolved personal Apple ID at that address | Federation does not resolve conflicts. §3 above. |

> **VERIFY WITH APPLE AND MICROSOFT.** The ABM federation flow, its navigation, the exact Microsoft
> permissions requested, how ABM behaves for a domain with unresolved personal Apple IDs, and the
> handling of pre-existing accounts are **Apple's and Microsoft's and they change**. Follow Apple's
> **current** ABM federation documentation rather than a remembered flow.

---

## 5. Restrictions not applying / the App Store is still there

**Symptom:** `SHARED IPAD – Restrictions – Field Lockdown` shows as assigned, but the device still has
the App Store, still allows adding accounts, or still allows app removal.

| Cause | Diagnose | Fix |
|---|---|---|
| **The device is not supervised** *(the usual cause)* | Intune → **Devices → (device) → Properties → Supervised**. | Most of these restrictions **only apply to supervised devices** and are **silently ignored** on an unsupervised one. **Wipe and re-enroll via ADE** with Supervised enabled (Steps 7, 12). No in-place fix exists. |
| The device isn't in the group | Intune → **Devices → (device) → Group membership**; or run `SHAREDIPAD-Validate.ps1`. | If the group is **empty**, go to §8 — the Provisioning Client owner is missing. |
| The profile isn't assigned to *this* group | `SHAREDIPAD-Validate.ps1` reports assignment per group. Common at Expand: assigned to Pilot, forgotten for Production. | Add the assignment (Step 14), or run `SHAREDIPAD-Set-Restrictions.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Production' -WhatIf:$false`. |
| Not synced yet | Intune → **Devices → (device) → Sync**; check the profile's **Device status**. | Allow time and re-check. Policy delivery is not instant. |
| Profile shows **Error** or **Conflict** | Open the profile → **Device status** → the device → read the per-setting result. | A **Conflict** means another profile sets the same setting differently. Find the other profile and resolve it — the device does not pick a winner for you. |
| Camera/Safari blocked and the workload broke | The lockdown is too tight. | Loosen the specific setting (Step 9), **then re-run Test 5** — loosening a restriction can reopen a leak. |

---

## 6. The device won't ADE-enroll / the serial isn't on the token

**Symptom:** Setup Assistant never shows **Remote Management**; the iPad comes up as a normal personal
device; or the serial does not appear under the ADE token in Intune.

| Cause | Diagnose | Fix |
|---|---|---|
| **The device is not in Apple Business Manager** *(the most common, and the most expensive)* | ABM → **Devices** → search the serial. No result = not in ABM. | **A device not in ABM cannot be ADE-enrolled and therefore CANNOT run Shared iPad** (R6). There is no Intune setting that fixes this. Either bring it into ABM by an Apple-supported route, or replace it with an iPad purchased through an ABM-linked reseller. **VERIFY WITH APPLE** — the routes for adding already-owned devices, the eligibility rules, and any provisional window are Apple's and change. **Establish this across the whole fleet in the Assess phase** — it decides whether this is a configuration project or a hardware purchase. |
| The serial isn't assigned to the MDM server | ABM → **Devices** → check the serial's assigned MDM server. | Assign it to **`Intune – Shared iPad`**, then **Sync** in Intune (Step 8). |
| Assigned in ABM but not visible in Intune | Intune → token → **Devices** → **Sync**. | Apple **rate-limits** this sync. Wait several minutes. **Do not click Sync repeatedly** — it will not go faster. |
| The serial has no enrollment profile assigned | Intune → token → **Devices** → check the **Profile status** column. | Select the serials → **Assign profile** → `SHARED IPAD – ADE Profile – Shared` (Step 8). |
| The device was already set up | It went past Setup Assistant. | **Erase All Content and Settings** (Step 12) so it returns to Setup Assistant. |
| The ADE token has expired | `SHAREDIPAD-Discovery.ps1` reports the expiry. | **The token expires annually.** Renew it in ABM and re-upload (Step 6). An expired token stops all new enrollments. Calendar it. |
| The APNs certificate has expired | `SHAREDIPAD-Discovery.ps1` reports the expiry. | Renew it **with the same company Apple ID** you originally used (Step 5). A new Apple ID means re-enrolling every managed device in the tenant. |
| Enrollment restrictions block iOS/iPadOS | Intune → **Devices → Enrollment → Enrollment device platform restrictions**. | Allow iOS/iPadOS for the target scope. |

**The Shared iPad option is missing from the enrollment profile:** confirm you are creating an
**iOS/iPadOS** profile, and that you drilled into the **ADE token** first (**Devices → Enrollment →
Apple → Enrollment program tokens → (open the token) → Profiles → Create profile → iOS/iPadOS**). The
Profiles tab does not exist anywhere else in the console, and Shared iPad appears under the
**user-affinity** choice on the Management settings page — it is a multi-user model, so it is not under
"enroll without user affinity". **VERIFY WITH APPLE AND MICROSOFT** — the console layout for this page
changes.

---

## 7. Storage full / a user can't sign in for lack of space

**Symptom:** A user cannot sign in and the device reports it is full; or users' data is being evicted
and they have to re-download everything each shift; or later users in a shift cycle fail while early
ones succeed.

**Cause:** **Each resident user consumes storage on the device.** The device is either undersized, or
the enrollment profile's **maximum cached users** is set higher than the hardware can carry. This is
the constraint teams underestimate, and it typically appears at wave 3, not at the pilot.

**Diagnose:**
1. Intune → **Devices → (device) → Hardware** — total and free storage.
2. Run `SHAREDIPAD-Report.ps1` and review the `StorageGB` / `FreeGB` / `FreePercent` columns across the
   fleet. Look for a pattern, not a single device.
3. Check the **maximum cached users** on `SHARED IPAD – ADE Profile – Shared` (Step 7).

**Fix:**
- **Reduce the maximum cached users** to what the hardware can genuinely carry, and re-enroll the
  affected devices for the new value to take effect at enrollment.
- **Or re-size the hardware.** Under-specced iPads are a procurement problem, not a configuration one.
- **VERIFY WITH APPLE** — Apple publishes the **current minimum and recommended storage** for Shared
  iPad and the **maximum number of resident users**, and both have changed across iPadOS releases. **Get
  the figures from Apple's current Shared iPad documentation.** Do not use a number from an older
  deployment; do not use a number from this document — it deliberately does not give you one.
- **Run Test 9 at the pilot**, with three or four users on one device. Finding this at device 4 of 40 is
  a conversation. Finding it at device 34 is a re-procurement.

---

## 8. The device group is empty after enrollment / nothing deploys

**Symptom:** iPads enroll successfully, but `SHARED IPAD – FMD – Pilot` (or `– Production`) is empty.
No restrictions, no compliance, no apps arrive. Everything in the console looks correctly configured.

**Cause:** **The Intune Provisioning Client service principal is not an Owner of the group**, or the
group is **Dynamic** instead of Assigned.

Enrollment-time device grouping works by that first-party principal **owning** the Assigned group.
Without the owner, nothing is ever added to the group — and because every policy is assigned to the
group, nothing deploys. **This failure looks exactly like a policy problem and is not one.**

**Diagnose:**
1. Entra → **Groups → `SHARED IPAD – FMD – Pilot` → Owners**.
2. Run `SHAREDIPAD-Validate.ps1` — it checks this explicitly and matches by AppId.

**Fix:**
1. Confirm the group's membership type is **Assigned**, **not Dynamic**. If it is Dynamic, this
   mechanism does not apply at all — recreate it as Assigned (Step 2).
2. Entra → **Groups → (the group) → Owners → Add owners**, and search by **AppId
   `f1346770-5b25-470b-88bd-d5744ab7952c`**.
   - **Search by the AppId, not the display name.** The display name varies by tenant — many show
     **`Intune Autopilot ConfidentialClient`**, others show something else. Matching on the display name
     is how people conclude the principal "isn't there" when it is.
   - **If the principal genuinely isn't present:** open `https://intune.microsoft.com` once as a
     **Global Administrator** to provision it into the tenant, then add it as owner.
3. **Verify the owner on `SHARED IPAD – FMD – Production` too**, before the first expansion wave. Do not
   assume it carried over from the pilot group — it does not.
4. Re-enroll a test device to confirm it now lands in the group.

**Verify this before every pilot and every wave.** It is one click to check and a lost afternoon to
diagnose.

---

## 9. An app isn't available or misbehaves under Shared iPad

**Symptom:** An app in `SHARED IPAD – Apps – Field Allowlist` doesn't install, doesn't appear, or
behaves oddly — won't stay signed in, loses data between sessions, or leaks between users.

| Symptom | Cause | Fix |
|---|---|---|
| App never installs | Not assigned **Required** to the device's group; or not synced. | Confirm the Required assignment to the correct group (Step 11a) and sync. `SHAREDIPAD-Validate.ps1` checks this. |
| App installs but isn't on the home screen | It's not in the **allowlist** (`SHARED IPAD – Apps – Field Allowlist`, Step 11b) — the allowlist hides everything it doesn't name. | Add the app's **bundle ID** to the allowlist. |
| **The wrong app** installed | Selected by name from App Store search. Search returns near-identical results. | Remove it and re-add by the **exact publisher string and bundle ID** (Step 11a). Get the CMMS/viewer publisher and bundle ID **from the vendor, in writing**. |
| App won't install on a Shared iPad specifically | A store app may depend on an App Store identity that a Shared iPad does not have. | Re-add it as a **volume purchased (VPP/ABM)** app and license it **by device**. This is the preferred model for a fleet. |
| App loses the user's data between their own sessions | The app isn't storing data in the per-user space. | Vendor issue. Raise it with the vendor. |
| **The app leaks data between users** | **The app is not honouring the Shared iPad user boundary.** | **Vendor gap — you cannot configure around it.** Take the Test 5 evidence to the vendor and ask explicitly whether the app supports **Apple Shared iPad**. Do not burn days in Intune. |
| A Microsoft app behaves unexpectedly | Possible, and unexpected if Shared iPad is working. | Re-verify Test 3 first. Then raise a Microsoft support case. **Do not reach for Shared Device Mode as a patch** until you understand why — layering B on a broken A hides the real fault. |

> **If you are layering Option B (Microsoft 365 Shared Device Mode):** it requires the **Microsoft
> Authenticator** broker and per-app configuration, and it affects **only apps that participate in
> SDM**. **The set of Microsoft apps supporting shared device mode on iOS/iPadOS changes over time —
> verify the current supported-app list against Microsoft's documentation before designing around it.**
> This solution does not assert that list, and neither should you. An app that does not participate is
> simply unaffected by SDM — that is not a bug, and no amount of configuration will change it.

---

## 10. Compliance shows Not evaluated / the device is Not compliant

| Symptom | Cause | Fix |
|---|---|---|
| **Not evaluated** | The device isn't in the group the policy is assigned to. | §8, then confirm the assignment (Step 10). |
| **Not compliant — minimum OS** | iPadOS is below the floor set in `SHARED IPAD – Compliance – iPadOS`. | Update iPadOS (R10). If the floor itself is wrong, **VERIFY WITH APPLE** the current Shared iPad minimum and correct the policy — don't lower the floor to make a red dashboard green. |
| **Not compliant — jailbreak** | Detected or falsely detected. | Investigate. On a supervised, ADE-enrolled, locked-down field iPad, a genuine jailbreak is a serious finding — treat it as one. |
| **Not compliant — passcode** | The policy requires a passcode the shared-use model doesn't set. | Discuss with the customer's security owner. Under Shared iPad each user authenticates at sign-in; decide the device-passcode requirement deliberately (Step 10) rather than by default. |
| Compliance grace period masking failures | The policy's noncompliance action is delayed. | Set **Mark device noncompliant → Immediately** for a field fleet so you see reality. |

---

## 11. The scripts

| Symptom | Cause | Fix |
|---|---|---|
| `Connect-MgGraph` fails or scopes are refused | The signed-in account lacks the rights, or admin consent hasn't been granted for the scope. | Sign in as **Intune Administrator** (or Global Administrator). Each script's header lists its exact **Required Graph scopes** — grant those, no more. |
| **"Group not found"** / **"profile not found"** for an object you can see in the portal | **The scripts match on EXACT display name, and the object names use an en dash (–), not a hyphen (-).** They look nearly identical and are different characters. | Copy the name **verbatim** from this guide, or pass it with the `-DeviceGroupName` / `-ProfileName` parameter. Do not retype the dash. This is the single most common script failure. |
| "Found N objects named X" | A duplicate object exists. | Resolve the duplicate in the portal. The scripts deliberately refuse to guess which one you meant. |
| `SHAREDIPAD-Set-Restrictions.ps1` reports what it would do but changes nothing | **Working as designed — it defaults to `-WhatIf`.** | Read the dry-run output, then re-run with **`-WhatIf:$false`** to apply. That explicit step is the point. |
| `SHAREDIPAD-Validate.ps1` says PASS but Test 5 still fails | **Expected and important.** A PASS proves the **architecture** is configured. It cannot prove sessions are isolated. | Go to §1. The session-isolation A/B test (Testing §5) is the only real gate. Never sign a project off on the script alone. |
| `SHAREDIPAD-AppleIDConflict.ps1` shows every user as "UNKNOWN" conflict | **Working as designed. The script cannot query Apple.** | It builds the **candidate** list from Entra. **The authoritative conflict list comes from Apple Business Manager.** Fill the `ABMConflict` column from ABM. Never present the script's output to a customer as a conflict list. |
| "Specify a scope" error from `SHAREDIPAD-AppleIDConflict.ps1` | Deliberate — it refuses to run unscoped across a whole tenant. | Pass `-GroupName 'PILOT – Shared iPad Users'` or `-Domain 'contoso.com'`. An unscoped worklist is one nobody can action. |
| Shared iPad state reports "unknown" / a property looks absent | The Graph property naming for Shared iPad on the ADE enrollment profile has varied across API versions. The scripts check the known variants. | **Verify the true state in the portal**: Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles → `SHARED IPAD – ADE Profile – Shared`**. The portal is authoritative; treat a script "unknown" as *check by hand*, not as a failure. |
| Device counts don't match the portal | Graph paging, or a stale sync. | The scripts follow `@odata.nextLink` and page fully. If the numbers still differ, force a device sync and re-run. |
| Nothing returned for iPads | The filter looks for `operatingSystem eq 'iOS'` and a model containing "iPad" — correct for iPadOS, which Graph still reports as iOS. | If genuinely empty, no iPads are enrolled yet. Check Intune → **Devices → All devices**. |


---


# 7. Best Practices — Shared iPad for Frontline Teams

## Architecture

- **Fix the architecture, not the symptom.** Every hour spent tuning Outlook settings on a single-user
  iPad passed between shifts is an hour wasted. There is no app configuration that produces per-user
  data separation on a device that has no per-user boundary. Deploy Shared iPad, or accept a partial
  fix and say so.
- **Decide A vs B explicitly, in writing, with the customer.** Shared iPad (OS-level) and Microsoft 365
  Shared Device Mode (app-level) solve different amounts of the problem. Write the decision and its
  rationale down. A customer who thinks they bought OS-level isolation and got app-level isolation has
  a grievance you will be defending in six months.
- **Deploy Option A first, and validate it, before layering Option B.** Layering SDM on a broken Shared
  iPad deployment hides the real fault and makes the failure harder to diagnose. Get the session test
  passing on Shared iPad alone, then add SDM and re-run the test.
- **Never assert the Microsoft SDM supported-app list from memory.** It changes. Check Microsoft's
  current documentation each time you design around it. A design built on a stale list fails at
  validation, in front of the customer.
- **Never carry Apple's numbers forward from an old project.** The Shared iPad minimum iPadOS version,
  the storage minimums, and the maximum resident-user count change. Check Apple's current
  documentation every time. This is the single most common way an experienced engineer gets it wrong.

## The Apple ID reclamation campaign

- **Run the conflict discovery FIRST, before you promise a date.** The size of the conflict list
  determines the project timeline more than any technical task. Find out on day one, not week six.
- **Never let the technical team make the reclamation decision by default.** Asking staff to change a
  personal Apple ID reaches their personal iPhone, their family photos, and their App Store purchases.
  That is an HR, legal, and identity decision. Put the options in front of the customer's HR, legal,
  and identity owners, get the decision in writing, and then execute it. "The engineer ran a script and
  everyone got an email from Apple" is how a project becomes an incident.
- **Get executive sponsorship before the first notification goes out.** No sponsor, no comms plan, no
  agreed grace period → do not send anything. This is Requirement R18 and it is the one most often
  skipped.
- **Consider the subdomain option early.** Issuing Managed Apple IDs on a subdomain staff have never
  used personally (e.g. `staff.contoso.com`) may sidestep the conflict entirely and turn a
  personal-data confrontation into a non-event. **Verify with Apple** that it fits your ABM/federation
  design before proposing it — but raise it early, because it is much harder to switch to once the
  campaign has started.
- **Track the campaign in the CSV, not in someone's head.** `SHAREDIPAD-AppleIDConflict.ps1` emits
  tracking columns for a reason. A 40-person campaign with a tail of non-responders needs a list.
- **ABM is the truth; the script is the tracker.** Never present the script's candidate list to a
  customer as a conflict list. It is not one, and saying it is will cost you credibility when the
  numbers disagree with ABM.
- **Give staff a real support path, not just a deadline.** The people you are asking to change their
  Apple ID are field workers mid-shift. A deadline without help produces refusals.

## Devices and procurement

- **Establish ABM device eligibility before you scope the project.** Serials not in ABM cannot be
  ADE-enrolled and cannot run Shared iPad. On an inherited fleet bought piecemeal over years, this is
  frequently a procurement conversation, not a configuration one. Find out in the Assess phase.
- **Size storage for the resident-user count, and buy accordingly.** Under-specced iPads produce
  sign-in failures and user eviction at exactly the moment the fleet goes live. Storage is cheap at
  purchase and expensive at wave 4.
- **Set the maximum cached users to what the hardware can actually carry** — not to the number of staff
  on the roster. A device configured for more users than it can hold does not warn you; it fails.
- **Use VPP / ABM-licensed apps rather than store apps where you can.** A Shared iPad has no personal
  App Store identity; device-licensed apps sidestep a whole class of install failure.
- **Pilot the CMMS app before you commit the fleet.** Ask the vendor, in writing, whether the app
  supports Apple Shared iPad. If it does not honour the per-user boundary, you will find out at Test 5
  — and no Intune setting will fix it.

## Configuration

- **Use the allowlist, not a blocklist.** A blocklist of apps to hide is obsolete the moment a new app
  exists. Name what is permitted and hide the rest.
- **Do not lock to a single app.** Kiosk single-app mode is right for an appliance and wrong here — the
  field workload spans several apps and the user must be able to reach sign-out.
- **Block account modification.** It is the setting that stops a shift worker adding their personal
  Apple ID or personal mail to a field iPad, and it is the one people forget.
- **Block predictive keyboard and autofill.** Shared keyboard state leaks identity across shifts. It is
  a small setting and a real disclosure.
- **Keep Camera allowed.** It is part of the workload. Locking down the thing the field team actually
  needs is how a deployment gets worked around.
- **Confirm Safari with the field team before blocking it.** If the CMMS relies on the browser for SSO
  or for opening links, blocking Safari breaks the workload — and the failure will look like a CMMS
  problem.

## Naming and hygiene

- **Use the object names verbatim, everywhere.** `SHARED IPAD – FMD – Pilot`,
  `SHARED IPAD – FMD – Production`, `SHARED IPAD – ADE Profile – Shared`, `SHARED IPAD – Restrictions –
  Field Lockdown`, `SHARED IPAD – Compliance – iPadOS`, `SHARED IPAD – Apps – Field Allowlist`,
  `PILOT – Shared iPad Users`. The scripts match on exact display names, and the names use an **en dash
  (–)**, not a hyphen. A renamed object is an object the scripts cannot find and the next engineer
  cannot audit.
- **Keep Pilot and Production as separate groups permanently.** Do not collapse them after rollout.
  The next iPadOS change, the next app version, the next policy tweak all need somewhere safe to land
  first.
- **Use a company-owned Apple ID for the APNs certificate and record it.** A certificate created on a
  departed employee's personal Apple ID cannot be renewed, and the remedy is re-enrolling every managed
  device in the tenant.

## Operations

- **Calendar both annual expiries the day you create them** — the APNs certificate and the ADE token.
  An expired APNs certificate breaks the entire fleet's management silently. An expired ADE token stops
  every new enrollment.
- **Verify the Provisioning Client group owner before every wave.** It is one click to check and a lost
  afternoon to diagnose. The failure — an empty group and nothing deploying — looks exactly like a
  policy problem.
- **Stage in waves of 8–10, never in one weekend.** A shift without devices is a shift not working.
  Validate each wave before starting the next.
- **Spot-check the session-isolation test on one device per wave.** Not just wave 1. Configuration
  drifts, and the test is cheap.
- **Brief the field team before their devices are staged.** Shared iPad gives a clean device *after*
  sign-out. A user who does not know to sign out leaves an open session on the rack — the one
  operational gap the architecture does not close for you. Print the handover runbook (Testing §5) and
  put it on the rack.
- **Designate a handover station with known-good Wi-Fi.** Sign-in and sign-out are network operations.
  A sign-out attempted in a dead spot in the yard is a sign-out that may not complete.
- **Keep the `SHAREDIPAD-Report.ps1` CSV as the as-built record**, and re-run it periodically. It is
  your evidence that the fleet is still in the state you left it.

## Scripts

- **Run everything read-only first.** Four of the five scripts cannot change anything. The fifth
  defaults to `-WhatIf` and requires an explicit `-WhatIf:$false`. Read the dry-run output before you
  apply — that is what it is for.
- **Never present a script PASS as proof of session isolation.** `SHAREDIPAD-Validate.ps1` proves the
  architecture exists. Only the A/B test with two real humans proves the sessions are isolated. That
  distinction is the difference between a delivered project and a callback.
- **Scope `SHAREDIPAD-AppleIDConflict.ps1` to a group or domain.** An unscoped tenant-wide worklist is
  a list nobody can action.


---


# 8. Deliverables Summary — Shared iPad for Frontline Teams

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)

- **Executive Summary** — the business case in one page: the leak, the root cause, the A-vs-B decision,
  the Managed Apple ID blocker, and the outcome.
- **Solution Overview** — the root cause stated plainly (why a shared single-user iPad *cannot* isolate
  sessions), the two supported architectures with a side-by-side comparison and honest trade-offs, how
  this solution works, the Managed Apple ID reclamation workstream, benefits, limitations, the standard
  deployment model, and what the existing catalog already covers.
- **Requirements Guide** — 18 prerequisites, each with **Description · Why required · How to verify ·
  How to implement if missing**: Intune and Microsoft 365 licensing, Entra ID, Apple Business Manager,
  verified domains, **devices present in ABM** (the constraint that decides feasibility on an existing
  fleet), the Apple MDM push certificate, the ADE token, supervision, iPadOS version, **storage sizing
  for per-user data**, Managed Apple IDs, ABM↔Entra federation, **the personal Apple ID conflict as a
  gate**, admin roles on both sides, network, Wi-Fi at the handover points, and executive sponsorship.
  Plus the category-level **Global Requirements — Intune Solutions**.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: assess and prepare
  identity (groups, the enrollment-time grouping owner, **the Apple ID conflict-resolution gate**,
  federation); configure the Apple connection (APNs, ADE token, **the enrollment profile with Shared
  iPad enabled** — the step that delivers isolation, device assignment); configure the device
  (field lockdown restrictions, compliance, the app allowlist with exact publisher/bundle IDs); pilot
  (wipe and re-enroll, validation gate); and expand (fleet eligibility, staged waves).
- **Testing & Validation** — nine tests with explicit PASS/FAIL gates, built around **the
  session-isolation A/B test**: eight discrete checks (mailbox, cached mail, chat, photos, autofill,
  signed-in state, files, browser state) run with two real users on one device, in both directions,
  plus a diagnostic table mapping each failure back to the architecture step that caused it. Includes
  the **shift-handover runbook** for the field team.
- **Troubleshooting** — symptom → cause → fix, led by the #1 failure ("the next user still sees the
  prior user's mail"), plus Managed Apple ID sign-in, ABM conflicts, federation loops, ADE enrollment,
  storage, app behaviour under Shared iPad, restrictions, and the scripts.
- **Best Practices** — architecture discipline, running the reclamation campaign without causing an
  incident, procurement and sizing, configuration choices, naming hygiene, and operations.

## PowerShell scripts (Microsoft Graph) — `SHAREDIPAD-Scripts.zip`

All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK).
Each header states **Purpose · How to run · Required Graph scopes · Expected results**.
**Four of the five make no changes of any kind. The fifth defaults to `-WhatIf`.**

1. **`SHAREDIPAD-Discovery.ps1`** *(read-only)* — readiness discovery: the ADE/ABM token and its expiry,
   the Apple MDM push certificate and its expiry, every ADE enrollment profile **and whether Shared iPad
   is enabled on it**, the iPad inventory (model, storage, iPadOS, supervised, ADE state, ownership),
   and which of this solution's named objects exist.
2. **`SHAREDIPAD-Validate.ps1`** *(read-only)* — PASS/FAIL scoring against the success criteria: ADE
   token valid, a **Shared-iPad-enabled** profile exists and is assigned, the device group is Assigned
   and owned by the Intune Provisioning Client, pilot devices supervised and ADE-enrolled, restrictions
   and compliance assigned, app allowlist assigned. Prints a clear PASS/FAIL summary — and says plainly
   that a PASS proves the *architecture*, not the isolation.
3. **`SHAREDIPAD-Report.ps1`** *(read-only)* — fleet report: per-device Shared iPad readiness with the
   blocking reason, assigned ADE profile, supervision, storage, compliance, and last check-in, with CSV
   export. Use it to size the project and track waves.
4. **`SHAREDIPAD-AppleIDConflict.ps1`** *(read-only)* — builds the **Entra-side candidate worklist** of
   users who need a Managed Apple ID and may therefore collide with a personal Apple ID, as a CSV with
   tracking columns for the reclamation campaign. **It states clearly that it cannot query Apple — the
   authoritative conflict list comes from Apple Business Manager; this is the candidate/tracking list
   only.**
5. **`SHAREDIPAD-Set-Restrictions.ps1`** *(the only state-changing script)* — assigns and verifies the
   `SHARED IPAD – Restrictions – Field Lockdown` profile assignment, with a read-only pre-flight that
   checks the group is Assigned and owned by the Provisioning Client. **Defaults to `-WhatIf` and says
   so** — it changes nothing unless you pass `-WhatIf:$false` explicitly. It never removes an existing
   assignment.

## Objects this solution creates

| Object | Type |
|---|---|
| `PILOT – Shared iPad Users` | Entra security group (Assigned, users) |
| `SHARED IPAD – FMD – Pilot` | Entra security group (Assigned, devices) |
| `SHARED IPAD – FMD – Production` | Entra security group (Assigned, devices) |
| `SHARED IPAD – ADE Profile – Shared` | Intune ADE enrollment profile (Shared iPad enabled) |
| `SHARED IPAD – Restrictions – Field Lockdown` | Intune device configuration profile |
| `SHARED IPAD – Compliance – iPadOS` | Intune compliance policy |
| `SHARED IPAD – Apps – Field Allowlist` | Intune device configuration profile + the app assignments |

## Hero image

- **`SHAREDIPAD-hero.png`** — the product image (1200×1200) used on the listing.

## How it's delivered

A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## A note on vendor specifics

This guide deliberately **flags rather than asserts** anything that Apple or Microsoft controls and
changes: current Shared iPad prerequisites (iPadOS version, storage minimums, maximum resident users),
Apple Business Manager portal navigation and flow names, the domain-verification and Apple ID
conflict-resolution mechanics, ABM↔Entra federation specifics, and the Microsoft 365 Shared Device Mode
iOS supported-app list. Each carries an explicit **verify against current Apple/Microsoft documentation**
flag. The concepts, decision points, and sequencing are given confidently; the vendor-controlled
specifics are pointed at the vendor's live documentation — because you are following this click-by-click,
and a confidently-stated wrong number costs more than a flag.
