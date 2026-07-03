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
