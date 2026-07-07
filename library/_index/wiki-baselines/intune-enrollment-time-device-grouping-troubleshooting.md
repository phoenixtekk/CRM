# Intune Enrollment-Time Device Grouping — Prerequisites, Setup & Troubleshooting (Autopilot Device Preparation + Apple ADE)

> **Version 1.0.0** · Category: Intune · Solution code: ETDG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

**Outcome.** Windows Autopilot **device preparation** and Apple **Automated Device Enrollment
(ADE)** enrollments that reliably place each device into the correct security group **at the moment
of enrollment** — so compliance, configuration, and apps apply during provisioning instead of hours
later. This solution ends the recurring, deployment-blocking failure where saving the enrollment
policy's Device Group returns *"Unable to save device group… the Intune Provisioning Client
application is not an owner."*

**The problem it solves.** Enrollment-Time Grouping only works if a specific Microsoft first-party
service principal — the **Intune Provisioning Client** (AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`) — is an **Owner** of the target group, and the group is a
narrowly-shaped object (Security, **Assigned** membership, **cloud-only**, not mail-enabled, not
role-assignable). Teams miss this because the failure appears **only after Save**, the service
principal's **display name varies by tenant**, and the portal simultaneously throws **unrelated
Azure Monitor `AuthorizationFailed` errors** that misdirect the investigation. Microsoft documents
the requirement for Windows; the identical Apple ADE flow is **barely documented**, so admins are
left guessing.

**Approach.** A prerequisites-first playbook plus a symptom → root-cause diagnostic tree. It gives
the exact group specification (each attribute with why/verify/fix), the owner-by-AppId requirement
and how to add it, the RBAC-scope rules, and named, ordered setup steps for **both** platforms —
then maps every error string to its real cause and explicitly neutralizes the Azure-log red herring.
Five Microsoft Graph PowerShell tools assess group readiness, add the owner (dry-run by default),
validate all prerequisites, and diagnose failures.

**Why it is low-risk.** Everything is **pilot-first** with explicit pass/fail gates and an instant,
non-destructive rollback (clear the Device Group setting), so already-enrolled devices are never
affected. The tooling is **read-only or `-WhatIf` by default**, requests **least-privilege** Graph
scopes, and stores **no secrets**. The result is a repeatable, evidence-backed configuration that
turns a stubborn zero-touch blocker into a solved, documented, and verifiable outcome across the
Windows and Apple fleets.


---


# Solution Overview

## What this solution does

You configure a **device group** on a Windows Autopilot **device preparation** policy, or on
an **Apple Automated Device Enrollment (ADE)** enrollment policy, so that devices land in a
known security group the moment they enroll — ready for the compliance, configuration, and app
assignments targeted at that group. You save the policy… and it fails:

> **"Unable to save device group for `<name>`. You cannot update this configuration because we
> could not find the security group you selected or the Intune Provisioning Client application
> is not an owner."**

The group looks correct. The policy is valid. Yet **Enrollment-Time Grouping** will not commit.
And while you dig, the Azure portal buries you in unrelated `AuthorizationFailed` /
`microsoft.insights/eventtypes/values/read` errors in the Activity Log that send you chasing the
wrong thing entirely.

This solution is the definitive **prerequisites, setup, and diagnostic playbook** for
Enrollment-Time Device Grouping across **both platforms**. It explains the mechanism that trips
everyone up, gives you the exact group specification, walks the setup end-to-end for Windows and
Apple, and hands you a **symptom → root-cause decision tree** that maps every error string to its
real cause — plus five PowerShell (Microsoft Graph) tools to assess, remediate, validate, and
diagnose.

## What Enrollment-Time Grouping is

Historically, a device only landed in an Entra security group **after** it enrolled and Entra
re-evaluated dynamic-group rules — a delay of minutes to hours during which nothing targeted at
that group applied. **Enrollment-Time Grouping** closes that gap: Intune adds the device to a
**specific, pre-chosen Assigned security group at the moment of enrollment**, so the first policy
sync already sees the device as a group member. That is what makes true zero-touch provisioning
work — apps and configuration are present before the user reaches the desktop or home screen.

This capability appears in two places:

- **Windows Autopilot device preparation** — the newer, simplified Autopilot experience. The
  enrollment policy has a **Device group** setting where you name the group devices join at
  enrollment. Microsoft documents the requirement here.
- **Apple Automated Device Enrollment (ADE)** — the enrollment profile attached to an Apple
  enrollment program token exposes the **same Device Group option** and uses the **same backend
  mechanism**. This solution targets **shared / no-user-affinity** Apple deployments (kiosk,
  shared iPad, front-line device pools).

> **Documentation reality (state this to stakeholders).** Microsoft documents Enrollment-Time
> Grouping primarily for **Windows Autopilot device preparation**. **Apple ADE** exposes the same
> Device Group control and relies on the same service backend, but Microsoft publishes **little
> Apple-specific guidance** for it. This playbook applies the documented Windows requirement to
> the Apple flow because the backend is shared — it does **not** invent Apple-specific Microsoft
> documentation that does not exist. Because the feature is relatively new and partly
> preview-gated, **verify the exact control names and availability in your own tenant.**

## The mechanism that trips everyone up

To add a device to a group **on your behalf, at enrollment time**, Intune acts through a
Microsoft first-party service principal called the **Intune Provisioning Client**. Entra will
only let that service principal write membership into a group if it is an **Owner** of that group.

- **The service principal must be an OWNER of the target group.** AppId
  **`f1346770-5b25-470b-88bd-d5744ab7952c`** — a fixed Microsoft first-party identifier.
- **The display name varies by tenant.** In some tenants it shows as **Intune Provisioning
  Client**; in others as **Intune Autopilot ConfidentialClient**. **Always match by AppId, never
  by name.**
- **The failure happens only *after* Save.** Adding the group to the policy in the UI succeeds;
  the relationship Intune establishes when you **Save** is what fails if the owner is missing.
  That is why the error feels like it comes from nowhere.

When the owner is present, correct, and propagated, Save commits and devices populate the group at
enrollment. When it is missing, you get the "not an owner" error — every time, on both platforms.

## Reference design

| Artifact | Windows | Apple |
|----------|---------|-------|
| Target device group | `Autopilot – Devices – Prod` | `iOS – Shared Devices – Prod` |
| Pilot device group | `Autopilot – Devices – Pilot` | `iOS – Shared Devices – Pilot` |
| Group owner (required) | Intune Provisioning Client SP (AppId `f1346770-…`) | same SP, same AppId |
| Enrollment policy | `Autopilot DevicePrep – Shared – Prod` | `ADE Enrollment – Shared iOS – Prod` |
| Enrollment token | (Autopilot uses device-prep policy) | `ADE Token – Corporate – Prod` |

Every target group in this design is the same shape: **Security**, **Assigned** membership,
**cloud-only**, **not mail-enabled**, **not role-assignable**, ideally **empty at creation**, and
**owned by the Intune Provisioning Client**. The full matrix and the *why* behind each attribute
are in **02 — Requirements**.

## Benefits

- **Zero-touch that actually works** — devices are group members at first sync, so apps and
  configuration apply during provisioning, not hours later.
- **One method, both platforms** — the same prerequisite and the same fix cover Windows Autopilot
  device preparation and Apple ADE.
- **No more wrong turns** — the Azure Activity Log `AuthorizationFailed` noise is called out as an
  unrelated red herring so you stop chasing it.
- **Repeatable and evidenced** — PowerShell/Graph tools prove readiness before you touch a policy
  and map any error you hit to its cause.

## Limitations and boundaries

- **Group membership must be Assigned, not Dynamic.** Intune manages membership at enrollment; a
  Dynamic group's rule engine owns membership and conflicts with that — Dynamic groups are not
  supported for this purpose.
- **The group must be cloud-only.** A group synced from on-premises AD cannot have its membership
  written by the service principal.
- **Preview / version dependence.** Control names, availability, and behavior for Enrollment-Time
  Grouping (especially on Apple) may differ by tenant and change over time — **verify in your
  tenant**.
- **Not a licensing or MDM-authority fix.** This solution assumes Intune is the MDM authority and
  the category prerequisites (see the Global Requirements) are already met.

## Deployment model

This solution follows the standard house model — **Assess → Configure → Pilot → Validate →
Expand** — with explicit pass/fail gates and a documented rollback at each step:

1. **Assess** — confirm the group specification and whether the Intune Provisioning Client is
   already an owner (`ETDG-Assess-GroupReadiness.ps1`, `ETDG-Test-EnrollmentGroupPrereqs.ps1`).
2. **Configure** — create the group to spec and add the service principal as Owner
   (`ETDG-Set-ProvisioningClientOwner.ps1`, `-WhatIf` by default).
3. **Pilot** — wire the **pilot** group to a pilot enrollment policy on each platform, enroll a
   test device, confirm it joins the group.
4. **Validate** — the policy Saves, the device populates the group at enrollment, and the group's
   assignments (apps/config) apply (`05 — Testing`).
5. **Expand** — promote to the **Prod** groups and policies; keep the diagnostic report tool
   (`ETDG-Get-DiagnosticReport.ps1`) on hand for any recurrence.


---


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


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation

Follow these ordered steps to stand up Enrollment-Time Device Grouping correctly on **both**
platforms, using the reference-design artifact names. Pilot first, validate against explicit gates,
then expand. A rollback is documented at the end of each phase.

> **Naming convention** (`<Purpose> – <Scope> – <Stage>`), reused in Testing, Troubleshooting, and
> the scripts:
> - Windows target group: **`Autopilot – Devices – Pilot`** → **`Autopilot – Devices – Prod`**
> - Apple target group: **`iOS – Shared Devices – Pilot`** → **`iOS – Shared Devices – Prod`**
> - Windows enrollment policy: **`Autopilot DevicePrep – Shared – Prod`**
> - Apple enrollment profile: **`ADE Enrollment – Shared iOS – Prod`**
> - Apple enrollment token: **`ADE Token – Corporate – Prod`**

---

## Phase 0 — Assess (before you change anything)

**Step 0.1 — Baseline the group (if one already exists).** Run
`ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot – Devices – Pilot"`. It reports Type,
MembershipType, `onPremisesSyncEnabled`, `mailEnabled`, `isAssignableToRole`, member count, and
whether AppId `f1346770-5b25-470b-88bd-d5744ab7952c` is already an Owner — pass/fail per prerequisite
(R1–R7).

**Step 0.2 — Confirm the service principal exists and check RBAC scope.** Run
`ETDG-Test-EnrollmentGroupPrereqs.ps1 -GroupName "Autopilot – Devices – Pilot"`. It validates R1–R9,
confirms the Intune Provisioning Client SP is present in the tenant (by AppId), and lists the
operating admin's Intune role assignments / scope groups.

**Gate 0 (pass/fail):** Proceed only when you know exactly which prerequisites are unmet. If the SP
is **absent**, resolve that first (Step B.0). **Do not** open a policy Save until the group is to
spec and owned.

---

## Phase A — Create the target group to spec

Do this for the **Pilot** group first (`Autopilot – Devices – Pilot` and/or
`iOS – Shared Devices – Pilot`), then repeat for **Prod** in Phase E.

**Step A.1 — New Security, Assigned, cloud-only group.**
Entra admin center → **Groups → New group**:
- **Group type:** Security
- **Group name:** `Autopilot – Devices – Pilot` (or `iOS – Shared Devices – Pilot`)
- **Membership type:** **Assigned** (do **not** choose Dynamic Device or Dynamic User) — **R2**
- Leave **Microsoft Entra roles can be assigned to the group = No** — **R5** (cannot be changed
  later)
- Do **not** mail-enable it — **R4**
- Add **no members** yet — **R6**

**Step A.2 — Confirm it is cloud-only.** After creation, open the group → confirm **Source =
Cloud** (not "Windows Server AD") — **R3**. If it shows as directory-synced, you selected a synced
group; create a genuinely cloud-only one.

**Step A.3 — Confirm the admin can manage it.** Verify you can open **Owners** and **Members**
without an access error — **R8**.

**Pass/fail (Gate A):** `ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot – Devices – Pilot"`
reports **all of R1–R6 = PASS**. If any fails, fix per **02 — Requirements** before continuing.

**Rollback A:** Delete the newly created group (Entra → Groups → `<group>` → Delete). Nothing is
wired to a policy yet, so deletion has no enrollment impact.

---

## Phase B — Add the Intune Provisioning Client as **Owner**

**Step B.0 — Provision the service principal if it is missing.** If Step 0.2 reported the SP
absent: sign in to **`https://intune.microsoft.com` once as a Global Administrator** to trigger
first-party SP provisioning, then re-run `ETDG-Test-EnrollmentGroupPrereqs.ps1`. If it still does
not appear, open a **Microsoft support case** to have the Intune Provisioning Client initialized.

**Step B.1 — Add the owner (portal).** Entra → **Groups → `Autopilot – Devices – Pilot` → Owners →
Add owners**. Search by AppId **`f1346770-5b25-470b-88bd-d5744ab7952c`** (or by name — **Intune
Provisioning Client** *or* **Intune Autopilot ConfidentialClient**; **match by AppId**, the name
varies by tenant). Select it → **Add**.

**Step B.1 (alt) — Add the owner (script).** Run
`ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "Autopilot – Devices – Pilot"` to preview
(`-WhatIf` default), then `-WhatIf:$false` to commit.

**Step B.2 — Wait for propagation.** Entra can take **5–10 minutes** to propagate the ownership.
Refresh the **Owners** blade and confirm an owner with **Application ID**
`f1346770-5b25-470b-88bd-d5744ab7952c` is listed before proceeding.

**Pass/fail (Gate B):** `ETDG-Assess-GroupReadiness.ps1` reports **Provisioning Client owner =
PASS** (found by AppId). If not present after 10 minutes, re-add and wait again.

**Rollback B:** Remove the SP from **Owners** (Entra → Groups → `<group>` → Owners → remove). The
group reverts to a plain security group; no devices are affected until a policy is wired.

---

## Phase C — Confirm admin management + RBAC scope

**Step C.1 — Manage check.** Confirm the operating admin can still edit the group's Owners/Members
(**R8**).

**Step C.2 — RBAC scope (custom Intune RBAC only).** If your tenant uses custom Intune RBAC: Intune
→ **Tenant administration → Roles → `<admin's role assignment>` → Scope (Groups)** and confirm the
target group (or a parent scope group containing it) is in scope (**R9**).
`ETDG-Test-EnrollmentGroupPrereqs.ps1` lists the admin's scope groups.

**Pass/fail (Gate C):** Admin can manage the group **and** (if custom RBAC) the group is in the
admin's scope. Tenants using only built-in roles pass C automatically.

---

## Phase D — Wire the group to the enrollment policy (pilot), then Save

Do the platform(s) you are deploying. Use the **Pilot** group in this phase.

### D-Windows — Autopilot device preparation

**Step DW.1 — Open the policy.** Intune → **Devices → Enrollment → Windows → Device preparation
policies** → create or edit **`Autopilot DevicePrep – Shared – Prod`** (name a pilot copy
`Autopilot DevicePrep – Shared – Pilot` if you prefer to keep pilot and prod separate).
*(Verify the exact blade name in your tenant — the device-preparation experience is newer and
labels vary.)*

**Step DW.2 — Set the Device Group.** In the policy's **Device group** setting, select
**`Autopilot – Devices – Pilot`**. This is the group devices join at enrollment.

**Step DW.3 — Save.** Click **Save/Create**. **Enrollment-Time Grouping is established here** — if
the owner (Phase B) is correct and propagated, Save commits. If you see *"…the Intune Provisioning
Client application is not an owner,"* stop and go to **06 — Troubleshooting** (do not disable
anything).

