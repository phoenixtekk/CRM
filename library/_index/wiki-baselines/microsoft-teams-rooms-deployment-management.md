# Microsoft Teams Rooms Deployment & Management

> **Version 1.0.0** · Category: Teams · Solution code: TEAMSROOMS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Teams Rooms Deployment & Management

## The outcome

Meeting rooms that just work. Users walk into any room, see their meeting on the console, press **Join** once, and connect with reliable audio, video, and content sharing — because every room was provisioned, licensed, and configured to one documented standard, and is monitored and updated centrally. This solution delivers the complete Microsoft-side deployment and ongoing management of **Microsoft Teams Rooms**: resource-account creation and licensing, calendar-processing and room-policy configuration, onboarding to the **Teams Rooms Pro Management** portal for health and updates, peripheral/front-of-room standards, and pilot-room validation.

## The approach

A disciplined, repeatable method — **Assess → Design → Configure → Pilot → Validate → Expand** — that is **pilot-first**. One room is provisioned and configured to the standard, signed in, and used for real meetings against explicit pass/fail gates (books reliably, one-touch-joins, working media, healthy and managed centrally). Only after the pilot passes every gate is the identical, named configuration repeated across the fleet. Every object — the room's resource account, its meeting and calling policies, its Pro Management profile and update ring — is named to a consistent `<Purpose> – <Scope> – <Stage>` convention and reused verbatim, so the deployment is self-documenting, auditable, and reproducible.

## Why it is low-risk

- **Blast radius of one.** Configuring pilot-first means a mistake is contained to a single room, never the fleet.
- **Safe-by-default automation.** The included PowerShell tools are **read-only or dry-run by default** and require an explicit `-Commit` to change anything — no hardcoded credentials, modern-auth throughout.
- **Explicit gates and a documented rollback.** Nothing expands until the pilot passes measurable checks, and every uniquely named object makes rollback exact.
- **No invented vendor detail.** Microsoft admin-center paths and cmdlets are current and real; plan-, licensing-, and cloud-dependent items (Pro vs Basic, room caps, Government-cloud URLs) are flagged "verify in your tenant" rather than guessed. Certified-hardware internals are deferred to the OEM.

## What you receive

A complete implementation guide, a requirements checklist, testing and troubleshooting guides, durable best practices, and **five PowerShell tools** — discovery/assessment, resource-account create-and-configure, room-policy and calendar-processing configuration, health/inventory reporting, and readiness validation — so your team can deploy and operate every room to the same standard at a fraction of the cost and time of a consulting engagement.


---


# 1. Solution Overview — Microsoft Teams Rooms Deployment & Management

## What this solution delivers

This solution productizes the **Microsoft-side deployment and ongoing management of Microsoft Teams Rooms** — the certified in-room meeting systems that turn a physical meeting space into a one-touch-join Teams endpoint. It covers the full lifecycle a Teams administrator owns: creating and licensing each room's **resource account** (an Exchange Online room mailbox), configuring **calendar processing** so the room books and joins meetings correctly, applying the **Teams meeting and calling policies** a room should run under, onboarding devices to the **Teams Rooms Pro Management** portal for monitoring, health, and update management, setting **peripheral and front-of-room standards**, and validating a **pilot room** before expanding to the fleet.

The result is rooms that behave the same everywhere: a user walks up, sees their meeting on the console, presses **Join**, and the room connects with working audio, video, and content sharing — because every room was provisioned, licensed, and policy-configured to one documented standard, and is monitored centrally.

## What Teams Rooms is (and what this solution is not)

A **Microsoft Teams Room** is a certified hardware system (a compute unit plus a touch console, camera, and audio, on **Teams Rooms on Windows** or **Teams Rooms on Android**) signed into a dedicated **resource account**. That account is a **room mailbox** in Exchange Online, licensed for Teams Rooms, so the room appears in the address book, accepts meeting invitations, and shows the day's agenda on its console.

- **In scope (built and validated here):** the tenant-side objects and configuration — resource account creation, licensing (Teams Rooms Pro vs Basic), calendar processing, Teams meeting/calling policy assignment, Pro Management portal onboarding, monitoring and update management, peripheral standards, pilot validation, and repeatable PowerShell tooling.
- **Deferred to the hardware vendor's documentation (concept level):** the certified device's own physical setup and firmware — cabling, display/camera/microphone mounting, the OEM's out-of-box setup wizard, and vendor-specific settings. Certified hardware from any OEM is integrated at the pattern level; this solution specifies **what** the device account and configuration must satisfy, not the OEM's on-device menus.
- **Out of scope:** room audio-visual construction (in-wall cabling, acoustics, displays procurement), network cabling, and PSTN/voice dial-in build (Teams Phone is a separate engagement; this solution notes where a room needs it but does not build the voice routing stack).

## Licensing model (verify in your tenant)

Teams Rooms is licensed **per device/resource account**, in two tiers. The tier you assign changes what management you get, so confirm current entitlements in the Microsoft 365 admin center before you buy:

- **Teams Rooms Basic** — no-cost tier for a limited number of rooms (Microsoft documents a cap, commonly cited as up to 25 rooms per tenant — **verify the current cap in your tenant**). Delivers core one-touch join and meetings, with **limited** management and analytics.
- **Teams Rooms Pro** — paid per-room tier that unlocks the full **Teams Rooms Pro Management** service: proactive health monitoring, managed software/firmware updates, configuration profiles, remote actions, and advanced in-meeting experiences (for example intelligent camera and advanced layouts, several of which are plan-dependent). Rooms you intend to manage centrally at scale should be **Pro**.

> Commercial vs Government cloud: portal URLs differ in Government (GCC High / DoD) clouds (for example `*.office365.us`). Where this solution names a portal URL, it is the Commercial URL — **verify the correct URL for your cloud**.

## Reference design

The standard this solution builds toward:

1. **One resource account per room**, named to a convention, as a **room mailbox** in Exchange Online, with the password set **not to expire** and the account enabled (a room signs in unattended, so an expiring password takes the room offline).
2. **Calendar processing tuned for Teams Rooms** — the room auto-accepts valid invitations, **keeps the meeting subject and body** (so the join button and agenda render), does not add the organizer to the subject, and processes external invitations so cross-org meetings appear on the console.
3. **A dedicated Teams meeting policy and calling policy** applied to room accounts, so rooms get room-appropriate behavior (for example auto-admit, content sharing, and — where licensed — advanced in-meeting features) rather than inheriting an end-user policy.
4. **Teams Rooms Pro Management onboarding** for Pro rooms — devices enrolled to the Pro Management portal for health, update rings, and configuration profiles.
5. **A peripheral/front-of-room standard** — certified camera, microphone/soundbar, and front-of-room display selected from Microsoft's certified list and configured consistently.

