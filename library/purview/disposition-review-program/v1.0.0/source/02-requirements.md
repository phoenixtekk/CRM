# 2. Requirements

These are the **solution-specific** prerequisites for standing up a disposition review program in
Microsoft Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell + Graph
toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal stakeholders; and a
pilot scope with change control). Do not repeat those — verify them first, then confirm the
disposition-specific prerequisites below. Each is stated as **Description / Why / Verify / Implement if
missing.**

---

## 2.1 Compliance licensing for disposition review (single- and multi-stage)
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks **disposition review** on
  retention labels. Single-stage review and records management generally require an **E5 / E5
  Compliance-class** plan or the equivalent Purview add-on; **multi-stage** disposition review is newer and
  its availability may differ.
- **Why required:** Disposition review is **plan-gated** — without the right entitlement the label editor
  will not offer "review disposition" and `New-ComplianceTag`/`Set-ComplianceTag` will not accept the
  reviewer/multi-stage properties.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses confirm the compliance plan/add-on. In
  the Microsoft Purview portal, confirm **Records management** is visible and that a retain-then-delete
  label offers a **disposition review** option (single and, where licensed, multi-stage). *Feature-to-plan
  mapping changes — verify the exact entitlement and the multi-stage capability in your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin and to every reviewer account before configuration.

## 2.2 The disposition-review requirement (input from records & legal)
- **Description:** The authoritative statement of **which retention categories/labels require review**
  before disposal (versus automatic deletion), **how many stages** each requires, **who reviews at each
  stage**, and the **disposition authority** (who may finally approve deletion). This is a specific slice of
  the organisation's retention schedule.
- **Why required:** This solution **implements** the review requirement; it does not author it. The stages,
  the reviewers, and the decision to review-versus-auto-delete are all determined by records/compliance/
  legal — without them there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) the list of review categories, the stage
  count and order per category, the named reviewer population per stage, and the final disposition
  authority — or at least a pilot subset.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal functions** —
  request the requirement before configuring. Do not invent review stages, reviewer identities, or the
  decision to review versus auto-delete.

## 2.3 Roles: reviewers in Disposition Management, and least-privilege config
- **Description:** The permission model with strict **role separation** — the **Disposition Management**
  role group for every reviewer (so they can see and act on the Disposition queue), plus **Records
  Management** or **Compliance Administrator / Compliance Data Administrator** for the admin who creates and
  configures the labels and reviewer stages. A reviewer must be **both** a named reviewer on the label
  **and** a member of **Disposition Management** to act.
- **Why required:** Reviewers who are not in **Disposition Management** cannot see the queue at all;
  configuration of labels/stages requires the corresponding records/compliance role. Keeping these separate
  ensures the person disposing content is not necessarily the person who set the schedule.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm every
  reviewer is in **Disposition Management** and that the configuring admin holds Records Management /
  Compliance Administrator. Confirm reviewers are **not** over-granted beyond what review requires.
- **Implement if missing:** Add each reviewer account (or a mail-enabled group's members) to **Disposition
  Management** under change control; grant the admin the least-privilege records/compliance role. Grant
  Disposition Management **only** to named reviewers.

## 2.4 Reviewer groups and mailboxes (stage reviewers)
- **Description:** A **mail-enabled security group per stage** (e.g. `Disposition Reviewers – Records –
  Stage1`) whose members are the stage's reviewers, so stage membership is managed in one place; each
  reviewer must have a **mailbox** to receive disposition notifications, and each must also be in
  **Disposition Management** (2.3).
- **Why required:** Disposition-review stages are addressed by reviewer email (individual or mail-enabled
  group); notifications and reminders require a mailbox; managing reviewers via a group avoids editing the
  label every time membership changes.
- **Verify:** Confirm each stage has a mail-enabled security group (or an agreed reviewer email set), that
  members are mailbox-enabled, and that group membership matches the records/legal reviewer population.
- **Implement if missing:** Create the mail-enabled security groups per stage, populate them from the
  records/legal reviewer list, and add their members to Disposition Management (2.3).

## 2.5 Existing retention labels and disposition posture (verify, don't duplicate)
- **Description:** Knowledge of the **retention labels already in force** — particularly retain-then-delete
  labels — and whether each currently ends in **automatic deletion** or **disposition review**, plus any
  existing reviewers. Retention labels themselves are typically owned by the **org-wide Data Lifecycle &
  Records Management product**; this solution **adds/verifies** review behaviour on them rather than
  re-minting labels.
- **Why required:** Adding a second disposition label for a category that already has one causes confusion
  and precedence surprises; and a label that silently **auto-deletes** where review is required is the exact
  gap this program closes — you must find it first.
- **Verify:** Enumerate existing labels (`Get-ComplianceTag`) and identify which are retain-then-delete,
  which have review enabled (single/multi-stage), and which delete automatically; confirm ownership with the
  records program.
- **Implement if missing:** Engage the org-wide records program owners; capture the existing label baseline
  (the assessment script does this) before creating or modifying disposition labels, and keep label names
  consistent across both products.

## 2.6 Legal hold / eDiscovery boundary (respect, don't manage)
- **Description:** Awareness that content under **legal hold** or **eDiscovery hold** is exempt from
  disposal even after a review is approved, and confirmation that hold management stays with **legal /
  eDiscovery** and is out of this solution's scope.
- **Why required:** Disposition must never delete content that is under a preservation obligation; treating
  hold as someone else's owned control keeps this program inside its boundary and avoids a defensibility
  failure.
- **Verify:** Confirm with legal/eDiscovery that holds are managed separately and that held content is
  understood to be exempt from disposition; do not attempt to enumerate or alter holds from this solution.
- **Implement if missing:** Establish the hand-off: this program routes expiring content to review; legal/
  eDiscovery owns holds. Flag any content class where hold and disposition interact for legal's attention.

## 2.7 Disposition automation toolchain
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for retention labels, disposition-review properties, and role-group
  membership (`Get-/New-/Set-ComplianceTag`, `Get-/Add-RoleGroupMember`), and **Microsoft Graph PowerShell**
  for supporting reads (group/mailbox validation) — a modern-auth / MFA-capable admin.
- **Why required:** The provided scripts and the configuration steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-RoleGroupMember -Identity
  "Disposition Management"` return without error; `Connect-MgGraph` succeeds where used. In Government
  clouds, confirm the correct `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.8 Change control and a documented rollback for disposition
- **Description:** An approved change window and a **rollback plan** specific to disposition: how to
  **disable/unpublish** a disposition label policy, how to **change a label from review back to a staged
  state**, and the explicit note that **a completed (approved) disposition permanently deletes content and
  cannot be rolled back**.
- **Why required:** Disposal is high-impact and partly irreversible; a documented rollback is the safety net
  for the reversible parts (label policy, publication, reviewer membership) and forces a conscious decision
  on the irreversible part (an approved deletion).
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label-policy disable/
  unpublish and reviewer-group changes for the pilot categories, with completed disposition flagged
  **no-rollback**.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control sign-off,
  and explicitly flag **completed disposition** as no-rollback before any production content is governed.
