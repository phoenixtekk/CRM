# GCC High Parity Notes — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

This reference records what is **confirmed**, what **differs**, and what is **unconfirmed** for
passwordless / phishing-resistant authentication on the **US Government (GCC High / DoD) cloud**
versus Commercial. Every claim is cited to Microsoft documentation or explicitly flagged
**"verify for GCC High"** where Microsoft has not confirmed sovereign parity. **Never assume
Commercial parity** for preview features, Microsoft Authenticator passkey capabilities, or
cross-cloud behavior. Sovereign availability changes — verify against current Microsoft US Gov
documentation at deployment time.

## 1. Sovereign endpoints (confirmed)
Use the `*.us` plane for every portal, sign-in, and Graph call. The Commercial endpoints reject GCC
High accounts.

| Purpose | GCC High (US Gov L4) | DoD (US Gov L5) | Commercial |
|---|---|---|---|
| Microsoft Entra admin center | `https://entra.microsoft.us` | `https://entra.microsoft.us` | `https://entra.microsoft.com` |
| Azure portal | `https://portal.azure.us` | `https://portal.azure.us` | `https://portal.azure.com` |
| Microsoft 365 admin center | `https://portal.office365.us` | `https://portal.office365.us` | `https://admin.microsoft.com` |
| Sign-in / authentication | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` | `https://login.microsoftonline.com` |
| Security-info registration | `https://aka.ms/mysecurityinfo` (resolves to the sovereign My Sign-Ins) | same | `https://aka.ms/mysecurityinfo` |
| Microsoft Graph | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` | `https://graph.microsoft.com` |
| Graph PowerShell `-Environment` | `USGov` | `USGovDoD` | `Global` |

Sources:
- Microsoft Learn — *Microsoft Graph national cloud deployments* (`https://learn.microsoft.com/en-us/graph/deployments`): Graph = `graph.microsoft.us` (GCC High) / `dod-graph.microsoft.us` (DoD); Azure portal `portal.azure.us`; Entra ID sign-in `login.microsoftonline.us`. Also: **Graph Explorer is "Not supported"** for the US Gov L4/L5 endpoints.
- Microsoft Learn — *Microsoft 365 U.S. Government GCC High endpoints* (`https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints`): sovereign admin portals (`portal.office365.us`, `portal.azure.us`).
- Microsoft Learn — *Connect-MgGraph* national-cloud `-Environment` values (`USGov` → `graph.microsoft.us`, `USGovDoD` → `dod-graph.microsoft.us`): `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`.

## 2. Phishing-resistant methods — Generally Available in US Gov (confirmed)
Microsoft's *Entra feature availability in Azure for US Government* (page `ms.date` 2026-01-15) lists
the following under **Authentication, single sign-on, and MFA** as available (✅):

| Capability | US Gov availability | Notes |
|---|---|---|
| Multifactor authentication (MFA) | ✅ Available | Baseline MFA. |
| Passwordless — **Windows Hello for Business, Microsoft Authenticator, FIDO2 security key integrations** | ✅ Available | The exact table wording groups all three passwordless methods under one ✅ row. |
| **Certificate-based authentication (CBA)** | ✅ Available | The DoD-critical method for **CAC / PIV smart cards** — see §3. |
| Conditional Access | ✅ Available | Delivers **authentication strengths** (the enforcement layer). |
| Federated authentication (AD FS / other IdP) | ✅ Available | Relevant only if federating; direct CBA to Entra is preferred over AD FS. |

Source: Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government*
(`https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability`), exact rows:
"Passwordless (Windows Hello for Business, Microsoft Authenticator, FIDO2 security key integrations)
✅"; "Certificate-based authentication ✅"; "Conditional Access ✅".

**Implication:** the core deployment in this solution — enable **FIDO2 security keys**, **Windows
Hello for Business**, and/or **certificate-based authentication**; get users registered; create a
**phishing-resistant authentication strength**; and require it via **Conditional Access** — is fully
supported on GCC High. Build the whole program on these GA methods.

## 3. Certificate-based authentication (CBA) — the DoD / federal path (confirmed GA; details verify)
For **DoD (CAC)** and **federal civilian (PIV)** tenants, CBA is usually the primary
phishing-resistant method because the smart-card credential already exists. CBA authenticates the
**X.509 certificate directly to Microsoft Entra ID** (not through AD FS), which Microsoft and the
U.S. GSA describe as a phishing-resistant sign-in that can be required with Conditional Access.

- CBA is listed **✅ Available** for US Gov (feature-availability table, §2).
- Deployment requires: uploading the issuing/root **CA chain** to the Entra **certificate authorities** trust store, configuring **username binding** (map a certificate field — e.g. `PrincipalName` / `RFC822Name`, or the `certificateUserIds` attribute — to the user), and setting **authentication-binding** rules that decide which certificate policy OIDs count as single-factor vs multifactor (MFA).
- To count as **phishing-resistant MFA**, the certificate must be issued to a **hardware smart card** (CAC/PIV) and mapped via a **high-affinity binding**; Microsoft's phishing-resistant authentication-strength guidance covers which CBA bindings qualify. **Verify the current binding requirements for GCC High/DoD** at deployment time.

Sources:
- Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government* (CBA ✅).
- U.S. GSA IDManagement — *Certificate-Based Authentication on Microsoft Entra ID* (`https://www.idmanagement.gov/implement/cba-azure/`): direct X.509 auth to Entra ID is a phishing-resistant, Conditional-Access-verifiable login for PIV/CAC.
- Microsoft Learn — *How to configure Microsoft Entra certificate-based authentication* and *Certificate-based authentication technical deep dive* (bindings, `certificateUserIds`). **Verify for GCC High** — confirm the CBA configuration steps and any DoD-specific binding notes against the current sovereign docs.

