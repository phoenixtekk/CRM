# 6. Troubleshooting Guide — Zero Trust Architecture: Conditional Access Baseline & Rollout

Use `ENTZTCA-Discovery.ps1` for the current policy inventory, `ENTZTCA-Report.ps1` for report-only
impact, `ENTZTCA-Validate.ps1` for baseline state and break-glass exclusion, and the portal
`Conditional Access -> What If` and `Insights and reporting` for per-user analysis.

## A. Discovery / validation errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Policy.Read.All`, `AuditLog.Read.All`, `Directory.Read.All` |
| No policies listed | Wrong tenant, or lacking CA read | Confirm the tenant; add `Security Reader` / `Conditional Access Administrator` |
| Sign-in log query empty | Needs Entra ID P1+ and `AuditLog.Read.All` | Confirm licensing and scope; widen `-LegacyLookbackDays` / `-LookbackDays` |

## B. A policy locked users out (or would have)
| Symptom | Cause | Remediation |
|---|---|---|
| Users blocked right after enforce | The policy was enforced before its report-only data was clean | Set the policy back to `Report-only` immediately; run `ENTZTCA-Report.ps1` to find the affected users/apps; fix scope/exclusion; re-validate; re-enforce |
| Admins at risk of lock-out | Break-glass not excluded | Add `CA Exclusion - Break-Glass - Steady` to the policy's `Users -> Exclude`; `ENTZTCA-Validate.ps1` flags any policy missing it |
| Everyone caught by one policy | Policy targets All users with no exclusions | Re-scope to the correct persona group; the discovery/validate "All-users lock-out sweep" red-flags this |
| Fully locked out | — | Sign in with a break-glass account (excluded from all policies) and set the offending policy to `Report-only` |

## C. Break-glass exclusion keeps disappearing
- Confirm the break-glass accounts are members of `CA Exclusion - Break-Glass - Steady` and that the
  **group** (not just the individual users) is excluded on every policy — a per-user exclusion is
  fragile. `ENTZTCA-Validate.ps1` reports whether the exclusion is via group (preferred) or user.

## D. Report-only shows nothing / What-If disagrees
- Report-only results only appear after real interactive sign-ins occur while the policy is in
  report-only — allow a representative period. If `ENTZTCA-Report.ps1` is empty, widen `-LookbackDays`
  or check `-PolicyNameLike` matches your policy prefix. What-If is a simulator and does not need
  sign-in history; if What-If and report-only disagree, trust What-If for scope logic and report-only
  for real-world impact, and reconcile the conditions.

## E. Risk policies (CA004/CA005) not available or not firing
- Sign-in risk and user risk require **Entra ID P2** (Identity Protection). `ENTZTCA-Discovery.ps1`
  reports whether P2 is present; `ENTZTCA-Set-Baseline.ps1` skips these automatically without P2. *If
  you are P1-only*, omit them and compensate with `CA001` (MFA) + `CA003` (compliant/hybrid device)
  everywhere, and note the gap. *Verify current availability in your tenant.*

## F. Device control (CA003) blocks compliant users
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant device still blocked | Device not actually reporting compliant / not hybrid-joined | Confirm in `Entra -> Devices`; check Intune compliance policy assignment and evaluation; the device must be registered and evaluated compliant |
| No device meets the control | Intune compliance or hybrid join not in place | Stand up device management first (adjacent solution), or use the control the tenant supports; *verify availability* |

## G. Legacy-auth block (CA007) broke an app
- A legacy/basic-auth app or mail client cannot do modern auth. Identify it from
  `ENTZTCA-Discovery.ps1` (legacy-auth section) and the sign-in logs, migrate it to modern auth, and
  only then block. If a legitimate legacy app must stay temporarily, add it as a **documented,
  time-boxed exception** — never a permanent silent carve-out.

## H. Phishing-resistant strength (CA002) rejects everyone
- If admins have not yet registered a phishing-resistant method (FIDO2 / passkey), `CA002` will block
  them once enforced. Register the method first (see the Passwordless & Passkey solution), confirm
  adoption, keep `CA002` in report-only until admins are enrolled, then enforce. Also verify the
  authentication-strength id in `ENTZTCA-Set-Baseline.ps1` matches the built-in
  `Phishing-resistant MFA` strength in your tenant.

## I. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome
# all policies with state and exclusions
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value |
  Select-Object displayName, state, @{n='excludeGroups';e={$_.conditions.users.excludeGroups}}
# is the tenant P2?
((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName |
  Where-Object { $_ -like 'AAD_PREMIUM*' } | Sort-Object -Unique
```

## J. When to escalate
If a policy change locks out administrative access and a break-glass account cannot restore it, treat
it as a Sev-1: use the second break-glass account, contact Microsoft support with the tenant ID, and
follow your incident-response process. If you see a surge of risky sign-ins or an unexpected mass of
report-only blocks that suggests an attack, keep the relevant policies enforced, engage Identity
Protection (P2) and your security team, and do not disable the baseline to "make it work."
