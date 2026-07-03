# Hybrid Identity with Active Directory & Microsoft Entra Connect — Government (GCC High)

> **Version 1.0.0** · Category: Entra · Solution code: HYBIDG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Hybrid Identity with Active Directory & Microsoft Entra Connect (Government / GCC High)

## The problem

Deploying hybrid identity on a **Microsoft 365 U.S. Government GCC High** tenant is **not** the
Commercial process with a different sign-in page. GCC High is a physically and logically isolated
sovereign cloud with **different admin portals, different service endpoints, and a few feature
parity gaps**. Commercial steps applied to a GCC High tenant tend to fail **quietly** — the sync
engine cannot reach the right endpoints, or an admin configures the wrong (or an empty) tenant
through a Commercial portal. The result is wasted effort, delayed onboarding, and identity-plane
risk in an environment where a mistake breaks sign-in for everyone.

## The solution

This **Government (GCC High) edition** delivers hybrid identity between on-premises Active Directory
and a GCC High Entra ID tenant using **Microsoft Entra Connect Sync**, authored specifically for the
US sovereign cloud:

- **Correct sovereign portals and endpoints** throughout — `entra.microsoft.us`,
  `portal.office365.us`, `login.microsoftonline.us`, `graph.microsoft.us`, and the US Gov sync
  service instance.
- **The critical cloud-selection step** in Entra Connect (auto-detection via `*.windows.net`, or the
  manual `AzureInstance=4` + Custom install path) so the sync engine targets Azure Government, not
  Commercial.
- **An explicit Commercial-vs-GCC-High parity map** so you plan around the known gaps instead of
  discovering them in production.
- **Five PowerShell scripts** that connect to Microsoft Graph US Gov (`-Environment USGov`) to
  discover, validate, report, and safely remediate — change scripts default to `-WhatIf`.

## How it is delivered

A staged, gated model — **Assess → Configure → Pilot → Validate → Expand** — with break-glass
accounts prepared first and every change validated before the next. You prove the configuration on a
small named pilot before scaling to production in controlled waves.

## What is different in GCC High (the short version)

- **Portals/endpoints are `*.us`**, not `.com` — using Commercial URLs silently targets the wrong
  place.
- **Entra Connect must be pointed at the US Gov instance** during install, or sync fails.
- **All three sign-in methods (PHS, PTA, Federation) are available**, but a few peripheral features
  are not (e.g. My Staff, Entra threat-intelligence risk detection; HR-driven provisioning is
  partial).

Every claim in this solution is cited to Microsoft US Government documentation, or explicitly flagged
**"verify for GCC High"** where Microsoft has not published a definitive statement.

## The bottom line

Hybrid identity deployed correctly on GCC High — right portals, right endpoints, parity gaps handled
— proven on a pilot before you scale, at a fraction of consulting cost.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Solution Overview — Hybrid Identity with Active Directory & Microsoft Entra Connect (Government / GCC High)

This is the **Government (GCC High) edition** of the Hybrid Identity solution. It deploys hybrid
identity between your on-premises Active Directory and a **Microsoft 365 U.S. Government GCC High**
tenant, using **Microsoft Entra Connect Sync** (or Microsoft Entra Cloud Sync), so on-premises
users sign in to cloud services with their existing AD credentials.

The technology is the same product you would deploy in the Commercial cloud — but GCC High is a
**physically and logically network-isolated sovereign cloud** with **different admin portals,
different service endpoints, and a small number of feature parity gaps**. Using Commercial steps on
a GCC High tenant does not fail loudly; it fails quietly — the wizard cannot reach the right
endpoints, or an admin opens the wrong (Commercial) portal and sees an empty or wrong tenant. This
edition gives you the **correct sovereign portals and endpoints** and calls out the parity gaps so
the tenant is configured right the first time.

## What this solution delivers

- A working **hybrid identity** configuration: on-premises AD identities synchronized to your
  GCC High Entra ID tenant.
