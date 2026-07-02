# Requirements — Continuous Compliance Monitoring & Audit-Evidence Automation

Confirm each prerequisite below **before** you begin the Implementation Guide. Category-level
prerequisites (Entra tenant, Intune subscription, admin roles, enrollment, pilot group, supported
OS, network, change control) are listed once in **global-requirements-security.md** — read that
first. The items here are **specific to continuous compliance monitoring and audit-evidence
automation**. Each entry follows: **Description / Why / Verify / Implement if missing.**

---

## R1. An existing CIS/STIG baseline deployed to Intune + Entra

**Description:** A CIS Benchmark and/or DISA STIG configuration already built and assigned in Intune
(Settings Catalog / device-configuration / compliance policies / Security Baselines) and Entra
(Conditional Access, authentication methods, tenant settings) — the *expected state* you will measure
against.

**Why:** This solution measures **drift from a baseline**. Without a defined baseline there is
nothing to compare current state to, no "expected value" for evidence, and no gap to put in a POA&M.
The specific CIS/STIG rule IDs and official control text come from **CIS and DISA** — this solution
does not supply them.

**Verify:** In `https://intune.microsoft.com` → **Endpoint security → Security baselines** and/or
**Devices → Manage devices → Configuration**, confirm your baseline profiles exist and are assigned.
In `https://entra.microsoft.com` → **Protection → Conditional Access** confirm the identity controls
exist. You should be able to name the exact objects that encode your baseline.

**Implement if missing:** Build the one-time CIS/STIG baseline first (a separate build activity):
import the CIS/STIG content into Intune Settings Catalog / Security Baselines, create the matching
Entra Conditional Access and authentication-method policies, and assign them. Then return here to
monitor it.

---

## R2. Intune + Entra roles with Microsoft Graph read access

**Description:** An operator identity holding read rights to Intune and Entra configuration and
device state, and consented Microsoft Graph **read scopes** for the monitoring scripts.

**Why:** Discovery, Validation, and Report are **read-only** and must be able to read policies,
compliance state, Conditional Access, and directory objects via Graph. Insufficient scopes cause
empty or partial evidence — an audit gap.

**Verify:** In Entra → **Roles and administrators**, confirm the operator has at least a read role
(for example **Global Reader** plus **Intune Administrator** for later remediation). Run
`CCAUDIT-Discovery.ps1` (read-only) and confirm it connects and returns data without a permissions
error.

**Implement if missing:** Assign **Global Reader** (directory/CA read) and **Intune Administrator**
(Intune read/write for remediation). On first script run, consent the required delegated Graph read
scopes when prompted:
`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
`Policy.Read.All`, `Directory.Read.All`, `Group.Read.All`. (Remediation additionally needs
`DeviceManagementConfiguration.ReadWrite.All`; Set-ScopeTargeting needs `Group.ReadWrite.All`.)

---

## R3. A reporting / evidence destination

**Description:** A controlled location where the exported audit-evidence and POA&M-ready gap files are
written and stored (for example a restricted, access-logged file share or document library the
scripts' output folder points to).

**Why:** Audit evidence has value only if it is stored somewhere durable, access-controlled, and
tamper-evident. Writing evidence to a random local folder undermines its integrity.

**Verify:** Confirm you have a path (local staging + a controlled destination) where the operator can
write, that is backed up, access-restricted, and retained per policy. Confirm you can write a test
file there.

**Implement if missing:** Create a dedicated folder / library (for example a SharePoint document
library or restricted network share) with read/write limited to the compliance operators, versioning
or immutability enabled where available, and backup configured. Point the scripts' `-OutputPath` at
your local staging folder and copy finished evidence to the controlled destination.

---

## R4. Defined evidence-retention needs

**Description:** A written statement of how long audit evidence must be kept, in what format, and who
may access it — derived from your regulatory framework and audit cycle.

**Why:** Federally regulated environments mandate retention periods; the export cadence, storage, and
disposal must match. Retention that is too short fails audits; unmanaged retention creates risk.

**Verify:** Confirm a retention requirement exists (period, format, access, disposal) and that your
destination (R3) enforces it. Confirm ownership of the retention decision.

**Implement if missing:** Document the retention requirement with your compliance/audit lead (period,
immutable vs. versioned, access list, disposal method). Configure the destination's retention/hold
settings to match, and record the cadence (for example measure weekly, retain evidence per policy).

---

## R5. A defined pilot scope

**Description:** A small, representative Microsoft Entra security group of devices (and/or users) used
to prove the monitoring method before fleet-wide rollout — named **`CCAUDIT-Pilot-Devices`**.

**Why:** The category standard is Assess → Configure → **Pilot** → Validate → Expand. Piloting on a
small group first lets you validate measurement accuracy, drift detection, and evidence output
without noise or risk across the whole fleet, and lets you safely seed a test drift.

**Verify:** In Entra → **Groups**, confirm **`CCAUDIT-Pilot-Devices`** exists and contains a small
set of representative in-scope devices (mix of OS builds / roles).

**Implement if missing:** Create it — Entra → **Groups → New group** → type **Security**, name
**`CCAUDIT-Pilot-Devices`**, add a handful of representative enrolled devices — or generate it from
your baseline scope with **`CCAUDIT-Set-ScopeTargeting.ps1`** (default preview / -WhatIf; review,
then commit).

---

**When R1–R5 and the global requirements are all satisfied, proceed to the Implementation Guide.**
