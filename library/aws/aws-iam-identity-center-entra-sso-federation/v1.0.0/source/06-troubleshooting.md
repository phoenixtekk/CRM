# 6. Troubleshooting — AWS IAM Identity Center + Microsoft Entra SSO Federation

Symptom -> cause -> fix for the failures you are most likely to hit. Work in the sandbox account with the pilot group; never troubleshoot by widening permissions in production.

## T1. Sign-in fails with a SAML error ("invalid response", signature/audience mismatch)
Symptom: After Entra authentication the AWS portal shows a SAML error instead of account tiles.
Cause: The SAML trust metadata is stale or one-directional — AWS and Entra are not using each other's current metadata, or the certificate rotated.
Fix: Re-run **Step B4**. Re-download AWS's service-provider metadata into Entra's Basic SAML Configuration, and re-upload Entra's current **Federation Metadata XML** into the AWS external IdP configuration. Confirm the Entra SAML signing certificate is active (not expired) and re-test.

## T2. Redirect loop or "you do not have access" after authenticating
Symptom: Sign-in succeeds at Entra but bounces back, or shows no accessible accounts.
Cause: The user is authenticated but not **assigned** to the app and/or not a member of any group that has an account assignment.
Fix: In Entra, on `AWS IAM Identity Center – Federation – SSO` **-> Users and groups**, confirm the user (or their group) is added. In AWS, confirm an **account assignment** exists linking that group to a permission set on an account (`AWSSSO-Report.sh`). Authentication (SAML) and authorization (assignment) are separate — both are required.

## T3. Users or groups don't appear in AWS (SCIM provisioning)
Symptom: A pilot user/group is in Entra but never shows in **IAM Identity Center -> Users/Groups**, or an offboarded user keeps access.
Cause: Provisioning is Off, the SCIM token/endpoint is wrong, the object is out of scope, or you are inside the sync window.
Fix: In Entra **-> Provisioning**: confirm **Status = On** and **Scope = Sync only assigned users and groups**, and that the user/group is under **Users and groups**. Run **Test Connection** — if it fails, the AWS SCIM **Secret Token** likely expired or was mistyped; regenerate it in **IAM Identity Center -> Settings -> Automatic provisioning** and paste the new token. Check **View provisioning logs** for per-object errors. For deprovisioning, remember it follows the cycle — for urgent offboarding, also disable the user in Entra (`AWSSSO-Validate.ps1` reports provisioning state).

## T4. A read-only user can make changes (least-privilege breach)
Symptom: A member of `AWS-SSO-ReadOnly-AllAccounts` can modify resources, or sees an Admin tile.
Cause: The wrong managed policy is attached to the permission set, or the user is also in a higher-privilege group, or a stale console-created assignment exists.
Fix: Inspect the permission set (`SSO-ReadOnly – AllAccounts – Prod`) — it must attach `ReadOnlyAccess` only. Confirm the user's Entra group membership; a user in both ReadOnly and PowerUser groups gets the union. Reconcile against `AWSSSO-permission-sets.tf` (plan-first) so Terraform is authoritative, and re-run Gate 3.

## T5. Break-glass sign-in fails or isn't alerted
Symptom: The `breakglass-emergency` IAM user cannot sign in, or its use raises no alert.
Cause: The emergency user's MFA/login profile is misconfigured, or CloudTrail alerting on it was never wired.
Fix: Confirm the `breakglass-emergency` user has a valid password and registered MFA, and **no access keys**. Confirm a CloudTrail-based alert (e.g. EventBridge rule on that principal) notifies your team on sign-in. **Never** disable a legacy IAM user (Stage E3) until Gate 6 passes — break-glass is your recovery path.

## T6. Terraform plan wants to destroy/replace permission sets
Symptom: `terraform plan` shows it will replace or delete a permission set you created in the console.
Cause: The console-created object and the Terraform-declared object are not the same resource — Terraform doesn't know about the console object (no state), so it plans to create its own and may collide.
Fix: Import the existing permission set into Terraform state (`terraform import` on `aws_ssoadmin_permission_set`) rather than letting it recreate, or delete the console object and let Terraform own it. Standardize on Terraform going forward (Best Practices). Always review the plan before apply.

## T7. Provisioning "Test Connection" fails immediately
Symptom: In Entra the SCIM Test Connection fails before you can save credentials.
Cause: The AWS **Tenant URL** or **Secret Token** is wrong/expired, or automatic provisioning was never enabled on the AWS side.
Fix: In **IAM Identity Center -> Settings**, confirm **Automatic provisioning** is enabled and copy a freshly generated **Access token** and the exact **SCIM endpoint** URL. Paste both into Entra Admin Credentials and re-test. The token is shown once on generation — regenerate if you lost it.

## T8. Wrong or missing accounts in a user's portal after Expand
Symptom: After a production wave, users see too many or too few accounts.
Cause: Account assignments were applied to the wrong accounts, or group membership doesn't match the entitlement matrix.
Fix: Run `AWSSSO-Report.sh` and diff the *group -> permission set -> account* matrix against the R6 entitlement decision. Correct assignments in `AWSSSO-permission-sets.tf` (plan-first) and correct Entra group membership. Re-run Gate 7.
