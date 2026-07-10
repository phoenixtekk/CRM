# 5. Testing & Validation — Microsoft Fabric & Power BI Governance & Administration

Validate on the pilot ring before you expand tenant-wide. Each test states what to run, what passes, and
what fails. The scripts referenced here are in the `scripts/` folder of this package.

## 5.1 Baseline inventory captured (Assess gate)
- Run: `FABGOV-Discovery.ps1`.
- Pass: the script returns the current tenant settings of interest, at least the capacity
  `Fabric Capacity – Analytics – Prod`, a workspace inventory, and a sharing/export summary, with no
  authentication errors.
- Fail: an admin-permission or module error — fix the admin role (2.1) or install MicrosoftPowerBIMgmt
  (2.2) before continuing. You cannot validate change without a "before" picture.

## 5.2 Tenant-settings baseline resolves for the ring
- Run: `FABGOV-Validate.ps1` after Step 1, then manually spot-check in the admin portal.
- Pass: for a member of `Governance Pilot Ring – Fabric – Ring1`, Publish to web is disabled, export is
  scoped as configured, workspace creation is limited to `BI Creators – Analytics – Pilot`, and
  certification is limited to `BI Content Certifiers – Analytics – Prod`. The validator reports each
  setting as **Matches baseline**.
- Fail: any setting still shows "entire organization" when the baseline expects the ring, or a setting is
  scoped to the wrong group. Re-open the setting and re-apply the group scope.
- Manual proof: sign in as (or ask) a ring user to attempt Publish to web — the option should be absent
  or blocked.

## 5.3 Workspace roles match the access model
- Run: `FABGOV-Validate.ps1` (workspace-roles section).
- Pass: `Sales BI – Content – Dev/Test/Prod` each show only group-based role assignments matching Step 3
  (no individual users; Prod has no broad edit rights). The validator reports **Roles match model**.
- Fail: an individual user holds a role, or a workspace has an unexpected Admin/Member — remove it and
  re-assign to the correct group.

## 5.4 Workspaces are on the correct capacity
- Run: `FABGOV-Validate.ps1` (capacity-assignment section) and confirm in the Fabric Capacity Metrics
  app.
- Pass: `Sales BI – Content – Test` and `Sales BI – Content – Prod` are assigned to
  `Fabric Capacity – Analytics – Prod`; the metrics app shows them consuming from it.
- Fail: a workspace is unassigned or on the wrong capacity — reassign in Workspace settings →
  Premium/License.

## 5.5 Deployment pipeline promotes content correctly
- Run: a manual promotion in `Deployment Pipeline – Sales BI – DevTestProd`.
- Pass: content created in `Sales BI – Content – Dev` deploys to Test and then Production; the compare
  view shows only intended differences; deployment rules swap the production data source; only
  `Fabric Admins – Platform – Prod` can deploy to Production.
- Fail: promotion errors, an unexpected diff, or a non-admin can deploy to Prod — re-check stage-to-
  workspace pairing (Step 4.2), deployment rules (4.5), and pipeline access (4.6).

## 5.6 Capacity utilization and activity monitoring work
- Run: `FABGOV-Report.ps1`.
- Pass: the report returns capacity utilization for `Fabric Capacity – Analytics – Prod` and an activity
  summary (top sharers, exports, publish-to-web attempts) from the activity log without error, and the
  numbers reconcile with the Fabric Capacity Metrics app.
- Fail: empty or errored output — confirm admin-API access (2.6) and that Step 5 enabled the log and
  enhanced metadata.

## 5.7 Tenant-wide expansion is safe (Expand gate)
- Run: `FABGOV-Validate.ps1` after each single tenant-wide setting change in Step 7.
- Pass: the changed setting reports **Matches baseline** at the new production scope, and no previously
  passing check regressed.
- Fail: any regression — roll the setting back using the recorded rollback value and re-pilot before
  retrying. Never batch multiple tenant-wide changes between validations.

## Sign-off
Record for each test: date, operator, script output location, pass/fail, and (for tenant-wide changes)
the change-approval reference. A clean run of 5.1–5.6 on the ring plus an approved 5.7 per setting is the
bar for declaring the governance baseline in production.
