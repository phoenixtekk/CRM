# Requirements

These are the **solution-specific** prerequisites for Enrollment-Time Device Grouping. They build
**on top of** the category-level **Global Requirements — Intune Solutions** (Entra tenant, Intune
subscription, admin roles, enrollment, pilot group, network access) — confirm those first; this
document does **not** repeat them.

Each requirement is stated as **Description · Why · Verify · Implement-if-missing.** The centerpiece
is the **target-group specification** — a device group used for Enrollment-Time Grouping must match
**every** row of the matrix, or Save fails.

---

## R1. The target group is a **Security** group

**Description:** The group devices join at enrollment must be a **Security** group (not Microsoft
365 / Unified).
**Why:** Enrollment-Time Grouping targets device security principals; a Microsoft 365 group is a
collaboration object and is not valid here.
**Verify:** Entra → **Groups** → open the group → **Group type = Security**. Via Graph:
`groupTypes` is empty (an M365 group has `groupTypes: ["Unified"]`) and `securityEnabled = true`.
Run `ETDG-Assess-GroupReadiness.ps1`.
**Implement:** Entra → **Groups → New group → Group type: Security**.

## R2. Membership type is **Assigned** (never Dynamic)

**Description:** The group's membership type must be **Assigned**, so membership is written
explicitly — not computed by a rule.
**Why:** Intune adds the device to the group **at enrollment** by writing membership through the
Intune Provisioning Client. A **Dynamic** group (user or device) has its membership owned by
Entra's rule engine; the two cannot coexist, and Dynamic groups are **not supported** for this
purpose. This is the single most common misconfiguration.
**Verify:** Group → **Membership type = Assigned**. Via Graph: `membershipRule` is null and
`membershipRuleProcessingState` is not `On`. `ETDG-Assess-GroupReadiness.ps1` flags Dynamic.
**Implement:** Create a new **Assigned** group; you cannot convert a Dynamic group's rule-driven
membership into Assigned safely — make a fresh group to spec.

## R3. The group is **cloud-only** (not synced from on-premises AD)

**Description:** The group must be created in Entra, not synchronized from on-premises Active
Directory.
**Why:** Membership of a directory-synced group is mastered on-premises; the Intune Provisioning
Client cannot write cloud membership into it, so enrollment-time additions fail.
**Verify:** Group → **Source = Cloud** (not "Windows Server AD"). Via Graph:
`onPremisesSyncEnabled` is **null or false**. `ETDG-Assess-GroupReadiness.ps1` reports this.
**Implement:** Create the group in Entra directly. Do not use a group that AAD Connect / Entra
Cloud Sync manages.

## R4. The group is **not mail-enabled**

**Description:** The security group must **not** be mail-enabled (no mail-enabled security groups /
distribution semantics).
**Why:** Mail-enabled groups carry Exchange attributes and membership constraints that are
incompatible with programmatic enrollment-time membership writes.
**Verify:** Group has no email address. Via Graph: `mailEnabled = false`.
`ETDG-Assess-GroupReadiness.ps1` checks it.
**Implement:** Use a plain Security group created without mail. If the existing group is
mail-enabled, create a new non-mail-enabled group.

## R5. The group is **not Entra role-assignable**

**Description:** The group must **not** be marked "Microsoft Entra roles can be assigned to the
group."
**Why:** Role-assignable groups are protected objects with restricted management and ownership
rules; they cannot serve as an enrollment-time target and block the required ownership model.
**Verify:** Group → **Microsoft Entra roles can be assigned to the group = No**. Via Graph:
`isAssignableToRole = false` (or null). `ETDG-Assess-GroupReadiness.ps1` reports it.
**Implement:** This attribute is **set only at creation and cannot be changed** — if the group is
role-assignable, create a **new** non-role-assignable group.

## R6. The group is ideally **empty** at setup

**Description:** Start with an **empty** target group (no pre-existing members).
**Why:** Enrollment-Time Grouping is meant to populate the group as devices enroll; pre-loaded or
mixed membership makes validation ambiguous and can mask whether enrollment actually added the
device. Empty is cleanest; it is a **best practice**, not a hard blocker.
**Verify:** Group → **Members** is empty. Via Graph: member count = 0.
`ETDG-Assess-GroupReadiness.ps1` reports member count.
**Implement:** Remove pre-existing members, or create a fresh empty group.

