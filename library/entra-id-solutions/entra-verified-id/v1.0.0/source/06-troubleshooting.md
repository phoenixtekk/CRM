# 6. Troubleshooting Guide — Entra Verified ID — Verifiable Credentials

Use `ENTVID-Discovery.ps1` / `ENTVID-Validate.ps1` for service and prerequisite state,
`ENTVID-Report.ps1` for issued/revoked credentials, and the two request-builder scripts
(`ENTVID-New-IssuanceRequest.ps1`, `ENTVID-New-PresentationRequest.ps1`, build-only unless `-Submit`)
for the flows. Do portal work at `https://entra.microsoft.com` (Verified ID) and
`https://portal.azure.com` (Key Vault).

## A. Onboarding / service setup problems
| Symptom | Cause | Remediation |
|---|---|---|
| Verified ID setup fails or Key Vault step errors | Operator or Verified ID service lacks Key Vault key permissions | Grant the documented Key Vault key permissions (get, sign, key create) via access policy or Azure RBAC key roles; retry onboarding; run `ENTVID-Validate.ps1` |
| No issuer/authority after onboarding | Onboarding not completed, or wrong tenant | Re-run `Verified ID -> Setup`; confirm you are in the correct tenant; run `ENTVID-Discovery.ps1` |
| `Verified ID` not visible in the admin center | Feature not available/licensed in the tenant | *Verify current Verified ID availability and licensing for your tenant*; confirm the required Entra ID licensing is assigned |

## B. Domain verification problems
| Symptom | Cause | Remediation |
|---|---|---|
| Domain will not verify | `did-configuration.json` not published at `/.well-known/`, not HTTPS, or does not match the DID | Publish the generated file at `https://contoso.com/.well-known/did-configuration.json` over HTTPS; ensure it matches your DID; re-verify; run `ENTVID-Validate.ps1` |
| Well-known file returns 404 | Wrong path or web server not serving `.well-known` | Confirm the exact `/.well-known/did-configuration.json` path and that the host serves dotfolder content |
| Domain shows Verified but wallets still warn | Cached/stale file or mismatched content | Re-download the current `did-configuration.json` from Verified ID and republish; clear caches |

## C. Request Service app / API problems
| Symptom | Cause | Remediation |
|---|---|---|
| Request scripts get 401/403 from the Request Service API | Missing/unconsented API permission, wrong client credentials, or expired secret | Add and admin-consent the Verified ID Request Service permission; confirm client ID/tenant ID; rotate the secret/certificate. *Verify the current permission name/ID for your tenant* |
| Token acquisition fails | Wrong authority/scope in the client-credentials call | Confirm the token authority and the Request Service resource/scope used by the script; use the app's tenant ID |
| Secret found in logs/repo | Secret handled insecurely | Rotate the secret immediately; store it in a secrets store/env, never in source control or output |

## D. Issuance problems
| Symptom | Cause | Remediation |
|---|---|---|
| QR / deep link never appears | Ran build-only (no `-Submit`) | This is expected in build-only mode; re-run `ENTVID-New-IssuanceRequest.ps1 -Submit` after reviewing the payload |
| Credential does not land in the wallet | Holder did not complete sign-in/consent, or attestation (rules) failed | Confirm the holder signs in as the rules require and consents; check the rules definition's attestation method; retry |
| Wrong/empty claims on the credential | Rules definition maps the wrong source claims | Fix the credential type's rules definition (claim mapping); re-issue |
| Wallet cannot scan / open link | No Authenticator or no connectivity | Install Microsoft Authenticator; ensure the device has connectivity; retry |

## E. Verification problems
| Symptom | Cause | Remediation |
|---|---|---|
| Callback never receives a result | Callback endpoint not reachable by the Request Service, or wrong URL in the request | Use an HTTPS callback reachable from the internet; confirm the URL in `ENTVID-New-PresentationRequest.ps1`; re-submit |
| Verification rejects a valid credential | Credential expired or revoked, or issuer not trusted | Check issuance/expiry/revocation with `ENTVID-Report.ps1`; confirm the verifier trusts your issuer/DID and domain |
| Revoked credential still accepted | Verifier is not checking status | Ensure the verification request checks credential status/revocation; re-test after revoking (Step 9) |

## F. Governance / lifecycle
- Revocation: revoke in `Verified ID -> Credentials`; confirm a status-checking verifier rejects it. Run `ENTVID-Report.ps1` to see revoked state.
- Expiry/re-issuance: if credentials expire unexpectedly or never, review the credential type's lifecycle/expiry settings and your re-issuance cadence with your governance owners.

## G. Diagnostics quick reference
```powershell
# Read-only service/authority discovery via Microsoft Graph
Connect-MgGraph -Scopes 'VerifiableCredential.Authority.Read.All' -NoWelcome   # verify the exact scope for your tenant
# Domain well-known check (no auth)
Invoke-WebRequest -UseBasicParsing "https://contoso.com/.well-known/did-configuration.json" | Select-Object -Expand Content
# App registration + Request Service permission
Connect-MgGraph -Scopes 'Application.Read.All'
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=displayName eq 'VC Request Service App - Issuer/Verifier - Pilot'"
```
> The Verified ID admin Graph scopes/endpoints and Request Service API details can differ by tenant and
> may be preview — *verify the current names/IDs for your tenant* before scripting against them.

## H. When to escalate
If Key Vault permissions are correct, the domain well-known file resolves and matches your DID, the
Request Service app is consented with a valid credential, and issuance or verification still fails,
capture `ENTVID-Validate.ps1` output and the Request Service API error/response and open a Microsoft
support case for the Verified ID service, confirming whether any capability in play is preview for your
tenant.
