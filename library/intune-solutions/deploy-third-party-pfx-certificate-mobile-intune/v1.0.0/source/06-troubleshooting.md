# 6. Troubleshooting Guide — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

Use `PFXMOB-Discovery.ps1` (imported objects + connector + profiles), `PFXMOB-Validation.ps1`
(per-device chain + identity), `PFXMOB-Report.ps1` (fleet status), and `PFXMOB-Remediation.ps1`
(safe `-WhatIf` fixes).

## The core scenario — "PFX object exists in Graph but won't deploy"
Work this tree top to bottom; the cause is almost always step 2 or 3.

1. **Are you using a SCEP or PKCS (CA-issued) *template*?**
   - If yes → **that is the problem.** A SCEP/PKCS template issues a *new* certificate from your CA;
     it cannot deliver a pre-existing third-party PFX. Unassign it and switch to a **PKCS imported
     certificate** profile (Path A) or a **custom PKCS12** profile (Path B). Do not keep checking CA
     mappings, CA permissions, local cert stores, or "the request on the CA" — no certificate is being
     requested, so none of those will ever show activity.

2. **Is a *delivery profile* assigned to the user/group?**
   - The imported PFX object existing in Graph is **not** delivery. Confirm a
     `PFX Imported – iOS App Cert – Pilot` (Path A) or `Custom PKCS12 – iOS App Cert – Pilot` (Path B)
     profile is created **and assigned** to the device's group. Importing and assigning are separate
     steps — this missing assignment is the most common cause.

3. **Is the Certificate Connector healthy? (Path A)**
   - The connector **decrypts** the imported PFX at delivery. If it is unhealthy, the imported-PFX
     profile silently never deploys. See section A.

4. **Is the trusted chain present?**
   - If the leaf deploys but is untrusted/unusable, the root/intermediate chain is missing — deploy
     `Trusted Root – Org CA – iOS`. See section C.

5. **Does intended purpose match? (Path A, non-S/MIME app cert)**
   - The imported-PFX intended-purpose options are S/MIME-oriented; a mismatch can deploy a cert the
     app does not consume as expected. See section D.

6. **Is the device synced and enrolled?**
   - Force a sync; confirm the device is enrolled and in the assigned group. Run
     `PFXMOB-Remediation.ps1` (re-assign / re-trigger sync).

## A. Certificate Connector unhealthy (Path A)
| Symptom | Cause | Remediation |
|---|---|---|
| Imported-PFX profile never delivers | Connector offline / stale check-in | Intune → **Tenant administration → Connectors and tokens → Certificate connectors**; restart the connector service on the host; confirm it returns **Active/Healthy**; re-sync devices |
| Import succeeds but decrypt fails | Connector public key mismatch / wrong connector | Re-run `PFXMOB-Import-Pfx.ps1` so the PFX is encrypted to the *current* connector public key |

## B. Profile shows Error / Pending
- Confirm the device is enrolled and in `iOS App Cert – Pilot`/`– Broad`; force a sync.
- Re-check the profile assignment and platform (iOS/iPadOS). Run `PFXMOB-Remediation.ps1`.

## C. Chain missing — leaf present but untrusted/unusable
- Deploy/confirm `Trusted Root – Org CA – iOS` (and an intermediate profile if the chain has one).
- Verify with `PFXMOB-Validation.ps1` (checks chain + identity). A leaf without its chain is the
  classic "cert is there but nothing works" symptom.

## D. Intended-purpose mismatch (non-S/MIME app cert)
- The imported-PFX intended purpose is S/MIME-oriented (signing/encryption). If the app expects a
  plain app identity, the framing may not fit — set what the app expects, or use **Path B** (custom
  PKCS12), which avoids the imported-PFX intended-purpose model entirely.

## E. App can't access the keychain (delivered but not usable)
- The identity is in the **system keychain**, but the app may require it in **its own keychain access
  group** or via an **App Configuration policy**.
- Re-check the app vendor's required delivery method. If the vendor needs the app's keychain access
  group, a plain custom PKCS12 may not be directly accessible — follow the vendor's method or add an
  Intune **App Configuration policy** for the app (**Apps → App configuration policies → Add →
  Managed devices**).
- App-internal specifics are deferred to the app vendor; verify Intune delivery is correct first
  (`PFXMOB-Validation.ps1`), then hand off to the vendor.

## F. Diagnostics quick reference
```powershell
# Imported PFX objects + connector + profiles (read-only)
.\PFXMOB-Discovery.ps1
# Per-device chain + identity + profile state (read-only)
.\PFXMOB-Validation.ps1 -DeviceName 'iPad-Pilot-01'
# Fleet certificate-deployment status (read-only)
.\PFXMOB-Report.ps1
```
In Intune, check `Tenant administration > Connectors and tokens > Certificate connectors` (health) and
`Devices > Configuration > (profile) > Device status` (per-device result).

## G. When to escalate
If the correct delivery profile is assigned, the Certificate Connector is healthy (Path A), the chain
is present, the device is synced, and the certificate is confirmed installed by `PFXMOB-Validation.ps1`
but the **app still cannot use it**, the remaining cause is app-internal (keychain access group /
App Configuration). Collect the validation output and engage the **app vendor** with the vendor's
required certificate-delivery method.
