# 1. Solution Overview — Entra Identity Protection & Advanced Conditional Access

## What this is
This solution is the **risk and advanced layer** that sits on top of a Conditional Access baseline.
It combines two Microsoft Entra capabilities:

- **Microsoft Entra ID Protection** — a risk engine that continuously evaluates sign-ins and user
  accounts for signs of compromise (leaked credentials, impossible travel, anonymous IP, token
  replay, and more), assigns a risk level, and lets Conditional Access act on that risk.
- **Advanced Conditional Access** — the parts of Conditional Access beyond a static "require MFA"
  baseline: authentication contexts (step-up on a per-app or per-action basis), token protection
  (binding a session token to the device that obtained it), Continuous Access Evaluation (near
  real-time revocation), authentication strengths (demand a specific method such as phishing-resistant
  FIDO2), and named locations.

Together they turn a fixed access gate into an adaptive perimeter that reacts to risk as it emerges.

This is **distinct from the Conditional Access baseline** (require-MFA, block-legacy-auth,
device-compliance — covered by the Conditional Access baseline solution). This solution assumes that
baseline exists and adds the risk/context controls on top. It also absorbs and replaces the older
"Zero Trust for Identity" framing: the controls here are the identity core of a Zero Trust program.

## How it works
1. **Entra ID Protection** ingests signals from every sign-in and computes two scores: a **sign-in risk** (is *this* sign-in suspicious?) and a **user risk** (is *this account* likely compromised?). Detections range from real-time (impossible travel, anonymous IP) to offline (leaked credentials, threat-intelligence).
2. A **risk-based Conditional Access policy** uses those scores as a condition. For example: if sign-in risk is *medium or high*, require multi-factor authentication; if user risk is *high*, require a secure password change. Low-risk sign-ins pass through untouched.
3. An **authentication context** is a label (for example `c1`) you attach to a sensitive application or a sensitive action inside an app (such as a privileged operation). A Conditional Access policy then targets that label and demands a step-up — a fresh MFA, or a specific authentication strength — only when the sensitive context is invoked, not on every sign-in.
4. **Token protection** binds the refresh/session token to the client device's cryptographic key, so a token stolen and replayed from a different device is rejected. **Continuous Access Evaluation (CAE)** lets resource providers (Exchange Online, SharePoint, Graph) revoke or re-challenge a live session within minutes of a critical event (disabled account, password reset, elevated risk) instead of waiting up to an hour for the token to expire.
5. **Authentication strengths** let a policy require a *specific* method — for example phishing-resistant MFA (FIDO2 security key, passkey, Windows Hello for Business, certificate) — rather than "any MFA". Named locations define trusted or blocked IP ranges and countries that policies reference.
6. **Report-only mode** evaluates every new policy against real sign-ins and records "would have applied / would have blocked" in the sign-in logs **without affecting the user**. You read that data, confirm the blast radius, then move the policy to On.
7. **Break-glass emergency accounts** are excluded from all risk and enforcement policies, so a misconfigured risk policy or a bad enforcement flip can never lock every administrator out.

## What you can control
- Which risk levels trigger action, and what action (block, require MFA, require secure password change), for both sign-in risk and user risk policies.
- Authentication-context labels and which apps/actions map to them; the step-up each context demands.
- Token protection enforcement (via Conditional Access session controls) and the scope it applies to.
- Authentication strengths — built-in (phishing-resistant MFA, passwordless MFA, MFA) or a custom combination — and which policy/context requires each.
- Named locations (IP ranges, countries) marked trusted or used to block.
- Report-only vs enabled state for every policy, and the pilot scope each targets, plus break-glass exclusions.

## Benefits
- Adaptive — access reacts to real-time and offline risk instead of deciding once on fixed conditions.
- Step-up only where it matters — sensitive apps/actions demand a fresh, strong proof without adding friction to routine sign-ins.
- Token theft resistance — token protection and CAE make stolen tokens far less useful and revoke sessions in near real time.
- Phishing-resistant where required — authentication strengths let you demand FIDO2/passkey for the highest-value access.
- Safe to roll out — report-only first shows the exact blast radius before anything enforces.

## Limitations (be honest with buyers)
- **Entra ID P2** is required for risk-based Conditional Access and the full risky-users/risky-sign-ins experience (P1 sees limited risk data). *Verify current licensing availability in your tenant.*
- **Token protection** and some **authentication-context** and **CAE** behaviours have platform, client, and preview constraints (for example token protection currently targets specific Windows sign-in scenarios and clients). *Verify current availability and supported clients in your tenant before enforcing.*
- Risk-based policies act on Microsoft's risk scoring; tuning (dismissing false positives, confirming compromise) is an ongoing operational task, not a one-time setup.
- This layer governs Entra sign-in and session risk; it does not replace endpoint protection, a Conditional Access baseline, or PIM — it complements them.

## Auth / connections used
- Interactive administration in the Entra admin center (`https://entra.microsoft.com`).
- The included scripts use the **Microsoft Graph PowerShell SDK** (read-only scopes for discovery/validation/report; a scoped read-write policy scope only for the gated policy-state change script) and optionally **Az** / a Log Analytics workspace for KQL risk hunting when sign-in logs are exported to Microsoft Sentinel or Log Analytics.

## The standard deployment model
> Assess current risk posture and CA baseline -> Configure Identity Protection risk policies,
> authentication contexts, token protection, authentication strengths, and named locations in
> report-only -> Pilot against a small scope -> Validate report-only results and flip to enforce in
> stages -> Expand to the tenant. Break-glass accounts stay excluded throughout.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
