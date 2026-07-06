# 3. Implementation Guide — macOS Identity-Threat & Account-Lockout Hardening

Follow these steps in order, across Microsoft Entra (`https://entra.microsoft.com`) and Microsoft
Intune (`https://intune.microsoft.com`). The steps produce and reuse three named objects verbatim:
the findings register (`MACLOCK Sign-in Failure Findings - Mac-Originated - Sources`), the hardening
register (`MACLOCK Lockout & Spray Register - Mac Fleet - Baseline`), and the remediation evidence
pack (`MACLOCK Remediation Evidence Pack - Mac Credential State`). Scoped changes target the scope
groups `MACLOCK Scope - Pilot - Macs` and `MACLOCK Scope - Broad - Macs`.

> **Model:** Assess the Mac-originated failures, configure Smart Lockout + MFA and prepare the
> Mac-side remediation, pilot against the Mac scope group, validate the reduction, then expand.
> **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Create the scope groups
1. Run `MACLOCK-Set-ScopeTargeting.ps1 -Apply` to create the scope groups (`MACLOCK Scope - Pilot -
   Macs` and `MACLOCK Scope - Broad - Macs`), or create them in Entra to **Groups → New group →
   Security**.
2. Add a small, representative pilot population (the users whose Macs are producing failures) to
   `MACLOCK Scope - Pilot - Macs`.

## Step 2 — Assess: identify Mac-originated lockout / spray sources
1. In Entra, go to **Identity → Monitoring & health → Sign-in logs**. Add filters: **Status =
   Failure**, and add the **Operating system** column (filter to **macOS**). Note the top **users**,
   the **applications** (e.g. Exchange/Outlook, Wi-Fi/802.1X, browser), and the **failure reason /
   error codes** (bad password, account locked, MFA required).
2. If licensed, go to **Protection → Identity Protection → Risk detections** and note any
   **password-spray** or related detections and the users they hit.
3. Run `MACLOCK-Discovery.ps1` to read the same data via Microsoft Graph: it lists Mac-originated
   **failed sign-ins** grouped by user, app, and error code, and pulls the current **Smart Lockout**
   and **Conditional Access / MFA** posture.
4. Record every finding — user, Mac (device), app, error code, count — in `MACLOCK Sign-in Failure
   Findings - Mac-Originated - Sources`, and record the current Smart Lockout threshold/duration and
   MFA posture in `MACLOCK Lockout & Spray Register - Mac Fleet - Baseline` with their desired values.

## Step 3 — Configure Smart Lockout
1. In Entra, go to **Protection → Authentication methods → Password protection**.
2. Record the current **Lockout threshold** and **Lockout duration in seconds**, then set the desired
   values from the register (a threshold that tolerates a small burst of Mac retries without locking
   the real user, and a duration appropriate to your environment). Smart Lockout locks out the
   attacker's view while recognizing the legitimate user.
3. If accounts are **hybrid** (Requirement 2.6), coordinate with the on-premises AD lockout policy
   owner before changing thresholds so cloud and on-prem lockout don't conflict.
4. Capture the resulting settings into `MACLOCK Remediation Evidence Pack - Mac Credential State`.

## Step 4 — Enforce MFA (Conditional Access), piloted
1. In Entra, go to **Protection → Conditional Access → Policies → New policy**.
2. Name it `MACLOCK CA - Require MFA - Mac Pilot`. **Users:** assign `MACLOCK Scope - Pilot - Macs`.
   **Target resources:** All cloud apps (or the specific apps producing failures). **Grant:** Require
   multifactor authentication. Start in **Report-only**, review the sign-in log's Conditional Access
   evaluation, then set to **On**.
3. (If P2) Consider a companion risk-based policy that requires MFA / password change on detected
   sign-in risk for the same scope — name it `MACLOCK CA - Risk-Based MFA - Mac Pilot`.
4. Capture the policy settings into the evidence pack.

## Step 5 — Prepare the Mac-side remediation
1. Build the remediation guidance for the pilot Macs, covering: clearing **stale keychain items** for
   the affected accounts (Wi-Fi/802.1X, mail, app passwords); **re-syncing** the saved credential in
   the macOS Mail / Outlook profile and Wi-Fi after a password change; and resolving **SecureToken /
   local-account divergence** (re-aligning the local account password and SecureToken with the current
   Entra password after a reset).
2. Package the guidance/script for delivery via Intune: `https://intune.microsoft.com` to **Devices →
   macOS → Scripts** (shell script) or a documented runbook, scoped to `MACLOCK Scope - Pilot - Macs`.
3. Keep the endpoint action **gated by change control** — remediation is authentication-impacting.

## Step 6 — Pilot the remediation on the affected Macs
1. For the pilot users identified in Step 2, run the Mac-side remediation on their Macs (clear stale
   keychain items, re-enter the current password in Mail/Wi-Fi, resolve SecureToken divergence).
2. Confirm the user can sign in cleanly (no repeated prompts) and that the Mac stops re-submitting the
   old password.
3. File the before/after evidence into `MACLOCK Remediation Evidence Pack - Mac Credential State`.

## Step 7 — Validate the reduction
1. Run `MACLOCK-Validation.ps1` to confirm Smart Lockout and the MFA policy match the desired state
   in the register, and to re-read Mac-originated failures for the pilot users.
2. In the Entra sign-in logs, confirm the pilot users' **Mac-originated failures have dropped** and
   no new lockouts/spray detections are firing for them.
3. Run `MACLOCK-Report.ps1` to produce the before/after exposure report and file it into the evidence
   pack. Use `MACLOCK-Remediation.ps1` (default `-WhatIf`) to preview any remaining safe fixes
   (e.g. adding a user's Mac to the pilot scope) before applying.

## Step 8 — Expand and set the review cadence
1. Once the pilot validates (failures down, no legitimate-user lockouts, MFA working), expand the MFA
   policy and the Mac-side remediation from `MACLOCK Scope - Pilot - Macs` to `MACLOCK Scope - Broad -
   Macs`, and confirm the tenant-level Smart Lockout values are right for the whole fleet.
2. Set a review cadence (e.g. weekly sign-in-log review during rollout, then monthly) and re-run
   `MACLOCK-Discovery.ps1`, `MACLOCK-Validation.ps1`, and `MACLOCK-Report.ps1` each cycle so new
   Mac-originated failures are caught and remediated before they cause lockouts.

---
### Order of operations
`Scope groups → Assess (sign-in logs + Discovery) → Smart Lockout → MFA (CA, piloted) → Prepare Mac remediation → Pilot remediation → Validate reduction → Expand + review cadence`
