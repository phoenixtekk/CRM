# 7. Best Practices — Entra Verified ID — Verifiable Credentials

- Protect the signing keys like the crown jewels. Your DID's signing keys in Azure Key Vault are the root of trust for every credential you issue. Restrict Key Vault access to the minimum, prefer Azure RBAC key roles, enable logging, and never export the keys.
- Verify your domain and keep the well-known file live. The `did-configuration.json` at `https://contoso.com/.well-known/` is how verifiers see a trustworthy, human-readable issuer. Monitor that it stays published and valid; a missing or stale file undermines trust in your credentials.
- Use a certificate, not a secret, for the Request Service app — and rotate it. The `VC Request Service App – Issuer/Verifier – Pilot` credential authorizes issuance and verification; prefer a certificate, store it securely (never in source control), and rotate on a schedule.
- Build requests before you submit them. The issuance and verification scripts default to build-only for a reason: review the assembled payload (claims requested, callback, PIN options) before you `-Submit`, so you never issue or request something unintended.
- Request the minimum claims. Privacy is a feature of Verified ID — design verification flows to request only the claims the decision needs (selective disclosure), and make consent explicit. Do not collect attributes you cannot justify.
- Design credential types deliberately. Give each credential a clear purpose, a correct attestation method (directory-backed vs self-attested vs presentation-backed), a sensible expiry, and clean display branding. Start from the Verified Employee pattern where it fits.
- Plan revocation and lifecycle up front. Decide what triggers revocation (offboarding, role change, compromise), set credential expiry, and define a re-issuance cadence — with your governance owners, not ad hoc.
- Keep the pilot to one credential type and one relying party. Prove issuance, verification, and revocation end to end on a small scope before expanding to more credentials and verifiers.
- Confirm the holder's wallet path. Ensure pilot holders have Microsoft Authenticator and can scan a QR / open a deep link before you run an issuance; most first-run failures are wallet/connectivity, not the service.
- Do not assume Verified ID is authoritative by itself. A credential proves what the issuer asserted; whether it is sufficient for a given access or onboarding decision is a governance decision you own.
- Verify feature and preview status for your tenant. Verified ID capabilities, premium options, and any preview features can change and vary by cloud — verify current availability and licensing against Microsoft documentation for your tenant before you depend on a capability.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for keys, credential types, apps, and flows so audits and expansion are repeatable.
- Pilot before you expand, and keep a rollback path. Validate the full loop (issue -> verify -> revoke) before rollout; keep the ability to revoke and re-issue.

## Where to go next (adjacent catalog areas)
- **Zero Trust Conditional Access (`ENTZTCA`)** — the Conditional Access baseline; explore using a Verified ID presentation as a signal/authentication context where supported (*verify current availability*).
- **Entra ID Governance (`ENTIGA`)** — entitlement management and access reviews that can consume a Verified ID-backed onboarding or access decision.
- **External Identities / B2B (`ENTB2B`)** — onboard and prove external users; Verified ID is a strong way to establish trust in a partner or contractor identity.
- **Passwordless / passkey (`ENTPASSKEY`)** and **Privileged Identity Management (`ENTPIM`)** — strengthen the authentication and privileged-access model around the identities you now verify.
- **Enterprise-app / service-principal governance** — govern the Request Service app and any relying-party apps you register.
