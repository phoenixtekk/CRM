# Requirements

Before a technician can work the runbooks in this library, a small set of prerequisites must be in
place. These are **in addition to** the category-level prerequisites in
`global-requirements-infrastructure.md` (Entra tenant, Intune subscription, device enrollment,
supported Windows baseline, network access), which you should confirm first.

Each requirement below is written as **Description / Why / Verify / Implement if missing** so you
can confirm it click-by-click and fix it if it is not there.

---

## R1. Intune role with read access to devices (technician role)

**Description:** The technician's account holds an Intune role that can read device inventory,
compliance, configuration, and app assignments — at minimum **Help Desk Operator**, or a custom
role scoped to the same read actions plus the remote actions the team is allowed to use.

**Why:** Every runbook's **checks** are read operations against Intune (device state, compliance,
assigned policies). Without a role that can read these, the technician is blind and every ticket
becomes an escalation.

**Verify:** Sign in to `https://intune.microsoft.com`. Go to **Tenant administration → Roles →
All roles**, open the role assigned to the technician, and confirm it includes read for
**Managed devices**, **Device configurations**, and **Mobile apps**. Also open
**Devices → All devices**, pick any device, and confirm you can open its **Overview**,
**Hardware**, and **Device compliance** blades.

**Implement if missing:** In Intune → **Tenant administration → Roles → All roles**, select
**Help Desk Operator** → **Assignments → Assign**. Give the assignment a name, add the
technicians' Entra group under **Admin groups**, set **Scope (groups)** to the device groups they
support, and choose the **Scope tags** if used. Save. Have the technician sign out and back in.

---

## R2. Graph read access for the reporting scripts

**Description:** An account (or app registration) that can sign in to Microsoft Graph with the
**read** scopes the bundled PowerShell scripts request: `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementConfiguration.Read.All`, `DeviceManagementApps.Read.All`, and
`Directory.Read.All`.

**Why:** The Discovery, Validation, and Report scripts pull device health and context from Graph
so a technician can triage across many devices at once instead of clicking each one. They are
read-only and never write to the tenant.

**Verify:** On the technician's workstation, run
`Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"` and confirm sign-in succeeds
and the account consents (or has admin-consented) the scope. Run `Get-MgContext` and confirm the
scopes are present.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`). If your tenant requires
admin consent for these scopes, have an Intune Administrator or Global Administrator grant consent
once (Entra → **Enterprise applications → Microsoft Graph Command Line Tools → Permissions**), or
create a dedicated app registration with the read scopes above and admin-consent it.

---

## R3. Remote Help (or an approved remote-control tool)

**Description:** A tool that lets the technician view and, with user consent, control the device
to run the on-device steps in the runbooks — Microsoft **Remote Help** on the Intune-managed
fleet, or another remote-control tool the organization has approved.

**Why:** Several checks and resolutions require driving the local device (opening Settings,
running `dsregcmd`, reading Event Viewer). Remote Help is the sanctioned, audited way to do this
on an Intune fleet.

**Verify:** In Intune → **Tenant administration → Remote Help**, confirm Remote Help is
**enabled**. On a test device, open the **Remote Help** app and confirm the technician can request
a session and the user can grant control.

**Implement if missing:** In Intune → **Tenant administration → Remote Help**, set
**Enable Remote Help** to **Yes** and configure who can provide help. Deploy the Remote Help app
to the fleet (Intune → **Apps → Windows → Add → Microsoft Remote Help**) and assign it to the
support technicians and the supported devices. Ensure the required Remote Help / Intune Suite
licensing is assigned.

---

## R4. Asset and user context (who owns what)

**Description:** A reliable way to map a caller to their device(s) and to the device's primary
user, location, and hardware — the Intune **Primary user** field, device naming, and any asset
tag or CMDB the organization keeps.

**Why:** Intake and triage depend on identifying the exact device. Without primary-user mapping,
a technician cannot confirm they are looking at the right machine, and scope (one user vs. many)
cannot be established.

**Verify:** In Intune → **Devices → All devices**, open a device and confirm the **Primary user**
is populated and the **Device name** follows a recognizable convention. Confirm you can search by
serial number under **Hardware**.

**Implement if missing:** Ensure primary user is set on enrollment (it is by default for user-driven
enrollment). For shared/kiosk devices, document the exception. Adopt a device-naming convention in
your enrollment profile and, if you keep a CMDB, record the Intune device name and serial there so
callers can be matched to devices.

---

## R5. A place to record runbook outcomes (ticketing / notes)

**Description:** A ticketing system or shared notes location where the **evidence to collect** for
each runbook is stored against the ticket.

**Why:** The operating model's final stage is **Document**. Consistent evidence capture is what
makes escalations clean and lets trends surface in the Report script.

**Verify:** Confirm the team's ticketing system has a field or attachment area for screenshots,
device IDs, and timestamps, and that technicians know where the runbook evidence goes.

**Implement if missing:** Designate the evidence fields in your existing ticketing tool. If you do
not have one, a shared, access-controlled location with a per-ticket note is the minimum. Standardize
the fields to match the **evidence to collect** lists in the Runbook Library.

---

Once R1–R5 and the category-level global requirements are confirmed, the technician is ready to
work the Runbook Library in the next document.