## Object naming convention

Every object you create carries the pattern `<Purpose> – <Scope> – <Stage>` and is reused verbatim across the implementation, testing, troubleshooting, and scripts, so the deployment is self-documenting and auditable. The canonical names used throughout this solution:

| Object | Name | Example identifier |
| --- | --- | --- |
| Room resource account (pilot) | `Room Account – Boardroom-A – Pilot` | `room-boardroom-a@contoso.com` |
| Room resource account (prod) | `Room Account – <Room> – Prod` | `room-<room>@contoso.com` |
| Teams meeting policy for rooms | `Meeting Policy – Teams Rooms – Prod` | Teams admin center meeting policy |
| Teams calling policy for rooms | `Calling Policy – Teams Rooms – Prod` | Teams admin center calling policy |
| Pro Management configuration profile | `Config Profile – Teams Rooms – Standard` | Pro Management portal profile |
| Pro Management update ring (pilot) | `Update Ring – Teams Rooms – Pilot` | Pro Management portal ring |
| Pilot room group | `Room Group – Pilot – Stage 1` | Entra/M365 group of pilot rooms |

## Benefits

- **Rooms that just work.** One-touch join with working audio/video/content, because every room is provisioned and policy-configured identically.
- **Central management.** Pro rooms are monitored, updated, and health-checked from the Pro Management portal instead of being visited desk-by-desk.
- **Auditable standard.** Named objects and repeatable scripts make the configuration reviewable and reproducible for every new room.
- **Safe change.** Pilot-first with explicit pass/fail gates and a documented rollback keeps a mistake contained to one room, never the fleet.

## Limitations and boundaries

- **Hardware internals are vendor territory.** On-device firmware, OEM setup wizards, and physical AV are deferred to the certified device's own documentation.
- **Licensing/feature tiers are plan-dependent.** Basic vs Pro capabilities, room caps, and advanced in-meeting features change over time — this solution flags them "verify in your tenant" rather than freezing a number.
- **Voice dial-in is a separate build.** If a room needs PSTN dial-in/out, Teams Phone licensing and voice routing are a distinct engagement.
- **Government clouds differ.** Portal URLs and some feature availability differ in GCC High / DoD — verify for your cloud.

## Deployment model

This solution follows the house model, reused verbatim across the implementation, testing, and best-practice documents:

**Assess → Design → Configure → Pilot → Validate → Expand**

- **Assess** — inventory rooms, existing resource accounts/mailboxes, licensing entitlements, admin roles, certified hardware, and network readiness (read-only). Never assume a prerequisite exists.
- **Design** — decide the naming convention, licensing tier per room, calendar-processing standard, the room meeting/calling policies, the Pro Management configuration profile, and the peripheral standard.
- **Configure** — create and license the resource account, set calendar processing, grant the room policies, and (for Pro) onboard to Pro Management — first for the pilot room only.
- **Pilot** — sign one real room in and use it for live meetings against explicit gates.
- **Validate** — confirm the pilot passes every gate (books, joins, audio/video/content, appears healthy in Pro Management) before widening.
- **Expand** — repeat the named configuration room-by-room, adding rooms to the Pro Management update rings and monitoring health.

Tenant-wide policy changes and licensing are high-impact; every production change runs under change control with the documented rollback in Section 3.

## Outcome

At the end of the engagement, the pilot room signs in unattended, shows its agenda on the console, joins scheduled and ad-hoc Teams meetings with one touch, presents working audio/video/content, appears **healthy** in the Teams Rooms Pro Management portal, and is covered by a managed update ring — and you hold repeatable scripts (discovery, resource-account configuration, room-policy configuration, health reporting, and readiness validation) to provision and operate every remaining room to the same standard.


---


# 2. Requirements — Microsoft Teams Rooms Deployment & Management

This document enumerates the prerequisites specific to deploying and managing Microsoft Teams Rooms. Treat each with the four-part discipline used throughout this solution: **Description** (what it is), **Why** (why it matters), **Verify** (how to confirm it exists), and **Implement if missing** (how to put it in place). Confirm each in the **Assess** phase before creating the pilot resource account.

The **six category-wide prerequisites** common to every Teams solution — (1) a Microsoft 365 tenant with Teams and appropriate licensing, (2) least-privilege administrative roles, (3) the MicrosoftTeams PowerShell + Graph toolchain, (4) an identity/group source of truth, (5) a pilot scope and change control, and (6) security/compliance/governance stakeholders — are documented in `global-requirements-teams.md` and are **not repeated here**. The requirements below are the Teams Rooms–specific additions and refinements.

---

## R1 — Teams Rooms licensing (Pro or Basic) available to assign

- **Description.** A **Teams Rooms Pro** or **Teams Rooms Basic** license, one per room resource account. Pro is required for the Teams Rooms Pro Management portal (health, managed updates, configuration profiles); Basic is the no-cost tier for a limited number of rooms with reduced management.
- **Why.** A room mailbox without a Teams Rooms license cannot sign in as a Teams Room; the tier also decides whether the room can be centrally managed at scale.
- **Verify.** Microsoft 365 admin center → **Billing → Licenses** shows available **Teams Rooms Pro** / **Teams Rooms Basic** seats; or via Graph `Get-MgSubscribedSku` inspect the `SkuPartNumber` values and `prepaidUnits`/`consumedUnits`. **Verify the current Basic room cap in your tenant** (Microsoft documents a limit, commonly cited as up to 25 rooms).
- **Implement if missing.** Purchase the appropriate Teams Rooms tier and confirm the seats appear in Billing → Licenses before provisioning.

## R2 — Exchange Online room mailbox capability

