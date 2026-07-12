# 5. Testing Guide — Entra Verified ID — Verifiable Credentials

Run after the pilot is configured (Implementation Step 10) and after each expansion. Do portal checks
at `https://entra.microsoft.com` (Verified ID) and `https://portal.azure.com` (Key Vault); the
discovery/validation scripts connect to Microsoft Graph, and the request-builder scripts call the
Verified ID Request Service API only when you pass `-Submit`.

## Test 0 — Service and prerequisites confirmed
Do: Run `ENTVID-Discovery.ps1` and `ENTVID-Validate.ps1`.
Expected: Discovery shows Verified ID available and an issuer/authority onboarded; Validate confirms Key Vault access, the app registration with the Request Service permission, and the domain well-known file. A failure points to the exact prerequisite to fix.

## Test 1 — Domain is verified (well-known resolves)
Do: Browse `https://contoso.com/.well-known/did-configuration.json`; in `Verified ID` confirm the linked domain shows Verified; or run `ENTVID-Validate.ps1`.
Expected: The `did-configuration.json` resolves over HTTPS and links to your DID; the portal shows the domain Verified.

## Test 2 — Credential type is published
Do: Entra -> `Verified ID -> Credentials`; confirm `Verified Employee – HR Attributes – Pilot` exists with rules and display; or run `ENTVID-Discovery.ps1`.
Expected: The credential type is present and published, with the intended claims and display.

## Test 3 — Issuance request builds safely (no submit)
Do: Run `ENTVID-New-IssuanceRequest.ps1` with no `-Submit`.
Expected: The issuance request payload is assembled and printed; nothing is submitted to the Request Service API and no credential is issued (build-only is the default).

## Test 4 — Credential issues to the wallet
Do: Re-run `ENTVID-New-IssuanceRequest.ps1 -Submit`; on the pilot device, scan the QR/deep link in Microsoft Authenticator and complete sign-in/consent.
Expected: The credential `Verified Employee – HR Attributes – Pilot` appears in the wallet with the correct claims.

## Test 5 — Verification returns verified claims
Do: Run `ENTVID-New-PresentationRequest.ps1 -Submit`; as the holder, present the credential in Authenticator; check the relying-party callback.
Expected: The callback receives the verified claims and a valid cryptographic proof (issuer trusted, not tampered, not revoked). Consent was requested in the wallet and only the requested claims were shared.

## Test 6 — Revocation is honored
Do: Revoke the pilot credential in `Verified ID -> Credentials`; re-run the verification flow (`ENTVID-New-PresentationRequest.ps1 -Submit`).
Expected: A status-checking verifier rejects the revoked credential; `ENTVID-Report.ps1` shows it as revoked.

## Test 7 — Issued/revoked report
Do: Run `ENTVID-Report.ps1`.
Expected: A clear picture of the credential types, issuance activity, and revoked credentials (subject to the reporting/logging available in your tenant), read-only.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Test 0 confirms prerequisites; Tests 1-5 pass — domain verified, credential published, issuance builds safely then issues to a wallet, and verification returns verified claims with consent |
| Expand pass | Test 6 (revocation honored) and Test 7 (report) pass before adding more credential types and relying parties |
