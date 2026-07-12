# 2. Requirements Guide — Entra Verified ID — Verifiable Credentials

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant, base licensing, admin roles, break-glass
accounts, network access) are in `global-requirements-entra-id-solutions.md` and are not repeated here.

> The Verified ID feature set, premium options, and any preview capabilities are flagged **verify** —
> confirm current availability and the feature-to-license mapping in *your* tenant before you rely on
> them; Microsoft changes these over time.

## 2.1 Verified ID availability and licensing — verify
Description: Entra Verified ID available in your tenant, with any licensing it requires for the features you use.
Why: Verified ID is administered from the Entra admin center and depends on the service being available and appropriately licensed; some capabilities may be premium or preview.
Verify: Entra -> `Verified ID` appears in the admin center; you can start onboarding. Run `ENTVID-Discovery.ps1`. *Verify current Verified ID availability and licensing in your tenant.*
Implement: Confirm the tenant has Verified ID; assign any required Entra ID licensing (commonly Entra ID P1/P2 for the identity plane) to the administrators; check Microsoft's current Verified ID documentation for the precise licensing and any preview flags at the time you deploy.

## 2.2 Administrative roles for the operator
Description: A `Global Administrator` for the one-time Verified ID onboarding and consent, and an `Authentication Policy Administrator` (or equivalent) plus Key Vault permissions for ongoing configuration.
Why: Onboarding the Verified ID service and granting the app permissions requires elevated rights; Key Vault key operations require Key Vault access.
Verify: Entra -> `Roles and administrators`; confirm the operator can onboard Verified ID and administer the Request Service app. Run `ENTVID-Discovery.ps1`.
Implement: Assign the required roles for onboarding; grant the operator Key Vault access (see 2.3); reserve `Global Administrator` for the one-time onboarding consent.

## 2.3 Azure Key Vault for signing/encryption keys
Description: An Azure Key Vault in the same tenant, with access for the Verified ID service to create and use signing and encryption keys.
Why: Verified ID stores the keys that sign your credentials and your DID in Key Vault; without it the service cannot be onboarded.
Verify: Azure portal (`portal.azure.com`) -> the Key Vault exists; the operator (and the Verified ID service principal) have the required key permissions (get, sign, and key create as documented). Run `ENTVID-Validate.ps1`.
Implement: Create a Key Vault; grant the Verified ID onboarding process and operator the documented key permissions (access policies or Azure RBAC key roles). Follow the current Verified ID onboarding guidance for the exact permission set.

## 2.4 A verified, controllable domain
Description: A public domain you control (for example `contoso.com`) where you can publish a file at `/.well-known/did-configuration.json`.
Why: Domain verification links your DID to a human-readable domain so verifiers trust the issuer; it requires publishing a well-known configuration file at your domain.
Verify: You can host content at `https://contoso.com/.well-known/did-configuration.json`; the domain is reachable over HTTPS. Run `ENTVID-Validate.ps1` after onboarding to confirm the file resolves.
Implement: Choose the domain that will represent your issuer; ensure you can publish the `did-configuration.json` Verified ID generates to its `/.well-known/` path (web server or hosting you control). Avoid using a domain you cannot host files on.

## 2.5 App registration for the Request Service API
Description: A Microsoft Entra app registration with a client secret/certificate and permission to call the Verified ID **Request Service API**.
Why: The issuance and verification flows (and the two request-builder scripts) authenticate to the Request Service API with this app's client credentials.
Verify: Entra -> `App registrations`; the app exists with the Verified ID Request Service permission granted (admin-consented) and a valid secret/certificate. Run `ENTVID-Validate.ps1`. *Verify the current API permission name/ID in your tenant.*
Implement: Register an app; add and admin-consent the Verified ID Request Service API permission; create a client secret or (preferred) a certificate; record the client ID, tenant ID, and the authority/issuer authority for the scripts. Store the secret securely — never in the repo or in source control.

## 2.6 Microsoft Authenticator wallet for the pilot holder
Description: A test user with Microsoft Authenticator installed to receive and present the pilot credential.
Why: Credentials are issued to and presented from a wallet; without one you cannot complete an issuance or verification.
Verify: The pilot user has Authenticator installed and can scan a QR code / open a deep link. 
Implement: Install Microsoft Authenticator on the pilot user's device before the pilot issuance.

## 2.7 A pilot credential design and a relying-party endpoint
Description: A defined pilot credential type (for example *Verified Employee* with name, job title, employment status) and a callback endpoint for the verification flow.
Why: Issuance needs a credential type with rules/display; verification needs a callback URL where the Request Service posts the verified result.
Verify: You have decided the pilot credential's claims and attestation method, and you have an HTTPS callback endpoint reachable by the Request Service. Run `ENTVID-New-PresentationRequest.ps1` (build-only) to confirm the request payload assembles.
Implement: Design the pilot credential (start with the built-in Verified Employee pattern where suitable) and stand up (or reuse) an HTTPS callback endpoint for the verification result; keep the pilot to one credential type and one relying party.

## 2.8 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation.
Why: The discovery/validation/report scripts call Microsoft Graph and Verified ID admin/authority data.
Verify: `Get-Module Microsoft.Graph.Authentication -ListAvailable` returns a version; `Connect-MgGraph` connects to `graph.microsoft.com`. Run `ENTVID-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`.

---
## Checklist
- [ ] Verified ID available + licensing confirmed — `ENTVID-Discovery.ps1` · *verify*
- [ ] Operator holds onboarding/admin roles + Key Vault access
- [ ] Azure Key Vault created with the documented key permissions — `ENTVID-Validate.ps1`
- [ ] A verified, host-controllable domain for `did-configuration.json` — `ENTVID-Validate.ps1`
- [ ] App registration with Request Service API permission + secret/cert — `ENTVID-Validate.ps1` · *verify*
- [ ] Pilot holder has Microsoft Authenticator
- [ ] Pilot credential design + relying-party callback endpoint decided
- [ ] Graph PowerShell SDK present; `Connect-MgGraph` connects
