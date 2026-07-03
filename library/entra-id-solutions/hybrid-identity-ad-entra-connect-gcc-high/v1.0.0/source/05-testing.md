# Testing & Validation — Hybrid Identity (Government / GCC High)

Run these tests at the **Validate** gate (after Pilot) and again after any change. Every test names
a **pass/fail** condition and, where the surface differs, the **GCC High `*.us`** portal to check.
Do not expand scope until every applicable case passes.

> Test against the **Gov** surfaces. A "green" result on a Commercial portal proves nothing about
> your GCC High tenant.

## T1. Sync engine targets the US Gov instance
- **How:** Run `HYBIDG-Validation.ps1` (connects with `-Environment USGov`). On the Connect host,
  confirm the sign-in during install routed through `login.microsoftonline.us`.
- **Pass:** Script confirms the Gov tenant/domain; no Commercial endpoint in use.
- **Fail:** Script reports Commercial environment or cannot reach `graph.microsoft.us` → revisit
  cloud selection (Implementation Step 2.3) and the R8 allow-list.

## T2. Pilot users synchronized correctly
- **How:** `https://entra.microsoft.us` → `Users`; filter to the pilot users.
- **Pass:** Pilot users present, **synced from on-premises** (not cloud-only), UPNs use the verified
  public domain.
- **Fail:** Missing users, cloud-only users, or `onmicrosoft.us` fallback UPNs → check OU/group
  filtering and UPN hygiene (R7).

## T3. Sign-in works on the Gov authority
- **How:** Have a pilot user sign in at `https://login.microsoftonline.us` (e.g. to `portal.office365.us`).
- **Pass:** Sign-in succeeds with the AD password (PHS/PTA) or via AD FS (Federation).
- **Fail:** Sign-in fails → for PHS confirm hash sync ran; for PTA confirm the Gov agent is healthy;
  for Federation confirm the STS trust.

## T4. Password writeback / SSPR (if enabled)
- **How:** A pilot user resets their password via `https://aka.ms/sspr` (Gov-context) and confirms
  the new password works **on-premises** at a domain-joined workstation.
- **Pass:** Reset succeeds in cloud and the new password authenticates on-prem (writeback worked).
- **Fail:** Cloud reset works but on-prem still uses the old password → check writeback config and
  service-account permissions. (SSPR with on-prem writeback is available in Azure for US Government.)

## T5. Seamless SSO (if enabled)
- **How:** From a domain-joined, corporate-network device, browse to a Gov app and confirm no
  password prompt.
- **Pass:** User is signed in silently.
- **Fail:** Prompted for credentials → verify the `AZUREADSSOACC` computer object and Kerberos
  configuration; confirm the Gov agent endpoints are reachable.

## T6. Deletion threshold held (no accidental mass-delete)
- **How:** `HYBIDG-Report.ps1` and the Connect sync history.
- **Pass:** No unexpected deletions; the export deletion threshold stopped any large delete.
- **Fail:** Unexpected deletions staged → **do not confirm the export**; investigate scope/filtering
  before allowing the delete.

## T7. Auth-method failover (PTA / Federation only)
- **How:** In a maintenance window, stop one PTA agent (or one AD FS node) and confirm sign-in still
  works via the remaining agent/node.
- **Pass:** Sign-in unaffected with one agent/node down.
- **Fail:** Sign-in breaks → you have no redundancy; add a second Gov auth agent / AD FS node.

## T8. Break-glass accounts still work
- **How:** Sign in with `bg-admin1@<yourtenant>.onmicrosoft.us` at `login.microsoftonline.us`.
- **Pass:** Break-glass sign-in succeeds and is **excluded** from CA/MFA lockout.
- **Fail:** Break-glass blocked → fix exclusions immediately; this is your recovery path.

## T9. Connect Health reporting is live
- **How:** In `https://entra.microsoft.us`, open Connect Health (available in Azure for US
  Government) and confirm the agent reports.
- **Pass:** Sync + agent health visible, no critical alerts.
- **Fail:** No data → confirm the Health agent installed and can reach the Gov endpoints.

## Test summary gate

| Test | Applies to | Must pass before Expand |
| --- | --- | --- |
| T1 Gov instance | All | Yes |
| T2 Pilot sync | All | Yes |
| T3 Sign-in | All | Yes |
| T4 Writeback/SSPR | If enabled | Yes (if enabled) |
| T5 Seamless SSO | If enabled | Yes (if enabled) |
| T6 Deletion threshold | All | Yes |
| T7 Failover | PTA / Federation | Yes (those methods) |
| T8 Break-glass | All | Yes |
| T9 Connect Health | All | Recommended |

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