## R7. The **Intune Provisioning Client** service principal is an **OWNER** of the group

**Description:** The Microsoft first-party service principal **Intune Provisioning Client** — AppId
**`f1346770-5b25-470b-88bd-d5744ab7952c`** — must be an **Owner** of the target group. This is the
requirement whose absence produces the "not an owner" Save failure.
**Why:** Entra only permits that service principal to write membership into a group it **owns**.
Enrollment-Time Grouping performs that write; without ownership, Save cannot establish the group
relationship.
**Verify:** Entra → **Groups → `<group>` → Owners** → an owner whose **Application ID** is
`f1346770-5b25-470b-88bd-d5744ab7952c`. **Match by AppId, not name** — it may display as **Intune
Provisioning Client** *or* **Intune Autopilot ConfidentialClient**. `ETDG-Assess-GroupReadiness.ps1`
and `ETDG-Test-EnrollmentGroupPrereqs.ps1` confirm the owner by AppId.
**Implement:** Add it as owner — Entra → **Groups → `<group>` → Owners → Add owners**, search by the
AppId or its display name, select, **Add**. Or run `ETDG-Set-ProvisioningClientOwner.ps1`
(`-WhatIf` by default). **Allow 5–10 minutes for propagation** before retrying Save.

> **If the service principal does not exist in the tenant at all** (search returns nothing by AppId
> or name): it may not be provisioned yet. **Opening the Intune portal once as a Global
> Administrator** typically provisions the Intune first-party service principals. If it still does
> not appear, open a **Microsoft support case** to have it initialized —
> `ETDG-Test-EnrollmentGroupPrereqs.ps1` reports SP-exists as a distinct check.

## R8. The administrator can **manage** the group

**Description:** The admin performing setup must be able to manage the target group (view it, edit
owners/members, and select it in the enrollment policy).
**Why:** If the admin cannot manage the group, they cannot add the owner or wire it to a policy —
and in some tenants group creation/management is restricted.
**Verify:** The admin can open the group and edit **Owners** and **Members** without an access
error.
**Implement:** Grant the admin **Groups Administrator** (or ensure ownership/appropriate Entra
role) for the group. Reserve Global Administrator for tenant-wide changes.

## R9. The group is within the admin's **Intune RBAC scope groups** (if custom RBAC is used)

**Description:** If your tenant uses **custom Intune RBAC** with **scope groups / scope tags**, the
target group must fall within the operating admin's assigned **scope groups**.
**Why:** With custom RBAC, an admin can only act on objects inside their scope. A target group
outside scope can produce a "cannot find the security group you selected" symptom even when the
group and owner are correct — the admin simply cannot see/select it.
**Verify:** Intune → **Tenant administration → Roles → `<the admin's role assignment>`** → review
**Scope (Groups)**; confirm the target group (or a parent scope group containing it) is listed.
`ETDG-Test-EnrollmentGroupPrereqs.ps1` surfaces the admin's role assignments and scope groups.
**Implement:** Add the target group to the admin's role-assignment **scope groups**, or perform the
setup with an admin whose scope already includes it. (Tenants **without** custom Intune RBAC — using
built-in roles only — are unaffected.)

## R10. Microsoft Graph PowerShell for automation

**Description:** The **Microsoft.Graph** PowerShell SDK (v2+), used with modern authentication, for
the five tools in this solution.
**Why:** The scripts assess group readiness, add the owner, validate prerequisites, and map errors —
all via Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a module;
`Connect-MgGraph` succeeds interactively.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent the **least** scopes the
scripts request (e.g. `Group.Read.All`, `Application.Read.All`, `DeviceManagementRBAC.Read.All` for
read tools; `Group.ReadWrite.All` only for the add-owner tool). No app secrets are stored — all
scripts use interactive/delegated Connect-MgGraph.

---

**Prerequisite gate:** Do not attempt to Save an enrollment policy's Device Group until **R1–R7**
pass (and **R9** where custom RBAC applies). Run `ETDG-Test-EnrollmentGroupPrereqs.ps1` — a full
pass means Save should commit after propagation; any fail maps directly to a fix above.