### D-Apple — ADE enrollment profile

**Step DA.1 — Locate the enrollment token.** Intune → **Devices → Enrollment → Apple → Enrollment
program tokens** → open **`ADE Token – Corporate – Prod`** → **Profiles**.
*(Path/label may read "Enrollment Program Tokens" or "ADE tokens" — verify in your tenant.)*

**Step DA.2 — Create/edit the ADE enrollment profile.** Create or edit **`ADE Enrollment – Shared
iOS – Prod`**. Set **User affinity = Enroll without user affinity** (shared devices). In the
profile's **Device Group** option, select **`iOS – Shared Devices – Pilot`**.

**Step DA.3 — Save.** Save the profile. The **same backend** establishes Enrollment-Time Grouping
here; the same owner requirement applies. Watch for the generic **"Updating device group for Apple
enrollment policy"** notification — if it hangs or fails, go to **06 — Troubleshooting**.

**Pass/fail (Gate D):** The pilot enrollment policy **Saves without the "not an owner" error** on
each platform you deployed.

**Rollback D:** Clear the **Device Group** setting on the policy/profile and Save (or delete the
pilot policy). Enrollment continues **without** enrollment-time grouping; devices fall back to
post-enrollment (dynamic/manual) group membership.

---

## Phase E — Validate, then Expand to Prod

