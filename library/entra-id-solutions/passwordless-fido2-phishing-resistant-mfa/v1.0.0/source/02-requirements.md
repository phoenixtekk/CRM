# 2. Requirements Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

## 2.1 Licensing
**Description:** Entra ID P1 (Conditional Access + authentication strengths); P2 only if you add risk-based enforcement.
**Why:** Authentication strengths are delivered through Conditional Access, which requires P1.
**Verify:** M365 admin center → **Billing → Licenses** (Entra ID P1/P2 is included in M365 E3/E5 and Business Premium).
**Implement:** Assign M365 E3/E5, Business Premium, or standalone Entra ID P1.

## 2.2 Admin roles
**Description:** Authentication Policy Administrator + Conditional Access Administrator for the operator.
**Why:** You will edit the Authentication methods policy and create Conditional Access policies.
**Verify:** Entra → **Roles and administrators**.
**Implement:** Assign both roles; reserve Global Administrator for tenant-wide changes.

## 2.3 Break-glass accounts
**Description:** Two cloud-only emergency-access accounts excluded from Conditional Access.
**Why:** An authentication-strength policy can lock out all admins; break-glass preserves access.
**Verify:** Entra → **Users**; two `*.onmicrosoft.com` accounts excluded from every CA policy.
**Implement:** Create them, store credentials offline, exclude from all CA policies, monitor sign-ins. (See global G4.)

## 2.4 Authentication methods policy available
**Description:** The converged **Authentication methods** policy is in use (not the legacy MFA settings).
**Why:** FIDO2, Windows Hello for Business, and certificate-based auth are enabled here.
**Verify:** Entra → **Protection → Authentication methods → Policies** opens; run `FIDO2-Discovery.ps1`.
**Implement:** Migrate from legacy MFA/SSPR method settings to the Authentication methods policy.

## 2.5 FIDO2 security keys (hardware + support)
**Description:** FIDO2-certified security keys procured for the in-scope users; modern browsers/OS for WebAuthn.
**Why:** FIDO2 is the portable, phishing-resistant credential for roaming users and admins.
**Verify:** Keys on hand; user devices on a supported OS/browser; run `FIDO2-Discovery.ps1` (FIDO2 method state).
**Implement:** Procure FIDO2 keys; optionally restrict to specific key models by AAGUID in the FIDO2 method settings.

## 2.6 Windows Hello for Business readiness
**Description:** Windows 10/11 devices able to provision Windows Hello (Entra-joined or hybrid).
**Why:** Windows Hello is the device-bound passwordless credential for assigned PCs.
**Verify:** Devices are Entra-joined/registered; run `FIDO2-Discovery.ps1`.
**Implement:** Enable Windows Hello for Business (Intune policy or the Authentication methods policy); ensure TPM present.

## 2.7 (Optional) Certificate-based authentication
**Description:** A configured certificate authority and trust chain in Entra, plus issued certificates/smart cards.
**Why:** Required only if certificate-based auth is part of the program (often federal/PIV).
**Verify:** Entra → **Protection → Show more → Certificate-based authentication** shows CAs configured.
**Implement:** Upload the CA chain and configure username binding before enabling the method.

## 2.8 Conditional Access readiness
**Description:** Conditional Access available; an app/service inventory for tenant-wide enforcement.
**Why:** Enforcement uses an authentication-strength grant; legacy apps may not honor it.
**Verify:** Entra → **Protection → Conditional Access → Policies**; run `FIDO2-Report.ps1` for current method coverage.
**Implement:** Plan policy scope; start in **Report-only**; identify exclusions for legacy protocols. (See global G6.)

## 2.9 Pilot and rollout groups
**Description:** Entra security groups for the pilot and the broad/all-staff rollout.
**Why:** Method scoping, the registration campaign, and CA enforcement target groups, piloted first.
**Verify:** Entra → **Groups**; pilot + rollout groups exist (or build with `FIDO2-Set-RolloutTargeting.ps1`).
**Implement:** Create `Phishing-Resistant – Pilot – Users` and `Phishing-Resistant – All Staff – Users`.

---
## Checklist
- [ ] Entra ID P1 licensing assigned
- [ ] Authentication Policy + Conditional Access Administrator roles
- [ ] Two break-glass accounts excluded from CA
- [ ] Authentication methods policy in use — `FIDO2-Discovery.ps1`
- [ ] FIDO2 keys procured; OS/browser supported
- [ ] Windows Hello for Business readiness confirmed
- [ ] (Optional) Certificate-based authentication CA configured
- [ ] Conditional Access ready; legacy-app exclusions identified
- [ ] Pilot + rollout Entra groups created
