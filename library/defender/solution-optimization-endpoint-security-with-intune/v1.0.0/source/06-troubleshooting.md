# 6. Troubleshooting Guide — Solution Optimization: Endpoint Security with Microsoft Intune

Common field issues, in **symptom → cause → fix** form. Run `SOPEIS-Discovery.ps1` and `SOPEIS-ConflictReport.ps1` first — most causes surface there.

## No baseline / report empty
**Symptom:** `SOPEIS-Report.ps1` returns no metrics, or there is no "before" to compare against.
**Cause:** The baseline was never saved, or the account lacks read access to policies/compliance/managed devices.
**Fix:** Run `SOPEIS-Report.ps1 -SaveBaseline` **before** making changes (Implementation Step 1); confirm the account has **Intune Read Only Operator** / **Security Reader** and the Graph scopes (`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, `Group.Read.All`). Re-run.

## Baseline migration not applying
**Symptom:** Pilot devices stay on the old baseline version after Implementation Step 2.
**Cause:** The new-version baseline is unassigned or targets the wrong group, the old baseline **still targets** the ring (overlap), or the device hasn't checked in.
**Fix:** Confirm `Security Baseline – Pilot Ring – Pilot` is on the latest version and assigned to `Intune Optimize – Pilot Ring – Pilot`; **remove the pilot ring from the old baseline's assignment**; force a sync and allow the check-in cadence. Re-run `SOPEIS-Validate.ps1`.

## Conflict persists after consolidation
**Symptom:** `SOPEIS-ConflictReport.ps1` still shows a setting in Conflict after you consolidated.
**Cause:** More than one policy still sets that setting (a legacy device-configuration profile, a second endpoint-security policy, or the old baseline), or an added assignment re-introduced overlap.
**Fix:** Use the report to find **every** policy contributing the setting; remove the setting (or the assignment) from all but the authoritative `Endpoint Security – <area> – Prod` policy. Re-check after devices sync. Avoid double-targeting when expanding coverage (Test 7).

## Compliance tuned too loose/tight
**Symptom:** After tuning, either benign devices are still flagged non-compliant, or a genuinely non-compliant device now passes.
**Cause:** A threshold is still mis-set (too strict → false positives; too lax → real gap passes).
**Fix:** Re-open `Compliance – Windows Corporate – Prod`; align the thresholds so real gaps (encryption off, Defender unhealthy) fail and benign variance passes; keep a grace period on the action. Re-run `SOPEIS-Report.ps1 -BaselinePath .\sopeis-baseline.json`. *Thresholds are the security team's decision.*

## Unexpected Conditional Access blocks
**Symptom:** Users are (or would be) blocked after a compliance change.
**Cause:** A Conditional Access **Require compliant device** grant is enforcing against devices the tuned compliance policy now marks non-compliant.
**Fix:** Keep `CA – Require Compliant Device – ReportOnly` in **Report-only**; use the **What-If** tool to model impact; re-tune compliance so legitimate devices pass; move to enforce **last** and in stages. *The enforce decision is the identity team's.*

## Coverage gap / double assignment
**Symptom:** Some devices receive no policy, or a device is now targeted by two policies.
**Cause:** Unassigned policies, an empty dynamic-group rule, an over-broad exclusion, or an added assignment that overlaps an existing one.
**Fix:** Fix the assignment model to a consistent group set; correct dynamic-group rules and exclusions; preview assignment changes with `SOPEIS-Set-Assignment.ps1 -WhatIf` before applying; verify no double-targeting with `SOPEIS-ConflictReport.ps1`. Re-run `SOPEIS-Validate.ps1`.

## Policy stuck pending / not applying
**Symptom:** A pilot device shows the policy as **Pending** or **Not applicable** and never applies.
**Cause:** The device hasn't checked in, isn't a member of the assigned group, or the policy's OS/platform filter excludes it.
**Fix:** Force an Intune sync on the device; confirm group membership and that the platform/filter matches the device; allow the check-in cadence. Re-check with `SOPEIS-Validate.ps1`.

## Script cannot authenticate or read Intune data
**Symptom:** `SOPEIS-*.ps1` fails on connect or returns nothing.
**Cause:** `Microsoft.Graph.Authentication` is missing, the account isn't signed in, or it lacks the required read scopes/consent.
**Fix:** Let the script install the module (it checks on run); `Connect-MgGraph` with the listed scopes and consent them; confirm at least Intune Read Only Operator / Security Reader. Re-run the script.