**Step E.1 — Enroll a pilot device.** Enroll one Windows Autopilot device-prep device and/or one
Apple ADE device against the pilot policy.

**Step E.2 — Confirm enrollment-time membership.** After enrollment, confirm the device appears as
a **Member** of `Autopilot – Devices – Pilot` / `iOS – Shared Devices – Pilot`, and that
group-targeted apps/config apply. See **05 — Testing** for the exact checks and pass/fail.

**Step E.3 — Expand to Prod.** Repeat **Phases A–D** for the **Prod** groups
(`Autopilot – Devices – Prod`, `iOS – Shared Devices – Prod`) and the **Prod** enrollment policies,
then re-validate.

**Pass/fail (Gate E):** A pilot device **joins the group at enrollment** and receives the group's
assignments. Only then promote to Prod.

**Rollback E:** Point the Prod policy back at the previously working configuration (or clear its
Device Group). Because the group and owner are additive, rollback never removes protection from
already-enrolled devices — it only stops future enrollment-time additions.

---

## Order of operations (must not be reordered)

1. Group exists **to spec** (R1–R6) → 2. Owner added (R7) → 3. **Wait 5–10 min** for propagation →
4. Wire to policy → 5. **Save**. Saving before the owner has propagated is the most common
self-inflicted failure.


