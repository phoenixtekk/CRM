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
