# 6. Troubleshooting Guide — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra

Use `ENTPASSKEYG-Discovery.ps1` for the methods-policy state, `ENTPASSKEYG-Report.ps1` for adoption,
`ENTPASSKEYG-Validate.ps1` for the enforcement controls, and the portal `Conditional Access ->
Insights and reporting` for report-only impact.

## A. Discovery or validation errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Policy.Read.All` (and `UserAuthenticationMethod.Read.All` for the report) |
| Auth/endpoint errors, or connects to the wrong tenant/cloud | Connected to the commercial cloud instead of US Gov | Use `Connect-MgGraph -Environment USGov` (GCC High → `login.microsoftonline.us` / `graph.microsoft.us`). For DoD (IL5) use `-Environment USGovDoD` (`dod-graph.microsoft.us`). *Verify the correct cloud for your tenant.* |
| Empty method list | Signed in to the wrong tenant, or lacking `Authentication Policy Administrator` read | Confirm the tenant; ensure the operator can read the authentication methods policy |
| CA policies not listed | The operator cannot read Conditional Access | Add `Security Reader` / `Conditional Access Administrator` |

## B. The passkey (Authenticator) option is missing
- The Passkey option under Microsoft Authenticator may be in preview or gated by tenant configuration,
  **and passkey / FIDO2 method availability in GCC High and DoD can lag the commercial cloud.** *Verify
  current availability and any preview status for your GCC High (or DoD) tenant against current Microsoft
  Government documentation* under `Authentication methods -> Policies -> Microsoft Authenticator` — do not
  assume commercial parity. Confirm users are on the latest Authenticator and a supported device OS. If
  the device-bound passkey path is unavailable in your cloud, use FIDO2 security keys for that wave while
  you confirm availability.

## C. FIDO2 security-key registration fails
| Symptom | Cause | Remediation |
|---|---|---|
| "This security key isn't allowed" | Key restrictions / AAGUID allow-list excludes the key model | Add the key's AAGUID to the allow-list, or relax `Enforce key restrictions`, in the FIDO2 method `Configure` blade |
| Registration blocked with no other method | User has no existing credential to register with | Issue a Temporary Access Pass so the user can bootstrap the key |
| Attestation error | `Enforce attestation` on, key provides none | Use an attestation-capable key, or relax attestation per your policy |

## D. User can't register — no way to start
- This is why TAP is enabled first. Issue a Temporary Access Pass (`Users ->` user `-> Authentication
  methods -> Add -> Temporary Access Pass`), which lets the user sign in without a password and add a
  FIDO2 key or passkey. Confirm TAP is enabled and the user is in its target scope
  (`ENTPASSKEYG-Validate.ps1`).

## E. Registration campaign not prompting
- Confirm `Authentication methods -> Registration campaign -> State = Enabled` and the user is in
  `Passwordless Registration Campaign - Pilot - Pilot`. The nudge appears on interactive sign-in only,
  respects the snooze count, and does not prompt users who already have the target method. It will not
  prompt during non-interactive or app-token flows.

## F. Conditional Access policy blocks the wrong people (or nobody)
| Symptom | Cause | Remediation |
|---|---|---|
| A user is unexpectedly blocked after enforce | They had not registered a phishing-resistant method before the policy was turned on | Return the policy to `Report-only`, confirm adoption with `ENTPASSKEYG-Report.ps1`, register the user (TAP if needed), then re-enforce |
| Policy has no effect after enforce | Left in `Report-only`, or scope/exclusions wrong | Set `Enable policy = On`; check the user is in the include scope and not excluded |
| Admins locked out risk | Break-glass not excluded | Always exclude the two break-glass accounts; `ENTPASSKEYG-Validate.ps1` flags a policy that does not |

## G. "Authentication strength" not requiring passwordless
- Confirm the grant control is `Require authentication strength -> Phishing-resistant MFA` (the
  built-in strength), not the generic `Require multifactor authentication` (which still accepts
  phishable methods). `ENTPASSKEYG-Validate.ps1` notes policies using built-in MFA instead of the
  phishing-resistant strength.

## H. Weak-method retirement caused lock-outs
- SMS/Voice were scoped out for a group before its users registered a stronger method. Re-add the
  group to SMS/Voice targeting to restore the fallback immediately, then drive registration and only
  retire again once `ENTPASSKEYG-Report.ps1` shows high adoption for that group.

## I. Diagnostics quick reference
```powershell
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','UserAuthenticationMethod.Read.All' -NoWelcome
# methods policy state
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy').authenticationMethodConfigurations |
  Select-Object id, state
# a user's registered methods
(Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/<upn>/authentication/methods").value.'@odata.type'
# phishing-resistant CA policies
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value |
  Where-Object { $_.grantControls.authenticationStrength.id } | Select-Object displayName, state
```

## J. When to escalate
If a lost or stolen FIDO2 key or a compromised device is suspected, treat it as an incident: revoke
the credential immediately (`Users ->` user `-> Authentication methods ->` remove the key/passkey),
review the user's recent sign-ins, issue a fresh TAP only after verifying identity, and engage your
incident-response process. If admin sign-in is disrupted tenant-wide, use a break-glass account and
set the enforcing CA policy to `Report-only` while you investigate.
