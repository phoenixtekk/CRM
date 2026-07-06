# Troubleshooting

Common failure modes when standing up Apps Script and AppSheet governance, and how to resolve them.
Each entry gives the **symptom**, the **likely cause**, and the **fix**. When a change involves
org-wide settings, apply the fix under change control and test on the pilot OU first.

---

## Settings changed but nothing seems different

- **Symptom:** You changed app access control or an AppSheet setting, but behavior hasn't changed.
- **Likely cause:** Propagation delay. Admin console changes can take **up to 24 hours** to fully
  apply (usually faster).
- **Fix:** Wait and re-test; confirm you saved at the correct **OU/group scope** (a setting applied at
  a parent OU may be overridden by a child OU). Re-run `GWAUTO-Validation.ps1` after propagation.

## Builders suddenly can't run apps they relied on

- **Symptom:** After tightening app access control, users are blocked from an Apps Script add-on or
  third-party app they need.
- **Likely cause:** The app was **unconfigured** and your unconfigured-apps posture now blocks it, or
  internal-app trust is off and the app needs a restricted service.
- **Fix:** Explicitly **trust** the specific, reviewed app in **Security → Access and data control →
  API controls → App access control** rather than loosening the whole posture. For your own reviewed
  Apps Script projects, add them to trusted (or check *Trust internal apps* if appropriate). This is
  why the design pilots on a scoped OU first.

## Apps Script authorization / scope errors after restriction

- **Symptom:** A script throws an authorization error, or a user can't grant a scope it needs.
- **Likely cause:** **High-risk OAuth scope restriction** (Gmail/Drive) is blocking a high-risk scope
  for an untrusted app.
- **Fix:** Decide deliberately — either **narrow the script's scope** to a non-high-risk scope
  (preferred; e.g. `drive.file` instead of full Drive), or **trust** the app after review so it may
  request the high-risk scope. Don't disable the restriction org-wide to fix one script.

## AppSheet policy isn't enforcing

- **Symptom:** You wrote an AppSheet governance policy but apps still violate it.
- **Likely cause:** (1) The policy is at **Warning** stage (surfaces, doesn't block) rather than
  **Error**; (2) it's applied at the wrong **level** (org vs team vs individual); or (3) you're on
  **AppSheet Core**, which does not support per-condition governance policies at all.
- **Fix:** Raise the policy to **Error** at the correct **stage** (edit/deploy/always) and **level**
  (remember org and team combine to the **most restrictive**). If you're on Core, use the **AppSheet
  Core security setting** (all-or-nothing) instead, and scope Enterprise Plus to the teams that need
  policies.

## Core security setting is too blunt

- **Symptom:** Turning on the AppSheet Core security setting blocked a legitimate external data
  source or webhook a team needs.
- **Likely cause:** The Core setting is **all-or-nothing** — it disables external sharing, external
  sources, external automation email, external API, and webhooks together.
- **Fix:** If you need to permit one of these for a specific team, you need **Enterprise Plus**
  governance policies (granular) for that team rather than the blunt Core toggle; otherwise the
  capability stays off for everyone.

## "Anyone can mark apps deployed" — review model not enforced

- **Symptom:** Builders self-deploy Tier 1/2 automations without review.
- **Likely cause:** The **deploy-control** policy (*only certain people can mark apps as deployed*)
  isn't configured, or you're on Core (no policy support).
- **Fix:** On Enterprise Plus, add the deploy-control policy and name the reviewers. For Apps Script,
  enforce review through the deployment/trust step and the review checklist before an add-on is
  trusted org-wide.

## Discovery/Validation returns nothing or errors

- **Symptom:** `GWAUTO-Discovery.ps1` or `GWAUTO-Validation.ps1` returns empty or errors on auth.
- **Likely cause:** Missing admin privileges/scopes for the tooling, wrong target OU/group, or the
  Workspace API/AppSheet Admin data not accessible to the running account.
- **Fix:** Run as an account with the required admin privileges; confirm the target scope with
  `GWAUTO-Set-ScopeTargeting.ps1 -WhatIf`; verify API access. See each script's `.DESCRIPTION` header
  for required scopes/tools.

## Data-residency requirement not met

- **Symptom:** AppSheet data is stored/processed outside the required region.
- **Likely cause:** The AppSheet **app creation region** wasn't set (Enterprise Plus feature).
- **Fix:** Set the required **data region** in AppSheet (Enterprise Plus). Note existing apps may
  need to be recreated in-region — confirm current behavior in AppSheet's data-residency docs for
  your tenant.

## Remediation would change more than expected

- **Symptom:** `GWAUTO-Remediation.ps1 -WhatIf` previews changes you didn't intend.
- **Likely cause:** Broad targeting, or flagged items that need a human decision (external sharing,
  broad scopes) rather than an automated fix.
- **Fix:** Narrow the scope with `GWAUTO-Set-ScopeTargeting.ps1`, review the `-WhatIf` output line by
  line, and only run without `-WhatIf` for the specific, reviewed items. The default `-WhatIf` exists
  precisely so nothing changes until you've confirmed the plan.

---

*If a fix requires an org-wide setting change, stage it under change control and validate on the
pilot OU before expanding — the same discipline the Implementation guide uses.*