- **Description.** The ability to create a **room mailbox** (`RecipientTypeDetails = RoomMailbox`) in **Exchange Online** for each room, via the Exchange admin center or Exchange Online PowerShell.
- **Why.** A Teams Room's resource account **is** an Exchange Online room mailbox — it is how the room appears in the address book, receives invitations, and shows its agenda. Without it there is no account to sign the room into.
- **Verify.** `Connect-ExchangeOnline` succeeds and `Get-Mailbox -RecipientTypeDetails RoomMailbox` runs; confirm you can create objects (Exchange Administrator or a role with `Mail Recipient Creation`).
- **Implement if missing.** Have an Exchange Administrator grant the necessary role, and confirm the Exchange Online PowerShell module (`ExchangeOnlineManagement`) is installed on the admin workstation.

## R3 — Directory access to set account properties (password policy, usage location, licensing)

- **Description.** Rights in **Microsoft Entra ID** (via Microsoft Graph PowerShell or the admin centers) to enable the account, set a **usage location** (required before licensing), set the password to **not expire**, and **assign the Teams Rooms license**.
- **Why.** A room signs in unattended and permanently; an expiring password silently takes the room offline. Usage location is a hard prerequisite for license assignment. These are directory operations, separate from mailbox creation.
- **Verify.** `Connect-MgGraph` with scopes `User.ReadWrite.All`, `Organization.Read.All` succeeds; you can read/update the target user with `Get-MgUser` / `Update-MgUser`.
- **Implement if missing.** Have a Global Administrator or User Administrator grant the least-privilege role and consent the Graph scopes; install the `Microsoft.Graph` PowerShell module.

## R4 — Certified Teams Rooms hardware and peripherals

- **Description.** A **certified Teams Rooms system** (Teams Rooms on Windows or on Android) with **certified peripherals** — camera, microphone/soundbar, and front-of-room display — selected from Microsoft's certified device list. Hardware internals and the OEM setup wizard are the vendor's domain.
- **Why.** Only certified systems deliver the supported one-touch join and management experience and are eligible for Pro Management; non-certified peripherals cause audio/video and support gaps.
- **Verify.** Confirm the make/model appears on Microsoft's **certified Teams Rooms** list, and that peripherals are certified — check the OEM's documentation.
- **Implement if missing.** Procure certified hardware/peripherals; defer physical setup and firmware to the OEM's documentation. This solution provides the account/config side that the device signs into.

## R5 — Network readiness for Teams real-time media

- **Description.** Network access from the room's location that meets Microsoft's connectivity guidance for Teams real-time media — the required URLs/ports open, and ideally the Teams media traffic prioritized (QoS) and not forced through a proxy.
- **Why.** A room that can sign in but has blocked/degraded media joins meetings with no or poor audio/video. Rooms are fixed, high-visibility endpoints; media quality problems are immediately obvious.
- **Verify.** Confirm the room subnet meets Microsoft 365 network connectivity guidance (required endpoints reachable, UDP for media permitted); optionally run Microsoft's network assessment from the room location.
- **Implement if missing.** Work with the network team to open the required endpoints, allow UDP media, bypass proxy for Teams optimized traffic, and apply QoS marking per Microsoft guidance before validating the pilot room.

## R6 — Teams Rooms Pro Management access (for Pro rooms)

- **Description.** Access to the **Teams Rooms Pro Management** portal (Commercial: `portal.rooms.microsoft.com` — **verify the URL for your cloud**) and the **Teams admin center → Teams Rooms / Teams devices** area, with the roles that allow enrolling and managing rooms.
- **Why.** Central health monitoring, managed updates, configuration profiles, and remote actions for Pro rooms are delivered through Pro Management and the Teams admin center. Without access you cannot onboard or monitor rooms centrally.
- **Verify.** You can open the Pro Management portal and the Teams admin center **Teams Rooms** node with a **Teams Administrator** (or Teams Device Administrator) role.
- **Implement if missing.** Have a Global/Teams Administrator grant the least-privilege device-management role and confirm Pro entitlements (R1) are in place, then confirm portal access.

## R7 — A named pilot room and defined standards

- **Description.** One physical **pilot room** designated for first validation, plus the agreed **standards** to configure toward: the naming convention, the calendar-processing settings, the room meeting/calling policy names, the Pro Management configuration profile, and the peripheral standard.
- **Why.** The deployment model is pilot-first with pass/fail gates; you cannot validate without a designated room and a documented target configuration to measure against.
- **Verify.** A specific room is booked for the pilot, and the standards are written down (Section 1's naming table and Section 3's configuration values).
- **Implement if missing.** Pick a low-risk, easily accessible room as `Room Account – Boardroom-A – Pilot`, and finalize the standards with the collaboration-governance stakeholders before configuring.


---


# Global Requirements — Microsoft Teams Solutions

These requirements apply to **every** solution in the **Teams** category (Teams governance, meetings,
external access, Teams Phone, apps, Teams Rooms, and Teams security/compliance). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Teams solution).** The **Teams admin center**
> (admin.teams.microsoft.com), the **Microsoft 365 admin center**, the **MicrosoftTeams PowerShell
> module**, and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from
> Microsoft's public documentation. Where a capability, policy, or portal path is **plan- or
> version-dependent** (Teams Phone licensing, Calling Plans vs Operator Connect vs Direct Routing,
> Premium features, Commercial vs Government cloud), it is **cited or flagged "verify in your tenant"**
> — never invented. **Third-party devices and apps** (certified Teams Rooms hardware, SBCs, ISV apps)
> are integrated at the pattern level; their internals are deferred to the vendor's own docs. Automation
> is **PowerShell** (MicrosoftTeams module / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with Microsoft Teams and appropriate licensing
- **Description:** A Microsoft 365 tenant with **Microsoft Teams** enabled and the licensing the
  capability requires (e.g. Teams Phone + a calling plan/Operator Connect for voice, Teams Premium for
  premium features, the appropriate E-plan for advanced compliance).
- **Why required:** All policy, voice, app, and compliance configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the Teams subscription and relevant add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege Teams roles)
- **Description:** Access with the least-privilege role the solution names — typically **Teams
  Administrator** (or Teams Communications/Device Administrator), with **Global Administrator** only
  where genuinely required.
- **Why required:** Teams policy, voice, app, and org-wide settings require the corresponding role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Microsoft Teams PowerShell + Graph toolchain
- **Description:** A workstation with the **MicrosoftTeams** PowerShell module (and Graph PowerShell
  where used), modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through Teams PowerShell / Graph.
- **How to verify:** `Connect-MicrosoftTeams` succeeds; `Get-Module MicrosoftTeams`.
- **How to implement if missing:** `Install-Module MicrosoftTeams`; confirm modern-auth sign-in.

