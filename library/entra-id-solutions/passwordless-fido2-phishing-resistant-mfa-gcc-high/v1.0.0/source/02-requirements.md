# 2. Requirements Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.
This edition targets the **US sovereign cloud** — use the `*.us` portals and US Gov Graph throughout.

## 2.0 Sovereign endpoints (GCC High / DoD)
**Description:** Administer on the `*.us` plane; the Commercial `*.com` portals reject GCC High accounts.
**Why:** Signing in or scripting against the wrong cloud fails or silently targets the wrong tenant.
**Verify:** You can sign in at `https://entra.microsoft.us`; `FIDO2G-Discovery.ps1` connects with `-Environment USGov`.

| Purpose | GCC High | DoD | Commercial |
|---|---|---|---|
| Entra admin center | `https://entra.microsoft.us` | `https://entra.microsoft.us` | `entra.microsoft.com` |
| Azure portal | `https://portal.azure.us` | `https://portal.azure.us` | `portal.azure.com` |
| Microsoft 365 admin center | `https://portal.office365.us` | `https://portal.office365.us` | `admin.microsoft.com` |
| Sign-in | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` | `login.microsoftonline.com` |
| Microsoft Graph | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` | `graph.microsoft.com` |
| Graph PowerShell `-Environment` | `USGov` | `USGovDoD` | `Global` |

**Implement:** Bookmark the sovereign portals; always pass `-Environment USGov` (or `USGovDoD`) in scripts. Source: Microsoft Learn, *Microsoft Graph national cloud deployments*.

## 2.1 Licensing (US Gov SKUs)
**Description:** Entra ID P1 (Conditional Access + authentication strengths); P2 only if you add risk-based enforcement. In the sovereign clouds these ship inside the **Government** bundles.
**Why:** Authentication strengths are delivered through Conditional Access, which requires Entra ID P1 (`AAD_PREMIUM`); risk-based Conditional Access needs P2 (`AAD_PREMIUM_P2`).
**Verify:** M365 admin center (`https://portal.office365.us`) → **Billing → Licenses**; look for the Entra P1/P2 service plan.
**Implement:** Assign **Microsoft 365 G3** (carries `AAD_PREMIUM` / P1) or **G5** (carries `AAD_PREMIUM_P2` / P2), or **EMS E3/E5 for Government**, or standalone Entra ID P1/P2 for Government. FIDO2, Windows Hello for Business, and CBA method enablement do not themselves require a premium SKU, but the **Conditional Access enforcement** does.

## 2.2 Admin roles
**Description:** Authentication Policy Administrator + Conditional Access Administrator for the operator.
**Why:** You will edit the Authentication methods policy and create Conditional Access policies.
**Verify:** Entra (`entra.microsoft.us`) → **Roles and administrators**.
**Implement:** Assign both roles; reserve Global Administrator for tenant-wide changes. (See global G3.)

## 2.3 Break-glass accounts
**Description:** Two cloud-only emergency-access accounts excluded from Conditional Access.
**Why:** An authentication-strength policy can lock out all admins; break-glass preserves access. Critical on GCC High, where support-assisted recovery is slower.
**Verify:** Entra → **Users**; two `*.onmicrosoft.us`/`*.onmicrosoft.com` cloud-only accounts excluded from every CA policy.
**Implement:** Create them, store credentials offline, exclude from all CA policies, monitor sign-ins. (See global G4.)

## 2.4 Authentication methods policy available
**Description:** The converged **Authentication methods** policy is in use (not the legacy MFA settings).
**Why:** FIDO2, Windows Hello for Business, and certificate-based auth are enabled here.
**Verify:** Entra → **Protection → Authentication methods → Policies** opens; run `FIDO2G-Discovery.ps1`.
**Implement:** Migrate from legacy MFA/SSPR method settings to the Authentication methods policy. (See global G5.)

## 2.5 FIDO2 security keys (hardware + support)
**Description:** FIDO2-certified security keys procured for in-scope users; modern browsers/OS for WebAuthn. Prefer **FIPS 140-validated** keys for government use.
**Why:** FIDO2 is the portable, phishing-resistant credential for roaming users and admins.
**Verify:** Keys on hand; user devices on a supported OS/browser; run `FIDO2G-Discovery.ps1` (FIDO2 method state).
**Implement:** Procure FIPS-validated FIDO2 keys; optionally restrict to specific key models by **AAGUID** in the FIDO2 method settings. AAGUID restriction is part of the GA FIDO2 configuration — **verify the exact sovereign-portal UI**.