- A chosen and configured **sign-in method**: Password Hash Synchronization (PHS), Pass-through
  Authentication (PTA), or Federation (AD FS) — all supported in Azure for US Government
  ([Microsoft Entra feature availability in Azure for US Government](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
- **Correct GCC High endpoints** opened on the proxy/firewall so the sync engine can reach the US
  Gov service instance.
- Five **PowerShell scripts** that connect to **Microsoft Graph US Gov endpoints**
  (`-Environment USGov`) to discover, validate, report on, and safely remediate the configuration.

## The deployment model (all solutions)

Assess → Configure → Pilot → Validate → Expand, with a **gate** at each transition. You do not
proceed until the current stage passes its checks. On the identity plane a mistake breaks sign-in
for everyone, so break-glass accounts are prepared first and every change is staged.

| Stage | Goal | Gate to pass before moving on |
| --- | --- | --- |
| **Assess** | Inventory AD, tenant, licensing, roles, endpoints | Discovery clean; break-glass accounts confirmed |
| **Configure** | Install Entra Connect against the **US Gov** instance; pick sign-in method | Sync installed against US Gov endpoints; no wrong-cloud detection |
| **Pilot** | Sync a small named scope (one OU / one group) | Pilot users appear in the GCC High tenant and sign in |
| **Validate** | Test sign-in, writeback, SSPR, failover for the pilot | All test cases pass; no unexpected deletions |
| **Expand** | Widen sync scope to production in controlled waves | Each wave validates before the next |

## Named objects you will create and reuse

Create these once and reuse the exact names throughout. Consistent names make the scripts,
troubleshooting, and hand-off unambiguous.

| Object | Suggested name | Used for |
| --- | --- | --- |
| Pilot OU (or group) | `OU=HybridPilot` / group `sg-HybridIdentity-Pilot` | The Assess/Pilot sync scope |
| Sync scope group (expand) | `sg-HybridIdentity-InScope` | Group-based sync targeting during Expand |
| Break-glass accounts | `bg-admin1@<yourtenant>.onmicrosoft.us`, `bg-admin2@<yourtenant>.onmicrosoft.us` | Emergency access, excluded from CA/MFA |
| Connect host server | `SVR-ENTRACONNECT01` | The Entra Connect Sync host |

> Note the break-glass UPN suffix is **`.onmicrosoft.us`** in GCC High, not `.onmicrosoft.com`.
> Verify the exact initial domain on your tenant under **Identity → Settings → Domain names** in
> the Entra admin center for US Gov.

## Commercial vs GCC High — what's different

This is the section that keeps a government deployment from silently breaking. Everything below is
either cited to Microsoft US Gov documentation or explicitly flagged **"verify for GCC High"** where
Microsoft has not published a definitive statement.

### 1. Admin portals and sign-in are `*.us`, not `.com`

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in / token authority | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (DoD: `dod-graph.microsoft.us`) |
| Defender / Security | `security.microsoft.com` | `security.microsoft.us` |
| Purview / Compliance | `compliance.microsoft.com` | `compliance.microsoft.us` / `purview.microsoft.us` |

Sources: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments),
[Microsoft 365 U.S. Government GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints).

### 2. Entra Connect must target the US Gov service instance

The sync engine talks to a **US-only set of endpoints**, and Entra Connect will not use them unless
either `*.windows.net` is open (which lets it auto-detect the Azure Government tenant) or you set the
`AzureInstance` registry value to `4` and use the **Custom** installation path. The Gov URLs to open
are `*.microsoftonline.com`, `*.microsoftonline.us`, `*.windows.net`, and `*.gov.us.microsoftonline.com`
plus Certificate Revocation Lists
([Entra Connect: Sync service instances — Microsoft Azure Government](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)).
See `03-implementation.md` for the exact steps.

### 3. Sign-in methods — all three are available, but confirm PTA/SSO agent endpoints

Password Hash Synchronization, Pass-through Authentication, and Federation (AD FS) are all listed as
available in Azure for US Government
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
PTA and Seamless SSO use authentication agents that must reach the **US Gov** agent endpoints —
verify the agent registers against the Gov cloud during install (the same `*.microsoftonline.us` /
`*.gov.us.microsoftonline.com` allow-list applies). **Verify for GCC High:** confirm your specific
PTA agent version registers to the Gov instance in a lab before production.

### 4. Feature parity gaps to plan around

Most hybrid-identity features are at parity. The known **not-available** items in Azure for US
Government per Microsoft's feature-availability table are:

- **My Staff** (delegated user-management portal) — **❌ not available**.
- **Microsoft Entra threat intelligence** risk detection (within ID Protection) — **❌ not
  available**. Other ID Protection risk detections (leaked credentials, atypical travel, password
  spray, etc.) are available.
- **Enterprise State Roaming** for Windows 10 shared-device sign-out — noted as **not available**.
- **HR-driven provisioning** — **partial** (see the HR-provisioning apps note in the same table).

Everything else used by this solution — directory synchronization (Connect Sync and Cloud Sync),
Connect Health reporting, PHS, PTA, federation, SSO, MFA, Conditional Access, SSPR with on-premises
writeback, password writeback, and PIM — is **available**
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).

### 5. Licensing is the Government SKU family

Use the **US Government** license SKUs (for example **Microsoft 365 G3 / G5 Gov**, which include
Entra ID P1/P2 equivalents). See `02-requirements.md`. **Verify for GCC High:** confirm the exact
SKU your agency holds carries Entra ID P1 (P2 where risk-based features are wanted), as Gov bundles
differ from Commercial names.

For the full, cited breakdown see `gcc-high-parity-notes.md`.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Requirements — Hybrid Identity (Government / GCC High)