## 4. Identity, groups & lifecycle source of truth
- **Description:** A defined identity/group source (Entra ID groups, and where used **Microsoft 365
  Groups** which back teams) and the **lifecycle** stance (creation, naming, expiration/retention) the
  org expects.
- **Why required:** Teams are backed by M365 Groups; governance, provisioning, and access key off
  groups and the lifecycle model.
- **How to verify:** Confirm which groups/OU model is authoritative and the lifecycle expectations.
- **How to implement if missing:** Define the group/lifecycle model before configuring governance.

## 5. A pilot scope and change control
- **Description:** A **pilot team / policy group / user set** to validate on before org-wide rollout,
  and a **change-control** process for production policy/voice/compliance changes.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; policy and voice changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security, compliance/records, and collaboration-governance**
  stakeholders whose policies the configuration must satisfy (external access, information barriers,
  retention, DLP, app governance).
- **Why required:** Collaboration governance and compliance settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every Teams solution is the same: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.
Automation is delivered as **PowerShell** (MicrosoftTeams module / Graph) — never with hardcoded
credentials or secrets in code.*


---


# 3. Implementation — Microsoft Teams Rooms Deployment & Management

This is the ordered, runnable procedure. It follows the deployment model **Assess → Design → Configure → Pilot → Validate → Expand**, provisions the **pilot room first**, names every object with the `<Purpose> – <Scope> – <Stage>` convention from Section 1, and defines explicit **pass/fail gates** and a **rollback**. Portal paths and cmdlets are current Microsoft public-documentation detail; plan-/cloud-dependent items are flagged **verify in your tenant**.

Throughout, the canonical pilot objects are:

- Resource account: `Room Account – Boardroom-A – Pilot` → UPN `room-boardroom-a@contoso.com`
- Meeting policy: `Meeting Policy – Teams Rooms – Prod`
- Calling policy: `Calling Policy – Teams Rooms – Prod`
- Pro Management profile: `Config Profile – Teams Rooms – Standard`
- Pro Management update ring: `Update Ring – Teams Rooms – Pilot`

> **Connections used below.** Exchange Online (`Connect-ExchangeOnline`), Microsoft Graph (`Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All"`), and Microsoft Teams (`Connect-MicrosoftTeams`) — all modern-auth, no stored credentials.

---

## Phase 1 — Assess (read-only)

Establish the baseline before changing anything.

1. **Inventory existing rooms and mailboxes.** In Exchange Online PowerShell:
   ```powershell
   Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited |
     Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
   ```
   Run `TEAMSROOMS-Discovery.ps1` (read-only) to capture room mailboxes, their calendar processing, license assignment, and current Teams policy grants in one pass.
2. **Confirm licensing entitlements (R1).** `Get-MgSubscribedSku | Select-Object SkuPartNumber, @{N='Available';E={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}` and confirm Teams Rooms Pro/Basic seats are available. **Verify the Basic room cap for your tenant.**
3. **Confirm admin roles and network readiness (R2, R3, R5, R6).** Verify you hold the least-privilege roles and that the pilot room's subnet meets Teams media guidance.
4. **Record the baseline.** Save the discovery output; it is the reference for the rollback and for validating that only intended objects changed.

**Gate A (exit Assess):** you have a confirmed pilot room, available Teams Rooms licensing, the required roles, and a saved baseline. Do not proceed until all are true.

---

## Phase 2 — Design

Finalize the standard (write it down; do not configure yet).

1. **Naming.** Confirm the Section 1 naming table for the pilot and for production rooms.
2. **Licensing tier per room.** Decide **Pro** (centrally managed) vs **Basic** per room. The pilot room should be **Pro** so you validate the Pro Management path.
3. **Calendar-processing standard** (the Teams Rooms recommended values, applied in Phase 3):
   | Setting | Value | Reason |
   | --- | --- | --- |
   | `AutomateProcessing` | `AutoAccept` | Room auto-accepts valid invitations |
   | `AddOrganizerToSubject` | `$false` | Keep the real subject on the console |
   | `DeleteSubject` | `$false` | Preserve the meeting subject |
   | `DeleteComments` | `$false` | Preserve the invite body (holds the Join link) |
   | `RemovePrivateProperty` | `$false` | Keep private-flag handling intact |
   | `AddAdditionalResponse` | `$true` | Send a helpful auto-reply |
   | `ProcessExternalMeetingMessages` | `$true` | Show external-org invites on the console |
   | `AllowConflicts` | `$false` | Prevent double-booking (adjust to policy) |
   | `BookingWindowInDays` / `MaximumDurationInMinutes` | per policy | Booking horizon / max length |
4. **Room policies.** Define `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` values (auto-admit, content sharing, IP video, etc.) with the governance stakeholders.
5. **Pro Management profile and update ring.** Define `Config Profile – Teams Rooms – Standard` and the pilot update ring `Update Ring – Teams Rooms – Pilot`.
6. **Peripheral standard.** Record the certified camera, microphone/soundbar, and front-of-room display models.

**Gate B (exit Design):** the standard is documented and approved under change control.

---

## Phase 3 — Configure (pilot room only)

Apply the standard to the **pilot room only**. Every write below defaults to a dry run; the helper scripts require an explicit `-Commit` to make changes.

### 3.1 Create the resource account (room mailbox)

Exchange Online PowerShell:
```powershell
New-Mailbox -Name "Room Account - Boardroom-A - Pilot" `
  -Alias "room-boardroom-a" `
  -MicrosoftOnlineServicesID "room-boardroom-a@contoso.com" `
  -Room
