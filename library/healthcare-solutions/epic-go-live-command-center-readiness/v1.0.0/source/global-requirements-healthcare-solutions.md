# Global Requirements — Healthcare Solutions

> **Category-wide prerequisites shared by every solution in the Healthcare Solutions category.**
> These are the baseline tenant, licensing, governance, and operational conditions that every
> healthcare endpoint solution assumes. A solution's own `02-requirements.md` lists only the
> requirements specific to that solution and references this document for the shared baseline.
> Read this first. Never assume any item is already satisfied — verify each one.

Each requirement follows the standard four-part structure: **Description / Why / Verify / Implement if missing.**

---

## GR1 — Microsoft 365 / Intune tenant and administrative roles

**Description.** A Microsoft 365 tenant with Microsoft Intune (Microsoft Endpoint Manager) and Microsoft Entra ID, and the appropriate least-privilege administrative roles for the team performing the work.

**Why.** Every solution in this category manages and validates devices through Intune and Entra via the admin centers and Microsoft Graph. Without the tenant and the right roles, neither the consoles nor the PowerShell scripts can read or change device state.

**Verify.** Sign in to the **Microsoft Intune admin center** (intune.microsoft.com) and the **Microsoft Entra admin center** (entra.microsoft.com). Confirm your account holds the least-privilege role needed for the task — typically **Intune Administrator** for device/app management and a read role for discovery — under **Entra admin center > Roles & admins**. Confirm Microsoft Graph PowerShell can connect with the required scopes.

**Implement if missing.** Have a Global Administrator assign the specific least-privilege roles required (avoid Global Admin for routine work). Establish a break-glass account. Register/consent the Microsoft Graph PowerShell scopes the scripts request (read-only scopes for discovery/validation/reporting; the minimal write scopes only for remediation/group management).

---

## GR2 — Windows edition and licensing

**Description.** Supported, correctly licensed Windows on the clinical endpoints (e.g., Windows Enterprise/Education or Pro as appropriate), with the Microsoft 365 / Entra ID / Intune licensing that entitles management and the security features in use.

**Why.** Compliance policies, security baselines, Conditional Access, and management features depend on the correct OS edition and license SKUs. An unlicensed or under-licensed device can fail enrollment, compliance, or Conditional Access — and surface as a "mysterious" go-live failure.

**Verify.** Confirm the Windows edition and build on representative devices meet the standard, and confirm license assignment (user and/or device) in the Microsoft 365 admin center and Entra. Confirm the edition supports every feature the solution requires.

**Implement if missing.** Assign or upgrade licenses, and upgrade the OS edition/build where required, through the managed deployment process. Reconcile license counts against the in-scope device/user count so nothing is missed at scale.

---

## GR3 — HIPAA / HITRUST data handling and change control

**Description.** All work complies with the organization's HIPAA and HITRUST obligations for handling ePHI and for change control: data minimization in any exported report, access controls on evidence, approved change records for any state change, and an auditable trail.

**Why.** Clinical endpoints operate in a regulated environment. Reports and scripts must not leak ePHI, every change must be authorized and traceable, and the activity must withstand audit. A readiness sweep that exports patient data, or a remediation made without a change record, is a compliance incident regardless of its technical merit.

**Verify.** Confirm reports/exports contain only device and posture metadata (never ePHI), confirm exported evidence is stored in an access-controlled location, and confirm a change-control process covers any device-state change. Confirm logging/auditing is enabled for the actions taken.

**Implement if missing.** Scope all exports to non-ePHI device metadata; store evidence in an access-controlled, organization-approved location; route every state change through the organization's change-management process with an approved change record; and ensure Intune/Entra audit logging is on. When in doubt, treat data as sensitive and minimize.

---

## GR4 — Clinical maintenance windows and change-freeze awareness

**Description.** Agreed maintenance windows for any change to clinical devices, and awareness of any change freeze around the go-live.

**Why.** Clinical devices are in use around the clock. Pushing a change, reboot, or remediation during active patient care is unacceptable; doing it during a declared freeze can violate the activation plan. Timing is a safety and governance constraint, not a convenience.

**Verify.** Confirm the approved maintenance windows with clinical operations and confirm any change-freeze dates around the activation with the Epic program. Confirm scheduled actions (deployments, remediations, reboots) land inside approved windows.

**Implement if missing.** Negotiate maintenance windows with clinical leadership, document the freeze dates, and schedule all state-changing actions accordingly. Default remediation tooling to read-only / `-WhatIf` so nothing changes outside an approved, scheduled action.

---

## GR5 — Network connectivity and dependencies

**Description.** The in-scope devices have the network connectivity and reach to the dependencies they need: Epic application servers / presentation layer, Imprivata appliances, print pathways, Intune/Entra/Microsoft Graph endpoints, and DNS/time services.

**Why.** Many "endpoint" failures are actually reachability failures — a device that can't reach the Epic presentation layer, the Imprivata appliance, or the Microsoft management endpoints will fail in ways that look like device problems. Confirming connectivity prevents misdiagnosis.

**Verify.** Confirm devices on the activation floors can reach each required dependency (Epic, Imprivata, print, Microsoft endpoints) on the correct ports, and that firewall/proxy/VLAN rules for those floors are in place. Validate DNS resolution and time sync.

**Implement if missing.** Work with the network team to open required paths, correct VLAN/firewall/proxy rules for the activation area, and confirm DNS/time. Document the dependency map so the triage runbook can quickly distinguish device faults from network faults.

---

## GR6 — Representative test device

**Description.** At least one representative device per in-scope device class, available for testing changes, validation logic, and remediation actions before they touch the broader fleet.

**Why.** Validating a sweep or remediation on a real, representative device first prevents a flawed action from being applied at scale during the highest-stakes week. It is the safe-rollout discipline this category depends on.

**Verify.** Confirm a test device exists for each device class (workstation, WOW, exam-room PC, shared/kiosk) configured like production, and that the team can run discovery/validation/remediation against it.

**Implement if missing.** Designate and configure test devices per class to match production. Always run new validation logic and any `-Apply` remediation against the test device first and confirm the result before expanding scope.

---

## GR7 — Documented rollback

**Description.** A documented rollback for every state-changing action: how to reverse a deployment, a remediation, a compliance change, or a group-membership change if it causes a problem.

**Why.** At go-live, a bad change must be reversible fast. A rollback plan turns a mistake into a brief incident instead of an outage during patient care.

**Verify.** Confirm each state-changing step in the solution has a defined, tested reversal, and that the team knows how to invoke it. Confirm backups/exports of prior state exist where needed (e.g., prior group membership, prior client version).

**Implement if missing.** Author and test a rollback for each change: capture prior state before acting (the discovery/report scripts provide a before-snapshot), define the reversal steps, and rehearse them on the test device. Keep rollback steps in the change record so they are at hand during hypercare.
