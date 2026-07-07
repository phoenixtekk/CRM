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