---


# Testing & Validation

Run these validations in order. Each has an **expected pass/fail** so you can prove the deployment
works before promoting to Prod. The scripts referenced are described in **08 — Deliverables
Summary**.

---

## T1. Group specification is correct (R1–R6)

**How:** `ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot – Devices – Pilot"` (repeat for the
Apple group).
**Pass:** Type = Security, MembershipType = Assigned, `onPremisesSyncEnabled` = null/false,
`mailEnabled` = false, `isAssignableToRole` = false, member count = 0 (or intended) — all **PASS**.
**Fail:** Any attribute off-spec → fix per **02 — Requirements** (create a fresh group where the
attribute is create-only, i.e. Dynamic, role-assignable, or synced).

## T2. The Intune Provisioning Client is an Owner (R7)

**How:** `ETDG-Assess-GroupReadiness.ps1` (owner check) **or** Entra → Groups → `<group>` → Owners.
**Pass:** An owner with **Application ID** `f1346770-5b25-470b-88bd-d5744ab7952c` is listed (name
may read *Intune Provisioning Client* or *Intune Autopilot ConfidentialClient* — matched by AppId).
**Fail:** No owner by that AppId → add it (Phase B), **wait 5–10 minutes**, re-test.

## T3. Service principal exists + RBAC scope (R7, R9)

