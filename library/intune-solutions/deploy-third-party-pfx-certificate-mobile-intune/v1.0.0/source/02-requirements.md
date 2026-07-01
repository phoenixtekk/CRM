# 2. Requirements Guide — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> Naming convention used throughout this package: `<Purpose> – <Scope> – <Stage>`. The objects you
> create are named exactly: `PFX Imported – iOS App Cert – Pilot` (Path A profile), `Custom PKCS12 –
> iOS App Cert – Pilot` (Path B profile), `Trusted Root – Org CA – iOS` (chain profile), and device
> groups `iOS App Cert – Pilot` and `iOS App Cert – Broad`. Reuse these verbatim in every step.
> Wherever a service identity is referenced, use the neutral placeholder
> `Intune.Cert.<service>@<your-domain>` — never a real tenant UPN.

## 2.1 Licensing
**Description:** Intune (Plan 1) for the configuration profiles and (for Path A) the Certificate
Connector.
**Why:** Intune delivers the imported-PFX / custom / trusted-certificate profiles to devices.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 iOS/iPadOS enrollment
**Description:** The target iOS/iPadOS devices are enrolled in Intune.
**Why:** Configuration profiles apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices** (filter to iOS/iPadOS); run `PFXMOB-Discovery.ps1`.
**Implement:** Enroll devices (Apple ADE, Apple Configurator, or user enrollment) per your model.

## 2.3 The third-party PFX file + password
**Description:** The actual `.pfx`/`.p12` file (private key included) and its password, from the
issuing third party.
**Why:** Both paths deliver *this exact file*; there is nothing to "issue" — you are delivering an
existing credential.
**Verify:** You can open the PFX with the password (e.g. import to a throwaway local store on an admin
workstation and confirm it loads with its private key).
**Implement:** Obtain the `.pfx` and password from the third party; store the password as a secret
(never hardcode it in scripts or docs).

## 2.4 The trusted root/intermediate chain
**Description:** The root (and any intermediate) CA certificate(s) that issued the leaf in the PFX, as
`.cer`/`.crt` files.
**Why:** A leaf identity is unusable on the device unless its issuing chain is trusted; the chain is
delivered by a separate **Trusted certificate** profile (`Trusted Root – Org CA – iOS`).
**Verify:** Inspect the PFX issuer chain (e.g. on an admin workstation) and confirm you have each CA
certificate above the leaf.
**Implement:** Obtain the root/intermediate `.cer` files from the issuing party.

## 2.5 Intune Certificate Connector (REQUIRED for Path A; not needed for Path B)
**Description:** A healthy Intune Certificate Connector installed on a Windows server.
**Why:** Path A (PKCS imported certificate) encrypts the PFX to the connector's public key on import,
and the connector **decrypts** it at delivery time. No healthy connector = imported PFX never
deploys.
**Verify:** Intune → **Tenant administration → Connectors and tokens → Certificate connectors**; the
connector shows **Active/Healthy** with a recent check-in. Run `PFXMOB-Discovery.ps1`.
**Implement:** Install the Intune Certificate Connector on a domain-joined Windows server
(`Tenant administration → Connectors and tokens → Certificate connectors → Add`), sign in, and
confirm it reports healthy. (Skip this requirement entirely if you choose Path B.)

## 2.6 Microsoft Graph PowerShell (for Path A import + the reporting scripts)
**Description:** The Microsoft Graph PowerShell SDK on the admin workstation.
**Why:** `PFXMOB-Import-Pfx.ps1` imports the PFX via Graph; the discovery/validation/report scripts
read Intune state via Graph.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent to the required scopes
(`DeviceManagementConfiguration.Read.All`, and `DeviceManagementConfiguration.ReadWrite.All` for the
import/remediation scripts) on first connect.

## 2.7 The target app and its keychain requirement
**Description:** The iOS app that must consume the certificate, and its vendor-stated method for
accessing an identity (keychain access group / App Configuration key, or a custom profile it expects).
**Why:** Delivering the identity to the system keychain does not guarantee the app can read it; the
app vendor's required delivery method governs (see Overview, "App-use and the iOS keychain").
**Verify:** Check the app vendor's documentation for how the app expects the certificate to be
provided.
**Implement:** Follow the vendor's stated method; use the decision guide (Path A vs Path B) and, if
required, add an Intune **App Configuration policy** for the app. App-internal specifics are deferred
to the vendor.

## 2.8 Pilot and broad device groups
**Description:** Entra security groups `iOS App Cert – Pilot` (a few representative devices) and
`iOS App Cert – Broad` (the rest).
**Why:** Every deployment is piloted before fleet rollout.
**Verify:** Entra → **Groups**; both groups exist.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] iOS/iPadOS devices enrolled — `PFXMOB-Discovery.ps1`
- [ ] Third-party `.pfx`/`.p12` file + password in hand (password stored as a secret)
- [ ] Root/intermediate chain `.cer` files in hand
- [ ] Certificate Connector healthy (Path A only) — `PFXMOB-Discovery.ps1`
- [ ] Microsoft Graph PowerShell installed + scopes consented
- [ ] App vendor's keychain/App Configuration requirement understood
- [ ] `iOS App Cert – Pilot` and `iOS App Cert – Broad` groups created
