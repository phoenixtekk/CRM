# Testing & Validation

Run these validations at the gates named in the Implementation Guide. Each has an explicit **pass/fail**
signal. Do not advance a phase until its tests pass. The provided validation and reporting scripts
(`Test-CloudAuthSignIn.ps1`, `Get-M365SignInMethodReport.ps1`) automate most of these read-only checks.

## T1. Assessment completeness (Phase 0 gate)

- **Procedure:** Confirm `Federation Assessment – M365 – Prod` contains: ADFS token-signing cert
  thumbprint(s) + expiry, the Entra-trusted `SigningCertificate` thumbprint, the Microsoft 365
  relying-party claims rules, **all** relying-party trusts, the current sign-in method, and
  directory-sync health.
- **Pass:** all present; ADFS primary token-signing thumbprint **matches** the Entra-trusted cert.
- **Fail:** any item missing, or the thumbprints **differ** (federation will break at token validation —
  fix per Track A2 before anything else).

## T2. Federated sign-in works (Track A)

- **Procedure:** From an internal client and (via WAP) an external client, sign in to
  `https://outlook.office.com` / `https://portal.office.com` with a federated user. Confirm the redirect
  to `https://<fed-service-name>/adfs/ls/` and successful return to Microsoft 365.
- **Pass:** sign-in succeeds internally **and** externally; the ADFS sign-in page renders.
- **Fail:** error at ADFS (see Troubleshooting — cert mismatch, claims, endpoint/WAP).

## T3. Token-signing certificate health (Track A)

- **Procedure:** `Get-AdfsCertificate -CertificateType Token-Signing` (record primary thumbprint +
  NotAfter); `Get-MgDomainFederationConfiguration -DomainId <domain>` (record trusted signing cert).
- **Pass:** primary ADFS token-signing thumbprint **equals** Entra's trusted thumbprint; **NotAfter >
  60 days** out.
- **Fail:** mismatch (Entra will reject tokens) or expiry within 60 days → run `Token-Signing Cert –
  ADFS – Rollover` (A2).

## T4. Federation metadata & endpoints reachable (Track A)

- **Procedure:** Retrieve
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` internally and via WAP.
- **Pass:** valid XML both paths; the certificate in the metadata matches the ADFS primary signing cert.
- **Fail:** unreachable/invalid → check ADFS service, WAP publishing, SSL cert, DNS.

## T5. Cloud sign-in for Staged Rollout pilot users (Track B, Pilot gate)

- **Procedure:** Have each `Staged Rollout – Pilot – Wave1` user sign in (browser + Outlook). Confirm
  **no ADFS redirect** occurs (they authenticate at `login.microsoftonline.com` directly). For PTA,
  confirm the PTA agent shows the auth. Use `Test-CloudAuthSignIn.ps1` to report each user's effective
  sign-in path.
- **Pass:** every pilot user authenticates via the cloud (PHS/PTA); Seamless SSO gives silent sign-in on
  the corpnet; Conditional Access parity policies apply.
- **Fail:** any pilot user still hits ADFS, or Seamless SSO prompts unexpectedly → verify Staged Rollout
  membership, `AZUREADSSOACC`, and browser intranet-zone settings; revert the user from Staged Rollout if
  needed.

## T6. Non-pilot users unaffected (Track B, Pilot gate)

- **Procedure:** Sign in as a **non-pilot** federated user during the pilot.
- **Pass:** they still authenticate via ADFS with no change.
- **Fail:** a non-pilot user changed path → the domain may have been converted prematurely; investigate
  before continuing.

## T7. Domain converted to managed (Track B, Expand)

- **Procedure:** `Get-MgDomain -DomainId <domain>` and check `AuthenticationType`. Sign in as a
  previously federated (non-pilot) user.
- **Pass:** `AuthenticationType = Managed`; all users now authenticate in the cloud; no ADFS redirect.
- **Fail:** still `Federated`, or users error → re-check the conversion; rollback = re-federate
  (ADFS still running).

## T8. Legacy/rich-client and modern-auth clients still work (Track B)

- **Procedure:** Test Outlook (modern auth), a mobile mail client, and any known **legacy-auth**
  dependency. Confirm no broken sign-in after conversion.
- **Pass:** all supported clients authenticate; MFA/Conditional Access behaves as designed.
- **Fail:** a client breaks → check its auth method and Conditional Access; legacy-auth clients that
  relied on ADFS behavior may need reconfiguration.

## T9. No orphaned relying party before decommission (Track B, Decommission gate)

- **Procedure:** Review the relying-party inventory from Phase 0; confirm every non-Microsoft-365
  relying party has been migrated/re-homed.
- **Pass:** only Microsoft 365 depended on ADFS, or all others are migrated.
- **Fail:** an active relying party remains → **do not** decommission ADFS; re-home it first.

## T10. Post-decommission sign-in stability (Track B)

- **Procedure:** After removing ADFS/WAP, monitor sign-in logs (Entra sign-in logs) across a full
  business cycle. Confirm no failures reference the retired federation service.
- **Pass:** clean sign-ins; no references to `sts.<domain>` / ADFS; all domains `Managed`.
- **Fail:** any dependency surfaces → the ADFS servers should still be **parked** (per B4) to restore.
