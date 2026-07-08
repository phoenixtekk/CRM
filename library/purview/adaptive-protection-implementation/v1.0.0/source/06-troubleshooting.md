# Troubleshooting — Adaptive Protection in Microsoft Purview

Adaptive Protection spans three surfaces — **Insider Risk Management** (the signal), **DLP** and
**Conditional Access** (the controls) — so most problems are really a break in the chain
**activity → IRM score → risk level → DLP/CA action**. Work the chain in that order; the scripts
(`PURVAP-Discovery.ps1`, `PURVAP-Test-Readiness.ps1`) tell you which link is broken. Where a symptom is
licensing- or preview-related, **verify against your licensing/tenant** rather than assuming a bug.

---

## No users are ever assigned a risk level

- **No IRM scoring source.** Adaptive Protection maps **IRM scoring** onto levels — if no insider-risk
  policy is scoring the user, there is no level. Confirm an active IRM policy (`PURVAP-Discovery.ps1`;
  Purview → Insider Risk Management → Policies).
- **Adaptive Protection not active / not set up.** Confirm **Insider Risk Management → Adaptive
  Protection** shows active with **Elevated/Moderate/Minor** defined (Quick or Custom setup).
- **Thresholds too high (Custom setup).** If your Custom mapping requires high-severity alerts, few or
  no users will reach a level. Retune the mapping, or start with **Quick setup**.
- **Propagation delay.** Level assignment follows insider-risk scoring, which is not instantaneous.
  Allow time after the sanctioned test activity before concluding it failed.

## The adaptive-protection risk-level condition is not visible when authoring a DLP rule

- **Licensing.** The condition requires the right licence (E5 / E5 Compliance) and **Adaptive
  Protection enabled**. Confirm in Billing and in the Adaptive Protection setup — **verify in your
  tenant**.
- **Adaptive Protection not yet on.** The condition only appears **after** Adaptive Protection is
  active. Complete Phase 2 first, then allow propagation time.
- **Portal-only surface.** The condition is added in the **portal**; do not expect to set it via
  PowerShell. `PURVAP-Set-DlpPolicy.ps1` scaffolds only the simulation-mode shell and hands the
  condition to the portal by design.

## The wrong DLP action fires for a user's level (e.g. block at Minor)

- **Overlapping rules / precedence.** Ensure each rule keys on **one** level and the three levels are
  mutually exclusive; check DLP rule **priority** so a broad rule isn't shadowing a per-level one.
- **Missing label/classification condition.** If a rule omits the sensitivity-label/SIT condition it
  can match content it shouldn't. Confirm each rule combines **risk level AND label/SIT** (Phase 3).
- **Stale level.** Risk levels are **time-bound** and decay; a user you *expect* to be Elevated may
  have dropped to Moderate/Minor. Confirm the **current** level, not a past one.

## DLP simulation shows no matches

- **Still no risk level (see above).** No level → the risk-level condition never matches.
- **No labeled content in scope.** The rules key on labeled/SIT content; if the test file has no
  label (or the label isn't published/applied), nothing matches. Confirm labels (R5).
- **Workload/device not covered.** Endpoint actions (USB/print/upload) require **device onboarding**;
  Exchange/SharePoint/OneDrive/Teams must be in the policy's locations (R6).
- **Simulation is working as intended.** Simulation reports what **would** happen — it does **not**
  block. Empty results with no risky test activity are expected, not a failure.

## Conditional Access policy is not evaluating (report-only shows nothing)

- **Entra ID P2 / Insider risk condition.** The CA **Insider risk** condition needs **Entra ID P2**.
  Confirm licensing and that the condition is selectable.
- **Scope/user mismatch.** Confirm the test account is in `SG-AP-Pilot` (the policy's scope) and is
  **not** in an exclusion (e.g. the break-glass group).
- **User not Elevated.** `CA-InsiderRisk-Elevated` targets **Elevated**; a Moderate/Minor/normal user
  won't trigger it. Confirm the account's current level.
- **Report-only insights lag.** Report-only results appear in **sign-in logs**; allow time and filter
  by the policy name.

## Risk of locking out administrators (Conditional Access)

- **Break-glass not excluded.** **Always** exclude the break-glass/emergency-access account from any
  blocking CA policy, and verify the exclusion **before** turning the policy from report-only to on
  (R7). If lockout is occurring, set the policy to **report-only/Off** immediately and fix the
  exclusion.

## "It blocked legitimate work after we enforced"

- **Enforced too early / too broadly.** Return the DLP policy to **simulation** (or the CA policy to
  **report-only**) — this stops the impact immediately — then tune conditions and re-pilot on
  `SG-AP-Pilot` before re-enforcing.
- **Action too hard for the level.** Prefer **warn/override** at Moderate so legitimate work has a
  justification path; reserve hard **block** for Elevated. Fix the **response**, or retune the
  **signal** so fewer users reach the hard-block level.

## Permission / role errors running the scripts or authoring

- **IRM/DLP read access.** `PURVAP-Discovery.ps1` / `PURVAP-Test-Readiness.ps1` need read access to
  compliance policies (Connect-IPPSSession). `Get-InsiderRiskPolicy` may be unavailable in some
  tenants/sessions — the scripts fall back to "confirm in portal."
- **Graph scopes.** `PURVAP-Set-Scope.ps1` needs `Group.ReadWrite.All` (and `User.Read.All`,
  `Directory.Read.All`); `PURVAP-Discovery.ps1 -IncludeConditionalAccess` needs `Policy.Read.All`.
  Consent the delegated scopes with an admin.
- **Cross-surface roles.** Authoring spans IRM, DLP (Compliance Administrator), and CA (Conditional
  Access Administrator). A "can't see/author" symptom is usually a **missing role on that specific
  surface** (R2) — not a product fault.

## Reporting rollup doesn't match the portal

- **Portal is authoritative.** `PURVAP-Report.ps1` summarizes the **unified audit log**, which lags and
  may not expose per-risk-level detail. Reconcile against **Activity explorer / DLP alerts** and CA
  **report-only** insights — those are the source of truth.
- **Window/latency.** Widen `-Days`, and allow for audit ingestion latency before concluding records
  are missing.

---

> **When in doubt, walk the chain:** is an IRM policy **scoring** the user? Is Adaptive Protection
> **active** with levels defined? Does the user have a **current** level? Do the DLP rules combine
> **risk level AND label**, and is the policy in the mode you expect? Is CA **Entra ID P2**, scoped,
> and the user **Elevated**? Each script maps to a link in that chain. And remember: a risk level
> tightens **controls**, not judgement — determinations remain with **HR/legal** (see IRM).
