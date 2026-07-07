# Requirements

These are the **solution-specific** prerequisites for deploying and rolling out Gemini Enterprise.
They build **on top of** the shared Google-category requirements in
`global-requirements-google.md` — that file already covers the Workspace/Cloud Identity tenant and
super-admin, the identity source of truth and provisioning, DNS control, a pilot OU/group and change
control, and the security/compliance stakeholders. Verify the shared six first; then verify each of
the following before starting the implementation steps.

> Where a capability below is version- or preview-dependent (a Gemini feature, an Admin-console
> control path, or a Reports API metric), **verify it live in your tenant** — do not assume the label
> or availability from this document.

## 1. Gemini / AI licensing owned by the tenant

- **Description:** The tenant holds the Gemini Enterprise / AI add-on entitlement (as a Workspace
  add-on SKU or the applicable Gemini edition) with enough **available seats** for the planned waves.
- **Why required:** Feature enablement at the OU level does not grant a per-user paid capability;
  **license assignment** is what consumes a seat and unlocks the user experience. Rollout waves are
  bounded by available seats.
- **How to verify:** In **admin.google.com → Billing → Subscriptions**, confirm the Gemini/AI
  subscription is present and note **licenses assigned vs. total**. Cross-check with the assessment
  script (`gemini_license_readiness.py`). Exact SKU name/edition is entitlement-dependent — **verify
  in your tenant**.
- **How to implement if missing:** Procure/adjust the subscription through Google or an authorized
  reseller before rollout; do not start a wave you cannot license end to end.

## 2. Governance guardrails already in place (the separate governance solution)

- **Description:** The Gemini **security/data guardrails** — DLP posture, data-region/residency
  settings, model-usage/admin-security policy, and any regulated-workload controls — are configured
  and validated by the separate **Gemini Enterprise Secure Adoption & Governance** solution.
- **Why required:** This deployment turns features **on**; it must never do so ahead of the guardrails
  that make them safe. Every rollout gate re-validates that guardrails are respected.
- **How to verify:** Confirm with the governance owner that the guardrail baseline is live for the
  scopes you will enable; run `gemini_guardrail_precheck.py` (read-only) against the target OUs.
- **How to implement if missing:** Complete/deploy the governance solution for the target scopes
  **before** enabling Gemini features there. Do not proceed on an ungoverned scope.

## 3. Super-admin (or delegated admin) with the right privileges

- **Description:** An administrator with the Google Admin **privileges** to manage the Gemini/AI
  service, assign licenses, and manage the target OUs/groups — ideally a **delegated admin role**
  scoped to those tasks rather than a full super-admin for day-to-day rollout work.
- **Why required:** License assignment and per-OU service configuration require these privileges;
  least-privilege delegation reduces blast radius during a large rollout.
- **How to verify:** In **Admin console → Account → Admin roles**, confirm the operator's role grants
  license management and service (Gemini) settings for the target org tree.
- **How to implement if missing:** Create a delegated admin role with the minimum privileges for
  licensing + Gemini service management and assign it to the rollout operators.

## 4. A rollout-ready OU / group structure

- **Description:** An OU tree and/or Google Groups that cleanly express the **rollout waves** —
  a pilot cohort plus the ordered production waves — so features and licenses can be scoped per wave
  without catching unintended users.
- **Why required:** Gemini service settings and license assignment are applied by OU/group; clean
  scoping is what makes the rollout phased and reversible.
- **How to verify:** Confirm the pilot OU/group from the shared requirements exists, and that
  additional wave groups exist or can be created; run `gemini_rollout_wave_planner.py --dry-run` to
  map users to waves against the structure.
- **How to implement if missing:** Create the wave OUs/groups (`Rollout Cohort – Pilot – Wave 0`,
  `Rollout Cohort – Wave 1`, …) and confirm membership is driven from the identity source of truth.

## 5. Admin SDK access for measurement (Reports API)

- **Description:** The **Admin SDK** with the **Reports API** enabled and an authorized principal
  (delegated admin credentials via Application Default Credentials, or a properly authorized
  service account with domain-wide delegation) able to read usage/activity reports **read-only**.
- **Why required:** Adoption measurement and license/usage reporting are driven from the Reports API;
  without it there is no baseline and no per-wave trend.
- **How to verify:** Confirm the Admin SDK is enabled for the project and that the reporting principal
  can call the Reports API; run `gemini_adoption_report.py --dry-run`. The **exact Gemini usage
  metrics/parameters exposed** by the Reports API are version-dependent — **verify in your tenant**
  which activity events and usage counters are available.
- **How to implement if missing:** Enable the Admin SDK API, grant the reporting principal the
  read-only reports scope, and (if using a service account) authorize domain-wide delegation for the
  reports read scope only.

## 6. A readiness/training package and adoption target

- **Description:** A per-wave **enablement/training package** (quick-start guidance, example prompts,
  Gems/NotebookLM usage where available, and role-specific use cases) and an agreed **adoption target**
  (the pass threshold for a wave's validation gate).
- **Why required:** Turning a feature on without readiness produces licenses that are assigned but
  unused; the adoption target is the objective pass/fail criterion for expanding.
- **How to verify:** Confirm the training package exists for the pilot and an adoption threshold is
  agreed with the sponsor (e.g. a target active-user percentage within the wave window).
- **How to implement if missing:** Build the readiness package for the pilot and agree the adoption
  target with the sponsor before enabling the pilot cohort.
