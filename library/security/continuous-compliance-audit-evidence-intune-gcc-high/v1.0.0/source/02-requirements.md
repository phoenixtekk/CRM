# Requirements — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

Confirm each prerequisite below **before** you begin the Implementation Guide. Category-level
prerequisites (Entra tenant, Intune subscription, admin roles, enrollment, pilot group, supported
OS, network, change control) are listed once in **global-requirements-security.md** — read that
first. The items here are **specific to continuous compliance monitoring and audit-evidence
automation on a GCC High tenant**. Each entry follows: **Description / Why / Verify / Implement if
missing.**

> **GCC High note:** every "Verify" below uses the **US sovereign-cloud portals** —
> `intune.microsoft.us`, `entra.microsoft.us`, `portal.office365.us`, sign-in at
> `login.microsoftonline.us`. If any portal loads at a `.com` host you are in the **Commercial**
> cloud — stop and switch. Scripts connect to **US Gov Graph** (`graph.microsoft.us`,
> `Connect-MgGraph -Environment USGov`; DoD `dod-graph.microsoft.us`, `-Environment USGovDoD`).

---

## R1. An existing CIS/STIG baseline deployed to Intune + Entra (in the GCC High tenant)

**Description:** A CIS Benchmark and/or DISA STIG configuration already built and assigned in Intune
(Settings Catalog / device-configuration / compliance policies / Security Baselines) and Entra
(Conditional Access, authentication methods, tenant settings) **in your GCC High tenant** — the
*expected state* you will measure against.

**Why:** This solution measures **drift from a baseline**. Without a defined baseline there is nothing
to compare current state to, no "expected value" for evidence, and no gap to put in a POA&M. The
specific CIS/STIG rule IDs and official control text come from **CIS and DISA** — this solution does
not supply them. (Microsoft points GCC High/DoD admins to the DISA STIGs Document Library on
`public.cyber.mil` for the hardening content.)

**Verify:** In `https://intune.microsoft.us` → **Endpoint security → Security baselines** and/or
**Devices → Manage devices → Configuration**, confirm your baseline profiles exist and are assigned.
In `https://entra.microsoft.us` → **Entra ID → Conditional Access** confirm the identity controls
exist. You should be able to name the exact objects that encode your baseline.

**Implement if missing:** Build the one-time CIS/STIG baseline first (a separate build activity), in
the **GCC High** tenant: import the CIS/STIG content into Intune Settings Catalog / Security Baselines,
create the matching Entra Conditional Access and authentication-method policies, and assign them. Then
return here to monitor it. **Parity check:** confirm each control you intend to monitor is enforced by
a mechanism that **exists in GCC High** — e.g. STIG rules requiring **BIOS/DFCI** enforcement or
**Windows update rings** are **not yet available** in GCC High (see `gcc-high-parity-notes.md` §3) and
must be handled out-of-band.

---

## R2. Intune + Entra roles with Microsoft Graph **US Gov** read access

**Description:** An operator identity holding read rights to Intune and Entra configuration and device
state in the GCC High tenant, and consented Microsoft Graph **US Gov read scopes** for the monitoring
scripts.

**Why:** Discovery, Validation, and Report are **read-only** and must be able to read policies,
compliance state, Conditional Access, and directory objects via **US Gov Graph**. Insufficient scopes
cause empty or partial evidence — an audit gap. Connecting to the wrong cloud (Commercial Graph)
returns nothing.

**Verify:** In `https://entra.microsoft.us` → **Roles and administrators**, confirm the operator has
at least a read role (for example **Global Reader** plus **Intune Administrator** for later
remediation). Run `CCAUDITG-Discovery.ps1` (read-only) and confirm it connects to **US Gov** and
returns data without a permissions error. Confirm the connected environment with `Get-MgContext`
(Graph host should be `graph.microsoft.us`).