## 4. Known differences and limitations vs Commercial (confirmed)
| Area | Commercial | US Gov (GCC High / DoD) | Source |
|---|---|---|---|
| Graph Explorer (browser tool) | Supported | **Not supported** for `graph.microsoft.us` / `dod-graph.microsoft.us` — use PowerShell `-Environment USGov` | Graph national cloud deployments |
| Delegated user-management portal (**My Staff**) | Available | **Not available (❌)** — no delegated helpdesk portal for frontline TAP/registration assistance | Entra feature availability for US Government |
| **Microsoft Entra threat intelligence** (ID Protection detection) | Available | **Not available (❌)** — noted because risk-based Conditional Access on top of the phishing-resistant grant has one fewer detection source | Entra feature availability for US Government |
| Shared device sign-out / **Enterprise state roaming** (Windows 10) | Available | **Not available** for Windows 10 devices | Entra feature availability for US Government |

Note: most **ID Protection risk detections** (leaked credentials, anonymous IP, atypical/impossible
travel, password spray, etc.) **are ✅ available** in US Gov — only *Microsoft Entra threat
intelligence* is ❌. So risk-based enforcement is still possible; just do not design around the
threat-intelligence signal.

## 5. Verify for GCC High (unconfirmed sovereign parity — do not assume Commercial parity)
The following are **Preview**, **Microsoft-Authenticator-dependent**, or **cross-cloud** in
Commercial and are **not confirmed** for GCC High at authoring time. Treat each as "verify for GCC
High" and default to the GA path (hardware FIDO2 keys, Windows Hello for Business, or CBA/smart card):

- **Passkeys in Microsoft Authenticator** (device-bound passkeys in the Authenticator app), **cross-device passkey sign-in via QR code**, and **synced passkeys** (Apple iCloud Keychain / Google Password Manager). Microsoft's passkey concept page does not confirm sovereign-cloud availability, and Microsoft Authenticator features frequently lag in the US Gov clouds. **Verify for GCC High.** The GA, sovereign-safe choice is a **hardware FIDO2 security key** or **CBA smart card**, not a synced/phone passkey. Source: Microsoft Learn — *Passkeys (FIDO2) authentication method in Microsoft Entra ID* (`https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-passkeys-fido2`).
- **Temporary Access Pass (TAP)** as the bootstrap credential for registering a first passwordless method. TAP is not called out separately in the US Gov feature-availability table; Microsoft documents it under passwordless onboarding for Commercial. **Verify for GCC High** before designing frontline onboarding around TAP; have a fallback (in-person key enrollment or CBA issuance) if TAP is unavailable. Source: Microsoft Learn — *Configure a Temporary Access Pass* (`https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-temporary-access-pass`).
- **Registration campaign** to nudge users to add a passwordless method at sign-in. The converged Authentication methods policy is available in US Gov, but confirm the **registration campaign** sub-feature (and which methods it can nudge) is present in your sovereign tenant. **Verify for GCC High**; if absent, drive registration by direct communication + supervised enrollment.
- **FIDO2 provisioning / Microsoft-managed AAGUID conveniences and passkey profiles** that appear in Commercial previews — **verify for GCC High.** AAGUID **restriction** (allow-listing specific certified key models) in the FIDO2 method settings is part of the GA FIDO2 configuration and is expected; confirm the exact UI in the sovereign portal.
- **Hybrid FIDO2 (on-prem SSO to AD DS with a security key)** — supported in Commercial for Entra hybrid-joined Windows; confirm the on-prem components (Kerberos-trust / cloud Kerberos) and version prerequisites for your GCC High + on-prem AD environment. **Verify for GCC High.**

> General rule: features marked **Preview** in Microsoft's Commercial docs, and anything that depends
> on the **Microsoft Authenticator app** or **cross-cloud** behavior, should be assumed **later or
> absent** in the sovereign clouds until Microsoft's US Gov documentation confirms them. When in
> doubt, flag "verify for GCC High" and deploy the GA path: **hardware FIDO2 key, Windows Hello for
> Business, or CBA smart card**, enforced with a Conditional Access authentication strength.

## 6. Sources
- Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government*: `https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability`
- Microsoft Learn — *Microsoft Graph national cloud deployments*: `https://learn.microsoft.com/en-us/graph/deployments`
- Microsoft Learn — *Connect-MgGraph (Microsoft.Graph.Authentication)* national-cloud `-Environment` values: `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`
- Microsoft Learn — *Microsoft 365 U.S. Government GCC High endpoints*: `https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints`
- Microsoft Learn — *Passkeys (FIDO2) authentication method in Microsoft Entra ID*: `https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-passkeys-fido2`
- Microsoft Learn — *How to enable passkeys (FIDO2) in Microsoft Entra ID*: `https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-authentication-passkeys-fido2`
- Microsoft Learn — *Configure a Temporary Access Pass*: `https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-temporary-access-pass`
- U.S. GSA IDManagement — *Certificate-Based Authentication on Microsoft Entra ID*: `https://www.idmanagement.gov/implement/cba-azure/`
- Microsoft Learn — *Get started with phishing-resistant MFA deployment in Microsoft Entra ID* (phishing-resistant authentication-strength guidance).