```
`-Room` creates the mailbox as a **room mailbox** with a disabled, system-generated password. (`TEAMSROOMS-Set-ResourceAccount.ps1 -Commit` wraps this step plus 3.2–3.4.)

### 3.2 Enable the account, set usage location, and stop password expiry

The room mailbox's Entra account must be **enabled**, have a **usage location** (required before licensing), and have its password set to **not expire** (a room signs in unattended). Set a strong password of record, then via Microsoft Graph:
```powershell
$u = Get-MgUser -UserId "room-boardroom-a@contoso.com"
Update-MgUser -UserId $u.Id -AccountEnabled:$true -UsageLocation "US"
# Stop the password expiring (a room's sign-in is permanent):
Update-MgUser -UserId $u.Id -PasswordPolicies "DisablePasswordExpiration"
```
> Set `UsageLocation` to the room's country. Store the account password in your privileged secrets vault, not in scripts.

### 3.3 Assign the Teams Rooms license

Assign **Teams Rooms Pro** (for the pilot) to the account. Confirm the SkuId from `Get-MgSubscribedSku`, then:
```powershell
$sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "Microsoft_Teams_Rooms_Pro" }
Set-MgUserLicense -UserId $u.Id -AddLicenses @{ SkuId = $sku.SkuId } -RemoveLicenses @()
```
> **Verify the exact `SkuPartNumber`** in your tenant — Teams Rooms SKU part numbers vary and change over time. Do not hardcode a SkuId; resolve it from `Get-MgSubscribedSku`.

### 3.4 Configure calendar processing

Apply the Phase 2 calendar-processing standard (Exchange Online):
```powershell
Set-CalendarProcessing -Identity "room-boardroom-a@contoso.com" `
  -AutomateProcessing AutoAccept `
  -AddOrganizerToSubject $false -DeleteSubject $false -DeleteComments $false `
  -RemovePrivateProperty $false `
  -AddAdditionalResponse $true `
  -AdditionalResponse "This room is a Microsoft Teams Room. Add it to your Teams meeting to enable one-touch join." `
  -ProcessExternalMeetingMessages $true `
  -AllowConflicts $false
```
Verify with `Get-CalendarProcessing -Identity "room-boardroom-a@contoso.com"`. (`TEAMSROOMS-Set-RoomPolicy.ps1` applies this and 3.5 with `-WhatIf`/`-Commit`.)

### 3.5 Grant the room Teams meeting and calling policies

Create the room policies in the Teams admin center (**Meetings → Meeting policies** and **Voice → Calling policies**), named `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod`, then grant them to the room account:
```powershell
Grant-CsTeamsMeetingPolicy -Identity "room-boardroom-a@contoso.com" `
  -PolicyName "Meeting Policy - Teams Rooms - Prod"
Grant-CsTeamsCallingPolicy -Identity "room-boardroom-a@contoso.com" `
  -PolicyName "Calling Policy - Teams Rooms - Prod"
```
> Policy availability and specific settings can be **plan-dependent** (some advanced meeting features require Teams Premium) — verify which settings your licensing exposes.

### 3.6 Sign the device in and onboard to Pro Management

