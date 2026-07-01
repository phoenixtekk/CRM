# Global Requirements — Healthcare Solutions (category-level)

These requirements apply to **every** solution in the **Healthcare Solutions** category. They are
published once at the category level so individual solution listings stay focused. Confirm all of
them are in place before deploying *any* Healthcare Solutions product into a clinical environment.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

> Clinical environments carry obligations (HIPAA, often HITRUST) and uptime expectations that a
> standard office fleet does not. Treat every change as a controlled clinical change, not an ad-hoc
> IT task.

## G1. Microsoft 365 / Intune tenant with admin roles
**Description:** An active Microsoft Entra ID tenant with a Microsoft Intune subscription, and an
operator holding **Intune Administrator** (or **Application Manager** / **Endpoint Security Manager**
as appropriate).
**Why:** Intune is the delivery channel for every configuration and application in this category;
authoring apps and assignments requires elevated rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows an
active subscription; Entra → **Roles and administrators** shows the operator's role.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; assign the
operator **Intune Administrator**. Reserve Global Administrator for tenant-wide setup only.

## G2. Windows licensing for managed clinical endpoints
**Description:** Targeted devices run a supported, licensed **Windows 10 / Windows 11**
(Enterprise or Pro) with current cumulative updates.
**Why:** Modern Intune app-management and security features assume a patched, supported OS.
**Verify:** `winver` on a device, or Intune → device → **Hardware**.
**Implement:** Apply correct Windows licensing; deploy **Update rings**
(Intune → **Devices → Windows → Update rings**) or upgrade devices to a supported build.

## G3. Devices enrolled and identity-joined
**Description:** Clinical endpoints are **Intune-enrolled** and **Microsoft Entra joined** (or
**hybrid Entra joined** where co-managed with Configuration Manager).
**Why:** Policies and apps only reach enrolled, identity-bound devices, and assignments are scoped to
Entra device groups.
**Verify:** Intune → **Devices → All devices** (device present, compliant); on the device
`dsregcmd /status` shows `AzureAdJoined : YES` (or `DomainJoined : YES` + `AzureAdJoined : YES` for
hybrid).
**Implement:** Enroll via Autopilot or **Settings → Accounts → Access work or school**; for hybrid,
configure Entra Connect + group policy / co-management.

## G4. HIPAA / HITRUST data-handling and clinical change control
**Description:** A documented change-control process for clinical endpoints, and data-handling that
keeps **electronic protected health information (ePHI)** in-bounds — no ePHI in logs, exports, or
script output; least-privilege access; auditable changes.
**Why:** Clinical endpoints handle ePHI; uncontrolled changes risk both patient safety and
HIPAA / HITRUST compliance. Every deployment, update, and retire action must be change-managed and
auditable.
**Verify:** Confirm a change ticket / change-advisory-board (CAB) approval exists for the deployment;
confirm the scripts and reports in use do **not** capture patient data (the tools in this category
are read-only over device/app state, not over clinical content).
**Implement:** Route the change through your CAB; record the approved change window, rollback plan,
and back-out criteria; restrict who can run deployment actions; retain change records per your
compliance program.

## G5. Clinical maintenance windows
**Description:** Approved, low-acuity maintenance windows during which clinical endpoints may be
changed or rebooted, agreed with clinical operations.
**Why:** Pushing an app or reboot during patient care is unacceptable; shared clinical devices are
often in use around the clock.
**Verify:** A documented maintenance-window schedule exists and is referenced in the change ticket.
**Implement:** Agree windows with clinical operations / nursing leadership; align Intune assignment
**availability** and any restart behavior to those windows.

## G6. Network access to Microsoft and vendor service endpoints
**Description:** Outbound HTTPS from clinical endpoints to **Microsoft 365 / Entra / Intune** service
URLs, plus any **vendor endpoints** the solution requires (for this category, the Epic environment
and Microsoft content-delivery endpoints for app payloads and the WebView2 runtime).
**Why:** Enrollment, policy sync, app delivery, and authentication all depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; confirm app installs report **Succeeded** in Intune.
**Implement:** Allow Microsoft's published Office 365 / Intune URL & IP ranges, plus the vendor
endpoints your build team specifies, through proxy / firewall.

## G7. A non-production / test clinical device
**Description:** At least one **dedicated test device** representative of the clinical fleet (ideally
one of each form factor — fixed workstation and a WOW) that is **not in live patient care**.
**Why:** Every change is proven on a test device before any pilot or broad assignment touches a
device used for care.
**Verify:** The test device is enrolled, in the pilot ring group, and flagged as non-production.
**Implement:** Set aside a representative device; add it to the pilot ring group used by the solution.

## G8. Rollback posture
**Description:** A defined back-out plan for every change: how to revert the app, how to restore the
previously known-good client version, and the criteria that trigger a rollback.
**Why:** In a clinical setting a failed change must be reversible quickly to protect care delivery.
**Verify:** The change ticket includes a rollback plan and a named previously-validated version /
package to revert to.
**Implement:** Keep the prior validated `.intunewin` package and its detection values; document the
revert steps (re-assign prior version / remove the new assignment) before deploying the new one.

---
**The standard deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.**
For application-lifecycle solutions in this category this is realized as
**Assess → Package → Pilot → Validate → Broad Deploy → Lifecycle (update / supersede / retire)**.
