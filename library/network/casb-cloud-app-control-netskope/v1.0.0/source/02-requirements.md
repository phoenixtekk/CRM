# 2. Requirements Guide — CASB & Cloud App Control with Netskope

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-network.md`.

## 2.1 Netskope tenant with the CASB module licensed
Description: An active Netskope tenant with the CASB module (inline and API) licensed and enabled.
Why: CASB is the control plane for discovery, risk scoring, and the allow/restrict/coach/block levers.
Verify: Sign in to your Netskope tenant as an administrator and confirm the CASB capability is present.
Implement: Engage your Netskope account team / reseller to add the CASB module to the tenant.

## 2.2 Traffic steering / SWG already in place
Description: Live web/cloud traffic is already steered through Netskope (client or steering config).
Why: Inline CASB and activity controls only see and act on traffic that flows through Netskope.
Verify: Confirm steering is active for the target population; run `NSCASB-Validation.ps1` for the steering-readiness signals.
Implement: Deploy/assign the Netskope client and steering configuration (the category steering/SWG prerequisite) before enabling inline control.

## 2.3 SSL/TLS inspection enabled for the in-scope apps
Description: Decryption is enabled so Netskope can inspect activity inside HTTPS cloud-app traffic.
Why: Without inspection, inline activity and data-movement controls cannot read the activity to act on it.
Why-not-everywhere: Some apps/categories are exempted by policy; confirm the in-scope apps are inspected.
Verify: Confirm an inspection policy covers the target cloud-app categories; client decryption certificate is trusted on endpoints.
Implement: Enable SSL inspection for the in-scope categories and deploy the decryption certificate (via Intune — category prerequisite G3).

## 2.4 Microsoft Entra ID identity for users and groups
Description: Users and groups resolve from Microsoft Entra ID for identity-based policy scoping.
Why: Every control is scoped to identity (the pilot group, then broader groups), not to IP.
Verify: `https://entra.microsoft.com` -> Groups; run `NSCASB-Discovery.ps1` to confirm Graph connectivity and group readiness.
Implement: Ensure Entra ID is the identity source and groups exist (sync Active Directory if hybrid — category prerequisite G5).

## 2.5 API connections to sanctioned apps (for API CASB)
Description: Authorized API connections from Netskope to each sanctioned app you intend to govern at rest.
Why: API CASB governs data already resident in a sanctioned app (exposed shares, risky files) out-of-band.
Verify: In the Netskope tenant, confirm an API connection (instance) exists and is healthy for each sanctioned app.
Implement: Establish the API connection per Netskope's documented connector flow for that specific app; authorize least-privilege access.

## 2.6 A sanctioned-app inventory (the starting register)
Description: A first-draft list of which cloud apps are officially sanctioned vs not.
Why: Discovery refines it, but you need a baseline to make sanctioned/unsanctioned policy decisions against.
Verify: Run `NSCASB-Discovery.ps1` to enumerate Entra enterprise applications as a cloud-app inventory signal; reconcile with Netskope discovery.
Implement: Draft the sanctioned list with the business; record each app's disposition in the app risk register.

## 2.7 A pilot group and a rollback path
Description: An Entra security group of pilot users for staged control rollout, plus a documented rollback.
Why: Every control change is piloted and must be reversible (inline enforcement affects live traffic).
Verify: Entra -> Groups; confirm the pilot group exists (build it with `NSCASB-Set-ScopeTargeting.ps1`).
Implement: Create the pilot group; write the rollback (scope-out / set control to monitor-only / disable policy) — category prerequisites G6 and G7.

---
## Checklist
- [ ] Netskope tenant with CASB module licensed
- [ ] Traffic steering / SWG in place — `NSCASB-Validation.ps1`
- [ ] SSL/TLS inspection enabled for in-scope apps
- [ ] Entra ID identity + groups — `NSCASB-Discovery.ps1`
- [ ] API connections to sanctioned apps (for API CASB)
- [ ] Sanctioned-app inventory drafted into the app risk register
- [ ] Pilot group created and rollback documented — `NSCASB-Set-ScopeTargeting.ps1`
