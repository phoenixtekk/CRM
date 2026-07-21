# 2. Requirements Guide — Remote Help Operations & Adoption

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> This solution is the **operations/adoption layer**. Its single biggest prerequisite is that the
> **base Remote Help deployment already exists** — see 2.1. It does **not** re-teach that setup.

## 2.1 Remote Help already deployed (the base product)
**Description:** Remote Help is already **enabled** tenant-wide, the **Remote Help app is deployed**
to devices via Intune, and the base security model (Entra authentication, RBAC framework,
compliance visibility, audit) is in place.
**Why:** This solution builds the help-desk operating model *around* a working Remote Help
deployment. Without it there is nothing to operate.
**Verify:** Intune → **Tenant administration → Remote Help** shows Remote Help **Enabled**; the
Remote Help app shows as installed on pilot devices. Or run **`RHELPOPS-Discovery.ps1`** (reports
whether Remote Help is enabled and which RBAC role assignments already exist).
**Implement:** If Remote Help is **not** yet deployed, run the separate **"Remote Help"** solution
(slug `remote-help`) first — it covers enable, app deployment, and the security model. Return here
once it is in place.

## 2.2 Help-desk tier definition
**Description:** A defined set of support tiers and, for each, the intended Remote Help capability
(view only, full control, elevation).
**Why:** Roles and scope are assigned per tier; you cannot map roles until the tiers exist.
**Verify:** A written tier model exists (for example **Tier 1 – Service Desk**, **Tier 2 – Desktop
Support**, **Tier 3 – Escalation Engineering**).
**Implement:** Document the tiers and their intended capability before configuring roles (this guide
uses those three tier names throughout).

## 2.3 RBAC role rights to create/assign roles
**Description:** An operator account with rights to create and assign Intune RBAC roles and to read
role assignments.
**Why:** This solution creates custom Remote Help RBAC roles and assigns them with scope.
**Verify:** Intune → **Tenant administration → Roles** is accessible and **Create** / **Assignments**
are available to your account.
**Implement:** Assign **Intune Administrator** (or a role that grants RBAC management) to the
operator. *(The exact built-in role that grants "manage Intune roles" — and whether a custom role
can — must be **verified against current Microsoft documentation**.)*

## 2.4 Remote Help RBAC roles & permissions
**Description:** Remote Help RBAC roles that express each tier's capability (view, full control,
elevation) — either the built-in Remote Help roles or custom roles built from Remote Help
permissions.
**Why:** The role is what limits *what* an agent can do in a session; scope limits *who* they can
help.
**Verify:** Intune → **Tenant administration → Roles**; confirm Remote Help roles/permissions are
available to select.
**Implement:** Create the custom roles in Section 3. *(The exact **names** of the built-in Remote
Help roles, the exact **permission names** for view vs full control vs elevation, and whether
unattended access is expressed as a permission — **verify against current Microsoft documentation**;
do not assume the labels.)*

## 2.5 Licensing for helpers (and any unattended scenario)
**Description:** A Remote Help license assigned to helper (agent) accounts, and any additional
licensing that unattended assistance may require.
**Why:** Remote Help is a licensed add-on; unattended scenarios may have their own licensing or
capability requirements.
**Verify:** M365 admin center → **Billing → Licenses** (Intune Suite / Remote Help add-on) for agent
accounts.
**Implement:** Assign the Remote Help / Intune Suite license to every agent account. *(Whether
unattended access requires any additional license or capability — **verify against current Microsoft
documentation**.)*

## 2.6 Unattended-access governance decision
**Description:** A documented decision on **whether** unattended assistance is allowed, **where** (which
device populations), and **which tier** owns it, plus the guardrails (change/ticket requirement,
logging, review).
**Why:** Unattended access removes the live-consent step, so it must be a deliberate, governed
practice — not a default.
**Verify:** A written unattended-access policy exists and names the owning tier.
**Implement:** Complete the decision in Section 3, Step 4. *(Whether Remote Help offers unattended
access at all, on which platforms, and its exact consent/behavior model — **verify against current
Microsoft documentation** before enabling anything.)*

## 2.7 Ticketing / ITSM integration points
**Description:** A ticketing/ITSM system and a defined point in its workflow where a Remote Help
session is initiated and where the session outcome is logged back.
**Why:** Sessions must be traceable to a ticket for accountability, escalation, and reporting.
**Verify:** Your ITSM system has a ticket state/field where "Remote Help session" can be recorded
(for example a work-note, activity, or custom field).
**Implement:** Define the session-to-ticket steps in Section 3, Step 5. This is a **process**
integration (agents record the session on the ticket); it is not a code integration to any specific
ITSM product.

## 2.8 Reporting / audit read access
**Description:** Access to Remote Help usage/audit data for reporting KPIs.
**Why:** Measurement depends on being able to read session/usage and audit activity.
**Verify:** Intune → **Tenant administration → Remote Help** shows a usage report; or an account with
Graph **AuditLog.Read.All** / **DeviceManagementApps.Read.All** can run **`RHELPOPS-Report.ps1`**.
**Implement:** Grant the reporting account the read access above. *(The exact Remote Help usage
report location and the Graph scopes/endpoints that expose session data — **verify against current
Microsoft documentation**.)*

---
## Checklist
- [ ] Remote Help already deployed (base `remote-help` solution) — `RHELPOPS-Discovery.ps1`
- [ ] Help-desk tiers defined (Tier 1 / Tier 2 / Tier 3) with intended capability
- [ ] Operator has rights to create/assign RBAC roles
- [ ] Remote Help RBAC roles/permissions available (names verified against Microsoft docs)
- [ ] Remote Help license on agent accounts (+ any unattended licensing verified)
- [ ] Unattended-access governance decision documented (owning tier + guardrails)
- [ ] Ticketing/ITSM session-log point defined
- [ ] Reporting/audit read access granted
