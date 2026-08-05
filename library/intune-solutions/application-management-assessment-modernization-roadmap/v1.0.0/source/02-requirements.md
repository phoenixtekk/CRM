# 2. Requirements Guide — Application Management Current-State Assessment & Modernization Roadmap

Verify **every** requirement before you begin scoring. Each entry follows the same shape:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites live in `global-requirements-intune-solutions.md` — read that first; this guide adds only
the assessment-specific prerequisites and does not repeat the seven.

This is a **read-only** assessment. The access requirements below are deliberately least-privilege: you
need to *read* the tenant, never to change it.

## 2.1 Least-privilege read-only tenant access (Intune role: Read Only Operator)

**Description:** An assessor account granted the built-in Intune RBAC role **Read Only Operator**, plus
the Entra role **Global Reader**. This combination reads every Intune app, assignment, policy, and
device record and every Entra group and directory object the assessment needs — without any write
capability.

**Why required:** The scores must reflect what exists in the tenant, not what a low-privilege account
happens to be able to see. A dimension the account cannot read will false-score. Equally, granting the
assessor a write-capable role (Intune Administrator, Application Manager) breaks the read-only guarantee
that lets the customer approve the engagement quickly.

**How to verify:**
1. In the Intune admin center (`https://intune.microsoft.com`), go to **Tenant administration → Roles →
   All roles → Read Only Operator → Assignments** and confirm the assessor account (or an Entra group it
   belongs to) is listed with an assignment scoped to **All devices / All users** (or the agreed scope).
2. In the Entra admin center (`https://entra.microsoft.com`), go to **Roles and administrators → Global
   Reader → Assignments** and confirm the account is present.
3. Run `APPASMT-Estate-Inventory.ps1 -WhatIfAccessCheck` (the header block documents this switch); it
   confirms the sign-in succeeds and reports which object types are readable.

**How to implement if missing:**
- Intune → **Tenant administration → Roles → All roles → Read Only Operator → Assignments → Assign** →
  add the assessor account or a dedicated Entra group named `APPASMT – Assessors`, choose the scope
  groups (or All), and save.
- Entra → **Roles and administrators → Global Reader → Add assignments** → add the same account.
- Do **not** substitute Intune Administrator or Global Administrator "to save time" — the read-only
  posture is a deliverable, not a convenience.

## 2.2 Microsoft Graph PowerShell SDK with read-only scopes consented

**Description:** A workstation with the **Microsoft Graph PowerShell SDK** installed and the assessor
able to consent to the following **read-only** delegated scopes:
`DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All`,
`DeviceManagementManagedDevices.Read.All`, `DeviceManagementRBAC.Read.All`,
`Group.Read.All`, `Directory.Read.All`.

**Why required:** All five assessment scripts connect through Graph. Every scope ends in `.Read.All` —
there is no `.ReadWrite` scope anywhere in this solution, which is what enforces the read-only guarantee
at the API level regardless of the account's role.

**How to verify:**
- Run `Get-InstalledModule Microsoft.Graph` — it returns an installed version.
- Run `Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All","Group.Read.All","Directory.Read.All"`
  and confirm it completes and, on first run, that an administrator consents to exactly these read scopes.
- Run `Get-MgContext` and confirm the `Scopes` list contains only `.Read.All` entries.

**How to implement if missing:**
- `Install-Module Microsoft.Graph -Scope CurrentUser` (or `-Scope AllUsers` from an elevated prompt).
- If your tenant requires admin consent for delegated scopes, have a Global Administrator approve the
  read scopes once (Entra → **Enterprise applications → Microsoft Graph Command Line Tools →
  Permissions → Grant admin consent**, or accept the consent prompt on first `Connect-MgGraph`).
- **Government tenants:** connect with `Connect-MgGraph -Environment USGov` (GCC High) — see §2.7.

## 2.3 An agreed Assessment Charter (scope, dimensions, target levels)

**Description:** A signed one-pager, `APPASMT – Assessment Charter`, recording: which of the nine
dimensions are in scope, the **target level** the organization is aiming for on each (not every
organization needs L5 everywhere), the platforms in scope (Windows / macOS / iOS / Android), which
business units or device groups are included, what is explicitly **out of scope**, the stakeholder list,
and the readout date.

**Why required:** A maturity score is meaningless without a target to compare it to. A gap is the
distance between the current level and the agreed target — with no agreed target, there is no gap and no
roadmap. The charter also protects the engagement from scope creep.

**How to verify:** The charter exists, names a target level per in-scope dimension, and is signed by the
sponsor and the endpoint/security owners.

