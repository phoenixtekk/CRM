# Troubleshooting

Common failure modes when standing up and running the Google Workspace day-2 operations practice, and
how to resolve them. Symptoms are grouped by area. Admin console paths reflect Google's public
documentation at authoring time — where a label or capability may differ by edition or rollout, the
guidance says **verify in your tenant.**

---

## Authentication and API access (the Python tools)

**Symptom: `403` / `insufficientPermissions` or `access_denied` from any tool.**
- The credential lacks the required **read-only scope**, or the scope was not authorized for the
  service account under domain-wide delegation.
- Fix: in **Admin console → Security → API controls → Domain-wide delegation**, confirm the client ID
  is listed with **exactly** the read-only scopes each tool names in its header (Directory readonly,
  Reports audit readonly, etc.). Re-authorize if a scope is missing. For OAuth-user credentials,
  re-consent with the required scopes.

**Symptom: `403 admin.googleapis.com ... has not been used in project ... or it is disabled`.**
- The **Admin SDK API** (and/or the Reports API) is not enabled in the Cloud project backing the
  credential.
- Fix: enable the **Admin SDK API** in the associated Google Cloud project (R4), wait a few minutes,
  and retry.

**Symptom: a tool prints `no live credential ... rendering SAMPLE/offline`.**
- No Application Default Credentials are available, or the client libraries are not installed.
- Fix: `pip install google-api-python-client google-auth` and provide a credential (ADC via
  `gcloud auth application-default login`, or a service-account credential path via the standard
  `GOOGLE_APPLICATION_CREDENTIALS` environment variable). The sample/offline output is for inspection
  only — it is clearly labelled and must not be treated as real tenant data.

**Symptom: Reports API returns empty results for a window you know had activity.**
- Reports data has an **ingestion delay** (events can take time to appear) and a per-service
  **retention window**; a query outside retention returns nothing.
- Fix: widen `--days`, allow for ingestion latency, and confirm the event's service retention window
  for your edition (**verify in your tenant**). For long-term needs, export logs (e.g. BigQuery).

---

## OU tree and settings

**Symptom: a setting you changed on a child OU did not take effect / reverted.**
- The child OU is set to **Inherit** from its parent, so parent values win, or another admin changed
  it back under a different session.
- Fix: in the service's settings, confirm the child OU shows **Override** (not Inherit) for that
  setting. Re-run `config_drift_detector.py` for that OU to confirm.

**Symptom: a policy is not applying to the users you expect.**
- Users may not be in the OU you think, or the policy is targeted by a **configuration group** rather
  than the OU (or vice versa).
- Fix: run `ou_policy_assessment.py` and check `users_per_ou`; confirm each user's actual `orgUnitPath`
  in **Directory → Users**. If the policy is group-targeted, confirm the group membership — and
  **verify group-based policy targeting is available for that service in your tenant.**

**Symptom: `config_drift_detector.py` reports `VERIFY: <setting> ... actual=verify-in-console`.**
- That setting has no wired read API in the reference tool for your edition; the tool refuses to guess
  a value.
- Fix: check the setting manually in the console, or extend `read_live_settings()` with the concrete
  Admin SDK call your edition supports (verify the endpoint/scope names). This is expected behavior,
  not an error.

**Symptom: drift is reported but the live value is actually the intended one.**
- The **baseline** is stale, not the tenant.
- Fix: update `ou-policy-baseline.json` under change control to the correct intended value, then
  re-run. Never edit the baseline silently — it is the governed source of truth (treat as code).

---

## Admin roles and delegation

**Symptom: `admin_role_auditor.py` exits `4` (super-admin count exceeds threshold).**
- More accounts hold super-admin than the break-glass minimum.
- Fix: in **Account → Admin roles → Super Admin**, review each assignment; move routine operators to
  scoped custom roles and keep only break-glass accounts as super-admin. Re-run the auditor.

**Symptom: a delegated help-desk admin cannot perform an in-scope action.**
- The custom role is missing the specific privilege, or its **OU scope** does not include the target
  user.
- Fix: in **Account → Admin roles**, add the missing privilege to the custom role and confirm the OU
  scope covers the target population. Note that some privileges are **not OU-scopable** — **verify in
  your tenant** which privileges support OU scoping.

**Symptom: an out-of-scope action unexpectedly succeeded during testing (T4).**
- The role grants more than intended, or the operator also holds a broader role/super-admin.
- Fix: run the auditor CSV, find every role the operator holds, and remove the excess.

---

## Monitoring and alerts

**Symptom: a configured alert did not fire on its test event (T5).**
- The alert type may not be enabled for your edition, the rule condition/threshold was not met, or the
  event has not yet ingested.
- Fix: in **Security → Alert center → Settings**, confirm the alert is enabled and its recipients are
  correct; allow for ingestion latency; **verify the alert type is available for your edition.** Some
  alerts cannot be safely simulated — validate against a real prior event in the logs instead.

**Symptom: alert notifications are not reaching the security-ops team.**
- Recipients are set to an individual on PTO, or a group address that is not receiving external/system
  mail.
- Fix: set recipients to the security-ops **group** and confirm the group can receive the
  notifications; send a test.

---

## Runbooks and lifecycle helper

**Symptom: `ops_config_helper.py --apply` prints that live writes are "not wired".**
- By design, the reference helper does not perform live writes, to prevent accidental changes.
- Fix: implement each step against the Admin SDK for your environment, **keeping the `--apply` +
  typed-confirmation gate**. Until then, run in dry-run and perform the documented console steps
  manually.

**Symptom: offboarding left data inaccessible.**
- Drive/data ownership transfer was skipped or the account was deleted before transfer.
- Fix: follow `Runbook – User Offboarding – Production` in order — **transfer ownership (Data Transfer)
  before** suspending/deleting; if under legal hold, retain rather than delete. Dry-run first to see
  the full ordered checklist.

---

## Compliance boundary reminder

If a question is whether a control **satisfies** CMMC/NIST 800-171/ITAR/DFARS or an assessor's
determination — that is **out of scope for troubleshooting here.** The operations practice supplies
the technical configuration, monitoring, and evidence; the determination belongs to your compliance,
legal, and assessment (C3PAO) partners.
