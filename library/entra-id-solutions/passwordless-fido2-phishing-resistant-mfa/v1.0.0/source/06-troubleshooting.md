# 6. Troubleshooting Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

Use `FIDO2-Discovery.ps1` for tenant method state, `FIDO2-Validation.ps1` for a user's registered
methods, `FIDO2-Report.ps1` for coverage, and `FIDO2-Remediation.ps1` (default `-WhatIf`) for laggards.

## A. Users locked out after enforcement
| Symptom | Cause | Remediation |
|---|---|---|
| Users can't sign in after the strength policy turns on | Enforced before users registered a phishing-resistant method | Set the CA policy to **Report-only**, drive registration via the campaign, confirm coverage with `FIDO2-Report.ps1`, then re-enable |
| Admins locked out | Break-glass accounts not excluded | Sign in with break-glass; exclude them from every CA policy (global G4) |

## B. FIDO2 key won't register
| Symptom | Cause | Remediation |
|---|---|---|
| "Security key" option missing at `aka.ms/mysecurityinfo` | FIDO2 not enabled or user not targeted | Enable FIDO2 and target the user's group; run `FIDO2-Discovery.ps1` |
| Key rejected during registration | Key model blocked by AAGUID restriction, or unsupported browser/OS | Allow the model's AAGUID (or remove the restriction); use a supported browser/OS |

## C. Windows Hello for Business not provisioning
- Confirm the device is Entra-joined/registered and has a TPM; confirm Windows Hello for Business is enabled (Authentication methods policy or Intune) and the user is targeted.

## D. Conditional Access not requiring the strength
| Symptom | Cause | Remediation |
|---|---|---|
| Weak methods still work | Policy in Report-only, or wrong grant | Confirm the policy is **On** and the grant is **Require authentication strength** with the right strength selected |
| Some apps bypass it | Legacy/non-modern-auth apps/protocols | Inventory and remediate or scope them; don't leave permanent broad exclusions |

## E. Certificate-based authentication failing
- Confirm the CA chain is uploaded, the trust/issuer is valid, and username binding is configured before the method is enabled; check certificate validity/revocation.

## F. Diagnostics quick reference (Microsoft Graph PowerShell)
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','UserAuthenticationMethod.Read.All','AuditLog.Read.All'
# Tenant method policy (FIDO2 etc.)
Invoke-MgGraphRequest GET '/v1.0/policies/authenticationMethodsPolicy'
# A user's registered methods
Invoke-MgGraphRequest GET "/v1.0/users/<upn>/authentication/methods"
# Registration details (coverage)
Invoke-MgGraphRequest GET '/v1.0/reports/authenticationMethods/userRegistrationDetails'
```

## G. When to escalate
If methods are enabled and targeted, the user has registered a phishing-resistant method, the CA
policy grant is correct, and sign-in still fails, collect the Entra **Sign-in logs** entry (the
failed CA policy + authentication-strength detail) and open a Microsoft support case.
