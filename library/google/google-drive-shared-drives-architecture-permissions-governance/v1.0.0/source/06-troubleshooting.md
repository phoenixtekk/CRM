# 6. Troubleshooting

Common failure modes when standing up and governing the Drive & Shared Drives architecture, with
resolutions. Ordered roughly by where they surface in Assess → Configure → Pilot → Validate.

---

## API & automation

### `403 insufficientPermissions` / `accessNotConfigured` from a Python tool
- **Cause:** The Admin SDK or Drive API is not enabled in the Cloud project, or the OAuth client /
  delegated service account is not authorized for the scope the tool needs.
- **Resolution:** Enable **Admin SDK API** and **Google Drive API** in the project. In **Admin console
  → Security → API controls → Domain-wide delegation**, authorize the client ID for the exact scopes
  in Requirement 2.6 (read-only for assessment/validation; add the write scopes **only** for
  `--apply`). Confirm the impersonated identity holds the **Drive and Docs** admin privilege (2.1).

### `403 domainAdminAccess` when listing Shared Drive permissions in the governance report
- **Cause:** `useDomainAdminAccess=true` requires the caller to be an administrator with the Drive
  privilege; a non-admin identity cannot enumerate all Shared Drives' permissions.
- **Resolution:** Run the tool as (or impersonating) the 2.1 admin identity. If you only need Drives
  you are a member of, remove admin-access and accept the reduced scope.

### `403 userRateLimitExceeded` / `429` / throttling on large scans
- **Cause:** Drive API per-user/per-project quota exceeded during a wide `files.list` sweep.
- **Resolution:** Lower `--max`, run against a single `--ou` at a time, and re-run during off-peak
  windows. Add exponential-backoff retries if you extend the tools; request a quota increase in the
  Cloud project for genuinely large estates. The assessment is resumable — take the baseline in
  batches.

### Assessment returns very few files or misses external shares
- **Cause:** The impersonated identity cannot see content it is not an admin over, or `allDrives`
  traversal was not used.
- **Resolution:** Confirm the tool is run with the admin identity and that
  `includeItemsFromAllDrives`/`supportsAllDrives` are set (they are in the shipped tools). For a full
  estate view, use a delegated service account impersonating a Drive admin.

## Configuration & sharing

### External sharing still succeeds after tightening the OU sharing setting
- **Cause:** Sharing settings are inherited by OU — the user is in a **different OU** than the one you
  changed, or a **trust rule / target audience** is still permitting the share, or the change has not
  propagated.
- **Resolution:** Verify the user's OU in **Directory → Users**; apply `Sharing Profile – <OU> –
  Restricted` to the correct OU. Check **Trust rules** for an over-permissive `Trust Rule – …`.
  Setting propagation can take time — re-run `external_sharing_policy_validator.py` after propagation;
  it is the authoritative gate.

### Target audiences / trust rules pages are missing
- **Cause:** These controls are **edition-gated** (Enterprise/Education tiers).
- **Resolution:** Confirm the edition in **Billing → Subscriptions** (Requirement 2.4). On lower
  editions, fall back to OU-level sharing settings + manual review driven by
  `drive_sharing_exposure_assessment.py`; flag the gap to the licensing owner.

### DLP rule blocks legitimate work (false positives)
- **Cause:** A `DLP – <Detector> – Block-External` rule's detector is too broad, or was shipped
  straight to **block** without an audit/warn tuning phase.
- **Resolution:** Set the rule action to **audit only** to observe matches, tighten the detector
  (add confidence thresholds / context, narrow the word-list/regex), move to **warn**, then **block**.
  This is the documented DLP rollback (§3.6). Never ship a blocking rule cold.

### DLP does not fire on a synthetic external share (Test 5 fails)
- **Cause:** The rule is scoped to the wrong OU, the trigger doesn't include Drive external sharing, or
  the detector doesn't match the synthetic value.
- **Resolution:** Confirm the rule's **scope** covers the pilot OU and its **trigger** is
  Drive/external sharing; verify the synthetic value matches the detector pattern; check **Security →
  Data protection** logs / the security investigation tool for a near-miss.

## Ownership, membership & provisioning

### Orphaned-owner files remain after relocating content (Test 7 fails)
- **Cause:** Files were **copied** into a Shared Drive rather than **moved/owner-transferred**, so the
  originals still exist owned by the departed user.
- **Resolution:** Move (transfer ownership) the originals into the Shared Drive, or use Drive's
  transfer-ownership flow; then trash the personal-drive copies. Re-run the assessment to confirm the
  orphaned-owner count is 0.

### Provisioner refuses a member (`must be a GROUP email`)
- **Cause:** The catalog lists an individual **user** as a member; the design mandates group-based
  membership.
- **Resolution:** Create/choose the appropriate Google Group (2.2), add the user to that group, and
  put the **group** in the catalog. This is intentional — it keeps access auditable and directory-driven.

### Provisioner creates a duplicate Shared Drive
- **Cause:** `drives().create` is not idempotent across sessions — re-running `--apply` on a row whose
  Drive already exists makes a second Drive of the same name.
- **Resolution:** Use `drive_governance_config_helper.py` (which refuses duplicate names in the
  catalog) and run the provisioner's **dry-run** first; if a duplicate was created, empty and delete it
  through **Manage Shared Drives** (rollback §3.6). Track created drive IDs in the catalog.

### "Anyone with the link" still appears in the validator after cleanup
- **Cause:** Existing files carry an `anyone` permission from before the policy change — settings
  govern **new** shares, not retroactively strip old ones.
- **Resolution:** Use the assessment output to target the offending files and remove the `anyone`
  permission (an `--apply` remediation, or manual for a small set); re-run
  `external_sharing_policy_validator.py` until it exits 0.

## Gates & rollback

### A pilot gate (G2) fails
- **Cause:** A legitimate workflow broke or an un-scoped external leak remains.
- **Resolution:** Execute the documented **rollback** (§3.6) — restore the recorded G0 sharing
  settings, disable the offending trust rule/audience, set the DLP rule to audit-only — then re-enter
  Design with the lesson recorded. Do **not** expand past a failing gate.