## 2.6 Windows Hello for Business readiness
**Description:** Windows 10/11 devices able to provision Windows Hello (Entra-joined or hybrid).
**Why:** Windows Hello is the device-bound passwordless credential for assigned PCs.
**Verify:** Devices are Entra-joined/registered; run `FIDO2G-Discovery.ps1`.
**Implement:** Enable Windows Hello for Business (Intune policy at `https://endpoint.microsoft.us`, or the Authentication methods policy); ensure a TPM is present.

## 2.7 Certificate-based authentication (CAC / PIV) — often primary for DoD/federal
**Description:** A configured certificate authority and trust chain in Entra, username binding set, and issued CAC/PIV smart cards.
**Why:** For DoD (CAC) and federal-civilian (PIV) tenants this is usually the primary phishing-resistant method — the smart card already exists.
**Verify:** Entra → **Protection → Show more → Certificate-based authentication** shows CAs configured; a test smart-card sign-in succeeds. Listed **✅ Available** for US Gov (feature-availability table).
**Implement:** Upload the issuing/root CA chain to the Entra **certificate authorities** store; configure **username binding** (e.g. `PrincipalName` / `RFC822Name`, or `certificateUserIds`); set **authentication-binding** so a hardware-smart-card certificate policy counts as MFA. **Verify the current CBA binding requirements for GCC High/DoD** (see `gcc-high-parity-notes.md` §3). Sources: Microsoft Learn *feature availability*; U.S. GSA IDManagement *CBA on Entra ID*.

## 2.8 Conditional Access readiness
**Description:** Conditional Access available; an app/service inventory for tenant-wide enforcement.
**Why:** Enforcement uses an authentication-strength grant; legacy apps/protocols may not honor it.
**Verify:** Entra → **Protection → Conditional Access → Policies**; run `FIDO2G-Report.ps1` for current method coverage. Conditional Access is **✅ Available** in US Gov.
**Implement:** Plan policy scope; start in **Report-only**; identify exclusions for legacy protocols. (See global G6.)

## 2.9 Pilot and rollout groups
**Description:** Entra security groups for the pilot and the broad/all-staff rollout.
**Why:** Method scoping, registration, and CA enforcement target groups, piloted first.
**Verify:** Entra → **Groups**; pilot + rollout groups exist (or build with `FIDO2G-Set-ScopeTargeting.ps1`).
**Implement:** Create `Phishing-Resistant – Pilot – Users` and `Phishing-Resistant – All Staff – Users`.

## 2.10 Onboarding bootstrap method (verify for GCC High)
**Description:** A way to register a first passwordless method before one exists — Temporary Access Pass (TAP), or supervised in-person enrollment.
**Why:** A brand-new user with no credential needs a bootstrap to register a key or enroll Windows Hello.
**Verify:** Entra → **Protection → Authentication methods → Policies → Temporary Access Pass** — confirm it is present and enabled in your **sovereign** tenant. TAP is **not called out** in the US Gov feature table — **verify for GCC High**.
**Implement:** If TAP is available, enable it scoped to the pilot; if not, use **in-person supervised enrollment** (or CAC/PIV issuance) as the bootstrap. Do not assume TAP parity.

---
## Checklist
- [ ] Sovereign `*.us` portals reachable; scripts use `-Environment USGov`
- [ ] Entra ID P1 (Government) licensing assigned (P2 if risk-based)
- [ ] Authentication Policy + Conditional Access Administrator roles
- [ ] Two break-glass accounts excluded from CA
- [ ] Authentication methods policy in use — `FIDO2G-Discovery.ps1`
- [ ] FIDO2 (FIPS-validated) keys procured; OS/browser supported
- [ ] Windows Hello for Business readiness confirmed
- [ ] Certificate-based auth (CAC/PIV) CA + binding configured (verify for GCC High)
- [ ] Conditional Access ready; legacy-app exclusions identified
- [ ] Pilot + rollout Entra groups created
- [ ] Onboarding bootstrap decided (TAP verified, or supervised enrollment)
