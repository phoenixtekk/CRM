# 2. Requirements — Self-Deploy: Microsoft Entra Hybrid Identity

The **category-level** prerequisites (an Entra ID tenant, P1/P2 licensing, administrative roles,
break-glass accounts, healthy on-premises AD, an Entra Connect host, UPN/domain hygiene, and network
access to Microsoft cloud endpoints) are documented once in
**`global-requirements-entra-id-solutions.md`** — confirm those first; they are not repeated here.

Below are the prerequisites specific to running this **self-deploy** and its labs. Because this is
training, the labs are **read-only / inspection-first**: you inspect and rehearse against whatever
hybrid environment you have (or a lab environment) without changing a production sync configuration.

Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A read-only vantage point into the identity estate
Description: The ability to sign in to the Entra admin center and run read-only Graph queries with at
least a **Global Reader** (or Security Reader) role.
Why required: Every lab inspects real configuration — domains, sync status, source anchor, auth method,
hybrid-join state — without changing it.
How to verify: Entra → **Roles and administrators**; confirm the operator has Global Reader (or higher
read). `EKHYBID-Discovery.ps1` confirms it can read directory/sync data.
How to implement if missing: Assign **Global Reader** to the training operator. Elevated write roles are
**not** needed for this kit (they are needed in the HYBID implementation solution).

## R2. (Where available) Read access to an existing hybrid configuration
Description: A tenant that already has (or a lab that can host) Entra Connect Sync or Cloud Sync and,
ideally, at least one synchronized user and one hybrid-joined device to inspect.
Why required: The health-check and inspection labs are richest against a real hybrid setup; you learn to
read source anchor, sync errors, and hybrid-join state from live data.
How to verify: Entra → **Identity → Hybrid management → Microsoft Entra Connect** shows sync status and
last sync time; Entra → **Devices** shows any *Microsoft Entra hybrid joined* devices.
How to implement if missing: If no hybrid environment exists, complete the inspection labs
conceptually using the provided sample output, then use HYBID to stand one up. A disposable lab forest
+ Entra Connect is ideal for full hands-on practice.

## R3. Microsoft Graph PowerShell SDK
Description: The `Microsoft.Graph` PowerShell module (v2+) on the operator workstation.
Why required: The discovery, validation, report, and health-check helpers use Graph cmdlets.
How to verify: `Get-Module Microsoft.Graph -ListAvailable` returns v2+; `EKHYBID-Validate.ps1` reports it.
How to implement if missing: `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the
least-privilege read scopes (e.g. `Directory.Read.All`, `Domain.Read.All`, `AuditLog.Read.All`,
`Organization.Read.All`).

## R4. (For full hands-on) The on-premises AD PowerShell module (RSAT)
Description: RSAT Active Directory PowerShell tools on a domain-joined workstation or the Connect host.
Why required: The source-anchor, sync-scope, and UPN-hygiene inspection labs read AD attributes
(`ms-DS-ConsistencyGuid`, UPN suffixes, OU structure) directly.
How to verify: `Get-Module ActiveDirectory -ListAvailable` returns a module; `Get-ADForest` succeeds.
How to implement if missing: Install RSAT AD tools (**Optional Features** on Windows client, or
`Install-WindowsFeature RSAT-AD-PowerShell` on Server). Skip the AD-side labs if no AD is available and
complete them conceptually.

## R5. Licensing awareness (P1 / P2 / Governance / GSA)
Description: Awareness of which lab needs which license before you run it.
Why required: **Hybrid Conditional Access** requires **Entra ID P1**; risk-based CA and PIM require
**P2**; governance features require **Entra ID Governance**. Some capabilities are preview. *Do not
assume availability — verify current licensing and preview status in your own tenant.*
How to verify: M365 admin center → **Billing → Licenses**; `EKHYBID-Validate.ps1` reports detected
service plans.
How to implement if missing: Assign the needed license to lab users, or complete that lab as
concept-only. Trial licenses are acceptable for training — *verify eligibility in your tenant.*

## R6. (Optional) Log Analytics / Microsoft Sentinel with Entra diagnostic settings
Description: An Entra **Diagnostic setting** streaming `SignInLogs` / `AuditLogs` to a Log Analytics
workspace (optionally onboarded to Sentinel).
Why required: Only for the **KQL analysis lab** and `EKHYBID-Signals.kql`. The rest of the kit works
without it.
How to verify: Entra → **Monitoring → Diagnostic settings** shows a setting sending logs to a workspace
with recent `SigninLogs`.
How to implement if missing: Entra → **Diagnostic settings → Add** → select `SignInLogs`, `AuditLogs`
→ send to a workspace. *A workspace and retention may incur Azure cost — verify in your subscription.*
If unavailable, read the KQL lab as concept only.
