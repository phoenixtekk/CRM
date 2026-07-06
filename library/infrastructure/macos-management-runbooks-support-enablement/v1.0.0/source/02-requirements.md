# Requirements

Before a technician can work the runbooks in this library, a small set of prerequisites must be in
place. These are **in addition to** the category-level prerequisites in
`global-requirements-infrastructure.md` (Entra tenant, Intune subscription, device enrollment,
network access to Microsoft cloud endpoints), which you should confirm first.

> **macOS note on the global requirements:** the category-level global requirements are written
> for a Windows baseline (they mention Windows 10/11 and Windows auto-enrollment). For this
> solution, read those as their macOS equivalents: a **supported macOS release** (a current or
> prior-year macOS version that Apple and Intune still support) in place of the Windows baseline,
> and **Automated Device Enrollment (ADE) via Apple Business Manager** (or user-driven Company
> Portal enrollment) in place of Windows automatic enrollment. The identity, subscription,
> role, pilot-group, and network requirements apply unchanged.

Each requirement below is written as **Description / Why / Verify / Implement if missing** so you
can confirm it click-by-click and fix it if it is not there.

---

## R1. Intune role with read access to Mac devices (technician role)

**Description:** The technician's account holds an Intune role that can read device inventory,
compliance, configuration, and app assignments — at minimum **Help Desk Operator**, or a custom
role scoped to the same read actions plus the remote actions the team is allowed to use (Sync,
Restart, Rotate FileVault key, Collect diagnostics).

**Why:** Every runbook's **checks** are read operations against Intune (device state, compliance,
assigned profiles). Without a role that can read these, the technician is blind and every ticket
becomes an escalation.

**Verify:** Sign in to `https://intune.microsoft.com`. Go to **Tenant administration → Roles →
All roles**, open the role assigned to the technician, and confirm it includes read for
**Managed devices**, **Device configurations**, and **Mobile apps**. Also open
**Devices → All devices**, filter to **OS = macOS**, pick any Mac, and confirm you can open its
**Overview**, **Hardware**, and **Device compliance** blades.

**Implement if missing:** In Intune → **Tenant administration → Roles → All roles**, select
**Help Desk Operator** → **Assignments → Assign**. Give the assignment a name, add the
technicians' Entra group under **Admin groups**, set **Scope (groups)** to the Mac device groups
they support, and choose the **Scope tags** if used. Save. Have the technician sign out and back
in.

---

## R2. Graph read access for the reporting scripts

**Description:** An account (or app registration) that can sign in to Microsoft Graph with the
**read** scopes the bundled PowerShell scripts request: `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementConfiguration.Read.All`, `DeviceManagementApps.Read.All`, and
`Directory.Read.All`.

**Why:** The Discovery, Validation, and Report scripts pull Mac health and context from Graph so a
technician can triage across many Macs at once instead of clicking each one. They are read-only and
never write to the tenant.

**Verify:** On the technician's workstation, run
`Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"` and confirm sign-in succeeds
and the account consents (or has admin-consented) the scope. Run `Get-MgContext` and confirm the
scopes are present.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`). If your tenant requires
admin consent for these scopes, have an Intune Administrator or Global Administrator grant consent
once (Entra → **Enterprise applications → Microsoft Graph Command Line Tools → Permissions**), or
create a dedicated app registration with the read scopes above and admin-consent it. The
Remediation and Set-ScopeTargeting scripts additionally require write scopes, listed in their own
headers — grant those only when you intend to make a change.

---

## R3. A remote-control tool for Macs (with user consent)

**Description:** A tool that lets the technician view and, with user consent, control the Mac to
run the on-device steps in the runbooks. Microsoft **Remote Help** support for macOS may not cover
every scenario, so an organization-approved remote-control tool that supports macOS (and works
with macOS Screen Recording / Accessibility privacy consent) is often used.

**Why:** Several checks and resolutions require driving the local Mac (opening System Settings,
running `profiles status` or `fdesetup status`, reading Console logs). A sanctioned, audited remote
tool is the safe way to do this.

**Verify:** On a test Mac, start a session with the approved tool and confirm the technician can
view the screen and, with the user's consent, control it — including granting the macOS
**Screen Recording** and **Accessibility** privacy prompts the tool needs.

**Implement if missing:** Deploy and configure the organization-approved macOS remote-control tool
(and, where required, deploy its **Privacy Preferences Policy Control (PPPC)** profile via Intune →
**Devices → macOS → Configuration** so the tool's screen/accessibility permissions are
pre-approved). **Flagged as uncertain:** confirm current Remote Help macOS capabilities against
Microsoft's documentation before assuming a scenario is covered.

---

## R4. Asset and user context (who owns which Mac)

**Description:** A reliable way to map a caller to their Mac(s) and to the device's primary user,
location, and hardware — the Intune **Primary user** field, device naming, the **serial number**,
and any asset tag or CMDB the organization keeps. On Macs the **serial number** is especially
important because it is the key that ties the device to Apple Business Manager and ADE.

**Why:** Intake and triage depend on identifying the exact Mac. Without primary-user mapping and
the serial, a technician cannot confirm they are looking at the right machine, cannot check ABM
assignment, and cannot establish scope (one user vs. many).

**Verify:** In Intune → **Devices → All devices** (filter **OS = macOS**), open a Mac and confirm
the **Primary user** is populated, the **Device name** follows a recognizable convention, and the
**Serial number** under **Hardware** matches the physical device (Apple menu → **About This Mac**,
or on the login screen). Confirm you can search by serial.

**Implement if missing:** Ensure primary user is set on enrollment (it is by default for
user-driven / user-affinity ADE). For shared Macs, document the exception. Adopt a device-naming
convention and, if you keep a CMDB, record the Intune device name and serial there so callers can
be matched to Macs. Confirm the serials of managed Macs also appear in Apple Business Manager (see
Runbook 1).

---

## R5. A place to record runbook outcomes (ticketing / notes)

**Description:** A ticketing system or shared notes location where the **evidence to collect** for
each runbook is stored against the ticket, and where completed onboarding tasks are recorded.

**Why:** The operating model's final stage is **Document**. Consistent evidence capture is what
makes escalations clean, lets trends surface in the Report script, and feeds the enablement /
feature-evaluation loop.

**Verify:** Confirm the team's ticketing system has a field or attachment area for screenshots,
device IDs/serials, command output, and timestamps, and that technicians know where the runbook
evidence goes.

**Implement if missing:** Designate the evidence fields in your existing ticketing tool. If you do
not have one, a shared, access-controlled location with a per-ticket note is the minimum.
Standardize the fields to match the **evidence to collect** lists in the Runbook Library. **Never
record FileVault recovery keys, passwords, or bootstrap-token material in a ticket** (see Best
Practices — evidence capture).

---

Once R1–R5 and the category-level global requirements (read with the macOS note above) are
confirmed, the technician is ready to work the Runbook Library in the next document.
