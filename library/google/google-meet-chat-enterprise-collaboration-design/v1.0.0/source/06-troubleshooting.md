# Troubleshooting

Common failure modes when configuring and validating Google Meet and Chat governance, and how to
resolve them. Reference artifacts (e.g. `Meet Safety Policy – Pilot OU – Configure`) are reused by name.

---

## Configuration & scoping

### A setting change doesn't take effect for a user
- **Symptom:** A pilot user still sees old Meet/Chat behavior after you changed a policy.
- **Cause:** OU/group setting propagation lag; the user isn't in the expected OU/group; or the OU still
  shows **"Inherited"** rather than the override.
- **Resolution:** Confirm the user's OU under **Directory → Users**; confirm the OU shows the explicit
  value (not "Inherited") in the Meet/Chat settings page; allow propagation time (settings can take up
  to ~24h to fully apply — *verify current behavior for your tenant*), then re-test.

### A control isn't available to set
- **Symptom:** The toggle named in the guide is absent, greyed out, or worded differently.
- **Cause:** The control is edition-gated or the Admin-console UI wording/placement changed since
  authoring.
- **Resolution:** Confirm the edition includes the control (Requirement #1); search the current Admin
  console (labels drift — *verify in your tenant*). If the edition lacks it, scope the design to what
  the edition supports and flag the gap; do not assume an equivalent exists.

### Configuration-group targeting doesn't override the OU
- **Symptom:** A `External Collaboration – Partners` group member still gets the restrictive OU policy.
- **Cause:** Chat configuration-group targeting precedence, or the setting is OU-only (not group-
  targetable).
- **Resolution:** Confirm the setting supports group targeting; verify group membership; check the
  documented precedence for OU vs. group for that specific setting and adjust the scope accordingly.

## Recording & storage

### Recordings land in My Drive instead of the Shared Drive
- **Symptom:** A recorded pilot meeting's file is in the organizer's My Drive, not `Recording Storage –
  Meet Recordings Shared Drive – Configure`.
- **Cause:** The console does not expose a storage-location control in your edition, or the organizer
  didn't record into the Shared Drive context.
- **Resolution:** Where a storage-location control exists, set it; otherwise enforce operationally
  (organizers record from the governed context) and validate location in Test 3. Move stray artifacts
  into the Shared Drive and apply its retention.

### A user who shouldn't be able to record can record
- **Cause:** Recording is enabled at an OU broader than the `Meet Recorders – Approved` scope.
- **Resolution:** Narrow recording enablement to the approved group/OU; re-run Test 3.

## External access & retention

### External chat works to a non-allowlisted domain
- **Symptom:** Test 4 fails — external chat reaches a domain not in `Chat External Policy – Allowlisted
  Domains – Enforce`.
- **Cause:** External chat set to open (not allowlist-only) for the scope, or the allowlist wasn't
  applied to that OU/group.
- **Resolution:** Set external chat to allowlist-only for the scope, confirm the domain list, re-run the
  validator; do not expand until it passes.

### Vault retention rule isn't retaining / discovering messages
- **Symptom:** A message that should be retained isn't discoverable in Vault.
- **Cause:** Retention rule missing, mis-scoped, Chat history off where retention expects it, or edition
  lacks Vault.
- **Resolution:** Confirm `Vault Retention – Chat 3yr – Enforce` exists and is scoped to the OU; confirm
  Chat history is on where the record must be kept; confirm Vault is licensed. **Note:** applied
  retention can be irreversible — always pilot retention on a non-production OU first.

### Rolling back external/history/retention has side effects
- **Cause:** Some governance changes (especially applied Vault retention) are not cleanly reversible.
- **Resolution:** Use the captured `Meet+Chat Baseline – Enterprise – Assess` values to restore
  reversible settings; for retention, disabling the rule stops future retention but may not undo what
  was already retained — treat retention changes as forward-only and gate them tightly.

## Automation / API

### `403 insufficient permissions` / scope errors from a tool
- **Cause:** The OAuth client or service account lacks the read-only Directory/Reports scopes, or
  domain-wide delegation isn't authorized for the impersonated admin.
- **Resolution:** Authorize the exact scopes the tool declares in **Security → API controls → Domain-
  wide delegation**; pass the correct `--subject`; re-run. Grant a write scope only to the config helper
  and only under change control.

### `429` / rate-limit / quota errors on large tenants
- **Symptom:** Assessment or usage report fails part-way with quota/`429` errors.
- **Cause:** Admin SDK / Reports API per-minute quota exceeded when enumerating many OUs/groups/days.
- **Resolution:** Re-run (the tools page through results and skip not-yet-available report dates);
  reduce `--days`; run during off-peak; if persistent, request a quota increase for the project in the
  Google Cloud console. The tools are read-only, so re-running is safe.

### Usage report shows empty or missing parameters
- **Cause:** Reports data lags ~2–3 days, or the parameter isn't emitted by your edition/version.
- **Resolution:** Widen the look-back window past the lag; treat parameters the tool flags as "verify
  for your version" as edition-dependent, not errors. Never infer a value the API didn't return.

### Health check reports drift after a clean rollout
- **Symptom:** `meet_chat_policy_health_check.py` later flags a HIGH finding on a scope that previously
  passed.
- **Cause:** Real drift — a setting was changed out-of-band, an OU reverted to inherited defaults, or a
  new unapproved app was installed.
- **Resolution:** This is the tool working as intended. Investigate the specific finding, restore the
  designed value, and re-run the validator + health check. Schedule the health check to catch drift
  between formal reviews.
