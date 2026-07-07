# 2. Requirements

This solution assumes the **shared Teams category requirements** are already met — a Microsoft 365
tenant with Teams and appropriate licensing, least-privilege **Teams Administrator** access, the
**MicrosoftTeams** PowerShell + **Microsoft Graph** toolchain, an identity/group source of truth, a
pilot scope with change control, and engagement with security/compliance/governance stakeholders. See
**`global-requirements-teams.md`** for those six; do **not** duplicate them. Below are the
prerequisites **specific to meetings, webinars, templates, and policy assignment**.

---

## 2.1 Teams Premium licensing — required only for templates, sensitivity, watermark (verify per organizer)
- **Description:** Core meeting policies, the events policy, org meeting settings, and group assignment
  work on standard Teams licensing. But **meeting templates, applying a sensitivity label to a meeting,
  watermark, "prevent copy," and advanced meeting protection are Teams Premium features** — the
  **organizer** of the meeting must hold a **Teams Premium** license for them to take effect.
- **Why required:** If you design the template/sensitivity portion of this solution but the target
  cohort has no Teams Premium, those steps silently do nothing while the core policies still apply. This
  is the single most common surprise.
- **How to verify:** In the Microsoft 365 admin center, check **Billing > Licenses** for **Teams
  Premium** and which users hold it. In PowerShell you can confirm feature availability by inspecting
  whether template/sensitivity cmdlets and admin-center options are present. **Treat entitlement as
  "verify in your tenant/plan" — do not assume.**
- **How to implement if missing:** Either assign Teams Premium to the cohort that needs
  template/sensitivity features, or scope this deployment to the **core policy** work only (lobby,
  recording, roles, webinars, assignment) and defer templates until Premium is available.

## 2.2 Least-privilege admin roles for meeting policy work
- **Description:** The work needs the **Teams Administrator** role for meeting/events policy and group
  assignment. Creating or editing **sensitivity labels** requires a **Compliance/Records** role in
  **Microsoft Purview** (**Sensitivity Label Administrator** / Compliance Administrator) — held by the
  compliance owner, not necessarily the Teams admin. **Global Administrator** is not required for the
  core work.
- **Why required:** Meeting and events policies are gated by the Teams Administrator role; sensitivity
  labels are gated by the Purview compliance roles. Splitting them keeps least privilege intact.
- **How to verify:** In the M365 admin center / Entra roles confirm **Teams Administrator** on the
  operator; confirm the compliance owner holds the Purview label role.
- **How to implement if missing:** Have a Global Admin assign **Teams Administrator** to the operator
  under change control; route label creation to the compliance owner.

## 2.3 Cohort groups for policy assignment (source of truth confirmed)
- **Description:** Group-based assignment needs the **Entra ID / Microsoft 365 security groups** that
  represent each meeting cohort — at minimum a **pilot** group and the production cohorts (e.g. exec,
  standard, restricted). Group policy assignment supports security groups and M365 groups; **very large
  or dynamic groups** may evaluate more slowly — verify behavior in your tenant.
- **Why required:** `New-CsGroupPolicyAssignment` targets a group, not individual users. Without clean,
  authoritative cohort groups, assignment is guesswork and drifts from HR/identity reality.
- **How to verify:** Confirm the group object IDs (`Get-MgGroup`), their membership source (assigned vs
  dynamic), and that they are the authoritative cohorts. Confirm the pilot group exists and is small.
- **How to implement if missing:** Create or nominate the cohort groups (naming per the reference
  model, e.g. `Meeting Scope – Exec – Group`) before assigning policies.

## 2.4 A defined meeting/security baseline (what the org actually wants)
- **Description:** The desired settings for each cohort must be **decided before configuring**: lobby
  behavior (who bypasses), whether anonymous/PSTN can join and start, whether cloud recording and
  transcription are allowed, the default presenter role, meeting-chat behavior, and recording expiration.
- **Why required:** These are policy decisions, not technical ones — the tool applies them, but the
  security/collaboration owners decide them. Configuring without an agreed baseline produces churn.
- **How to verify:** Confirm a signed-off baseline table (per cohort) exists, reviewed by the security
  and collaboration-governance stakeholders (GR §6).
- **How to implement if missing:** Facilitate a short baseline decision with the stakeholders using the
  `Meeting Posture – Teams – Discovery` export as the starting point.

## 2.5 Recording storage understood (OneDrive / SharePoint)
- **Description:** Teams meeting recordings are stored in **OneDrive** (for non-channel meetings, in the
  organizer's OneDrive) or **SharePoint** (for channel meetings, in the team's site) — **not** in a
  separate recordings service. Recording behavior therefore depends on the organizer having a
  provisioned OneDrive and sufficient storage, and on OneDrive/SharePoint retention.
- **Why required:** If an organizer has no OneDrive license/provisioning, recording can fail or have
  nowhere to land. Recording **expiration** (`-NewMeetingRecordingExpirationDays`) and any
  OneDrive/SharePoint retention interact.
- **How to verify:** Confirm in-scope organizers have OneDrive provisioned and adequate quota; note any
  OneDrive/SharePoint retention labels that affect recordings (a compliance concern — coordinate).
- **How to implement if missing:** Ensure OneDrive is licensed/provisioned for organizers who record;
  coordinate recording expiration with the compliance owner's retention stance.

## 2.6 Sensitivity label(s) defined by compliance (if using templates)
- **Description:** If the deployment attaches a **sensitivity label** to a meeting template, the label
  must already be **defined and published in Microsoft Purview** by the compliance owner, with its
  meeting-protection settings (encryption, watermark, prevent copy, forced lobby/recording) decided.
- **Why required:** A template can only attach a label that exists; **what the label protects is a
  compliance determination**, deferred to that owner.
- **How to verify:** Confirm the exact label name(s) and that they are published to the relevant users.
- **How to implement if missing:** Request the compliance owner define/publish the label first; do not
  invent a label or its protections.

## 2.7 Commercial vs Government cloud confirmed
- **Description:** Confirm whether the tenant is **Commercial** or **Government** (**GCC / GCC High /
  DoD**). Admin-center URLs, some capability availability (including certain Premium and events
  features), and the PowerShell endpoint differ by cloud.
- **Why required:** Steps and URLs that are correct on Commercial may differ on Government clouds
  (`*.office365.us`, `*.microsoft.us`); assuming the wrong cloud produces broken links and missing
  features.
- **How to verify:** Confirm the cloud with the tenant owner; when connecting PowerShell, use the
  correct environment (e.g. `Connect-MicrosoftTeams -TeamsEnvironmentName TeamsGCCH` /
  `TeamsDOD` where applicable — **verify the exact parameter value for your cloud**).
- **How to implement if missing:** Record the cloud in the runbook and use the matching URLs/endpoints
  throughout.
