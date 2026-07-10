# Requirements

Before you can diagnose why **Microsoft Entra Connect cloud sync** is skipping users (JoinNotFound /
not provisioned), you need read access to each place that holds evidence: the **provisioning-agent
host**, on-premises **Active Directory**, and the **Entra ID tenant** (portal + Microsoft Graph). This
section lists what to have ready. Each item follows **Description / Why / Verify / Implement if
missing**. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

Gather these *before* an incident where possible — assembling access mid-incident wastes time.
Everything here is **read-only**; you never need write/remediation rights to run this toolkit.

> Naming convention used throughout this toolkit (reuse these names verbatim; the en-dash is `–`):
> - The cloud sync configuration: **`Cloud Sync – AD to Entra – Configuration`**
> - An organizational unit that IS in the scoping filters: **`Cloud Sync – In-Scope Users – OU`**
> - Pilot / test scope OU: **`Cloud Sync – Pilot Scope – Pilot`**
> - The domain-joined agent server: **`Cloud Sync – Provisioning Agent Host`**
> - Microsoft's fixed names, reused verbatim: the **"Microsoft Entra Provisioning Agent"** and
>   **"Microsoft Entra Connect Agent Updater"** services, and the **"Microsoft Entra AD Synchronization
>   Service"** service principal.

> **Government / sovereign-cloud note:** if the tenant is **GCC High / DoD**, the admin portals differ
> (`https://entra.microsoft.us`, sign-in via `https://login.microsoftonline.us`) and the Microsoft
> Graph endpoint differs (`https://graph.microsoft.us`); feature/endpoint parity can lag Commercial.
> The agent-host and AD checks are identical, but **verify the portal, Graph, and object availability
> for GCC High** in your sovereign cloud before acting on the tenant-side checks.

---

## R1. Access to the provisioning-agent host server

**Description:** Local (or remote-management) access to the domain-joined Windows server where the
**Microsoft Entra provisioning agent** for cloud sync is installed — enough to read its services, the
agent **Trace** folder, the execution policy, and the proxy configuration.

**Why:** Agent-side truth the cloud cannot see lives here: whether the **"Microsoft Entra Provisioning
Agent"** and **"Microsoft Entra Connect Agent Updater"** services are actually **Running**, and what
the agent trace logs recorded. The scripts `CLDSYNCDX-Collect-Diagnostics.ps1` and
`CLDSYNCDX-Check-Agent.ps1` run **on this host**.

**Verify:** You can open a PowerShell session on the host and run
`Get-Service "*Provisioning Agent*","*Agent Updater*"` and see output, and browse
`C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace`.

**Implement if missing:** Arrange local admin access, an RDP/remote-PowerShell session, or have an
on-site operator run the read-only collector and return the zip. No changes are made to the host.

---

## R2. Local administrator rights on the agent host

**Description:** Local administrator rights on the agent host, to read the agent services, the Trace
folder, and to run `Export-AADCloudSyncToolsLogs`.

**Why:** The agent installs under `ProgramData` and runs as a service; a standard user cannot reliably
read the Trace folder or export the diagnostic logs, so a check would report false negatives.

**Verify:** In an elevated PowerShell session, `Get-ChildItem "C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace"`
returns files.

**Implement if missing:** Run the host-side scripts **elevated** (Run as administrator). The scripts
read only; elevation is for visibility, not change.

---

## R3. The AADCloudSyncTools PowerShell module (on the agent host)

**Description:** The **AADCloudSyncTools** module available on the agent host, which ships with the
provisioning agent and wraps the log export and repair cmdlets
(`Connect-AADCloudSyncTools`, `Export-AADCloudSyncToolsLogs`, `Repair-AADCloudSyncToolsAccount`,
`Disable-AADCloudSyncToolsDirSyncAccidentalDeletionPrevention`).

**Why:** `CLDSYNCDX-Collect-Diagnostics.ps1` uses `Export-AADCloudSyncToolsLogs` (when present) to
gather a complete agent log bundle. The module is also where the *remediation* cmdlets live (used in
Phase 3, outside this read-only toolkit).

