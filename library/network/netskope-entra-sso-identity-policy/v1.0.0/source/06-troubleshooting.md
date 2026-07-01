# 6. Troubleshooting Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Use `NSSSO-Validation.ps1` / `NSSSO-Discovery.ps1` for the app's SSO + provisioning state,
`NSSSO-Report.ps1` for coverage, and `NSSSO-Remediation.ps1` (default `-WhatIf`) for safe fixes to
the Entra ID scope/assignment. Netskope-side issues are deferred to the Netskope documentation.

## A. SSO sign-in fails
| Symptom | Cause | Remediation |
|---|---|---|
| User can't sign in to Netskope via Entra | User not assigned to `Netskope SSO - Corp - Prod` | Entra → app → Users and groups → add the user's group; or run `NSSSO-Remediation.ps1` |
| "Sign-in but not recognized" | SAML claim mismatch (identifier/format Netskope expects) | Re-check Attributes and Claims against the Netskope SAML requirements (Netskope docs) |
| Certificate/trust error | Wrong or expired signing certificate / metadata | Re-download the Entra signing certificate and re-enter it on the Netskope side |

## B. Locked out of the Netskope admin console
- If SAML is misconfigured after switching the admin console to SSO, use the emergency local/break-glass Netskope admin (see Best Practices) to sign in and correct the SAML config; never enable SSO-only without a verified local admin.

## C. SCIM provisioning not working
| Symptom | Cause | Remediation |
|---|---|---|
| Provisioning Test Connection fails | Wrong SCIM Tenant URL or Secret Token | Re-generate/copy the SCIM endpoint and token in Netskope (deferred) and re-enter under Admin Credentials |
| Users/groups missing in Netskope | Scope is "assigned only" and user/group not assigned | Assign the group to the app; run `NSSSO-Report.ps1`; or run `NSSSO-Remediation.ps1` |
| Provisioning logs show errors | Attribute mapping mismatch | Re-check Mappings against Netskope's required attributes (Netskope docs) |
| Change not appearing | Provisioning is cycle-based | Wait for the next cycle; check Provisioning logs for the last run |

## D. Leaver still has access
- SCIM de-provisions on a cycle; confirm the user was removed from the assigned group and that a provisioning cycle has run. Run `NSSSO-Report.ps1` to confirm the user is disabled/removed in Netskope.

## E. Identity-based policy not matching
- Confirm the group is provisioned into Netskope (`NSSSO-Report.ps1`) and that `Identity Steering Policy - Corp - Prod` targets the provisioned group; group-based policy can only match groups SCIM has delivered. Netskope policy specifics are deferred to the Netskope documentation.

## F. Confusion with Entra Conditional Access
- If a sign-in is blocked at authentication, that is a Conditional Access decision, not this integration. This integration controls Netskope's inline policy after authentication. Review Conditional Access separately (out of scope here); see the Overview for the distinction.

## G. Diagnostics quick reference
```powershell
# Read-only checks (Microsoft Graph side)
.\NSSSO-Discovery.ps1     # app, SAML SSO config, SCIM provisioning status, groups
.\NSSSO-Validation.ps1    # SSO configured + provisioning enabled
.\NSSSO-Report.ps1        # SSO mode, provisioning status, assigned/target groups
```
In Entra: the enterprise app's Sign-in logs (SSO) and Provisioning logs (SCIM) are the primary
evidence. In Netskope: policy hit logs and the provisioned user/group list (deferred to Netskope docs).

## H. When to escalate
If SSO is correctly configured (Test 1), the user is assigned, claims match, provisioning is On and
its last cycle succeeded, but Netskope still does not recognize the identity or apply group policy,
collect the Entra sign-in and provisioning log entries and open a Netskope support case (the
remaining surface is Netskope-side configuration, which is deferred to the Netskope documentation).