**Implement if missing:** Assign **Global Reader** (directory/CA read) and **Intune Administrator**
(Intune read/write for remediation). On first script run, consent the required delegated Graph read
scopes when prompted:
`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
`Policy.Read.All`, `Directory.Read.All`, `Group.Read.All`. (Remediation additionally needs
`DeviceManagementConfiguration.ReadWrite.All`; Set-ScopeTargeting needs `Group.ReadWrite.All`.) The
scripts pass `-Environment USGov` (use `-Environment USGovDoD` on a DoD/IL5 tenant) so consent happens
against the **US Gov** identity endpoint.

---

## R3. A reporting / evidence destination (in-boundary, US-sovereign)

**Description:** A controlled location where the exported audit-evidence and POA&M-ready gap files are
written and stored — for example a restricted, access-logged **SharePoint (GCC High)** document
library or a US Gov file share the scripts' output folder points to. Optionally, a **Log Analytics /
Azure Monitor (Azure Government)** workspace as a durable, queryable evidence store.

**Why:** Audit evidence has value only if it is stored somewhere durable, access-controlled,
tamper-evident, and **inside your authorization boundary**. Writing evidence to a random local folder
— or worse, a Commercial-cloud location — undermines its integrity and can break data-residency.

**Verify:** Confirm you have a path (local staging + a controlled, in-boundary destination) where the
operator can write, that is backed up, access-restricted, and retained per policy. Confirm you can
write a test file there. If using Log Analytics, confirm the workspace is in **Azure Government**.

**Implement if missing:** Create a dedicated folder / library (for example a GCC High SharePoint
document library or restricted network share) with read/write limited to the compliance operators,
versioning or immutability enabled where available, and backup configured. Point the scripts'
`-OutputPath` at your local staging folder and copy finished evidence to the controlled destination.
The Intune **Log Analytics/Azure Monitor export is available** in GCC High/DoD if you want a queryable
store; the **Power BI Data-Warehouse connector is not** (see `gcc-high-parity-notes.md` §2).

---

## R4. Defined evidence-retention needs (aligned to your ATO / FedRAMP obligations)

**Description:** A written statement of how long audit evidence must be kept, in what format, and who
may access it — derived from your authorization (FedRAMP High / DoD IL4–IL5), regulatory framework,
and continuous-monitoring cadence.

**Why:** Federally regulated environments mandate retention periods and a **monthly** continuous-
monitoring / POA&M cadence; the export cadence, storage, and disposal must match. Retention that is
too short fails audits; unmanaged retention creates risk. NIST 800-53 **CA-5** requires a maintained
POA&M as the record of open weaknesses.

**Verify:** Confirm a retention requirement exists (period, format, access, disposal) and that your
destination (R3) enforces it. Confirm ownership of the retention decision and the monitoring cadence
your ATO expects (commonly monthly for FedRAMP High).

**Implement if missing:** Document the retention requirement with your compliance/ISSO/AO (period,
immutable vs. versioned, access list, disposal method) and the monitoring cadence. Configure the
destination's retention/hold settings to match, and record the cadence (for example measure at least
monthly, retain evidence per policy). **Verify the exact obligations against your own authorization
boundary and ATO** — the timelines cited in `gcc-high-parity-notes.md` §5 are the general FedRAMP
framework, not a substitute for your assessor's determination.

---

## R5. A defined pilot scope

**Description:** A small, representative Microsoft Entra security group of devices (and/or users) used
to prove the monitoring method before fleet-wide rollout — named **`CCAUDITG-Pilot-Devices`**.

**Why:** The category standard is Assess → Configure → **Pilot** → Validate → Expand. Piloting on a
small group first lets you validate measurement accuracy, drift detection, and evidence output without
noise or risk across the whole fleet, and lets you safely seed a test drift.

**Verify:** In `https://entra.microsoft.us` → **Groups**, confirm **`CCAUDITG-Pilot-Devices`** exists
and contains a small set of representative in-scope devices (mix of OS builds / roles).

**Implement if missing:** Create it — `entra.microsoft.us` → **Groups → New group** → type
**Security**, name **`CCAUDITG-Pilot-Devices`**, add a handful of representative enrolled devices — or
generate it from your baseline scope with **`CCAUDITG-Set-ScopeTargeting.ps1`** (default preview /
-WhatIf; review, then commit).

---

**When R1–R5 and the global requirements are all satisfied, proceed to the Implementation Guide.**