**Verify:** On the host, `Get-Module AADCloudSyncTools -ListAvailable` returns the module (it installs
with the agent under the agent's PowerShell module path). If absent, the collector still gathers the
services state and the Trace folder.

**Implement if missing:** Install it per Microsoft's guidance — `Install-Module -Name AADCloudSyncTools`
(it depends on the Microsoft Graph and MSAL modules). Then `Connect-AADCloudSyncTools` to authenticate.
Exact module setup is **deferred to Microsoft documentation**.

---

## R4. Microsoft Graph read access (for the tenant-side scripts)

**Description:** The ability to run `CLDSYNCDX-Get-ProvisioningLog.ps1` and
`CLDSYNCDX-Check-Provisioning.ps1` against Microsoft Graph with the read-only scopes
**`AuditLog.Read.All`**, **`Directory.Read.All`**, and **`Synchronization.Read.All`** (the last for
reading the synchronization job/quarantine state).

**Why:** The **provisioning logs** (the authoritative per-object skip reason) and the cloud sync
**synchronization job** (Active / quarantined) are read through Graph — the same data you can click
through in the portal.

**Verify:** Run `Connect-MgGraph -Scopes "AuditLog.Read.All","Directory.Read.All","Synchronization.Read.All"`
and confirm consent succeeds; `Get-MgContext` shows the scopes granted.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph -Scope CurrentUser`). Consent to the delegated **read** scopes above
at first connect — no write consent is required or requested.

---

## R5. Entra admin center read access (Hybrid Identity Administrator or Global Reader)

**Description:** Sign-in to the Microsoft Entra admin center (`https://entra.microsoft.com`; GCC High:
`https://entra.microsoft.us`) with a role that can view **Entra Connect → Cloud sync** — the
configuration, its scoping filters, the agent health, and the **provisioning logs**.

**Why:** Whether the configuration is **Enabled**, which **OUs are in the scoping filters**, whether
the agent shows **Healthy**, and the per-object provisioning-log entries are all visible here. The
**Hybrid Identity Administrator** role is the least-privileged role that can manage cloud sync;
**Global Reader** gives tenant-wide read.

**Verify:** Browse to **Entra ID → Entra Connect → Cloud sync** and confirm you can open the
configuration `Cloud Sync – AD to Entra – Configuration`, read its scope, and open **Logs**.

**Implement if missing:** In Entra → **Roles & admins**, assign **Global Reader** (tenant-wide read,
no change rights) or **Hybrid Identity Administrator**. Prefer read-only for diagnosis.

---

## R6. The AD object identifier and the intended scope

**Description:** For the user that is not provisioning, its **AD `ObjectGuid`** (and/or its `UPN`), plus
a recorded statement of which **OUs are supposed to be in scope** for `Cloud Sync – AD to Entra –
Configuration` (the DNs of the in-scope organizational units).

**Why:** Diagnosis is comparison. The **provisioning logs are searchable by the AD `ObjectGuid`** — it
is the reliable key to the per-object reason. Knowing the intended in-scope OUs turns "is this user in
scope?" into a one-line DN match (`CLDSYNCDX-Test-Object.ps1` takes the in-scope OU DNs as a parameter).

**Verify:** You can state, for the failing user: its `ObjectGuid` (from
`Get-ADUser <name> -Properties ObjectGuid`), its `UPN`, and the list of in-scope OU DNs the
configuration is set to synchronize.

**Implement if missing:** Read the `ObjectGuid` on the agent host (or any domain member) with the
ActiveDirectory module; read the configuration's scoping filters in **Entra Connect → Cloud sync →**
the configuration **→ Scope provisioning by … / Configure attribute mapping**.

---

## R7. On-premises Active Directory read access (for the object test)

**Description:** Read access to Active Directory (the ActiveDirectory PowerShell module on the agent
host or a domain member) to inspect the failing user's `IsCriticalSystemObject`,
`distinguishedName`/OU, `userPrincipalName`, and `proxyAddresses`.

**Why:** The **excluded-by-design** (`IsCriticalSystemObject`), **out-of-scope OU**, and
**already-exists / duplicate UPN or proxyAddress** conditions are AD-side facts.
`CLDSYNCDX-Test-Object.ps1` reads them read-only.

**Verify:** `Get-ADUser <name> -Properties IsCriticalSystemObject,proxyAddresses,userPrincipalName,distinguishedName`
returns the object.

**Implement if missing:** Install RSAT / the ActiveDirectory module
(`Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0` on a client, or the
AD DS role tools on a server) and use a read account. No write is needed.

---

## Checklist
- [ ] Access to `Cloud Sync – Provisioning Agent Host` (R1) — can read services + Trace folder
- [ ] Local administrator on the host (R2) — run scripts elevated
- [ ] AADCloudSyncTools module present on the host (R3) — for the log export
- [ ] Microsoft Graph read scopes (`AuditLog.Read.All`, `Directory.Read.All`, `Synchronization.Read.All`) (R4)
- [ ] Entra read role (Hybrid Identity Administrator or Global Reader) (R5)
- [ ] The failing user's `ObjectGuid`/`UPN` and the intended in-scope OU DNs recorded (R6)
- [ ] Active Directory read access + the ActiveDirectory module (R7)