Confirm every requirement below **before** you configure anything. Category-wide prerequisites are
in `global-requirements-entra-id-solutions.md`; this file adds the **GCC High–specific** items and
restates each category item with its **US Gov portal/endpoint**. Each entry follows the same shape:
**Description / Why / Verify / Implement-if-missing.**

> The identity plane is high risk. In GCC High, the most common failure is not a missing feature —
> it is an admin using a **Commercial portal/endpoint** and configuring the wrong (or an empty)
> tenant. Every "Verify" step below names the **`*.us`** surface on purpose.

## R1. A GCC High Microsoft Entra ID tenant
Description: An active **Microsoft 365 U.S. Government GCC High** tenant (Entra ID paired with Azure
Government).
Why: GCC High is a separate, isolated sovereign cloud; identities and tokens are not interchangeable
with Commercial ([Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments)).
Verify: Sign in to **`https://entra.microsoft.us`** (not `.com`) as an administrator and confirm the
tenant loads with your Gov domain.
Implement: Provision GCC High through an authorized Microsoft AOS-G partner / agency onboarding; you
cannot self-provision GCC High like Commercial.

## R2. US Government licensing (Entra ID P1, P2 where noted)
Description: Government license SKUs that include Entra ID P1 (P2 for risk-based and PIM features) —
e.g. **Microsoft 365 G3 / G5 Gov**, EMS G-SKUs, or standalone Entra ID P1/P2 for Government.
Why: Hybrid features (SSPR/password writeback, Conditional Access) require P1+; risk-based policies
require P2.
Verify: **`https://portal.office365.us`** → `Billing → Licenses`; confirm an Entra ID P1/P2-bearing
Gov SKU is assigned.
Implement: Assign the appropriate Government SKU. **Verify for GCC High:** confirm your specific Gov
bundle carries the P1/P2 entitlement, as Gov SKU names differ from Commercial.

## R3. Administrative roles (in the GCC High tenant)
Description: **Hybrid Identity Administrator** (and **Global Administrator** for the one-time
first-sync consent) in the GCC High tenant.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: In **`https://entra.microsoft.us`** → `Roles and administrators`, confirm the operator holds
`Hybrid Identity Administrator`, and a `Global Administrator` is available for first sync.
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and
first-sync changes.

## R4. Break-glass (emergency access) accounts — `.onmicrosoft.us`
Description: At least two **cloud-only** emergency access accounts, excluded from Conditional Access
and broad MFA policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you
back in.
Verify: In **`https://entra.microsoft.us`** → `Users`, confirm two cloud-only accounts on the
**`<yourtenant>.onmicrosoft.us`** domain with strong stored credentials.
Implement: Create `bg-admin1@<yourtenant>.onmicrosoft.us` and `bg-admin2@<yourtenant>.onmicrosoft.us`
as Global Administrators; exclude from policies; store credentials securely; monitor sign-ins.

## R5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: `dcdiag` and `repadmin /replsummary` return no errors on a domain controller; run
`HYBIDG-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## R6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, TLS 1.2 enabled, for Microsoft Entra
Connect Sync (or a lightweight host for the Cloud Sync provisioning agent). Name it
`SVR-ENTRACONNECT01`.
Why: Connect Sync runs as a service on this host and must reach both AD and the **GCC High** Entra ID
endpoints.
Verify: Supported, domain-joined server with TLS 1.2, current .NET, and PowerShell; run
`HYBIDG-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller in production), patch it, enable
TLS 1.2.

## R7. UPN / domain hygiene against the GCC High tenant
Description: User principal names use a **public, verified, routable** domain that is verified **in
the GCC High tenant** (not `.local`, not only the Commercial tenant).
Why: A non-routable or unverified UPN produces sign-in problems and `onmicrosoft.us` fallbacks.
Verify: **`https://entra.microsoft.us`** → `Identity → Settings → Domain names` shows the public
domain **Verified**; AD UPN suffixes match it; run `HYBIDG-Discovery.ps1`.
Implement: Add and verify the public domain in the **GCC High** tenant; add the matching UPN suffix
in AD; update user UPNs.

## R8. Network access to the **US Gov** cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to the **Azure Government** sync service
instance and required GCC High service URLs — **not** the Commercial ones alone.
Why: Synchronization, authentication-agent traffic, and tokens depend on the Gov endpoints; if only
Commercial URLs are open, sync silently fails or auto-detection picks the wrong cloud.
Verify: From `SVR-ENTRACONNECT01`, confirm reachability of the Gov URLs listed below (443).
Implement: Allow these through the proxy/firewall:

