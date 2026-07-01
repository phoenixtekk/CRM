# 2. Requirements Guide — Conditional Access Integration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Microsoft Entra ID P1 (or P2 for risk-based policies).
**Why:** Conditional Access is a P1 feature; risk-based conditions need P2.
**Verify:** M365 admin center → **Billing → Licenses** (P1 via M365 E3/E5/Business Premium).
**Implement:** Assign M365 E3/E5 or Business Premium to targeted users.

## 2.2 Break-glass (emergency access) accounts
**Description:** Two cloud-only Global Administrator accounts excluded from all CA policies.
**Why:** They guarantee you can always sign in if a CA policy misfires — the #1 lockout safeguard.
**Verify:** Entra → **Users** — two dedicated emergency accounts exist; run **`CAI-BreakGlassCheck.ps1`**.
**Implement:** Create two cloud-only `.onmicrosoft.com` Global Admins with long random passwords stored offline; exclude them from every CA policy.

## 2.3 Device compliance (for "require compliant device")
**Description:** Intune device compliance policies in place.
**Why:** The "require compliant device" control needs Intune to be marking devices Compliant.
**Verify:** Intune → **Devices → Compliance**; devices report Compliant.
**Implement:** Deploy the **Device Compliance Policies** solution first.

## 2.4 MFA registration
**Description:** Users are able to register MFA methods.
**Why:** "Require MFA" challenges users; they must have a method registered.
**Verify:** Entra → **Authentication methods**; run **`CAI-Discovery.ps1`** for the local user.
**Implement:** Enable authentication methods and (optionally) the registration campaign or SSPR.

## 2.5 Sign-in logs / reporting
**Description:** Access to Entra sign-in logs.
**Why:** Report-only impact is reviewed in the sign-in logs before enforcing.
**Verify:** Entra → **Monitoring → Sign-in logs** loads.
**Implement:** Ensure the operator has Reports Reader / Security Reader.

## 2.6 App protection (optional — mobile)
**Description:** Intune app protection policies for mobile apps.
**Why:** The "require app protection policy" control needs them defined.
**Verify:** Intune → **Apps → App protection policies**.
**Implement:** Create app protection policies for iOS/Android (optional companion work).

---
## Checklist
- [ ] Entra ID P1 licensing assigned
- [ ] **Two break-glass admins created and excluded** — `CAI-BreakGlassCheck.ps1`
- [ ] Device compliance policies in place
- [ ] MFA methods enabled / users can register
- [ ] Sign-in log access for review
- [ ] Pilot Entra group created
