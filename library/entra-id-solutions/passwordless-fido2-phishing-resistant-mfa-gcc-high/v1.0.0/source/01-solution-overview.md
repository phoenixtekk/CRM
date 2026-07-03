# 1. Solution Overview — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

> This is the **Government (GCC High)** edition. It deploys the same phishing-resistant, passwordless
> authentication model as the Commercial edition, but on the **US sovereign cloud**: the admin
> portals, sign-in endpoints, and Microsoft Graph endpoints are the `*.us` sovereign URLs, and a few
> adjacent capabilities lag or differ from Commercial. Configure a GCC High tenant with these steps —
> not with Commercial steps that silently authenticate against the wrong cloud.

## What phishing-resistant, passwordless authentication is
Passwordless means a user signs in **without typing a password** — proving identity with a
hardware-backed credential bound to the device or a security key. Phishing-resistant means the
credential **cannot be replayed against an attacker's fake site**: it is cryptographically bound to
the real sign-in origin, so a phished code or an approved push can't be reused. In Microsoft Entra
ID, the phishing-resistant, passwordless methods are **FIDO2 security keys**, **Windows Hello for
Business**, and **certificate-based authentication** (smart cards — CAC / PIV). This solution turns
those on, gets users registered, and then enforces them.

For a US Government tenant this is not optional polish. Executive Order 14028 and OMB M-22-09 direct
federal agencies toward **phishing-resistant MFA**, and CMMC / NIST SP 800-171 push the same
requirement onto the defense-industrial base. FIDO2 keys and CAC/PIV smart cards are the methods that
satisfy it.

## How it works
1. Entra ID's **Authentication methods** policy (at `https://entra.microsoft.us`) enables each method (FIDO2, Windows Hello for Business, certificate-based auth) and scopes *who* can register it.
2. Users **register** a credential — tapping/plugging a FIDO2 key, enrolling Windows Hello, or being issued a smart-card certificate — at the sovereign security-info portal (`https://aka.ms/mysecurityinfo`, which resolves to the US Gov My Sign-Ins) or during supervised enrollment.
3. A Conditional Access **authentication strength** defines the set of acceptable methods (the built-in *Phishing-resistant MFA* strength, or a custom one).
4. A Conditional Access **policy** requires that strength for the targeted users, so a password+SMS or password+push sign-in is **blocked** — only a phishing-resistant credential satisfies the grant.
5. Coverage and registration are reported from Entra (registration details) so you can see who is ready before you enforce. In this edition the reporting scripts query **US Gov Graph** (`-Environment USGov`).

## FIDO2 keys vs. Windows Hello for Business vs. certificate-based auth (CAC/PIV)
- **FIDO2 security keys** — a portable hardware key (USB/NFC) the user taps. Best for shared workstations, kiosks, frontline, and admins who roam between machines. Phishing-resistant by design. Prefer FIPS 140-validated keys for government use.
- **Windows Hello for Business** — a credential bound to a specific Windows PC, unlocked by PIN or biometric. Best for assigned, single-user devices.
- **Certificate-based authentication (CAC / PIV)** — X.509 certificates on a smart card. **This is usually the primary method for DoD (CAC) and federal-civilian (PIV) tenants**, because the smart-card credential already exists on the badge. Entra CBA authenticates the certificate **directly to Entra ID** (not through AD FS), which the U.S. GSA describes as a phishing-resistant, Conditional-Access-verifiable sign-in.

## Commercial vs GCC High — what's different
The authentication model is identical; the **cloud plane it runs on is not**. In GCC High:

- **You sign in and administer at sovereign `*.us` portals**, not the Commercial `*.com` portals. The Commercial portals will not recognize a GCC High account. (See the Requirements Guide for the full endpoint table.)
  - Microsoft Entra admin center: **`https://entra.microsoft.us`** (Commercial: `entra.microsoft.com`).
  - Azure portal: **`https://portal.azure.us`** (Commercial: `portal.azure.com`).
  - Microsoft 365 admin center: **`https://portal.office365.us`** (Commercial: `admin.microsoft.com`).
  - Sign-in / authentication: **`https://login.microsoftonline.us`** (Commercial: `login.microsoftonline.com`).
  - Microsoft Graph: **`https://graph.microsoft.us`** for GCC High, **`https://dod-graph.microsoft.us`** for DoD (Commercial: `graph.microsoft.com`). Source: Microsoft Learn, *Microsoft Graph national cloud deployments*.
