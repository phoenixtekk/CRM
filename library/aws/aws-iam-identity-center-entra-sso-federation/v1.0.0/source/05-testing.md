# 5. Testing — AWS IAM Identity Center + Microsoft Entra SSO Federation

Run every gate below against the **sandbox account** and **pilot group** before you expand to production or decommission any IAM user. Each gate has an explicit pass/fail. Reference the automation scripts by name where noted.

## Gate 1 — SAML sign-in works
Procedure: Open the **AWS access portal URL** in a clean browser. Sign in with a member of `AWS-SSO-Admin-Sandbox-Pilot`.
Pass: You are redirected to Entra, complete MFA, return to the portal, and see account tiles.
Fail: You get a SAML error, a redirect loop, or "no access." See Troubleshooting T1/T2.

## Gate 2 — SCIM provisioning synced the right objects
Procedure: In Entra, open the app **-> Provisioning -> View provisioning logs**. In AWS, open **IAM Identity Center -> Users** and **-> Groups**. Optionally run `AWSSSO-Validate.ps1` (read-only) against the Entra app.
Pass: The pilot users and all five `AWS-SSO-*` groups show **provisioned/success** in Entra and **appear in AWS** without being created by hand; `AWSSSO-Validate.ps1` reports provisioning **On**, connection healthy, and scope = assigned only.
Fail: Users/groups missing in AWS, provisioning errors, or the connection test fails. See Troubleshooting T3.

## Gate 3 — Least-privilege boundary holds
Procedure: Sign in as a user who is **only** in `AWS-SSO-ReadOnly-AllAccounts`. Open the sandbox account with the `SSO-ReadOnly – AllAccounts – Prod` role. Attempt a change (e.g. create an S3 bucket or stop an instance).
Pass: You can view resources but every write/change is **denied**; the user sees no Admin tile.
Fail: A read-only user can make changes, or sees roles they should not. Re-check the permission-set policy and assignments (`AWSSSO-Report.sh`). See Troubleshooting T4.

## Gate 4 — Deprovisioning (offboarding) works
Procedure: Remove a pilot user from `AWS-SSO-Admin-Sandbox-Pilot` (and any other AWS group) in Entra. Wait for the next provisioning cycle. Have that user try the portal.
Pass: Within the sync window the user loses the corresponding tiles/roles; provisioning logs show the update. This proves lifecycle automation replaces manual IAM-user offboarding.
Fail: The user retains access after removal. Check provisioning status/scope and sync latency. See Troubleshooting T3.

## Gate 5 — Session controls behave
Procedure: Sign into a role and note the session duration configured on the permission set (e.g. PT1H for `SSO-Admin – Sandbox – Pilot`). Stay idle past expiry or check the CLI credential expiry.
Pass: The session expires at the configured duration and re-authentication is required; no static keys were ever issued.
Fail: Sessions do not expire as configured. Re-check the permission-set session duration.

## Gate 6 — Break-glass path is proven
Procedure: In a controlled test, sign in as the `breakglass-emergency` IAM user (management account) with its MFA, and separately confirm a member of `AWS-SSO-BreakGlass-Emergency` can reach `SSO-BreakGlass – Management – Emergency`. Confirm CloudTrail/alerting fires on the emergency sign-in.
Pass: Both emergency paths work and are alerted on. You have a recovery route if federation ever breaks.
Fail: Break-glass sign-in fails or is not alerted. Fix before you disable any legacy IAM user (Troubleshooting T5).

## Gate 7 — Assignment matrix matches intent
Procedure: Run `AWSSSO-Report.sh` (read-only). Compare the *group -> permission set -> account* matrix to the R6 entitlement decision.
Pass: Every assignment is intended; no account/role is granted that the entitlement matrix does not list.
Fail: Extra or missing assignments. Correct via `AWSSSO-permission-sets.tf` (plan-first) and re-run.

---
When Gates 1–7 pass in the sandbox with the pilot group, proceed to Expand (production assignments, then staged IAM-user decommissioning). Re-run Gate 3 and Gate 7 after each production wave.
