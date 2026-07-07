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