1. On the certified device console, complete the OEM setup, then **sign in** with `room-boardroom-a@contoso.com` and its password of record. (Device-side setup is the OEM's documentation.)
2. In the **Teams admin center → Teams Rooms** (or **Teams devices**), confirm the room appears and is **online**.
3. In the **Teams Rooms Pro Management** portal (`portal.rooms.microsoft.com` — **verify the URL for your cloud**), confirm the room is enrolled; assign it the `Config Profile – Teams Rooms – Standard` and add it to the `Update Ring – Teams Rooms – Pilot`.

**Gate C (exit Configure):** the pilot room mailbox exists, is licensed, has the standard calendar processing and room policies, the device is signed in and online, and it is enrolled in Pro Management.

---

## Phase 4 — Pilot

Use the room for real meetings for an agreed window (for example one week).

1. **Book it.** Invite `Room Account – Boardroom-A – Pilot` to Teams meetings (internal and one external-org meeting); confirm each auto-accepts and shows on the console with subject and Join button.
2. **Join from the room.** Press **Join** on the console; confirm audio, video, and content sharing.
3. **Exercise Pro Management.** Confirm health telemetry appears and that the update ring is applied.
4. **Log issues** against Section 6 (Troubleshooting) and resolve before validation.

---

## Phase 5 — Validate (pass/fail gates)

Run `TEAMSROOMS-Validation.ps1` and the manual checks in Section 5. The pilot passes only when **all** gates are green:

- **Gate V1 — Provisioned:** mailbox is `RoomMailbox`, account enabled, password non-expiring, usage location set.
- **Gate V2 — Licensed:** a Teams Rooms (Pro for the pilot) license is assigned.
- **Gate V3 — Calendar:** calendar processing matches the standard (auto-accept, subject/body preserved).
- **Gate V4 — Policy:** the room account has `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod`.
- **Gate V5 — Joins reliably:** the room books, shows the agenda, and one-touch-joins with working audio/video/content.
- **Gate V6 — Managed & healthy:** the room is enrolled in Pro Management with **healthy** status and an assigned update ring.

If any gate fails, fix it (Section 6) and re-validate before expanding.

---

## Phase 6 — Expand

Repeat Phases 3–5 for each additional room, changing only `<Scope>` in the object names (for example `Room Account – Huddle-3 – Prod`). Reuse the **same** policies and Pro Management profile so every room is identical. Add production rooms to a broader `Update Ring – Teams Rooms – Prod` (kept behind the pilot ring so updates are proven on the pilot first). Monitor the fleet with `TEAMSROOMS-HealthReport.ps1` on a schedule.

---

## Rollback

Because you configure pilot-first, a problem is contained to one room. To roll back the pilot:

1. **Policies:** re-grant the tenant default policy — `Grant-CsTeamsMeetingPolicy -Identity room-boardroom-a@contoso.com -PolicyName $null` (and the calling policy) to remove the room-specific grant.
2. **Calendar processing:** restore the prior values captured in the Phase 1 baseline with `Set-CalendarProcessing`.
3. **License:** remove the Teams Rooms license with `Set-MgUserLicense -RemoveLicenses @($sku.SkuId) -AddLicenses @{}` if the account is being decommissioned.
4. **Pro Management:** unenroll the room from the portal and remove it from the update ring.
5. **Account:** if the room is being removed entirely, `Remove-Mailbox` the room mailbox under change control.

Because every object is uniquely named, rollback targets exactly the pilot objects and never affects users or other rooms.


---


# 5. Testing & Validation — Microsoft Teams Rooms Deployment & Management

These procedures validate the pilot room against the **Phase 5** gates in Section 3. Each test states **what to do**, the **expected pass**, and the **fail signal** (which routes to Section 6). Run them in order; the pilot is validated only when **every** test passes. Use `TEAMSROOMS-Validation.ps1` to automate the object-state checks (T1–T4, T6) and perform the in-room checks (T5) by hand.

Canonical objects under test: `Room Account – Boardroom-A – Pilot` (`room-boardroom-a@contoso.com`), `Meeting Policy – Teams Rooms – Prod`, `Calling Policy – Teams Rooms – Prod`, `Config Profile – Teams Rooms – Standard`, `Update Ring – Teams Rooms – Pilot`.

---

## T1 — Resource account is provisioned correctly (Gate V1)

- **Do.** Exchange Online: `Get-Mailbox room-boardroom-a@contoso.com | Select RecipientTypeDetails`. Graph: `Get-MgUser -UserId room-boardroom-a@contoso.com -Property AccountEnabled,UsageLocation,PasswordPolicies | Select AccountEnabled,UsageLocation,PasswordPolicies`.
- **Pass.** `RecipientTypeDetails = RoomMailbox`; `AccountEnabled = True`; `UsageLocation` is set; `PasswordPolicies` contains `DisablePasswordExpiration`.
- **Fail.** Not a room mailbox, account disabled, no usage location, or password can expire → Section 6, "Room signs out / password expired" and "License won't assign".

## T2 — Teams Rooms license is assigned (Gate V2)

- **Do.** `Get-MgUserLicenseDetail -UserId room-boardroom-a@contoso.com | Select SkuPartNumber`.
- **Pass.** A Teams Rooms SKU (Pro for the pilot) is listed. **Verify the exact SkuPartNumber for your tenant.**
- **Fail.** No Teams Rooms SKU, or an unexpected SKU → Section 6, "License won't assign".

## T3 — Calendar processing matches the standard (Gate V3)

- **Do.** `Get-CalendarProcessing -Identity room-boardroom-a@contoso.com | Select AutomateProcessing,AddOrganizerToSubject,DeleteSubject,DeleteComments,ProcessExternalMeetingMessages,AllowConflicts`.
- **Pass.** `AutomateProcessing = AutoAccept`; `AddOrganizerToSubject = False`; `DeleteSubject = False`; `DeleteComments = False`; `ProcessExternalMeetingMessages = True`; `AllowConflicts = False`.
- **Fail.** Subject/body being stripped (join button/agenda missing on console) or double-booking allowed unexpectedly → Section 6, "Console shows no subject / no Join button" and "Double-booked room".

## T4 — Room policies are granted (Gate V4)

- **Do.** `Get-CsOnlineUser -Identity room-boardroom-a@contoso.com | Select TeamsMeetingPolicy, TeamsCallingPolicy`.
- **Pass.** `TeamsMeetingPolicy = Meeting Policy - Teams Rooms - Prod` and `TeamsCallingPolicy = Calling Policy - Teams Rooms - Prod`.
- **Fail.** Policies show the global/default or the wrong name → re-run Section 3.5; see Section 6, "Room behaves like a user, not a room".

## T5 — Room books and one-touch-joins with working media (Gate V5)

- **Do.** From a normal user, create a Teams meeting and add `Room Account – Boardroom-A – Pilot` as a resource. Then, at the room console: confirm the meeting appears with its subject and a **Join** button; press **Join**; speak, share video, and share content from a laptop.
- **Pass.** The invite auto-accepts; the console shows subject and Join; one touch joins; two-way audio, camera video, and content sharing all work.
- **Fail.** Invite declined or not shown; no Join button; no/poor audio or video; content won't share → Section 6, "Room won't join / declines invites", "Console shows no subject / no Join button", "Poor or no audio/video".

## T6 — Room is centrally managed and healthy (Gate V6)

- **Do.** In the **Teams Rooms Pro Management** portal (verify URL for your cloud) and **Teams admin center → Teams Rooms**, locate the room.
- **Pass.** The room is **online/enrolled**, shows **healthy** status, has `Config Profile – Teams Rooms – Standard` applied, and is in `Update Ring – Teams Rooms – Pilot`.
- **Fail.** Room absent, unhealthy, unenrolled, or no update ring → Section 6, "Room not appearing / unhealthy in Pro Management".

## T7 — External-org meeting appears (regression)

- **Do.** Have someone outside the org invite the room to a Teams meeting.
- **Pass.** The external invitation auto-accepts and shows on the console with a Join button (because `ProcessExternalMeetingMessages = True`).
- **Fail.** External invite ignored → re-check T3 and Section 6.

---

## Validation sign-off

Record the pass/fail for T1–T7, the tester, and the date. **All must pass** before Phase 6 (Expand). Re-run T1–T4 and T6 with `TEAMSROOMS-Validation.ps1` after any later change to the room, and re-run T5 after firmware/software updates land via the update ring.


---


# 6. Troubleshooting — Microsoft Teams Rooms Deployment & Management

Common Teams Rooms failure modes with likely root cause and resolution. Each entry names the symptom, how to confirm it, the fix, and how to verify. Use `TEAMSROOMS-Discovery.ps1` / `TEAMSROOMS-Validation.ps1` to confirm tenant-side state; device/firmware symptoms route to the Teams Rooms Pro Management portal and the certified-hardware OEM's documentation.

---

## Room won't join / declines invitations

- **Symptom.** The room declines meeting invites, or accepted meetings never appear on the console.
- **Confirm.** `Get-CalendarProcessing -Identity room-boardroom-a@contoso.com | Select AutomateProcessing, AllowConflicts, ProcessExternalMeetingMessages`.
- **Root cause.** `AutomateProcessing` is not `AutoAccept`; or `AllowConflicts = $false` is rejecting an overlapping booking; or (for external meetings) `ProcessExternalMeetingMessages = $false`.
- **Fix.** Re-run `TEAMSROOMS-Set-RoomPolicy.ps1 -Commit` to apply the standard (Section 3.4); set `AutomateProcessing AutoAccept` and `ProcessExternalMeetingMessages $true`. If overlaps are legitimately being declined, that is expected behaviour with `AllowConflicts $false`.
- **Verify.** T1/T3 and T7 in Section 5 pass; a fresh invite auto-accepts and shows on the console.

## Console shows no subject / no Join button

- **Symptom.** The meeting appears on the console but with a generic title and **no Join button**.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select DeleteSubject, DeleteComments, AddOrganizerToSubject`.
- **Root cause.** `DeleteSubject = $true` or `DeleteComments = $true` strips the subject and the invite body — and the body carries the Teams Join link, so no Join button renders. (This is the single most common Teams Rooms misconfiguration.)
- **Fix.** Set `DeleteSubject $false`, `DeleteComments $false`, `AddOrganizerToSubject $false` (Section 3.4 / `TEAMSROOMS-Set-RoomPolicy.ps1`).
- **Verify.** T3 passes; a newly sent invite shows its real subject and a Join button on the console.

## License won't assign

- **Symptom.** `Set-MgUserLicense` fails, or the room has no Teams Rooms capability after assignment.
- **Confirm.** `Get-MgUser -UserId <room> -Property UsageLocation | Select UsageLocation` and `Get-MgSubscribedSku | Select SkuPartNumber, @{N='Avail';E={$_.PrepaidUnits.Enabled-$_.ConsumedUnits}}`.
- **Root cause.** No **UsageLocation** on the account (hard prerequisite for licensing); or **no available seats**; or the wrong **SkuPartNumber** was used (Teams Rooms SKU names vary by tenant).
- **Fix.** Set `UsageLocation` first (`Update-MgUser -UserId <id> -UsageLocation US`), confirm available seats, and resolve the correct SKU from `Get-MgSubscribedSku` — never hardcode a SkuId. Re-run `TEAMSROOMS-Set-ResourceAccount.ps1 -Commit`.
- **Verify.** T2 passes; `Get-MgUserLicenseDetail` lists the Teams Rooms SKU.

## Room signs out / password expired

- **Symptom.** A previously working room shows a sign-in prompt on the console and drops off management.
- **Confirm.** `Get-MgUser -UserId <room> -Property PasswordPolicies, AccountEnabled | Select PasswordPolicies, AccountEnabled`.
- **Root cause.** `PasswordPolicies` does not include `DisablePasswordExpiration`, so the unattended password expired; or the account was disabled; or the password of record was rotated without updating the device.
- **Fix.** Set `Update-MgUser -UserId <id> -PasswordPolicies "DisablePasswordExpiration"` and ensure `AccountEnabled` is true (Section 3.2). If the password was rotated, re-enter it on the device (OEM docs) and store it in the vault.
- **Verify.** T1 passes (`PasswordNeverExpires = True`); the room signs in and stays online.

## Room behaves like a user, not a room

- **Symptom.** The room has end-user meeting behaviour (unexpected lobby, chat, or missing content-sharing) rather than the room standard.
- **Confirm.** `Get-CsOnlineUser -Identity <room> | Select TeamsMeetingPolicy, TeamsCallingPolicy`.
- **Root cause.** The room inherited the **Global/default** policy instead of the room-specific policy.
- **Fix.** Grant `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` (Section 3.5 / `TEAMSROOMS-Set-RoomPolicy.ps1`). Note policy grants can take time to propagate.
- **Verify.** T4 passes; the room shows the room policy names.

## Poor or no audio/video in the room

- **Symptom.** The room joins but has no/one-way audio, no camera, or choppy video.
- **Confirm.** Check the peripherals are certified and selected on the device (OEM console); check the room subnet against Teams media guidance (R5).
- **Root cause.** Non-certified or disconnected peripheral; or network media path blocked/degraded (UDP blocked, forced proxy, no QoS).
- **Fix.** Use certified peripherals (defer device-side selection to OEM docs); with the network team, open required Teams endpoints, allow UDP media, bypass proxy for optimized traffic, and apply QoS (R5). Media quality is a **network/hardware** issue, not a tenant-config issue.
- **Verify.** T5 passes; two-way audio, camera, and content sharing all work from the room.

## Double-booked room

- **Symptom.** Two meetings land on the same slot.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select AllowConflicts, ConflictPercentageAllowed, MaximumConflictInstances`.
- **Root cause.** `AllowConflicts = $true` (or a permissive conflict threshold) allows overlapping bookings.
- **Fix.** Set `AllowConflicts $false` unless the room policy intends overlaps (Section 3.4).
- **Verify.** T3 passes; a conflicting invite is declined.

## Room not appearing / unhealthy in Pro Management

- **Symptom.** A Pro room is missing from the Teams Rooms Pro Management portal, or shows **unhealthy/offline**.
- **Confirm.** Check the Teams admin center → **Teams Rooms** for the device, and the Pro Management portal enrollment; confirm the account holds a **Pro** license (not Basic) — Basic rooms are not eligible for full Pro Management.
- **Root cause.** Room not enrolled; assigned a **Basic** (not Pro) license; the device is offline (network/power/sign-in); or (for Government cloud) the wrong portal URL was used.
- **Fix.** Assign a **Pro** license (R1), enroll the device and assign `Config Profile – Teams Rooms – Standard` and an update ring (Section 3.6), and confirm the device is online. **Verify the correct Pro Management portal URL for your cloud** (Commercial vs Government).
- **Verify.** T6 passes; the room shows **healthy** with a profile and update ring.

## External-org meetings don't show on the console

- **Symptom.** Invites from outside the organization never appear on the room.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select ProcessExternalMeetingMessages`.
- **Root cause.** `ProcessExternalMeetingMessages = $false`, so external invitations are not processed onto the room calendar.
- **Fix.** Set `ProcessExternalMeetingMessages $true` (Section 3.4).
- **Verify.** T7 passes; an external invite auto-accepts and shows a Join button.

---

### When to escalate to the OEM or network team

Tenant-side configuration (accounts, licensing, calendar processing, policies, Pro Management enrollment) is covered by this solution and its scripts. **Device firmware, on-device setup, physical AV, and peripheral internals** are the certified-hardware OEM's responsibility; **media-path quality** (endpoints, UDP, proxy, QoS) is the network team's. Route those symptoms accordingly rather than changing tenant configuration that is already correct.


---


# 7. Best Practices — Microsoft Teams Rooms Deployment & Management

Durable practices for running a fleet of consistent, reliable, centrally managed Teams Rooms. These generalize the deployment model into standing operational discipline.

## Provisioning & accounts

- **One resource account per room, named to the convention.** Use `Room Account – <Room> – <Stage>` and reuse the exact name across the mailbox, licensing, policy grants, and scripts so the deployment is self-documenting and auditable.
- **Passwords never expire; store them in a vault.** A room signs in unattended and permanently — always set `DisablePasswordExpiration` and keep the password of record in a privileged secrets vault, never in a script or spreadsheet. Rotate on a controlled schedule, not on an expiry timer.
- **Set usage location before licensing.** License assignment fails without it; make it a standard step in the provisioning script.
- **Resolve SKU IDs at runtime.** Never hardcode a Teams Rooms `SkuId` — read it from `Get-MgSubscribedSku` because SKU part numbers and IDs vary by tenant and change over time.

## Calendar processing

- **Preserve subject and body.** Keep `AddOrganizerToSubject`, `DeleteSubject`, and `DeleteComments` at `$false` so the console shows the real subject and the Join button. This is the single most common cause of "the room has no Join button."
- **Process external meeting messages.** Set `ProcessExternalMeetingMessages = $true` so cross-org meetings appear on the console — increasingly common with hybrid work.
- **Match booking policy to the room.** Tune `AllowConflicts`, `BookingWindowInDays`, and `MaximumDurationInMinutes` to how the room is actually used; document the choice.

## Policy & licensing

- **Give rooms their own policies.** Apply dedicated `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` rather than letting rooms inherit an end-user policy — rooms have different needs (auto-admit, content, no chat noise).
- **Right-tier each room.** Use **Pro** for any room you want centrally managed, updated, and health-monitored; reserve **Basic** for the few low-touch rooms within the (verify-in-tenant) cap.
- **Treat plan-dependent features as such.** Advanced meeting experiences may require Teams Premium or specific hardware — verify entitlement before promising a feature, and flag it rather than assume it.

## Central management (Pro Management)

- **Enroll every Pro room.** A room that isn't in Pro Management is a room you'll be visiting in person. Enroll at sign-in as a standard step.
- **Ring your updates.** Keep a small **pilot** update ring ahead of the fleet so firmware/software updates prove out on a couple of rooms before reaching the rest.
- **Standardize with configuration profiles.** Apply one `Config Profile – Teams Rooms – Standard` fleet-wide so settings drift is caught and corrected centrally.
- **Watch health proactively.** Schedule `TEAMSROOMS-HealthReport.ps1` and act on unhealthy/offline rooms before users report them; a room is the most visible endpoint in the building.

## Hardware & peripherals

- **Certified only.** Use certified systems and certified peripherals end to end — it is the line between "supported" and "you're on your own."
- **Standardize models per room class.** Pick a small set of certified configurations (huddle / standard / boardroom) so spares, support, and training are simple.
- **Defer device internals to the OEM.** Firmware, on-device setup, and physical AV follow the vendor's documentation; keep that boundary clear in runbooks.

## Change discipline

- **Pilot-first, always.** Validate any new standard or policy change on the pilot room against the Section 5 gates before touching the fleet.
- **Keep a baseline and a rollback.** Capture room state (discovery output) before changes; every uniquely named object makes rollback exact and contained.
- **Automate read-only checks; gate writes.** Run discovery/validation freely; require an explicit `-Commit` for any change so a dry run is always the default.

## Documentation & audit

- **Maintain a room register.** Track each room's account UPN, license tier, policies, profile, ring, and certified hardware — the health report can seed it.
- **Record every named object.** Because names encode purpose/scope/stage, an up-to-date register plus the scripts is a complete, reproducible description of the fleet.


---


# 8. Deliverables Summary — Microsoft Teams Rooms Deployment & Management

Everything included in this solution, at a glance.

## Documentation

| Document | What it gives you |
| --- | --- |
| **1. Solution Overview** | What Teams Rooms is, the reference design (resource account + licensing + calendar processing + room policies + Pro Management + peripherals), the licensing model (Pro vs Basic), the naming convention, benefits, limitations, and the deployment model. |
| **2. Requirements** | The Teams Rooms–specific prerequisites (licensing, room-mailbox capability, directory rights, certified hardware, network readiness, Pro Management access, pilot scope), each with Description / Why / Verify / Implement — building on the shared category requirements. |
| **3. Implementation** | The ordered Assess → Design → Configure → Pilot → Validate → Expand procedure: create + license the resource account, tune calendar processing, grant room policies, onboard to Pro Management — pilot-first, every object named, with pass/fail gates and a rollback. |
| **5. Testing & Validation** | Seven tests (T1–T7) mapped to the validation gates, each with the exact command, expected pass, and fail signal. |
| **6. Troubleshooting** | The common Teams Rooms failure modes (won't join, no Join button on console, poor media, license won't assign, room signs out, double-booked, unhealthy in Pro Management) with root cause and resolution. |
| **7. Best Practices** | Durable practices for a fleet: accounts, calendar processing, policy/licensing, central management, hardware, change discipline, and documentation. |
| **Executive Summary** | The outcome, the approach, and why it is low-risk — for decision-makers. |

## PowerShell tools (5)

All tools use modern-auth `Connect-*` cmdlets, store **no credentials**, and are **read-only or dry-run (`-WhatIf`/no `-Commit`) by default**.

| Script | Purpose | Safe default |
| --- | --- | --- |
| **TEAMSROOMS-Discovery.ps1** | Read-only assessment: enumerates room mailboxes and reports each room's mailbox type, account state, Teams Rooms license, calendar-processing values, and granted meeting/calling policies — the baseline for the Assess phase. | Read-only |
| **TEAMSROOMS-Set-ResourceAccount.ps1** | Creates and configures a room resource account: room mailbox, enable + usage location, non-expiring password, and Teams Rooms license (SKU resolved at runtime). | Dry-run unless `-Commit` |
| **TEAMSROOMS-Set-RoomPolicy.ps1** | Applies the Teams Rooms calendar-processing standard and grants the room's Teams meeting and calling policies. | Dry-run unless `-Commit` |
| **TEAMSROOMS-HealthReport.ps1** | Fleet health/inventory report: evaluates every room against the standard, flags non-conformant rooms and their specific gaps, and writes CSV (and optional HTML). | Read-only |
| **TEAMSROOMS-Validation.ps1** | Validates one room, a room list, or an Entra group of rooms against gates V1–V4 (provisioned, licensed, calendar, policy); returns a non-zero exit code if any gate fails so it can gate an expansion pipeline. Doubles as the scope/readiness helper. | Read-only |

## How they fit the workflow

1. **Assess** — `TEAMSROOMS-Discovery.ps1` captures the baseline.
2. **Configure (pilot)** — `TEAMSROOMS-Set-ResourceAccount.ps1 -Commit` then `TEAMSROOMS-Set-RoomPolicy.ps1 -Commit`.
3. **Validate** — `TEAMSROOMS-Validation.ps1` for gates V1–V4; manual in-room and Pro Management checks for V5–V6.
4. **Operate & Expand** — `TEAMSROOMS-HealthReport.ps1` on a schedule; re-run the configure + validate pair per new room.