**How:** `ETDG-Test-EnrollmentGroupPrereqs.ps1 -GroupName "Autopilot – Devices – Pilot"`.
**Pass:** SP found in tenant by AppId; and (custom RBAC only) the target group is within the
admin's scope groups.
**Fail — SP absent:** open Intune portal once as Global Admin to provision it; else Microsoft
support. **Fail — out of scope:** add the group to the admin's role-assignment scope groups.

## T4. The enrollment policy **Saves** (the core gate)

**How:** In Intune, set the pilot group as the **Device Group** on the pilot enrollment policy and
click **Save** — Windows: `Autopilot DevicePrep – Shared – Pilot/Prod`; Apple:
`ADE Enrollment – Shared iOS – Prod`.
**Pass:** Save completes with no error; the Device Group persists on reopen.
**Fail:** *"Unable to save device group… the Intune Provisioning Client application is not an
owner"* → owner missing or not yet propagated (T2). *"…could not find the security group you
selected"* → group deleted/renamed or out of RBAC scope (T3). Go to **06 — Troubleshooting**.

> **Ignore** any `AuthorizationFailed` / `microsoft.insights/eventtypes/values/read` entries in the
> Azure **Activity Log** that appear around this time — they are an **unrelated Azure Monitor
> red herring** (see Troubleshooting), not the enrollment-grouping result.

## T5. Device joins the group **at enrollment**

**How:** Enroll one pilot device (Windows Autopilot device-prep and/or Apple ADE, no user
affinity). After enrollment completes, check membership.
**Pass:** The device appears as a **Member** of `Autopilot – Devices – Pilot` /
`iOS – Shared Devices – Pilot` shortly after enrollment — **without** waiting on a dynamic-rule
re-evaluation. Confirm via Entra → Groups → `<group>` → Members, or
`ETDG-Assess-GroupReadiness.ps1` member count increments.
**Fail:** Device enrolls but never joins the group → re-check T2 (owner) and T4 (Save actually
committed); confirm the policy the device enrolled through has the Device Group set.

## T6. Group-targeted assignments apply during provisioning

**How:** Assign a benign test app or configuration profile to the pilot group **before** enrolling
the pilot device; enroll and observe.
**Pass:** The group-targeted app/config is delivered during or immediately after provisioning
(proving membership was effective at enrollment time, not hours later).
**Fail:** Assignment does not apply → confirm T5 (membership) first; if membership is present but
assignment lags, that is normal Intune sync latency, not an enrollment-grouping fault.

## T7. Second-device repeatability

**How:** Enroll a second pilot device.
**Pass:** It also joins the group at enrollment — confirming the configuration is durable, not a
one-off.
**Fail:** Inconsistent joins → capture the Save/enrollment behavior and run
`ETDG-Get-DiagnosticReport.ps1` with the observed symptom.

---

**Promotion gate:** T1–T7 all **PASS** on the pilot before wiring the **Prod** groups and policies.
Re-run T1–T5 after the Prod cutover.


---


# Troubleshooting

A **symptom → root-cause decision tree** for Enrollment-Time Device Grouping. Match the exact
string or behavior you see, apply the fix, and re-test with the referenced script. The single most
common cause is a **missing or not-yet-propagated Provisioning Client owner** — start there.

---

## Decision tree (start at the top)

```
Did the enrollment policy SAVE?
├─ NO — error: "...Intune Provisioning Client application is not an owner"   → §1
├─ NO — error: "...could not find the security group you selected"          → §2
├─ NO — Apple: "Updating device group for Apple enrollment policy" hangs    → §3
├─ Seeing AuthorizationFailed / microsoft.insights errors in Azure log      → §4 (IGNORE — red herring)
└─ YES it saved, but devices never join the group at enrollment            → §7

Owner IS present, spec passes, still fails on Save                          → §8 (escalate)
Service principal cannot be found at all (by AppId or name)                 → §6
Using custom Intune RBAC and can't see/select the group                    → §5
```

Fast triage: `ETDG-Get-DiagnosticReport.ps1 -Symptom <NotAnOwner|CouldNotFindGroup|AppleUpdatingHang|AzureAuthorizationFailed|SavedButNoMembership|Unknown> -GroupName "<group>"`.

---

## §1 — "…the Intune Provisioning Client application is not an owner" (the definitive error)

**Full string:** *"Unable to save device group for `<name>`. You cannot update this configuration
because we could not find the security group you selected or the Intune Provisioning Client
application is not an owner."*

**When:** After you click **Save** on the enrollment policy/profile (Windows Autopilot device-prep
or Apple ADE). The failure appears **only after Save** because that is when Intune establishes the
group relationship.

