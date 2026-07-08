# 2. Requirements Guide — Sensitivity Labeling for Meetings (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Sensitivity-label licensing, plus Teams Premium for meeting-option protection
**Description:** A tenant licensed for **sensitivity labels** (Microsoft 365 E3 includes manual
labeling; E5 / E5 Compliance for advanced capabilities), **plus Microsoft Teams Premium** for the
meeting-specific protections the label enforces — **who bypasses the lobby, presenter, recording
control, chat off / copy-prevention, watermark, and end-to-end encryption**. Encrypting the meeting
**invite** builds on the labeling baseline. (Global Requirement 1.)
**Why:** The invite-protection and basic label surface work on the labeling baseline; the
**meeting-option protections** are gated on **Teams Premium** and on the Meetings-scope capability being
available in your tenant.
**Verify:** M365 admin center → `Billing → Licenses` shows the sensitivity-label SKU and **Teams
Premium**; `IPMEET-Check-Prereqs.ps1` reports the label and Teams-Premium signals; confirm the
**Meetings** scope is selectable on a label in the Purview portal. **Verify against your own plan.**
**Implement:** Assign/purchase Teams Premium (or the plan that includes it) before configuring the
Premium-only controls. Where Premium is unavailable, scope the labels to invite-encryption and the
lobby/chat controls your plan supports, and record watermark/E2EE/recording-control as **deferred**.

## 2.2 Least-privilege roles across Purview and Teams
**Description:** **Information Protection Admin** (or **Compliance Administrator**) to author and publish
sensitivity labels and label policies in Purview; a **Teams Administrator** to read/confirm the Teams
meeting-policy baseline (lobby, recording, chat) that the labels operate on top of. Reserve **Global
Administrator** for one-time consent/enablement only. (Global Requirement 2 — least privilege.)
**Why:** Meeting labeling spans two surfaces — the label (Purview) and the underlying Teams meeting
configuration — each with its own least-privilege role.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows Information Protection Admin;
Teams admin center access confirmed; `Connect-IPPSSession` and `Connect-MicrosoftTeams` succeed.
**Implement:** Assign the least-privilege role on each surface under change control; do not use Global
Administrator for day-to-day label authoring.

