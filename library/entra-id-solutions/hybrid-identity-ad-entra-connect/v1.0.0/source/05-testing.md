# 5. Testing Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Run after the pilot goes live (Implementation Step 11) and after each change to scope, auth method,
or hybrid join.

## Test 1 — Sync engine healthy and running
Do: On the host run `Get-ADSyncScheduler` and `HYBID-Validation.ps1`.
Expected: `SyncCycleEnabled : True`, the server is not in staging mode, and a delta cycle completes.

## Test 2 — Pilot objects synchronized
Do: In `https://entra.microsoft.com -> Identity -> Users`, search for a pilot user; run `HYBID-Report.ps1`.
Expected: Pilot users from `Hybrid Pilot Sync Scope - Pilot - Pilot` appear in Entra ID with the correct UPN.

## Test 3 — No sync errors / no duplicates
Do: Run `HYBID-Report.ps1` (and `HYBID-Validation.ps1`).
Expected: Zero unresolved sync errors; no duplicate-attribute (UPN/proxyAddress) errors.

## Test 4 — Authentication method works
Do: Sign a pilot user in at `https://myapps.microsoft.com` (incognito), then on a domain-joined corporate device.
Expected: Sign-in succeeds; for PHS the cloud validates; for PTA an agent shows the auth in `Hybrid management`; Seamless SSO does not re-prompt on the corporate network.

## Test 5 — Password writeback (if enabled)
Do: Have a pilot user reset their password via self-service password reset; then sign in on-premises.
Expected: The new password works against AD — writeback succeeded.

## Test 6 — Hybrid Entra join
Do: On a pilot device run `dsregcmd /status`.
Expected: `AzureAdJoined : YES` and `DomainJoined : YES`; the device appears in `Identity -> Devices`.

## Test 7 — Staging-mode failover rehearsal (optional)
Do: If a second Connect server exists in staging mode, run `HYBID-Report.ps1` against it.
Expected: It imports and previews the same objects without exporting — ready to promote on failover.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-4 pass; zero unresolved sync errors; a pilot user signs in cloud and on a hybrid-joined device |
| Expand pass | Tests 1-3, 6 pass across the production scope before declaring complete |