- **Scripts must target US Gov Graph.** Every `Connect-MgGraph` call in this solution uses **`-Environment USGov`** (or `USGovDoD` for DoD); without it the SDK authenticates against the Commercial endpoint and fails against a GCC High tenant. All five scripts in this package default to `-Environment USGov`.
- **The core methods are GA in US Gov.** Microsoft's *Entra feature availability in Azure for US Government* lists **Passwordless (Windows Hello for Business, Microsoft Authenticator, FIDO2 security key integrations)**, **Certificate-based authentication**, and **Conditional Access** all as available (✅). The whole program in this solution is built on these GA methods. Source: Microsoft Learn, *Microsoft Entra feature availability in Azure for US Government*.
- **Certificate-based auth is the DoD/federal centerpiece.** Because CAC/PIV cards already exist, CBA is often the primary phishing-resistant method — direct-to-Entra, no AD FS. See `gcc-high-parity-notes.md` §3 for binding details, and **verify the current CBA configuration for GCC High/DoD** at deployment time.
- **Some adjacent capabilities lag, are partial, or differ** — call these out and verify against the current sovereign docs before relying on them:
  - **Passkeys in Microsoft Authenticator, cross-device (QR) passkey sign-in, and synced passkeys** (Apple/Google) are **not confirmed** for GCC High — Authenticator-dependent features often lag in the sovereign clouds. **Verify for GCC High**; default to a **hardware FIDO2 key** or **CBA smart card**.
  - **Temporary Access Pass (TAP)** as the passwordless bootstrap credential is **not called out** in the US Gov feature table — **verify for GCC High** before designing onboarding around it; have an in-person enrollment fallback.
  - **Registration campaign** (nudge to add a method at sign-in) — confirm the sub-feature is present in your sovereign tenant; if absent, drive registration by communication + supervised enrollment.
  - **My Staff** (delegated helpdesk portal for frontline registration) is listed **not available** (❌) for US Gov.
  - **Microsoft Entra threat intelligence** (one ID Protection detection) is **not available** (❌); most other risk detections *are* available, so risk-based enforcement is still possible.
  - **Graph Explorer** (the browser tool) is **not supported** for `graph.microsoft.us`/DoD — use PowerShell (`-Environment USGov`), which is exactly what this package's scripts do.

> Where this document says **"verify for GCC High,"** treat the capability as unconfirmed for the
> sovereign cloud: check the current Microsoft US Gov documentation (or the Microsoft 365 US
> Government service descriptions) before you depend on it. Never assume Commercial parity for a
> preview, Microsoft-Authenticator, or cross-cloud feature. Full detail is in `gcc-high-parity-notes.md`.

## What you can control
- Which methods are enabled and **who may register** each (per-group scoping), on the sovereign Authentication methods policy.
- Optional **AAGUID restriction** — allow-list specific certified (ideally FIPS-validated) FIDO2 key models.
- The **authentication strength** required (built-in Phishing-resistant MFA, or a custom strength combining FIDO2 / Windows Hello / CBA).
- The Conditional Access **scope** (pilot group first, then all staff), with break-glass exclusions.

## Benefits
- **Phishing-resistant** — credentials can't be replayed against fake sites; push-bombing stops working.
- **Passwordless** — no password to phish, spray, or reuse; better user experience.
- **Mandate-ready** — meets EO 14028 / OMB M-22-09 phishing-resistant-MFA direction and supports CMMC / NIST 800-171 authentication objectives common to GCC High tenants.
- **Enforceable** — Conditional Access authentication strengths block weak methods, not just recommend strong ones.
- **Measurable** — registration and method-coverage reporting (US Gov Graph) before and after enforcement.
- **Sovereign-correct** — configured on the `*.us` plane so a government tenant is secured in-cloud, not against Commercial endpoints.

## Limitations (be honest with buyers)
- FIDO2 keys and certificate-based auth need **hardware** (keys, or a PKI/smart-card stack) — a procurement and distribution step. In DoD/federal the smart cards usually already exist.
- Enforcing a phishing-resistant strength **before** users are registered will lock them out — registration must lead enforcement (hence the pilot gate).
- Certificate-based authentication requires a configured certificate authority, trust chain, and username binding in Entra; **verify the current CBA binding requirements for GCC High/DoD**.
- Some legacy / line-of-business apps and protocols don't honor modern auth; inventory them before tenant-wide enforcement.
- GCC High parity gaps apply to Authenticator-based passkeys, TAP, registration campaign, and My Staff (see *Commercial vs GCC High* above and `gcc-high-parity-notes.md`) — verify before relying on them.

## The standard deployment model
> **Enable methods → register users (supervised / campaign if available) → create the
> phishing-resistant authentication strength → require it via Conditional Access on the pilot →
> validate → expand to all staff.** Registration always leads enforcement so no one is locked out.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**