## 2.3 Security & Compliance PowerShell + MicrosoftTeams toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession` for
`Get-Label` / `Get-LabelPolicy` / `New-Label` / `New-LabelPolicy`) and the **MicrosoftTeams** module
(provides `Connect-MicrosoftTeams` / `Get-CsTeamsMeetingPolicy`), with a modern-auth / MFA admin.
(Global Requirement 3.)
**Why:** Labels and label policies are read/authored through Security & Compliance PowerShell; the Teams
meeting baseline is read through the MicrosoftTeams module; the provided scripts run on both.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, MicrosoftTeams`; the connect cmdlets
succeed. `IPMEET-Check-Prereqs.ps1` reports which modules/connections are present.
**Implement:** `Install-Module ExchangeOnlineManagement, MicrosoftTeams -Scope CurrentUser`; confirm
modern-auth sign-in before running steps.

## 2.4 Meetings-scope capability available and (where required) enabled
**Description:** The **Meetings** scope for sensitivity labels must be available in your tenant so a
label can be scoped to protect Teams meetings and calendar events. In some tenants this capability
and/or the Teams-Premium meeting-protection surface must be **enabled/verified** before the scope and
its settings appear.
**Why:** A meeting-scoped label cannot be authored — and its lobby/recording/chat settings cannot be set
— if the Meetings scope is not offered in the label configuration.
**Verify:** In the Purview portal, create/edit a label and confirm **Meetings and calendar events** (or
equivalent) is an available scope with the protection settings; `IPMEET-Check-Prereqs.ps1` reports
whether any Meetings-scoped label already exists. **Verify the exact enablement path against current
Microsoft guidance for your tenant** — the meeting-label surface is evolving.
**Implement:** Confirm the capability is available for your licensing/tenant and complete any tenant
enablement Microsoft documents before authoring the labels; if unavailable, this is a licensing/plan gap
(see 2.1).

## 2.5 A Teams meeting-policy baseline compatible with the taxonomy
**Description:** The Teams **meeting policy** baseline (`Get-CsTeamsMeetingPolicy`: lobby /
`AutoAdmittedUsers`, recording / `AllowCloudRecording`, chat / `MeetingChatEnabledType`) must be
**compatible** with the label taxonomy — a label tightens meeting behavior per the tier; it operates
within what the tenant Teams configuration allows.
**Why:** Meeting labels and Teams meeting policy interact. Understanding the baseline (e.g. is cloud
recording tenant-allowed, what is the default lobby) is required so the label's per-meeting settings are
expressible and their effect is understood.
**Verify:** `IPMEET-Discover.ps1` reports the Teams meeting-policy baseline; confirm it against the
taxonomy with your Teams administrator.
**Implement:** Where a baseline conflicts with the intended tier (e.g. lobby default is "Everyone"),
agree the baseline with the Teams admin under change control and record it in `Meeting Scope – Map`.

## 2.6 Meeting labels authored (Meetings scope) and published
**Description:** The meeting labels (`Meeting – General`, `Meeting – Confidential`,
`Meeting – Highly Confidential`) authored in the Purview portal with the **Meetings** scope and their
lobby/recording/chat/copy/content-protection settings, published via the **`Meeting Labels – Policy`**
label policy.
**Why:** A label must exist and be published to a user before that user can apply it when scheduling a
meeting; the policy is what surfaces the labels in Teams/Outlook.
**Verify:** `Get-Label` lists the meeting labels; `Get-LabelPolicy` shows the policy;
`IPMEET-Check-Prereqs.ps1` confirms Meetings-scoped labels are present. Confirm the labels appear when
scheduling a Teams meeting as a policy member.
**Implement:** Author the labels and their meeting settings (Implementation Guide Step 3) and publish
them to the pilot user group first, then expand.

## 2.7 In-scope meetings, classification intent, and stakeholders
**Description:** The **meeting types / audiences in scope** (e.g. board, M&A, HR investigations, security
incident bridges, legal privileged calls), the **classification intent** mapping meeting sensitivity to
the three tiers, and engagement with **compliance, security, HR, privacy, and legal** stakeholders
(Global Requirements 4 & 5).
**Why:** Which meeting gets which label is a business/classification decision, and recording and chat
controls have HR/privacy/legal implications — the determination is the stakeholders', the implementation
is yours.
**Verify:** The in-scope meeting types and the tier mapping are agreed; named approvers recorded.
**Implement:** Capture the classification intent and tier mapping before publishing labels; agree that
recording/records obligations for labeled meetings are owned by compliance/records.

## 2.8 A pilot user ring and change control
**Description:** A **pilot ring** — `Meeting Labels – Pilot Ring – Stage1`: a small set of named pilot
users who will label real meetings — plus a **change-control** process (Global Requirement 6).
**Why:** Lobby, recording, and chat changes are high-impact for the attendee experience; prove them with
a pilot group on real meetings before publishing to the estate. Turning chat off on a busy recurring
meeting without piloting generates help-desk tickets.
**Verify:** The pilot user ring is defined and a change window/approval path exists.
**Implement:** Define the ring and agree change control before publishing labels beyond the pilot.

---
## Checklist
- [ ] Sensitivity-label licensing confirmed; **Teams Premium** available for meeting-option protection (or Premium-only controls deferred)
- [ ] Information Protection Admin (Purview) + Teams Administrator assigned least-privilege
- [ ] ExchangeOnlineManagement + MicrosoftTeams installed; `Connect-IPPSSession` and `Connect-MicrosoftTeams` succeed
- [ ] **Meetings** scope available/enabled for labels in the Purview portal (verified for your tenant)
- [ ] Teams meeting-policy baseline (lobby / recording / chat) read and compatible with the taxonomy
- [ ] Meeting labels authored (Meetings scope) and `Meeting Labels – Policy` published to pilot users
- [ ] In-scope meeting types + tier mapping agreed; stakeholders named; records obligations owned
- [ ] `Meeting Labels – Pilot Ring – Stage1` (pilot users) defined; change control agreed
