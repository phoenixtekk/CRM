# 6. Troubleshooting — Self-Deploy: Multi-Factor Authentication & Conditional Access

The common failure modes, each as **symptom → cause → fix**. Most kit issues are a missing MFA
registration, a policy not in report-only, a missing break-glass exclusion, or misreading a
report-only result as a real failure — not a broken tenant. Use `EKMFACA-Discovery.ps1` for the
read-only picture and `EKMFACA-Validate.ps1` for the gate checks.

---

## 1. `Connect-MgGraph` fails or a script returns 403

- **Symptom:** A helper cannot connect, or a call is forbidden.
- **Cause:** The Graph SDK is not installed, scopes were not consented, the wrong cloud endpoint was
  used, or the account lacks the role.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and consent the scopes in the
  script header (read-only for discovery/validate/report; `Policy.ReadWrite.ConditionalAccess` for the
  lab-policy builder); for Government cloud pass the matching `-Environment`; confirm the account holds
  the needed role (**R2/R6**). *Verify the correct endpoints for your cloud.*

## 2. The report-only lab policy can't be created (CA blade missing)

- **Symptom:** `EKMFACA-LabPolicy.ps1` fails, or **Conditional Access** is unavailable in the portal.
- **Cause:** The tenant has no **Entra ID P1** (Conditional Access is a P1 feature), or the account
  lacks `Conditional Access Administrator`.
- **Fix:** Confirm P1 (**R1**) and the instructor role (**R2**). If there is no P1, run Labs 2–6 as a
  **read-only tour** of the CA and sign-in-log blades and note the gap; the MFA-methods lab (Lab 1)
  still runs in full. *Verify licensing.*

## 3. A lab policy is not in report-only

- **Symptom:** `EKMFACA-Validate.ps1` flags `CALab00n` as On or Off instead of report-only.
- **Cause:** The state was changed.
- **Fix:** Set **Enable policy = Report-only** immediately. In this kit **no lab policy is ever
  enforced** — report-only is mandatory. If it was briefly On, confirm no user was unexpectedly blocked
  (sign-in logs) and reset to report-only.

## 4. Break-glass is not excluded from a lab policy

- **Symptom:** `EKMFACA-Validate.ps1` flags a lab policy as missing the break-glass exclusion, or
  What-If shows a policy applying to a break-glass account.
- **Cause:** The exclusion group was not added to that policy.
- **Fix:** Add `Grp-MfaCa-Excl-BreakGlass` under **Assignments -> Users -> Exclude** on every lab
  policy (**R4/G4**). Exclude the **group**, not the individual users — a group exclusion is durable.
  This is the core anti-lockout habit the kit teaches.

## 5. What-If shows a policy applying to the wrong persona (or not at all)

- **Symptom:** In Lab 5, What-If doesn't match the design — an internal user doesn't hit `CALab001`, or
  an admin also hits an internals policy.
- **Cause:** The user is in the wrong persona group, the policy's include/exclude scope is off, or a
  condition (device/location/client) filters it out.
- **Fix:** Confirm the test user's persona-group membership; re-check the policy's **Users** include and
  **exclude** and its conditions; re-run What-If until it matches (Lab 5). Remember dynamic-group
  membership can lag.

## 6. A "failure" in the sign-in log is actually a report-only result

- **Symptom:** A learner reports the lab policy "blocked" a user.
- **Cause:** The sign-in shows `reportOnlyFailure` — the policy **would have** required/blocked, but
  because it is report-only it did **not** enforce.
- **Fix:** Teach the distinction (Lab 6): `success`/`failure` are enforced results; `reportOnlySuccess`
  / `reportOnlyFailure` / `reportOnlyNotApplied` are the report-only "would have." A report-only result
  is never an outage. Read the CA tab's per-policy result to confirm.

## 7. MFA prompts constantly / a phishing-resistant policy rejects an admin

- **Symptom:** A test admin under `CALab002` is asked for a method they don't have (in a real enforced
  version), or MFA prompts more than expected.
- **Cause:** The admin has not **registered** a phishing-resistant method (FIDO2/passkey), or sign-in
  frequency/session settings force re-prompts.
- **Fix:** In this kit the policy is report-only so it cannot actually block — but the lesson is real:
  drive **registration** of the required method first (Lab 1; the **Passwordless & Passkey** solution
  deploys it at scale) before any enforced policy requires it. *Verify passkey/method availability.*

## 8. Sign-in logs / the KQL lab return no rows

- **Symptom:** An `EKMFACA-Labs.kql` query returns 0 rows, or Sign-in logs look empty.
- **Cause:** The time window is too tight, the test users haven't signed in, or sign-in logs aren't
  exported to a Log Analytics workspace (the KQL variant).
- **Fix:** Widen the window (`ago(7d)`); have the persona test users sign in once to generate report-only
  results; use the **Entra -> Monitoring -> Sign-in logs** portal view if no workspace export exists.
  *Sign-in-log export/retention depend on P1/P2 — verify.*

## 9. Legacy-authentication confusion

- **Symptom:** `CALab003` (block legacy) shows results for apps you didn't expect, or a learner worries
  it will break mail.
- **Cause:** Legacy/basic-auth clients (older mail clients, `Other clients`) surface in the logs;
  `CALab003` is **report-only** so it only *observes* them here.
- **Fix:** Use Lab 6 / `EKMFACA-Discovery.ps1` to identify legacy-auth users/apps. In this kit you only
  observe — actually blocking legacy auth in production (migrate first, then enforce in waves) is the
  **ENTZTCA** solution, not this one.

## 10. Dynamic persona-group membership didn't update

- **Symptom:** A test user added to a persona doesn't appear to be scoped by the policy yet.
- **Cause:** If the persona group is dynamic, membership is evaluated **asynchronously** and can lag;
  if assigned, the user may not have been added.
- **Fix:** For assigned groups, confirm the membership; for dynamic groups, wait and refresh and confirm
  the rule matches the user's attribute exactly. Re-run What-If (Lab 5) once membership settles.