| Endpoint (open on proxy) | Purpose | Source |
| --- | --- | --- |
| `*.microsoftonline.com` | Baseline auth / config | [Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government) |
| `*.microsoftonline.us` | US Gov auth authority (`login.microsoftonline.us`) | same |
| `*.windows.net` | **Automatic Azure Government tenant detection** | same |
| `*.gov.us.microsoftonline.com` | US Gov sync service (`syncservice.gov.us.microsoftonline.com`) | same |
| `graph.microsoft.us` | US Gov Microsoft Graph (DoD: `dod-graph.microsoft.us`) | [Graph deployments](https://learn.microsoft.com/en-us/graph/deployments) |
| `*.auth.microsoft.us` | GCC High auth surface | [GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints) |
| Certificate Revocation Lists | Cert validation | [Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government) |

Always confirm the current list from the live **[GCC High endpoints JSON web service](https://endpoints.office.com/endpoints/USGOVGCCHigh)** before finalizing firewall rules — Microsoft
updates it monthly.

## R9. Correct Microsoft Graph module & environment for the scripts
Description: The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, and the
habit of connecting with **`-Environment USGov`** (or `USGovDoD` for L5/DoD).
Why: Without the Gov environment flag, `Connect-MgGraph` targets Commercial `graph.microsoft.com`
and returns the wrong tenant or an auth error.
Verify: `Get-Module Microsoft.Graph -ListAvailable`; run `HYBIDG-Validation.ps1`, which asserts the
Gov environment.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; always pass `-Environment USGov`.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# Implementation — Hybrid Identity (Government / GCC High)

Follow these steps in order. Each step names the **exact GCC High portal or endpoint** and, where it
matters, an inline **GCC-High caveat**. Do not skip the gates. If a step says "verify for GCC High,"
Microsoft has not published a definitive statement — validate it in a lab first.

> Before you start: confirm the break-glass accounts `bg-admin1@<yourtenant>.onmicrosoft.us` and
> `bg-admin2@<yourtenant>.onmicrosoft.us` exist and can sign in at
> **`https://login.microsoftonline.us`**. If you lock yourself out during an auth-method change,
> these are how you get back in.

## Stage 1 — Assess

### Step 1.1 Run discovery
On `SVR-ENTRACONNECT01`, run the read-only discovery script:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Discovery.ps1
```

It checks AD health, the Connect host prerequisites, UPN/domain hygiene, and connects to
**Microsoft Graph US Gov** (`-Environment USGov`) to read tenant/domain state. Resolve every failure
before continuing.

### Step 1.2 Confirm the tenant in the Gov portal
Sign in to **`https://entra.microsoft.us`**. Confirm you see **your GCC High tenant** (not a
Commercial tenant). Under `Identity → Settings → Domain names`, confirm your public domain shows
**Verified**.

**GATE:** Discovery clean, break-glass confirmed, correct Gov tenant visible.

## Stage 2 — Configure

### Step 2.1 Choose the sign-in method
All three are available in Azure for US Government
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)):

- **Password Hash Synchronization (PHS)** — simplest, most resilient; recommended default.
- **Pass-through Authentication (PTA)** — validates passwords on-prem via agents; needs the Gov
  agent endpoints open (R8).
- **Federation (AD FS)** — most complex; only if a hard requirement (e.g. smart-card/PIV at the STS)
  demands it.

**GCC-High caveat:** for PTA and Seamless SSO, the authentication agent must register against the
**US Gov** instance. Verify the agent picks the Gov cloud during install (the `*.microsoftonline.us`
/ `*.gov.us.microsoftonline.com` allow-list from R8 must be open). **Verify for GCC High** with your
specific agent version in a lab before production.

### Step 2.2 Download and start Entra Connect — but stop at the EULA
Download the current **Microsoft Entra Connect** from Microsoft. Start the installer. **When you
reach the first page (the EULA), do not accept it yet** — leave the wizard open.

### Step 2.3 Select the US Government cloud (the critical GCC High step)
This is the step that makes Entra Connect target the sovereign cloud instead of Commercial.

Microsoft supports two mechanisms
([Entra Connect: Sync service instances — Microsoft Azure Government](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)):

1. **Automatic detection (preferred, Connect ≥ 1.1.647.0):** if **`*.windows.net` is open** on your
   proxy, Connect auto-detects the Azure Government tenant. No registry edit is needed.
2. **Manual configuration (when Internet egress from the Connect host is restricted):**
   - With the wizard paused at the EULA, open **`regedit`**.
   - Set `HKLM\SOFTWARE\Microsoft\Azure AD Connect\AzureInstance` to the value **`4`**
     (4 = Azure US Government).
   - Return to the wizard, accept the EULA, and continue using the **Custom** (not Express)
     installation path.

> **Why this matters:** without `*.windows.net` open **and** without `AzureInstance=4`, Connect
> assumes Commercial and its sync engine cannot reach the Gov service instance. Symptom: sign-in /
> connectivity errors at the "Connect to Microsoft Entra ID" page even with correct Gov credentials.

### Step 2.4 Complete the Custom install and connect to the GCC High tenant
Continue the **Custom** path:

