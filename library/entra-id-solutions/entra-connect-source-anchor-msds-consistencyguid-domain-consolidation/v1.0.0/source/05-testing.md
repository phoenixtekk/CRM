# 5. Testing Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Run these after the wizard change (Implementation Step 6) and after the pilot migration (Step 8). Each
test states what to Do and the Expected result. The decisive test is Test 5.

## Test 1 — Precondition was clean before the change
Do: Review the `SRCANCHOR-Test-Preconditions.ps1` output captured at Gate A for each in-scope OU.
Expected: Zero in-scope objects had mS-DS-ConsistencyGuid populated before the switch (the wizard could seed every object).

## Test 2 — Connector-account permission is in place
Do: Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"`.
Expected: Every in-scope OU reports PASS for Write mS-DS-ConsistencyGuid.

## Test 3 — Source anchor is now mS-DS-ConsistencyGuid
Do: On the Connect server run `SRCANCHOR-Validate.ps1` (reads the anchor from `Get-ADSyncGlobalSettings`).
Expected: The current source anchor reads `mS-DS-ConsistencyGuid` (no longer `objectGUID`).

## Test 4 — Anchor value did NOT change (seamless for existing users)
Do: Run `SRCANCHOR-Validate.ps1` and review the per-object check.
Expected: Sampled in-scope objects have mS-DS-ConsistencyGuid populated, and each object's mS-DS-ConsistencyGuid (Base64) equals its prior immutableId (objectGUID Base64) — the anchor value is unchanged, so no re-sync and no duplicates.

## Test 5 — Migrated pilot user hard-matches (the decisive test)
Do: Migrate one `PILOT – Source Anchor – Validation Users` object into the target domain via Quest ODM **with mS-DS-ConsistencyGuid stamped on the target**, let a delta sync run, then find the user in `https://entra.microsoft.com -> Identity -> Users` (Gov: `https://entra.microsoft.us`).
Expected: The **same** Entra user object is updated in place (hard-matched) — **not** duplicated — and retains its mailbox, licenses, and sign-in.

## Test 6 — No duplicates or orphans across scope
Do: Run `SRCANCHOR-Report.ps1`.
Expected: In-scope object count matches the count with mS-DS-ConsistencyGuid populated; the duplicate-risk check is clean; no unresolved ADSync run errors.

## Test 7 — Sign-in still works (and AD FS, if used)
Do: Sign a migrated pilot user in at `https://myapps.microsoft.com` (incognito). If sign-in uses AD FS, also confirm federated sign-in succeeds after the wizard updated the claim rules.
Expected: Sign-in succeeds; for AD FS environments the issuance/claim rule update completed (TCP 80/443/5985 to the primary AD FS server were open).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Configure pass (Gate B) | Tests 3-4 pass: anchor is mS-DS-ConsistencyGuid and the seeded value equals the prior immutableId |
| Pilot pass (Gate C) | Test 5 passes: a Quest-migrated pilot user hard-matches — one object, no duplicate, licenses/mailbox intact |
| Validate pass (Gate D) | Tests 1-7 pass: clean precondition, permission PASS, anchor migrated, no duplicates/orphans, sign-in working |
