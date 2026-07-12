# 1. Solution Overview — Entra Verified ID — Verifiable Credentials

## What Entra Verified ID is
Microsoft Entra Verified ID is Microsoft's implementation of **verifiable credentials** — an open
standard (W3C Verifiable Credentials and Decentralized Identifiers) for issuing and verifying
tamper-evident digital claims about a person or organization. Instead of verifying identity or
attributes by phone, email, or a portal look-up, an **issuer** cryptographically signs a credential and
gives it to the subject; the subject stores it in a **wallet** (Microsoft Authenticator); and any
**verifier** (relying party) can request that credential and confirm, mathematically, that it was
issued by a trusted issuer, has not been tampered with, and has not been revoked — without contacting
the issuer.

Three roles define the model:
- **Issuer** — your organization signs and issues credentials (for example a *Verified Employee*
  credential asserting name, job title, and that the person is employed).
- **Holder** — the person who receives the credential into their wallet and consents to present it.
- **Verifier / relying party** — an app or service that requests a credential and verifies it to make
  a decision (grant access, complete onboarding, prove eligibility).

## How it works
1. You **onboard the Verified ID service** in your Entra tenant. Onboarding provisions a **trust
   system** and a **decentralized identifier (DID)** for your organization — the cryptographic identity
   that signs your credentials — with signing keys held in **Azure Key Vault**.
2. You **verify your domain** (for example `contoso.com`). Verified ID publishes a
   `did-configuration.json` at your domain's `/.well-known/` path linking your DID to your domain, so
   verifiers see a human-readable, domain-anchored issuer instead of an opaque identifier.
3. You **design a credential type**: a **rules definition** (what claims the credential carries and how
   the subject is attested — for example by signing in with their Entra account, so claims come from
   the directory) and a **display definition** (how the credential looks in the wallet — name, logo,
   colors, claim labels).
4. **Issuance flow**: your issuance app calls the **Request Service API** to create an issuance
   request; the person scans a QR code or follows a deep link, signs in / attests as the rules require,
   consents, and the credential lands in their Authenticator wallet.
5. **Verification flow**: a relying party calls the Request Service API to create a **presentation
   request** for a credential type; the person is shown a QR code / deep link, consents in the wallet,
   and presents the credential; the relying party's callback receives the verified claims and the
   cryptographic proof.
6. **Governance**: you can **revoke** an issued credential (so verifiers that check status reject it),
   manage credential **lifecycle** (expiry, re-issuance), and rely on the model's **privacy**
   properties — the holder consents to each presentation and shares only the requested claims (selective
   disclosure), and the issuer is not contacted during verification.

## How this fits the rest of the identity catalog (gap-only)
This solution stands up **Verified ID** end to end and references adjacent capabilities rather than
duplicating them:
- **Conditional Access** (`ENTZTCA`) — Verified ID can serve as a signal/authentication context in
  some scenarios; this solution builds the credential capability and points to `ENTZTCA` for the CA
  baseline. Using a Verified ID presentation inside a Conditional Access flow is an evolving area —
  *verify current availability in your tenant*.
- **Entra ID Governance / entitlement management** (`ENTIGA`) — Verified ID can support onboarding and
  access decisions that governance then enforces; the governance build-out lives in `ENTIGA`.
- **External Identities / B2B** (`ENTB2B`) — Verified ID is a way to onboard and prove external users;
  the cross-tenant collaboration plane is `ENTB2B`.
- **Privileged Identity Management** (`ENTPIM`), **passwordless / passkey** (`ENTPASSKEY`), **hybrid
  identity**, and **enterprise-app governance** are separate catalog areas referenced where relevant.

## What you can control
- The Verified ID service onboarding, the organization DID and its Key Vault signing keys, and domain
  verification (`did-configuration.json`).
- Credential types — rules definitions (claims and attestation method: ID-token/Entra sign-in,
  self-attested input, or presentation of another credential) and display definitions (branding and
  claim labels).
- The issuance flow (which app issues, to whom, with which PIN/security options).
- The verification flow (which credential types are accepted, which claims are requested, the callback
  endpoint).
- Governance — credential revocation, expiry/lifecycle, and the privacy posture (claims requested,
  consent).

## Benefits
- Tamper-evident and phishing-resistant — a credential is cryptographically signed; a verifier proves
  authenticity mathematically, not by trusting a screenshot or an email.
- Verify without a callback — verifiers confirm a credential without contacting the issuer, so
  verification is fast and works across organizational boundaries.
- Privacy by design — the holder consents to each presentation and shares only the requested claims;
  the issuer does not learn where the credential is used.
- Portable and reusable — one issued credential can be presented to many verifiers for onboarding,
  proof of employment, help-desk identity proofing, and access.
- Revocable — a credential can be revoked when it should no longer be trusted.

## Limitations (be honest with buyers)
- Verified ID requires **Azure Key Vault**, a **verified domain** you control, and an **app
  registration** with permission to call the Request Service API; these prerequisites must be in place
  before issuance works (see requirements).
- Licensing and availability: Verified ID capabilities and any premium/preview features may depend on
  Entra ID licensing and may be in **preview** or vary by cloud — **the Verified ID feature set and
  preview status must be verified for your tenant** (*verify current availability in your tenant*).
- The holder needs a **wallet** (Microsoft Authenticator) and connectivity to receive and present
  credentials.
- Verified ID proves *what the issuer asserted*; it does not, by itself, decide whether a given
  credential is authoritative for a given decision — that governance decision belongs to you.
- This solution does not make regulatory, data-classification, lawful-claims, or acceptable-use
  decisions — those belong to your compliance, legal, and security functions.

## Authentication and connections used
- Portal work is done in the Microsoft Entra admin center (`https://entra.microsoft.com`, under
  Verified ID) and the Azure portal (`https://portal.azure.com`) for Key Vault.
- Discovery/validation scripts use the **Microsoft Graph PowerShell SDK** (`Connect-MgGraph`) with
  read-only scopes.
- The issuance and verification scripts call the **Verified ID Request Service API** using an
  app-registration token (client credentials); those scripts **build the request and only submit when
  explicitly told**, so a dry run never issues or requests anything.

## The standard deployment model
> Assess prerequisites and tenant readiness -> Configure the Verified ID service, domain, credential
> type, and Request Service app -> Pilot: issue one credential to a wallet and verify it from a relying
> party -> Validate issuance, verification, and revocation -> Expand to more credential types and
> relying parties.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