- **Connect to Microsoft Entra ID:** sign in with a **Global Administrator of the GCC High tenant**.
  The sign-in prompt should route through **`login.microsoftonline.us`**. If it shows the Commercial
  `login.microsoftonline.com`, stop — cloud selection (Step 2.3) did not take.
- **Connect your directories:** add your on-premises AD forest with an appropriate service account.
- **Sign-in method:** choose the method from Step 2.1 (PHS recommended). Enable **Seamless SSO** if
  desired.
- **Domain and OU filtering:** at first, select **only the pilot OU** (`OU=HybridPilot`) or use
  group filtering with `sg-HybridIdentity-Pilot`. Do **not** sync the whole directory yet.
- **Optional features:** enable **Password writeback** if you will use SSPR writeback (available in
  Azure for US Government).
- **Start the synchronization** and let the initial sync complete.

### Step 2.5 Verify the install targeted Gov
Run:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Validation.ps1
```

It connects with `-Environment USGov` and asserts the tenant, verified domain, sync status, and
sign-in method are consistent with a GCC High deployment.

**GATE:** Connect installed against **US Gov** endpoints, no wrong-cloud detection, initial sync of
the pilot scope succeeded.

## Stage 3 — Pilot

### Step 3.1 Sync a small named scope
Confirm the pilot scope (`OU=HybridPilot` or `sg-HybridIdentity-Pilot`) is the **only** scope in
sync. Use the scope-targeting helper to build/confirm the target group safely:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Set-ScopeTargeting.ps1 -GroupName "sg-HybridIdentity-Pilot"
```

It defaults to **`-WhatIf`** — it shows what it would change and makes no change until you re-run
with `-WhatIf:$false`.

### Step 3.2 Confirm pilot users in the Gov tenant
In **`https://entra.microsoft.us`** → `Users`, confirm the pilot users appear with the correct UPNs
and are **synced from on-premises** (not cloud-only).

**GATE:** Pilot users present in GCC High tenant and able to sign in at `login.microsoftonline.us`.

## Stage 4 — Validate

Run the reporting script and work through `05-testing.md`:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Report.ps1
```

Test: pilot user sign-in, SSPR + password writeback (if enabled), Seamless SSO (if enabled), and —
for PTA/Federation — agent/STS failover. Confirm **no unexpected deletions** occurred (the sync
engine's deletion threshold should have held).

**GATE:** All `05-testing.md` cases pass; no unexpected object deletions.

## Stage 5 — Expand

### Step 5.1 Widen scope in waves
Move from pilot to production in controlled waves using **group-based targeting**
(`sg-HybridIdentity-InScope`). Add each wave's users to the group, let sync run, validate, then
proceed to the next wave. Re-run `HYBIDG-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview each
change.

### Step 5.2 Remediate drift safely
If validation finds drift (e.g. sync disabled, wrong domain, threshold too low), use:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Remediation.ps1
```

It defaults to **`-WhatIf`** and only applies changes when you re-run with `-WhatIf:$false`.

### Step 5.3 Ongoing operations
- Keep **Connect Health** reporting on (available in Azure for US Government) to watch sync health.
- Re-run `HYBIDG-Report.ps1` on a schedule and after any change.
- Keep the Gov endpoint allow-list (R8) current from the monthly
  [GCC High endpoints web service](https://endpoints.office.com/endpoints/USGOVGCCHigh).

**GATE:** Each wave validates before the next; production fully in scope and healthy.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Testing & Validation — Hybrid Identity (Government / GCC High)

Run these tests at the **Validate** gate (after Pilot) and again after any change. Every test names
a **pass/fail** condition and, where the surface differs, the **GCC High `*.us`** portal to check.
Do not expand scope until every applicable case passes.

> Test against the **Gov** surfaces. A "green" result on a Commercial portal proves nothing about
> your GCC High tenant.

## T1. Sync engine targets the US Gov instance
- **How:** Run `HYBIDG-Validation.ps1` (connects with `-Environment USGov`). On the Connect host,
  confirm the sign-in during install routed through `login.microsoftonline.us`.
- **Pass:** Script confirms the Gov tenant/domain; no Commercial endpoint in use.
- **Fail:** Script reports Commercial environment or cannot reach `graph.microsoft.us` → revisit
  cloud selection (Implementation Step 2.3) and the R8 allow-list.

## T2. Pilot users synchronized correctly
- **How:** `https://entra.microsoft.us` → `Users`; filter to the pilot users.
- **Pass:** Pilot users present, **synced from on-premises** (not cloud-only), UPNs use the verified
  public domain.
- **Fail:** Missing users, cloud-only users, or `onmicrosoft.us` fallback UPNs → check OU/group
  filtering and UPN hygiene (R7).