**Root cause:** The Intune Provisioning Client service principal (AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`) is **not an Owner** of the group — or you added it but it
**has not propagated yet**.

**Fix:**
1. Confirm the owner: `ETDG-Assess-GroupReadiness.ps1 -GroupName "<group>"` → **R7**. Or Entra →
   Groups → `<group>` → **Owners**, looking for **Application ID** `f1346770-…` (name may read
   *Intune Provisioning Client* or *Intune Autopilot ConfidentialClient* — **match by AppId**).
2. If missing, add it: `ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "<group>" -WhatIf:$false`,
   or portal → Owners → **Add owners** → search by AppId → Add.
3. **Wait 5–10 minutes** for Entra propagation. Refresh the Owners blade, confirm it is listed.
4. Retry **Save**.

> If the SP genuinely does not exist in the tenant, go to **§6** first.

---

## §2 — "…could not find the security group you selected"

**Root cause (one of):**
- The group was **deleted or renamed** after you selected it.
- The group is **off-spec** — e.g. it is a **Dynamic**, **role-assignable**, or **directory-synced**
  group and cannot serve as an enrollment-time target.
- **Custom Intune RBAC scope** — the group is **outside** the operating admin's scope groups, so
  the service cannot resolve it for that admin (see **§5**).

**Fix:** `ETDG-Assess-GroupReadiness.ps1 -GroupName "<group>"` to confirm the group exists and is
Security / Assigned / cloud-only / not role-assignable. If it is off-spec on a create-only attribute
(Dynamic, role-assignable, synced), **create a fresh group to spec** (see 03 — Implementation,
Phase A). If the group is fine, check RBAC scope (**§5**).

---

## §3 — Apple: "Updating device group for Apple enrollment policy" hangs or fails

**When:** Saving the ADE enrollment profile's Device Group. The generic notification appears and
then stalls or errors (Apple surfaces a less specific message than Windows).

**Root cause:** The **same backend** as Windows. It is almost always the **missing/unpropagated
owner** (**§1**) or an **off-spec group** (**§2**) — Apple just gives you a vaguer symptom.

**Fix:** Treat it as **§1** then **§2**: run `ETDG-Assess-GroupReadiness.ps1` on the Apple group
(`iOS – Shared Devices – Pilot/Prod`), fix any FAIL (owner first), wait for propagation, re-save the
profile.

> **Documentation gap (be honest with stakeholders):** Microsoft documents Enrollment-Time Grouping
> for Windows Autopilot device preparation; **there is little Apple-specific Microsoft documentation**
> for the ADE Device Group option even though it uses the same mechanism. Do not expect an
> Apple-specific KB to match the Windows one — **verify control names/behavior in your tenant**.

---

## §4 — Azure Activity Log `AuthorizationFailed` / `microsoft.insights/...` — RED HERRING, ignore

**Symptom:** While troubleshooting, the Azure portal shows **`AuthorizationFailed`** errors on
**`microsoft.insights/eventtypes/values/read`** across one or more subscriptions.

**Root cause:** These are **Azure Monitor Reader-access** errors surfaced by the Intune/Azure portal
background — a permissions gap on **Azure Monitor**, **completely unrelated** to Enrollment-Time
Grouping.

**Fix:** **Ignore them for this problem.** Do **not** start granting subscription-level RBAC or
Monitor Reader roles hoping to fix the enrollment error — it will not. Return to **§1/§2** and
diagnose the actual Save error. (`ETDG-Get-DiagnosticReport.ps1 -Symptom AzureAuthorizationFailed`
restates this.)

---

## §5 — Custom Intune RBAC: cannot see or select the group

**Symptom:** The group exists and is to spec, but you cannot select it, or Save reports "could not
find the security group" for a specific admin only.

**Root cause:** With **custom Intune RBAC**, an admin can only act on objects within their assigned
**scope groups**. The target group (or a parent scope group) is not in the admin's scope.

**Fix:** Intune → **Tenant administration → Roles → `<admin's role assignment>` → Scope (Groups)**;
add the target group (or a parent scope group that contains it). Or perform setup as an admin whose
scope already includes it. `ETDG-Test-EnrollmentGroupPrereqs.ps1` lists role assignments / scope
groups. Tenants using **built-in roles only** are unaffected.

---

## §6 — The service principal cannot be found at all

**Symptom:** Searching Owners by AppId `f1346770-…` or by name (either *Intune Provisioning Client*
or *Intune Autopilot ConfidentialClient*) returns **nothing**; `ETDG-Test-EnrollmentGroupPrereqs.ps1`
reports **SP present = FAIL**.

**Root cause:** The Intune first-party service principal is **not yet provisioned** in the tenant.

**Fix:**
1. Sign in to **`https://intune.microsoft.com` once as a Global Administrator** — opening the Intune
   portal typically provisions the Intune first-party service principals.
2. Re-run `ETDG-Test-EnrollmentGroupPrereqs.ps1`. If the SP now appears, proceed to add it as owner
   (**§1**).
3. If it **still** does not appear, open a **Microsoft support case** to have the Intune
   Provisioning Client initialized.

---

## §7 — Policy saved, but devices never join the group at enrollment

**Root cause (one of):**
- The **owner was removed** from the group after Save (routine "cleanup" that silently breaks it).
- The device enrolled through a **different policy/profile** that lacks the Device Group setting.
- The group was **changed off-spec** after the fact.

**Fix:** Re-run `ETDG-Assess-GroupReadiness.ps1` and confirm **R7 (owner) still PASS**; confirm the
exact enrollment policy the device used still has the correct Device Group; re-enroll a test device
(**05 — Testing**, T5). `ETDG-Get-DiagnosticReport.ps1 -Symptom SavedButNoMembership -GroupName
"<group>"` corroborates live state.

---

## §8 — Owner is present and correct, spec passes, Save STILL fails (escalation)

**When:** `ETDG-Assess-GroupReadiness.ps1` reports everything PASS (owner by AppId confirmed, group
to spec), propagation time has elapsed, and Save still fails.

**Root cause:** Likely a **tenant/service-side backend issue**, not your configuration.

**Fix (capture the real error, then escalate):**
1. Reproduce the Save with **browser dev tools** open (F12 → **Network**), or replay the operation
   via **Microsoft Graph**, and capture the **actual failing request/response** — the backend error
   is more specific than the portal banner.
2. Open a **Microsoft support case** with that payload (the group id, the SP AppId `f1346770-…`
   confirmed as owner, timestamps, and the captured backend error).

---

## Quick reference — error string → cause → action

| You see… | Cause | Do this |
|----------|-------|---------|
| "…Provisioning Client application is not an owner" | Owner missing / not propagated | §1 — add SP owner by AppId, wait 5–10 min, retry Save |
| "…could not find the security group you selected" | Group deleted/renamed, off-spec, or out of RBAC scope | §2 / §5 |
| Apple "Updating device group…" hangs | Same backend — usually owner/spec | §3 → §1/§2 |
| Azure `AuthorizationFailed` / `microsoft.insights` | Azure Monitor noise, unrelated | §4 — **ignore** |
| SP not found by AppId or name | SP not provisioned | §6 — open Intune as Global Admin / support |
| Saved but no membership | Owner removed / wrong policy / changed group | §7 |
| All PASS but Save fails | Service-side backend issue | §8 — capture via Graph/dev tools, support case |


---


# Best Practices

Durable practices for Enrollment-Time Device Grouping that keep it working across tenants,
platforms, and staff turnover.

## Group design

- **One purpose per group.** Use a dedicated Assigned security group per platform and role
  (`Autopilot – Devices – Prod`, `iOS – Shared Devices – Prod`). Do not reuse a group that also
  drives licensing or unrelated assignments — enrollment-time membership should be unambiguous.
- **Get the create-only attributes right the first time.** **Membership type (Dynamic vs
  Assigned)**, **role-assignable**, and **directory-sync source** cannot be safely changed after
  creation. If any is wrong, make a new group — do not try to convert.
- **Start empty.** An empty target group makes it obvious that enrollment is what populated it, and
  keeps validation honest.
- **Never use a Dynamic group** for this purpose. It is the number-one misconfiguration and it is
  unsupported — Intune's enrollment-time write and Entra's rule engine cannot both own membership.

## The owner requirement

- **Match the service principal by AppId, always.** `f1346770-5b25-470b-88bd-d5744ab7952c` is
  constant; the display name (**Intune Provisioning Client** vs **Intune Autopilot
  ConfidentialClient**) is not. Documentation, runbooks, and scripts should key on the AppId.
- **Add the owner *before* wiring the policy, and wait for propagation.** Budget **5–10 minutes**
  after adding the owner before you Save. Saving too early is a self-inflicted "not an owner"
  failure.
- **Treat the owner as protected configuration.** Do not remove the Intune Provisioning Client from
  a group's owners as part of routine cleanup — it silently breaks future enrollment-time
  additions. Document its presence in your group's description.

## RBAC and delegation

- **Keep target groups inside operators' Intune RBAC scope.** With custom RBAC, a group outside
  scope produces a confusing "cannot find the security group" symptom. Add enrollment-time target
  groups to the relevant role-assignment scope groups deliberately.
- **Use least privilege for the tooling.** Run the read-only assessment/validation scripts with
  read scopes; grant `Group.ReadWrite.All` only for the brief window you use the add-owner tool.

## Change control and validation

- **Pilot first, always.** Validate the full chain (group → owner → Save → device joins at
  enrollment → assignments apply) on `…– Pilot` groups before touching `…– Prod`.
- **Prove it with a real enrollment**, not just a successful Save. A policy can save and still not
  populate devices if something upstream changes; T5–T7 in Testing catch that.
- **Keep a rollback ready.** Clearing the Device Group on a policy is a safe, instant rollback that
  never removes protection from already-enrolled devices.

## Cross-platform discipline

- **Apply the documented Windows requirement to Apple deliberately.** Microsoft documents this for
  Autopilot device preparation; Apple ADE uses the same backend but is sparsely documented.
  Because control names and availability can differ, **verify Apple labels and behavior in your
  tenant** and record what you find — do not assume the Apple UI matches the Windows docs
  verbatim.
- **Standardize the naming convention** (`<Purpose> – <Scope> – <Stage>`) across both platforms so
  the same runbook, tests, and scripts read cleanly for Windows and Apple.

## Noise discipline

- **Pre-brief your team on the Azure Activity Log red herring.** The `AuthorizationFailed` /
  `microsoft.insights/eventtypes/values/read` errors are Azure Monitor Reader-access noise
  surfaced by the portal — **not** the enrollment-grouping problem. Teaching this up front saves
  hours of misdirected troubleshooting.

## Documentation and evidence

- **Record the exact artifact names, the AppId owner, and the tenant-verified control paths** in
  your own runbook, since Apple labels and the newer Windows blades are version-dependent.
- **Save the output of `ETDG-Assess-GroupReadiness.ps1` / `ETDG-Test-EnrollmentGroupPrereqs.ps1`**
  as the "known-good" baseline so a future regression is a one-command diff.


---


# Deliverables Summary

## Documentation

| Document | What it covers |
|----------|----------------|
| **01 — Solution Overview** | What Enrollment-Time Grouping is, the Provisioning-Client-owns-the-group mechanism, cross-platform scope (Autopilot device preparation + Apple ADE), the Windows-docs / Apple-doc-gap reality, and the Assess→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The full target-group specification matrix (Security / Assigned / cloud-only / not mail-enabled / not role-assignable / ideally empty), the Intune Provisioning Client owner requirement (AppId `f1346770-…`), admin-can-manage, Intune RBAC scope groups, and Graph PowerShell — each with Description / Why / Verify / Implement. References the category Global Requirements. |
| **03 — Implementation** | Ordered setup for both platforms: create the group to spec, add the Provisioning Client owner (provision the SP if absent), confirm manage + RBAC scope, wire to a Windows Autopilot device-preparation policy and an Apple ADE enrollment profile, wait for propagation, Save, validate — with pass/fail gates and rollback. |
| **05 — Testing** | Validation procedures T1–T7 with expected pass/fail: group spec, owner present, SP + RBAC scope, policy Saves, device joins the group at enrollment, assignments apply, repeatability. |
| **06 — Troubleshooting** | The symptom → root-cause decision tree keyed to the exact error strings, the Azure-log red herring, propagation delay, SP-named-differently (AppId), SP-missing (provision), RBAC scope, unsupported group shape, and the Graph / dev-tools inspection + Microsoft-support escalation path. |
| **07 — Best Practices** | Durable practices for group design, the owner requirement, RBAC/delegation, change control, cross-platform discipline, and noise discipline. |
| **Executive Summary** | One-page outcome, approach, and why it is low-risk. |

## PowerShell (Microsoft Graph) tools

All scripts use modern-auth `Connect-MgGraph` (no stored secrets), request the **least** scopes,
and are **read-only or `-WhatIf` by default**. The fixed AppId
`f1346770-5b25-470b-88bd-d5744ab7952c` is used throughout to identify the Intune Provisioning Client
by identifier, not by its tenant-variable display name.

| Script | What it does | Safe default |
|--------|--------------|--------------|
| **`ETDG-Assess-GroupReadiness.ps1`** | Reports a target group's Type, MembershipType, `onPremisesSyncEnabled`, `mailEnabled`, `isAssignableToRole`, and member count, and whether AppId `f1346770-…` is an **Owner** — pass/fail per prerequisite (R1–R7). | Read-only |
| **`ETDG-Set-ProvisioningClientOwner.ps1`** | Adds the Intune Provisioning Client service principal (by AppId) as an **Owner** of the target group. Previews the change first; commits only with `-WhatIf:$false`. | `-WhatIf` (preview) |
| **`ETDG-Test-EnrollmentGroupPrereqs.ps1`** | Full prerequisite validation: R1–R7 on the group, confirms the SP **exists** in the tenant by AppId, and lists the admin's Intune **RBAC role assignments / scope groups** (R9). | Read-only |
| **`ETDG-Get-DiagnosticReport.ps1`** | Maps an observed error string / state to its likely root cause per the decision tree, and explicitly flags the Azure Activity Log `AuthorizationFailed` entries as an unrelated red herring. Can pull live group state to corroborate. | Read-only |
| **`ETDG-Config.ps1`** | Shared configuration/helper: the fixed AppId, artifact-name defaults, a scope/connection helper, and a one-shot health summary that stitches the readiness + prereq checks into a single scoped run. | Read-only |
