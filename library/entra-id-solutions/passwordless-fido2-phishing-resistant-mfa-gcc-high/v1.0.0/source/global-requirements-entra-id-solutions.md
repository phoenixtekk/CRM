# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to **every** solution in the **Entra ID Solutions** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Entra ID identity solution. Each entry: **Description · Why · Verify ·
Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID tenant.
**Why:** It is the identity backbone that issues credentials, evaluates Conditional Access, and stores authentication methods.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator; the tenant Overview loads.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1 / P2)
**Description:** Entra ID P1 for Conditional Access; P2 for risk-based policies and Identity Protection.
**Why:** Conditional Access authentication strengths require P1; risk-driven enforcement requires P2.
**Verify:** Entra → **Overview**; or M365 admin center → **Billing → Licenses** (look for Entra ID P1/P2, included in M365 E3/E5 and Business Premium).
**Implement:** Assign M365 E3/E5, Business Premium, or standalone Entra ID P1/P2.

## G3. Administrative roles
**Description:** Appropriate Entra admin roles for the operator.
**Why:** Editing authentication methods and Conditional Access requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Authentication Policy Administrator** (methods) and **Conditional Access Administrator** (policies).
**Implement:** Assign **Authentication Policy Administrator** + **Conditional Access Administrator**; reserve **Global Administrator** for tenant-wide changes.

## G4. Break-glass (emergency-access) accounts
**Description:** At least two cloud-only emergency-access accounts excluded from Conditional Access.
**Why:** A misconfigured authentication-strength or MFA policy can lock out every admin; break-glass accounts preserve access.
**Verify:** Entra → **Users**; two `*.onmicrosoft.com` accounts exist and are excluded from all CA policies.
**Implement:** Create two cloud-only Global Administrator accounts with long passphrases, store credentials offline, exclude them from every CA policy, and monitor their sign-ins.

## G5. Authentication methods policy access
**Description:** The tenant uses the **Authentication methods** policy (the modern, converged surface) to manage methods.
**Why:** FIDO2, Windows Hello for Business, and certificate-based auth are enabled here, not in legacy per-method blades.
**Verify:** Entra → **Protection → Authentication methods → Policies** opens.
**Implement:** If still on the legacy MFA/SSPR method settings, migrate to the Authentication methods policy (Microsoft's guided migration toggle).

## G6. Conditional Access baseline
**Description:** Conditional Access is available and at least a baseline MFA policy exists (or security defaults are understood).
**Why:** Phishing-resistant enforcement is delivered through Conditional Access authentication strengths.
**Verify:** Entra → **Protection → Conditional Access → Policies** lists policies; security defaults state is known.
**Implement:** Disable security defaults only when replacing them with explicit CA policies; start in **Report-only** before enforcing.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365 / Entra sign-in and registration endpoints.
**Why:** Method registration, sign-in, and policy evaluation depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://aka.ms/mysecurityinfo`.
**Implement:** Allow Microsoft's published Microsoft 365 / Entra URL & IP ranges through proxy/firewall.

---
**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