## T3. Sign-in works on the Gov authority
- **How:** Have a pilot user sign in at `https://login.microsoftonline.us` (e.g. to `portal.office365.us`).
- **Pass:** Sign-in succeeds with the AD password (PHS/PTA) or via AD FS (Federation).
- **Fail:** Sign-in fails → for PHS confirm hash sync ran; for PTA confirm the Gov agent is healthy;
  for Federation confirm the STS trust.

## T4. Password writeback / SSPR (if enabled)
- **How:** A pilot user resets their password via `https://aka.ms/sspr` (Gov-context) and confirms
  the new password works **on-premises** at a domain-joined workstation.
- **Pass:** Reset succeeds in cloud and the new password authenticates on-prem (writeback worked).
- **Fail:** Cloud reset works but on-prem still uses the old password → check writeback config and
  service-account permissions. (SSPR with on-prem writeback is available in Azure for US Government.)

## T5. Seamless SSO (if enabled)
- **How:** From a domain-joined, corporate-network device, browse to a Gov app and confirm no
  password prompt.
- **Pass:** User is signed in silently.
- **Fail:** Prompted for credentials → verify the `AZUREADSSOACC` computer object and Kerberos
  configuration; confirm the Gov agent endpoints are reachable.

## T6. Deletion threshold held (no accidental mass-delete)
- **How:** `HYBIDG-Report.ps1` and the Connect sync history.
- **Pass:** No unexpected deletions; the export deletion threshold stopped any large delete.
- **Fail:** Unexpected deletions staged → **do not confirm the export**; investigate scope/filtering
  before allowing the delete.

## T7. Auth-method failover (PTA / Federation only)
- **How:** In a maintenance window, stop one PTA agent (or one AD FS node) and confirm sign-in still
  works via the remaining agent/node.
- **Pass:** Sign-in unaffected with one agent/node down.
- **Fail:** Sign-in breaks → you have no redundancy; add a second Gov auth agent / AD FS node.

## T8. Break-glass accounts still work
- **How:** Sign in with `bg-admin1@<yourtenant>.onmicrosoft.us` at `login.microsoftonline.us`.
- **Pass:** Break-glass sign-in succeeds and is **excluded** from CA/MFA lockout.
- **Fail:** Break-glass blocked → fix exclusions immediately; this is your recovery path.

## T9. Connect Health reporting is live
- **How:** In `https://entra.microsoft.us`, open Connect Health (available in Azure for US
  Government) and confirm the agent reports.
- **Pass:** Sync + agent health visible, no critical alerts.
- **Fail:** No data → confirm the Health agent installed and can reach the Gov endpoints.

## Test summary gate

| Test | Applies to | Must pass before Expand |
| --- | --- | --- |
| T1 Gov instance | All | Yes |
| T2 Pilot sync | All | Yes |
| T3 Sign-in | All | Yes |
| T4 Writeback/SSPR | If enabled | Yes (if enabled) |
| T5 Seamless SSO | If enabled | Yes (if enabled) |
| T6 Deletion threshold | All | Yes |
| T7 Failover | PTA / Federation | Yes (those methods) |
| T8 Break-glass | All | Yes |
| T9 Connect Health | All | Recommended |

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Troubleshooting — Hybrid Identity (Government / GCC High)

GCC-High-specific symptoms and fixes. Most GCC High incidents trace back to **wrong cloud / wrong
endpoint**, not a broken feature. Work top-down; the first few cover the vast majority of cases.

## 1. "I configured it in the portal but nothing changed"
**Cause:** You are in a **Commercial portal** (`entra.microsoft.com`, `portal.azure.com`,
`admin.microsoft.com`) which points at the wrong (or an empty) tenant.
**Fix:** Use the **`*.us`** portals only: `entra.microsoft.us`, `portal.azure.us`,
`portal.office365.us`. Confirm the tenant shown is your GCC High tenant with your verified Gov
domain.

## 2. Entra Connect sign-in fails at "Connect to Microsoft Entra ID"
**Cause:** Cloud selection did not take — Connect is trying Commercial endpoints.
**Fix:** Confirm the prompt routes through **`login.microsoftonline.us`**. If not, revisit
Implementation Step 2.3: either open **`*.windows.net`** for auto-detection, or pause the wizard at
the EULA and set `HKLM\SOFTWARE\Microsoft\Azure AD Connect\AzureInstance` = **`4`**, then use the
**Custom** install path
([Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)).

