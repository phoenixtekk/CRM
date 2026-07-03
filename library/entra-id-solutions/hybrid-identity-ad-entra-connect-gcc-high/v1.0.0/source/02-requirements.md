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
