# 3. Implementation Guide — Entra Verified ID — Verifiable Credentials

Follow these steps in order, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`,
under **`Verified ID`**) and the **Azure portal** (`https://portal.azure.com`) for Key Vault. Stand up
the service, one credential type, one issuance flow, and one verification flow first; expand only after
the Testing Guide passes.

> Model: onboard the service and verify your domain, design one credential type, register the Request
> Service app, issue one credential to a wallet, verify it from a relying party, and revoke it —
> validated on a pilot before you expand. Verified ID feature/preview status is flagged *verify* — check
> current Microsoft documentation for your tenant before relying on any preview capability.
>
> Naming convention: every object uses `<Purpose> – <Scope> – <Stage>`. The pilot objects are:
> `Verified ID Signing Key – Issuer – Pilot` (Key Vault key, created during onboarding),
> `Verified Employee – HR Attributes – Pilot` (credential type),
> `VC Request Service App – Issuer/Verifier – Pilot` (app registration),
> `Issuance Flow – Verified Employee – Pilot`, and `Verification Flow – Helpdesk Access – Pilot`.
> Reuse these exact names in testing, troubleshooting, and the scripts. Replace `contoso.com` with your
> real domain.

## Step 1 — Assess prerequisites
1. Run `ENTVID-Discovery.ps1` to record whether Verified ID is available, whether an authority/issuer already exists, and the tenant/licensing context. Keep the output as your before-state.
2. Confirm the requirements: Azure Key Vault present, a host-controllable domain (`contoso.com`), and roles. Run `ENTVID-Validate.ps1` (some checks will legitimately fail until after onboarding — that is expected on the first pass).

## Step 2 — Create/prepare the Azure Key Vault
1. Azure portal (`portal.azure.com`) -> create (or choose) a Key Vault in the same tenant.
2. Grant the operator and the Verified ID onboarding process the documented key permissions (get, sign, and key create) via access policies or Azure RBAC key roles. Follow current Verified ID onboarding guidance for the exact set. The signing key created here will be `Verified ID Signing Key – Issuer – Pilot`.

## Step 3 — Onboard the Verified ID service and set up the trust system
1. Entra -> `Verified ID -> Setup` (or `Get started`).
2. Choose the trust system and complete onboarding; select the Key Vault from Step 2 when prompted. Onboarding provisions your organization's **DID** and signing keys.
3. Note the **issuer/authority** identifier shown after onboarding — the scripts and requests reference it. Run `ENTVID-Discovery.ps1` to confirm the authority now exists.

> *Verify:* the trust system options and any preview features shown during onboarding — confirm against
> current Microsoft Verified ID documentation for your tenant before choosing.

## Step 4 — Verify your domain
1. In `Verified ID`, set/confirm the **linked domain** (`https://contoso.com`).
2. Download the generated `did-configuration.json` and publish it at `https://contoso.com/.well-known/did-configuration.json` on a web server you control.
3. Back in `Verified ID`, verify the domain; confirm it shows Verified. Run `ENTVID-Validate.ps1` to confirm the well-known file resolves and matches your DID.

## Step 5 — Design the credential type (rules + display)
1. Entra -> `Verified ID -> Credentials -> Add a credential`.
2. Create `Verified Employee – HR Attributes – Pilot` (start from the Verified Employee template where suitable).
3. **Rules definition**: choose the attestation method — for a directory-backed credential, use the ID-token/Entra sign-in method so claims (name, job title, employment status) come from the signed-in user's directory record.
4. **Display definition**: set the card name, logo, colors, and claim labels shown in the wallet. Create/publish the credential type.

## Step 6 — Register the Request Service API app
1. Entra -> `App registrations -> New registration`; name it `VC Request Service App – Issuer/Verifier – Pilot`.
2. `API permissions -> Add a permission` -> add the **Verified ID Request Service** application permission and **grant admin consent**. *Verify the current permission name/ID for your tenant.*
3. `Certificates & secrets` -> create a certificate (preferred) or client secret. Record the client ID, tenant ID, and store the secret/certificate securely (never in source control).

## Step 7 — Issue a pilot credential (issuance flow)
1. Build the issuance request with `ENTVID-New-IssuanceRequest.ps1` in **build-only** mode (the default): it assembles and prints the issuance request payload for `Verified Employee – HR Attributes – Pilot` without submitting.
2. Review the payload; then re-run with `-Submit` to POST it to the Request Service API. The script returns a QR code URL / deep link.
3. On the pilot user's device, open Microsoft Authenticator, scan the QR code / follow the link, sign in and consent as the rules require; confirm the credential appears in the wallet. This is `Issuance Flow – Verified Employee – Pilot`.

## Step 8 — Verify the pilot credential (verification flow)
1. Build the presentation (verification) request with `ENTVID-New-PresentationRequest.ps1` in **build-only** mode (default): it assembles the presentation request for `Verified Employee – HR Attributes – Pilot`, pointing at your callback endpoint, without submitting.
2. Review the payload; re-run with `-Submit` to POST it. The script returns a QR code / deep link.
3. As the pilot holder, scan/open it in Authenticator and consent to present the credential; confirm your relying-party callback receives the verified claims and cryptographic proof. This is `Verification Flow – Helpdesk Access – Pilot`.

## Step 9 — Revoke and confirm governance
1. Entra -> `Verified ID -> Credentials`, open the issued credential, and **revoke** the pilot credential.
2. Re-run the verification flow (Step 8) and confirm a status-checking verifier now rejects the revoked credential. Run `ENTVID-Report.ps1` to see issued vs revoked state.

## Step 10 — Validate on the pilot scope
1. Confirm end to end: domain verified, credential type published, issuance to wallet works, verification returns verified claims, revocation is honored. Run `ENTVID-Validate.ps1` and complete the Testing Guide.

## Step 11 — Expand to production
1. Add more credential types (for example proof-of-training, contractor, or customer credentials) with their own rules/display, following the same pattern and naming.
2. Onboard more relying parties (verification flows), each with its own callback and requested claims.
3. Establish credential lifecycle policy (expiry, re-issuance cadence, revocation triggers) with your governance owners; keep the Request Service app's secret/certificate rotated.
4. Re-validate each change with `ENTVID-Validate.ps1` and `ENTVID-Report.ps1`.

---
### Order of operations
`Assess (Discovery/Validate) -> Key Vault -> Onboard service + DID -> Verify domain (well-known) -> Credential type (rules+display) -> Request Service app -> Issue to wallet (build then submit) -> Verify from relying party (build then submit) -> Revoke + confirm -> Validate -> Expand`