## 3. Sync engine cannot reach the service / stalls
**Cause:** Gov sync endpoints are not open on the proxy/firewall.
**Fix:** Open `*.microsoftonline.us`, `*.gov.us.microsoftonline.com`, `*.windows.net`,
`graph.microsoft.us`, `*.auth.microsoft.us`, and CRLs (R8). Reconcile against the live
[GCC High endpoints web service](https://endpoints.office.com/endpoints/USGOVGCCHigh). Test 443
reachability from `SVR-ENTRACONNECT01`.

## 4. `Connect-MgGraph` returns the wrong tenant or an auth error
**Cause:** The Graph SDK defaulted to Commercial `graph.microsoft.com`.
**Fix:** Always pass **`-Environment USGov`** (or `USGovDoD` for DoD/L5). All scripts in this
solution do this; if you run Graph manually, add the flag. Confirm you can reach
`graph.microsoft.us`.

## 5. Users appear as cloud-only or with `onmicrosoft.us` UPNs
**Cause:** UPN/domain hygiene — the public domain is not verified **in the GCC High tenant**, or AD
UPN suffixes don't match.
**Fix:** In `entra.microsoft.us` → `Identity → Settings → Domain names`, verify the public domain
**in the Gov tenant**; add the matching UPN suffix in AD; update user UPNs; re-run sync (R7).

## 6. Pilot users not syncing (or too many syncing)
**Cause:** OU/group filtering scope is wrong.
**Fix:** Confirm only `OU=HybridPilot` / `sg-HybridIdentity-Pilot` is in scope. Use
`HYBIDG-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview, then apply.

## 7. Pass-through Authentication or Seamless SSO fails
**Cause:** The auth agent registered to the wrong cloud, or Gov agent endpoints are blocked.
**Fix:** Confirm the PTA/SSO agent registered against the **US Gov** instance and the
`*.microsoftonline.us` / `*.gov.us.microsoftonline.com` allow-list is open. For Seamless SSO verify
the `AZUREADSSOACC` computer object and Kerberos config. **Verify for GCC High** with your specific
agent version. PTA/PHS/Federation are all supported in Azure for US Government
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).

## 8. SSPR resets in cloud but on-prem password unchanged
**Cause:** Password writeback misconfigured or service-account permissions missing.
**Fix:** Confirm password writeback is enabled in Connect and the sync service account has the
required AD permissions. SSPR with on-premises writeback is available in Azure for US Government
(same source).

## 9. A feature you expect is "missing" in GCC High
**Cause:** It may be a genuine parity gap, not a misconfiguration.
**Fix:** Check `gcc-high-parity-notes.md`. Known gaps: **My Staff**, **Entra threat intelligence**
risk detection, **Enterprise State Roaming** shared-device sign-out (all ❌); **HR-driven
provisioning** is partial ([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
Do not spend hours "fixing" an unavailable feature.

## 10. Unexpected mass deletion staged on export
**Cause:** A scope/filtering change removed many objects; the deletion threshold caught it.
**Fix:** **Do not confirm the export.** Investigate the filtering change. Only lift/confirm the
threshold once you have confirmed the deletions are intended (T6).

## 11. Break-glass account is locked out
**Cause:** A Conditional Access / MFA policy is not excluding the break-glass accounts.
**Fix:** In `entra.microsoft.us`, exclude `bg-admin1@<yourtenant>.onmicrosoft.us` and
`bg-admin2@<yourtenant>.onmicrosoft.us` from all broad CA/MFA policies. Test per T8. These accounts
are your only recovery path if an auth change locks everyone out.

## 12. Connect Health shows no data
**Cause:** Health agent not installed or cannot reach Gov endpoints.
**Fix:** Confirm the Connect Health agent is installed and the Gov endpoints (R8) are reachable.
Connect Health is available in Azure for US Government (same source).

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Best Practices — Hybrid Identity (Government / GCC High)

These practices are specific to running hybrid identity on a **GCC High** tenant. General identity
hygiene still applies; the emphasis here is on the sovereign-cloud differences that cause the most
avoidable incidents.

## Sovereign-cloud discipline

- **Bookmark the `*.us` portals and use only them.** `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`, `security.microsoft.us`, `compliance.microsoft.us` /`purview.microsoft.us`,
  and sign-in at `login.microsoftonline.us`. A Commercial bookmark is the #1 cause of "I configured
  it but nothing changed" in GCC High.
- **Always pass `-Environment USGov`** (or `USGovDoD`) to `Connect-MgGraph`. Bake it into every
  script and runbook so no one ever silently hits Commercial `graph.microsoft.com`.
- **Confirm cloud selection before the first sync**, not after. Verify `*.windows.net` is open (auto
  detection) or `AzureInstance=4` is set with the Custom install path
  ([Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)).

## Endpoint & network hygiene

- **Pull the GCC High endpoint list from the web service, not a copied table.** The authoritative,
  monthly-updated source is `https://endpoints.office.com/endpoints/USGOVGCCHigh`. New URLs/IPs are
  published 30 days ahead — subscribe to the change log.
- **Open the Gov sync URLs explicitly:** `*.microsoftonline.us`, `*.gov.us.microsoftonline.com`,
  `*.windows.net`, `graph.microsoft.us`, `*.auth.microsoft.us`, plus CRLs
  ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)).
- **Don't assume ExpressRoute covers a feature.** Some Gov features (e.g. certain compliance export
  paths) depend on Azure Blob Storage and need separate connectivity — verify per feature.

