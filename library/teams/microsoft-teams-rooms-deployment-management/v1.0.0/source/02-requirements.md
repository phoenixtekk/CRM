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