**How to implement if missing:** Use the `APPASMT – Assessment Charter` template (Deliverables). Default
target levels: **L3 (Defined)** for D1, D2, D3, D6, D8; **L4 (Managed)** for D4, D5, D7; **L3** for D9 —
then adjust with the customer before scoring.

## 2.4 Named stakeholders available for interview

**Description:** Confirmed access to the people who can answer for each dimension: **application owners
/ business app sponsors**, **endpoint engineers** (the people who package and deploy), **security /
endpoint security**, **service desk / support lead**, and **procurement / software asset management**.

**Why required:** The technical data shows *what* is configured; the interviews explain *why*, *who
owns it*, and *what process produced it*. Dimensions D1 (Governance), D8 (Support), and D9 (Migration
debt) cannot be scored from tenant data alone — they need the interviews.

**How to verify:** Each role has a named person and a booked interview slot in the assessment window.

**How to implement if missing:** Work with the sponsor to identify the person actually doing each job
(not the org-chart owner). Where a role does not exist — e.g. "no one owns application security review"
— that absence is itself a finding, recorded against the relevant dimension.

## 2.5 Documentary artifacts requested and a place to store the Evidence Pack

**Description:** The `APPASMT – Artifact Request List` sent to the customer (packaging standard docs,
intake/approval records, ring definitions, patch cadence policy, WDAC/AppLocker policy, retirement
records, support runbooks, any SCCM/co-management inventory), plus a secure location to hold the
`APPASMT – Evidence Pack` (the script outputs) for the duration of the engagement.

**Why required:** Interviews claim processes exist; artifacts prove they do. A D2 (Packaging Standards)
score of L3 requires the *actual written standard* to be produced — "we have one" is not evidence.

**How to verify:** The request list has been sent; a shared, access-controlled folder (customer or
assessor tenant) exists for the Evidence Pack and collected artifacts.

**How to implement if missing:** Send the `APPASMT – Artifact Request List` at charter sign-off. Create
the evidence folder before the technical collection in Step 5. Never store tenant exports containing
device or user identifiers in an uncontrolled location.

## 2.6 A workstation that meets the collection prerequisites

**Description:** A Windows workstation (or PowerShell 7 on any supported OS) with outbound HTTPS to
Microsoft Graph, PowerShell 5.1 or 7.x, and permission to run local scripts
(`Set-ExecutionPolicy -Scope Process Bypass` for the session, or signed scripts).

**Why required:** The five scripts run locally against Graph. Corporate proxies or execution-policy
lockdown are the two most common reasons collection stalls on day one.

**How to verify:** From the workstation, `Connect-MgGraph` succeeds and
`Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?$top=1'`
returns data.

**How to implement if missing:** Allow the Graph endpoints through the proxy, run PowerShell as a normal
user with `-ExecutionPolicy Bypass` for the process, and confirm TLS 1.2 is enabled.

## 2.7 Government (GCC High / DoD) — confirm the sovereign-cloud endpoints

**Description:** If the tenant is a US-sovereign-cloud tenant (GCC High or DoD), the portals and Graph
endpoint differ from Commercial and must be targeted explicitly.

**Why required:** Running the Commercial endpoints against a Government tenant simply fails to
authenticate; the assessor must point the tools at the `.us` sovereign endpoints.

**How to verify:** Confirm with the customer which cloud the tenant is in. For GCC High, the admin
portals are `https://intune.microsoft.us` (Intune) and `https://portal.azure.us` (Azure/Entra), and
Graph is `https://graph.microsoft.us`.

**How to implement if missing:** Connect Graph with `Connect-MgGraph -Environment USGov` (GCC High) or
`-Environment USGovDoD` (DoD). Each script's `.NOTES` documents the switch. Where a specific Intune
feature's Government parity is uncertain, **verify for GCC High** against Microsoft's US-sovereign-cloud
documentation rather than assuming Commercial behaviour — the read-only assessment logic itself is
identical across clouds; only the endpoints change.

---

## Requirements checklist

- [ ] **2.1** Assessor has **Read Only Operator** (Intune) + **Global Reader** (Entra) — verified
- [ ] **2.2** Microsoft Graph PowerShell SDK installed; **read-only** scopes consented (`Get-MgContext` shows only `.Read.All`)
- [ ] **2.3** `APPASMT – Assessment Charter` signed with a target level per in-scope dimension
- [ ] **2.4** Named stakeholders (app owners, endpoint eng, security, service desk, procurement) booked
- [ ] **2.5** `APPASMT – Artifact Request List` sent; secure Evidence Pack folder created
- [ ] **2.6** Collection workstation reaches Graph; scripts can run
- [ ] **2.7** For Government tenants: sovereign-cloud endpoints confirmed and `-Environment` set