## Identity-plane safety

- **Two cloud-only break-glass accounts** on `<yourtenant>.onmicrosoft.us`, excluded from CA/MFA,
  credentials stored offline, sign-ins monitored. Test them (T8) on a schedule.
- **Stage every change**: pilot OU/group first, then group-based waves. Never flip the whole
  directory into sync at once.
- **Respect the deletion threshold.** If an export stages a large delete, do not confirm it —
  investigate filtering first (T6).
- **Prefer Password Hash Sync as the default** sign-in method for resilience; it survives on-prem
  outages better than PTA/Federation. Choose PTA/Federation only for a hard requirement, and always
  run **two** agents / AD FS nodes for failover.

## Feature-parity awareness

- **Design around the Gov gaps** (see `gcc-high-parity-notes.md`): **My Staff** and **Entra threat
  intelligence** risk detection are not available; **HR-driven provisioning** is partial; Enterprise
  State Roaming shared-device sign-out is not available
  ([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
- **Flag "verify for GCC High" items in your own runbook** and validate them in a lab tenant before
  production — Gov feature rollout can lag Commercial.

## Operations & documentation

- **Run `HYBIDG-Report.ps1` on a schedule** and after every change; keep the output with your change
  record.
- **Keep Connect Health on** (available in Azure for US Government) for continuous sync/agent
  visibility.
- **Record exact object names** (`OU=HybridPilot`, `sg-HybridIdentity-InScope`, `SVR-ENTRACONNECT01`,
  the two break-glass UPNs) in your runbook so scripts and troubleshooting stay unambiguous.
- **Patch the Connect host and agents** on a cadence; keep Entra Connect current so cloud
  auto-detection and Gov endpoint changes are supported.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Deliverables Summary — Hybrid Identity (Government / GCC High)

Everything included in this **Government (GCC High) edition**, and how the pieces fit the
Assess → Configure → Pilot → Validate → Expand model.

## Documents

| Document | What it gives you |
| --- | --- |
| `01-solution-overview.md` | The solution, the deployment model, named objects, and the **Commercial vs GCC High — what's different** section. |
| `02-requirements.md` | Every prerequisite with **Verify / Implement**, each pointed at the correct `*.us` portal/endpoint. |
| `03-implementation.md` | Ordered Gov steps, including **selecting the US Gov cloud in Entra Connect** (auto-detection or `AzureInstance=4` + Custom install). |
| `05-testing.md` | Pass/fail validation cases against the Gov surfaces, with a summary gate. |
| `06-troubleshooting.md` | GCC-High-specific failure symptoms and fixes. |
| `07-best-practices.md` | Sovereign-cloud discipline, endpoint hygiene, identity-plane safety. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-GCC-High parity reference. |
| `executive-summary.md` | One-page summary for decision-makers. |
| `global-requirements-entra-id-solutions.md` | Category-wide prerequisites (shared). |

## PowerShell scripts (`scripts/`)

All scripts connect to **Microsoft Graph US Gov** with `-Environment USGov`. Read-only scripts make
no changes; change scripts default to **`-WhatIf`**.

| Script | Type | Purpose |
| --- | --- | --- |
| `HYBIDG-Discovery.ps1` | Read-only | Inventory AD health, Connect host, UPN/domain hygiene, tenant state (Assess). |
| `HYBIDG-Validation.ps1` | Read-only | Assert the deployment targets the **US Gov** instance and is configured correctly. |
| `HYBIDG-Report.ps1` | Read-only | Produce a health/state report of sync, sign-in method, and scope. |
| `HYBIDG-Remediation.ps1` | Change (**`-WhatIf` default**) | Safely correct common drift (sync disabled, wrong settings). |
| `HYBIDG-Set-ScopeTargeting.ps1` | Change (**`-WhatIf` default`**) | Build/confirm the sync target group for staged Pilot/Expand waves. |

## How the deliverables map to the model

| Stage | Documents | Scripts |
| --- | --- | --- |
| **Assess** | 01, 02 | `HYBIDG-Discovery.ps1` |
| **Configure** | 03 | `HYBIDG-Validation.ps1` |
| **Pilot** | 03, 05 | `HYBIDG-Set-ScopeTargeting.ps1` |
| **Validate** | 05, 06 | `HYBIDG-Report.ps1` |
| **Expand** | 03, 07 | `HYBIDG-Set-ScopeTargeting.ps1`, `HYBIDG-Remediation.ps1` |

## Definition of done

- Discovery clean; break-glass accounts confirmed on `.onmicrosoft.us`.
- Entra Connect installed against the **US Gov** service instance; sign-in routes through
  `login.microsoftonline.us`.
- Pilot scope synced and validated; all applicable `05-testing.md` cases pass.
- Production expanded in waves; Connect Health green; Gov endpoint allow-list current.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
