# 6. Troubleshooting Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

Use `FIDO2G-Discovery.ps1` for tenant method state, `FIDO2G-Validation.ps1` for a user's registered
methods, `FIDO2G-Report.ps1` for coverage, and `FIDO2G-Remediation.ps1` (default `-WhatIf`) for
laggards. All scripts run against **US Gov Graph** (`-Environment USGov`, or `USGovDoD` for DoD).

## A. Wrong cloud / sovereign-endpoint problems (GCC High-specific — check first)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows `.com` / your account isn't recognized | Signed in to a Commercial portal | Use the sovereign portals: `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us` |
| Script auth fails or returns the wrong tenant / "AADSTS" endpoint errors | `Connect-MgGraph` defaulted to Commercial Graph | Pass **`-Environment USGov`** (or `USGovDoD`); all package scripts default to `USGov` |
| Graph Explorer won't work against your tenant | Graph Explorer is **not supported** for `graph.microsoft.us` / `dod-graph.microsoft.us` | Use the PowerShell scripts in this package instead |
| A documented feature/menu is missing | Commercial-only, Preview, or Authenticator/cross-cloud feature not in US Gov | Check `gcc-high-parity-notes.md`; use the GA fallback (hardware FIDO2 / Windows Hello / CBA) |

## B. Users locked out after enforcement
| Symptom | Cause | Remediation |
|---|---|---|
| Users can't sign in after the strength policy turns on | Enforced before users registered a phishing-resistant method | Set the CA policy to **Report-only**, drive registration, confirm coverage with `FIDO2G-Report.ps1`, then re-enable |
| Admins locked out | Break-glass accounts not excluded | Sign in with break-glass; exclude them from every CA policy (global G4). On GCC High, recovery is slower — keep break-glass current |

## C. FIDO2 key won't register
| Symptom | Cause | Remediation |
|---|---|---|
| "Security key" option missing at `aka.ms/mysecurityinfo` | FIDO2 not enabled or user not targeted | Enable FIDO2 and target the user's group; run `FIDO2G-Discovery.ps1` |
| Key rejected during registration | Key model blocked by AAGUID restriction, or unsupported browser/OS | Allow the model's AAGUID (or remove the restriction); use a supported browser/OS. Prefer FIPS-validated keys |
| You expected a phone/synced passkey option and it's absent | Authenticator/synced passkeys are **verify for GCC High** — likely not available | Use a **hardware FIDO2 key** or **CBA smart card** (the GA path); do not depend on synced passkeys |

## D. Onboarding bootstrap missing (TAP)
- If **Temporary Access Pass** is not present in the sovereign Authentication methods policy, that is expected — **TAP is verify for GCC High**. Use **supervised in-person enrollment** (register the FIDO2 key with the user present) or **CAC/PIV issuance** as the bootstrap instead of blocking on TAP.

## E. Windows Hello for Business not provisioning
- Confirm the device is Entra-joined/registered and has a TPM; confirm Windows Hello for Business is enabled (Authentication methods policy or Intune at `endpoint.microsoft.us`) and the user is targeted.

## F. Conditional Access not requiring the strength
| Symptom | Cause | Remediation |
|---|---|---|
| Weak methods still work | Policy in Report-only, or wrong grant | Confirm the policy is **On** and the grant is **Require authentication strength** with the right strength selected |
| Some apps bypass it | Legacy/non-modern-auth apps/protocols | Inventory and remediate or scope them; don't leave permanent broad exclusions |

## G. Certificate-based authentication (CAC/PIV) failing
| Symptom | Cause | Remediation |
|---|---|---|
| Smart-card sign-in fails | CA chain not uploaded, invalid trust/issuer, or revocation check failing | Confirm the issuing/root CA chain is in the Entra certificate-authorities store; check certificate validity/CRL/OCSP |
| User can't be matched to the certificate | Username binding not configured | Configure username binding (`PrincipalName` / `RFC822Name`, or `certificateUserIds`) |
| CBA works but only counts as single-factor (strength not satisfied) | Authentication-binding maps the certificate policy to single-factor | Set the authentication-binding so the hardware-smart-card certificate policy counts as **MFA**. **Verify the current GCC High/DoD binding requirements** (`gcc-high-parity-notes.md` §3) |

## H. Diagnostics quick reference (Microsoft Graph PowerShell — US Gov)
```powershell
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','UserAuthenticationMethod.Read.All','AuditLog.Read.All'
# (DoD tenants: -Environment USGovDoD)

# Tenant method policy (FIDO2, Windows Hello, CBA)
Invoke-MgGraphRequest GET '/v1.0/policies/authenticationMethodsPolicy'
# A user's registered methods
Invoke-MgGraphRequest GET "/v1.0/users/<upn>/authentication/methods"
# Registration details (coverage)
Invoke-MgGraphRequest GET '/v1.0/reports/authenticationMethods/userRegistrationDetails'
```
> Placeholders use a plain form (`<upn>`) in this diagnostic block only for clarity; the packaged
> scripts take real parameters (e.g. `-UserId`) and never require you to edit angle-bracket text.

## I. When to escalate
If methods are enabled and targeted on the **sovereign** tenant, the user has registered a
phishing-resistant method, the CA policy grant is correct, and sign-in still fails, collect the Entra
**Sign-in logs** entry (the failed CA policy + authentication-strength detail) at `entra.microsoft.us`
and open a Microsoft support case **for the US Government cloud**. Note the tenant is GCC High (or
DoD) in the case so it routes to the sovereign support queue.
