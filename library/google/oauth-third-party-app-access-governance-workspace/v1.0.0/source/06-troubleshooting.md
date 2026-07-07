# Troubleshooting

Common failure modes and resolutions for OAuth & third-party app-access governance. Artifact names
match the Implementation guide.

---

## Auth & API access

**`--check-auth` fails or the tools get 401/403.**
- Cause: ADC not set, or the authenticated identity lacks the read-only Reports/Directory scopes, or
  the Admin SDK API is not enabled.
- Fix: run `gcloud auth application-default login` as an admin; enable the **Admin SDK API** in the
  automation project; for a service account, authorize **domain-wide delegation** for
  `admin.reports.audit.readonly` and `admin.directory.user.security` (Requirement 2). Re-run
  `python oauth-app-inventory.py --check-auth`.

**`insufficientPermissions` on `tokens.list` / `tokens.delete`.**
- Cause: the delegated identity is not a super-admin equivalent for the Directory `tokens` resource,
  or DWD is scoped to the wrong scopes.
- Fix: confirm the account has the security-management privilege and that DWD lists exactly
  `admin.directory.user.security`. Never add write scopes the tool doesn't need.

**`ImportError: googleapiclient`.**
- Fix: `pip install google-api-python-client google-auth` (Python 3.10+).

## Inventory quality

**Inventory count is lower than the Admin console connected-apps count.**
- Cause: Reports API/token propagation lag, or a user page failed mid-enumeration (the tool warns per
  user on stderr).
- Fix: re-run after the reporting window settles; check stderr WARN lines and confirm no large group
  of users errored. Treat the console count as the source of truth for completeness (Test 1).

**Many apps show risk `UNKNOWN`.**
- Cause: their scopes aren't in the scope-sensitivity reference (or you're on the built-in starter
  hints).
- Fix: run `scope-config-helper.py --scope-ref scope-sensitivity.json --inventory app-inventory.json`
  to list the UNKNOWN scopes, classify them against Google's current OAuth scope documentation
  (*verify for your tenant*), and re-run the inventory with `--scope-ref`. UNKNOWN is deliberately
  **not** downgraded to LOW — triage it.

## Configuration & policy

**A legitimate app broke after applying the classification.**
- Cause: an app that legitimately needs a sensitive scope was set to **Limited/Blocked**, or it isn't
  on `Trusted Apps – Org-Wide – v1` with the correct OAuth client ID.
- Fix: the `api-access-control-helper.py` dry-run flags these as **BREAK-RISK** before apply — heed
  the flag. To recover: set the app to **Trusted** for the affected scope after vetting, or scope the
  change back to `App-Access Pilot – Pilot-OU – v1` while you investigate. **Rollback:** revert the
  per-app access level to its recorded prior value.

**Unverified-app block also blocks an app we actually use.**
- Cause: the app is unconfigured (not on any list) and `Unverified-App Block – Org-Wide – Pilot`
  denies it.
- Fix: vet the app via `App-Vetting Workflow – Org-Wide – v1` and add it to the Trusted (or Limited)
  list; unconfigured apps are *supposed* to be denied — that is Gate B working. Confirm you piloted
  before org-wide expansion.

**Marketplace Gate C fails: `trusted_not_allowlisted` / `only_in_allowlist` non-empty.**
- Cause: the Marketplace allowlist and `Trusted Apps – Org-Wide – v1` have drifted apart.
- Fix: reconcile — add missing Trusted apps to the allowlist and remove allowlist entries that aren't
  Trusted, so `Marketplace Allowlist – Org-Wide – v1` == the Trusted list. Re-run validation.

**Console path for the unconfigured-app / Marketplace setting isn't where the guide says.**
- Cause: Google moves and renames Admin console menus and rolls features out by edition.
- Fix: search the Admin console for "API controls", "app access control", "Marketplace"; confirm the
  setting under **Security → Access and data control → API controls**. Where a control's availability
  is edition/rollout-dependent, verify it exists for your tenant (author's flag, not an error).

## Revocation

**`risky-grant-revoker.py --apply` reports `error:` for some grants.**
- Cause: the (user, app) grant no longer exists (already revoked / user removed), or a transient API
  error.
- Fix: errors are recorded per grant in the evidence log and don't stop the run. Re-run dry-run to
  confirm the remaining set; already-gone grants are safe to ignore.

**Users complain an app stopped working after revocation.**
- Cause: revocation forces re-consent; this is expected for anything revoked.
- Fix: for a *legitimately needed* app, confirm it's Trusted/allowlisted and have the user
  re-authorize. This is why revocation is `--apply`-gated, approver-signed, and communicated. There is
  no "un-revoke" — only re-consent.

**Validation exits non-zero in a change-control pipeline.**
- Cause: `app-access-validation.py` returns exit code 1 when any gate FAILs (by design).
- Fix: read `validation.json` for the failing gate's offenders, remediate, and re-run until OVERALL
  = PASS before promoting scope from pilot to org-wide.
