# Troubleshooting

Common failure modes during Gemini Enterprise deployment and rollout, and how to resolve them. Each
maps back to the artifacts and gates in `03-implementation.md` and `05-testing.md`.

> Many symptoms trace to a **feature label, availability, or Reports metric that differs in your
> tenant**. When a step's control does not match, that is a **"verify in your tenant"** finding —
> confirm the live path and record it in `Feature Enablement Matrix – Workforce – v1` before treating
> it as a defect.

---

## Users have a license but see no Gemini experience

- **Likely cause:** the feature is enabled at the OU level but the user's **license is not assigned**,
  or the user is in an OU where the capability was not enabled.
- **Resolve:** run `gemini_license_readiness.py --verify-cohort "<cohort>"` (Gate G2). Reconcile any
  under-assignment against `License Assignment – Gemini – v1`. Confirm the user's OU is in the
  enablement scope in `Feature Enablement Matrix – Workforce – v1`. Note that feature settings and
  license assignment are independent — one being correct does not imply the other.

## Gemini appears for users who should not have it yet (scope bleed)

- **Likely cause:** a capability was enabled on a **parent OU** and inherited by child OUs, or on a
  group broader than the intended cohort.
- **Resolve:** run `gemini_feature_enablement.py --ou "<wave-ou>" --verify-scope` (Gate G1). Re-scope
  the setting to exactly the intended OU/group. If needed, roll the scope back from its snapshot
  (`--revert --from <snapshot>`) and re-apply correctly. Confirm the live config matches the matrix.

## Gate G0 fails — a required guardrail is missing

- **Likely cause:** the scope is **ungoverned** — the separate governance solution's baseline (DLP,
  data-region, model-usage, admin-security) is not deployed for this OU/group.
- **Resolve:** **stop** — do not enable Gemini on this scope. Engage the governance owner to deploy the
  baseline, then re-run `gemini_guardrail_precheck.py --ou "<wave-ou>" --expect guardrail-baseline.json`.
  If the check returns INDETERMINATE, the guardrail state is UNKNOWN, not absent — verify with the
  governance owner and supply a complete expected baseline; never treat UNKNOWN as pass.

## A capability's Admin-console toggle does not match the docs

- **Likely cause:** Gemini feature grouping and labels **evolve**; the capability may be under a
  different service, renamed, or in **preview** for your edition/region.
- **Resolve:** **verify in your tenant** — locate the actual control, record the exact path and whether
  it is GA or preview in the matrix, and only then enable. For NotebookLM Enterprise and other
  preview/edition-gated capabilities, if it is not clearly available **and** governed, mark it
  *Deferred* and do not enable it.

## Adoption gate (G3) fails — usage below target

- **Likely cause:** users are licensed and enabled but not using Gemini — commonly weak readiness/
  training, unclear role-specific value, or **connector gaps** (Gemini can't reach the data users need,
  which is the separate connector solution's domain).
- **Resolve:** do not expand. Investigate: confirm training was delivered for the wave; strengthen
  role-based use cases and starter Gems; capture connector gaps as feedback to the connector solution.
  Re-measure with `gemini_adoption_report.py --cohort "<cohort>" --against adoption-baseline.json
  --gate <target>`. Persistent failure after remediation is a signal to pause the wave, not to lower
  the bar.

## `gemini_adoption_report.py` shows no Gemini usage metrics

- **Likely cause:** the Reports API **parameter names for Gemini usage are version-dependent** and may
  live under app-specific reports rather than customer-level counters; or the reporting principal lacks
  the read scope; or data simply hasn't landed (Reports data typically lags ~2 days).
- **Resolve:** confirm the Admin SDK Reports API is enabled and the principal holds the read-only
  reports scope. Query a date at least 2 days back. **Verify in your tenant** which application/
  parameter carries Gemini activity and pass it via `--active-metric`. The tool reports INDETERMINATE
  rather than inventing a metric — treat that as "identify the real metric", not "pass".

## License assignment "succeeds" but seat count doesn't change

- **Likely cause:** assignment vs. the subscription's total/available seats is read in two different
  places — the Licensing API reports **assignments**, while total/available seats are shown under
  **Billing → Subscriptions** and are not exposed the same way.
- **Resolve:** re-check total/available seats in **Billing → Subscriptions** (verify in your tenant),
  and reconcile assignments with `gemini_license_readiness.py`. If waves are seat-constrained, re-run
  `gemini_rollout_wave_planner.py --license-baseline license-baseline.json` to confirm feasibility
  before assigning more.

## A wave regressed after enablement and must be reversed

- **Likely cause:** a wave introduced a scope, guardrail, or adoption problem that can't be fixed
  in place quickly.
- **Resolve:** use the **per-wave rollback**: `gemini_feature_enablement.py --ou "<wave-ou>" --revert
  --from <wave>-config-snapshot.json` (dry-run, then `--apply`), and unassign that wave's licenses
  explicitly (reverting a feature does not release seats). Prior waves are untouched. Fix the root
  cause, then re-enable the wave through the normal gated loop.

## Automation can't authenticate

- **Likely cause:** no Application Default Credentials present, wrong/missing API scopes, or (for a
  service account) domain-wide delegation not authorized for the required read scope.
- **Resolve:** establish ADC (`gcloud auth application-default login`) or configure an authorized
  service account **from the environment** — never embed a key in code. Grant exactly the read scopes
  the tool needs (licensing/directory read for readiness; reports read for adoption). If a client
  library is not installed, the tools print the equivalent Admin-console steps so the run is still
  actionable; install with `pip install google-api-python-client google-auth` to automate.
