# 2. Requirements Guide — macOS Identity-Threat & Account-Lockout Hardening

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-security.md`.

## 2.1 Entra sign-in logs (and, where licensed, Identity Protection)
**Description:** Access to Microsoft Entra **sign-in logs** (interactive and non-interactive) and, if
licensed, **Identity Protection** risk detections.
**Why:** The whole method starts by reading which failed sign-ins come from Macs; the sign-in logs
(with the operating-system and failure-reason fields) are the source of truth, and Identity
Protection surfaces the password-spray / risk detections those failures drive.
**Verify:** `https://entra.microsoft.com` to **Identity → Monitoring & health → Sign-in logs** loads
and shows sign-ins; for risk detections, **Protection → Identity Protection → Risk detections** loads
(if licensed). Run `MACLOCK-Discovery.ps1` to read Mac-originated failures via Microsoft Graph.
**Implement:** Ensure an Entra plan that surfaces sign-in logs (all Entra tenants) and, for the full
risk-detection surface and risk-based Conditional Access, **Entra ID P2** (flag this if you only need
Smart Lockout + MFA, which do not require P2).

## 2.2 Smart Lockout configuration access
**Description:** Access to the Entra **Smart Lockout** settings (lockout threshold and duration).
**Why:** Smart Lockout is the control that stops a burst of bad-password attempts from locking the
legitimate user while still blocking the attacker's view — the core tenant-side hardening here.
**Verify:** `https://entra.microsoft.com` to **Protection → Authentication methods → Password
protection** shows **Lockout threshold** and **Lockout duration in seconds**.
**Implement:** Confirm you hold a role that can edit password protection (Security Administrator);
record the current threshold/duration before changing them.

## 2.3 Conditional Access for MFA enforcement
**Description:** The ability to create a **Conditional Access** policy that requires MFA for the
scoped population.
**Why:** Enforcing MFA means a correct-password-only attempt (including a lucky spray hit) is never
sufficient to sign in — it shrinks the value of the failed-sign-in noise and protects the account.
**Verify:** `https://entra.microsoft.com` to **Protection → Conditional Access → Policies** loads and
you can create a policy.
**Implement:** Ensure Conditional Access is available (Entra ID P1/P2) and you hold Conditional
Access Administrator or Security Administrator; if only Security Defaults is on, plan the move to a
scoped Conditional Access MFA policy.

## 2.4 Intune with enrolled macOS devices
**Description:** Microsoft Intune with the target **Macs enrolled** and manageable.
**Why:** Intune scopes and delivers the Mac-side remediation guidance/scripts to the right devices,
and lets you confirm which Macs are managed and reporting.
**Verify:** `https://intune.microsoft.com` to **Devices → All devices**; the target Macs appear with
**OS = macOS** and are enrolled/compliant.
**Implement:** Enrol the Macs (Automated Device Enrollment / Company Portal) and confirm they check
in — see `global-requirements-security.md` G4.

## 2.5 A Mac pilot scope group
**Description:** A Microsoft Entra security group scoping the **pilot Mac population** (users and/or
their Macs) for the scoped changes.
**Why:** Everything that touches sign-in — MFA enforcement especially — is piloted before fleet
rollout so a misconfiguration can't lock out the whole fleet.
**Verify:** Entra to **Groups**; the pilot group exists — run `MACLOCK-Set-ScopeTargeting.ps1`.
**Implement:** Create the scope groups with `MACLOCK-Set-ScopeTargeting.ps1` (or Entra to Groups to
New group to Security).

## 2.6 Hybrid vs cloud-only lockout model confirmed
**Description:** A documented understanding of whether accounts are **cloud-only** or **hybrid**
(synced from Active Directory), because lockout behaviour differs.
**Why:** For hybrid accounts, an on-premises AD lockout policy and password writeback interact with
Entra Smart Lockout; tuning cloud Smart Lockout without knowing the on-prem policy can produce
surprising results.
**Verify:** Entra to **Connect / Connect Sync** (or ask the directory owner) whether the affected
users are synced; check whether an on-prem account-lockout GPO exists.
**Implement:** Record the model in the register; if hybrid, coordinate the cloud Smart Lockout tuning
with the on-prem lockout policy owner as part of change control (flag any uncertainty rather than
guessing).

## 2.7 macOS credential / keychain / SecureToken remediation authority
**Description:** An agreed, change-controlled way to perform the **Mac-side** fixes: clear stale
keychain items, re-sync saved credentials, and resolve SecureToken / local-account divergence.
**Why:** The *cause* of the repeated failures lives on the Mac; fixing it requires acting on the
endpoint (guided steps and/or Intune-delivered scripts), which is authentication-impacting and must
be gated.
**Verify:** A change ticket exists naming the pilot Macs, the remediation steps, and the rollback;
you can deliver a script/config to the pilot Macs via Intune.
**Implement:** Adopt the change-control process from `global-requirements-security.md` G8; scope the
remediation to `MACLOCK Scope - Pilot - Macs` first.

## 2.8 Microsoft Graph PowerShell for discovery and reporting
**Description:** The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
read scopes the scripts use.
**Why:** The discovery, validation, and report scripts read Entra **sign-in logs**, the current
Smart Lockout / authentication-methods policy, and Conditional Access policies via Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; run
`MACLOCK-Discovery.ps1`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the read scopes
(`AuditLog.Read.All`, `Directory.Read.All`, `Policy.Read.All`,
`IdentityRiskEvent.Read.All`) on first connect.

---
## Checklist
- [ ] Entra sign-in logs (and Identity Protection, if P2) — `MACLOCK-Discovery.ps1`
- [ ] Smart Lockout settings access (threshold + duration)
- [ ] Conditional Access available for MFA enforcement
- [ ] Intune with enrolled macOS devices
- [ ] Mac pilot scope group — `MACLOCK-Set-ScopeTargeting.ps1`
- [ ] Hybrid vs cloud-only lockout model confirmed
- [ ] macOS credential / keychain / SecureToken remediation authority + change control
- [ ] Microsoft Graph PowerShell installed — `MACLOCK-Discovery.ps1`
