# Implementation Guide

This guide follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — and
splits into two tracks after assessment:

- **Track A — Deploy / troubleshoot ADFS federation** (keep federation; make it healthy).
- **Track B — Migrate to managed authentication and decommission ADFS** (retire federation).

Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and reused verbatim in
testing, troubleshooting, and the scripts. **Pilot-first with rollback** — auth changes affect sign-in
for every federated user.

> **Cloud endpoints.** Commercial paths are shown. On **GCC High / DoD**, substitute
> `portal.azure.us`, `login.microsoftonline.us`, and `admin.exchange.microsoft.us`, and **verify Staged
> Rollout / managed-auth availability for your cloud** first.
>
> **Cmdlet currency.** `Update-MgDomain` / `Get-MgDomainFederationConfiguration` (Microsoft Graph) are
> the current cmdlets; MSOnline (`Set-MsolDomainAuthentication`, `Update-MSOLFederatedDomain`) is
> **legacy/deprecated** and shown only where an operator may still encounter it — **verify availability
> in your tenant**. Domain conversion is best driven from the **Microsoft Entra Connect** wizard.

---

## Phase 0 — Assess (read-only, both tracks)

**Goal:** produce `Federation Assessment – M365 – Prod` — a factual snapshot of the current state.

1. **Inventory the ADFS farm and WAP.** On a federation server:
   - `Get-AdfsProperties` — note `HostName` (the federation service name, e.g. `sts.<domain>`),
     `AutoCertificateRollover`, and the endpoints.
   - `Get-AdfsCertificate -CertificateType Token-Signing` — record the **thumbprint** and **NotAfter**
     (expiry) of the primary (and any secondary) token-signing certificate.
   - `Get-AdfsRelyingPartyTrust` — confirm the **Microsoft 365 / Azure AD** relying-party trust exists
     and note its **issuance transform (claims) rules** and **Access Control Policy**.
   - Identify **all other relying-party trusts** on the farm (they matter at decommission).
   - Note the **WAP** servers publishing ADFS and their certificate expiry.
2. **Inventory the Entra federation trust.** Using Microsoft Graph PowerShell (`Connect-MgGraph -Scopes
   Domain.Read.All`): `Get-MgDomainFederationConfiguration -DomainId <domain>` — record the
   `IssuerUri`, `PassiveSignInUri`, `MetadataExchangeUri`, and the **SigningCertificate** Entra currently
   trusts. Compare its thumbprint to the ADFS token-signing cert from step 1.
3. **Inventory sign-in method and directory sync.** In the Entra Connect wizard, note the current **user
   sign-in** method. Confirm directory sync is healthy (Synchronization Service Manager, recent success).
   List which domains are **Federated** vs **Managed** (`Get-MgDomain`).
4. **Record certificate health.** Flag any token-signing or WAP/SSL certificate expiring within the next
   **60 days** as a priority.

> Run the **discovery script** (`Get-M365FederationAssessment.ps1`) to produce this snapshot
> automatically (read-only).

**Assess gate (pass/fail):** you have a complete `Federation Assessment – M365 – Prod` showing the ADFS
cert thumbprints, the Entra-trusted signing cert, the claims rules, all relying-party trusts, the current
sign-in method, and directory-sync health. **Fail** = missing any of these → do not proceed.

---

## Phase 1 — Design (both tracks)

Decide the **track** and record the design:

- **Track A (keep federation):** you will repair claims/certs/endpoints and put token-signing cert
  rollover on a managed cadence. Record the target `Token-Signing Cert – ADFS – Rollover` plan.
- **Track B (migrate):** choose the managed method — **PHS** (recommended default) or **PTA** — as
  `Sign-In Method – Cloud – Target`. Map every ADFS access-control/MFA rule to an **Entra Conditional
  Access** policy (requirement R6). Define `Staged Rollout – Pilot – Wave1` (the pilot group) and the
  order of `Domain Conversion – <domain> – Managed` and `Decommission – ADFS/WAP – Prod`.

**Design gate:** the track is chosen, the rollback for each planned change is written down, and (Track B)
Conditional Access parity is authored in **report-only**. **Fail** = no rollback documented.

---

## Track A — Deploy / troubleshoot ADFS federation

### A1 — Repair / verify claims (issuance transform) rules

For the Microsoft 365 relying-party trust, the issuance transform rules must emit the required claims:
the **UPN**, the **ImmutableID** (from the sourceAnchor, base64 of the AD `objectGUID` by default), and
the **issuerId** matching the Entra federation trust. In **ADFS Management → Relying Party Trusts →
(Microsoft 365) → Edit Claim Issuance Policy**, confirm the standard Microsoft 365 rule set is present
and unmodified except for intended customizations. If corrupted, re-create from Microsoft's published
Microsoft 365 claim-rule set (the `Convert-MSOLFederatedUser` / Entra Connect-generated rules).

- **Rollback:** before editing, export the current rules
  (`(Get-AdfsRelyingPartyTrust -Name "<name>").IssuanceTransformRules > rules-backup.txt`); restore on
  failure.

### A2 — Roll the token-signing certificate (`Token-Signing Cert – ADFS – Rollover`)

The token-signing certificate expiring (or rolling) without Entra being updated is the classic outage.

1. **Determine rollover mode.** `(Get-AdfsProperties).AutoCertificateRollover`:
   - **`True` (auto):** ADFS generates a new self-signed token-signing cert automatically before expiry.
     You still must **update Entra's federation metadata** so Entra trusts the new cert.
   - **`False` (manual/enterprise CA cert):** you add the new cert yourself.
2. **Generate/promote the new cert.** For auto mode, force generation with
   `Update-AdfsCertificate -CertificateType Token-Signing -Urgent` **only in a maintenance window**
   (`-Urgent` promotes immediately and can disrupt in-flight sessions). For manual mode, import the new
   cert and `Set-AdfsCertificate` as secondary, then promote to primary.
3. **Update Microsoft Entra with the new signing cert.** Because the Microsoft 365 federation trust
   pulls from ADFS metadata, refresh it so Entra trusts the new certificate. Either:
   - **Preferred:** run the Entra Connect wizard's federation-management task to update the trust, or
   - Use Microsoft Graph: `Update-MgDomainFederationConfiguration` with the new `SigningCertificate`
     (base64 public cert) and matching endpoints. **Legacy equivalent:** `Update-MSOLFederatedDomain
     -DomainName <domain>` (MSOnline — deprecated; verify availability).
4. **Validate** immediately (Phase 5 tests): federated sign-in works and Entra's trusted cert thumbprint
   equals the ADFS primary token-signing thumbprint.

- **Rollback:** keep the previous cert as a **secondary** signing cert in ADFS (ADFS can sign with, and
  Entra can trust, two certs during overlap) until the new one is proven; revert the Entra trust to the
  prior metadata if sign-in fails.

> Use `Invoke-TokenSigningCertRollover.ps1 -WhatIf` to preview the rollover steps and the Entra update
> without changing anything.

### A3 — Verify endpoints, metadata, and WAP

- Confirm the federation metadata is reachable:
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` returns valid XML
  internally and (via WAP) externally.
- Confirm the ADFS sign-in page loads at `https://<fed-service-name>/adfs/ls/idpinitiatedsignon`
  (enable `IdpInitiatedSignonPage` if used) and through WAP from the extranet.
- On WAP: confirm the published web application for ADFS is healthy and its SSL cert is valid.

**Track A gate:** federated sign-in works internally and externally; Entra's trusted signing cert matches
ADFS primary; metadata resolves; no cert expires within 60 days. **Fail** = any check red → resolve
before closing the change.

---

## Track B — Migrate to managed authentication and decommission ADFS

### B1 — Configure the target sign-in method (Configure; domain stays federated)

1. **Enable PHS (recommended, or as PTA backup).** In the Entra Connect wizard → **Change user sign-in**
   → select **Password Hash Synchronization** (or **Pass-through Authentication**). Enabling PHS here
   **does not** change the federated domain's live sign-in — it makes the hashes available so Staged
   Rollout / conversion can use them. For **PTA**, install **two or more PTA agents** (R5).
2. **Enable Seamless SSO.** In the same wizard, tick **Enable single sign-on** and provide Domain Admin
   credentials to create the `AZUREADSSOACC` computer object. Push the browser intranet-zone settings
   (`https://autologon.microsoftazuread-sso.com`) via Group Policy so domain-joined clients get silent
   sign-in.
3. Confirm in Entra ID → **Connect** that PHS/PTA and Seamless SSO show **enabled/healthy**.

- **Rollback:** disabling PHS/Seamless SSO in the wizard reverts these; the domain is still federated, so
  live sign-in is unaffected at this stage.

### B2 — Pilot with Staged Rollout (`Staged Rollout – Pilot – Wave1`)

**Staged Rollout moves selected users to cloud auth while the domain stays federated** — reversible.

1. In **Entra admin center → Identity → Hybrid management → Microsoft Entra Connect → Connect Sync →
   Enable Staged Rollout for managed user sign-in**, toggle on **Password Hash Sync** (or **Pass-through
   authentication**) and **Seamless single sign-on**.
2. **Add the pilot group** to the rollout as `Staged Rollout – Pilot – Wave1`. Only those users now
   authenticate through the cloud; everyone else stays on ADFS.
3. Have pilot users sign in to Microsoft 365 (browser and Outlook). Confirm they authenticate via the
   cloud (no ADFS redirect) — see Phase 5 tests and `Test-CloudAuthSignIn.ps1`.

**Pilot gate:** every pilot user signs in via cloud auth (PHS/PTA), Seamless SSO works on the corpnet,
Conditional Access parity policies apply, and **non-pilot** users are unaffected on ADFS. **Fail** =
remove the user/group from Staged Rollout (instant revert) and fix before proceeding.

### B3 — Validate then Expand: convert the domain (`Domain Conversion – <domain> – Managed`)

Once the pilot passes, convert the domain from **federated → managed** so **all** users move to cloud
auth:

1. **Preferred:** run the **Entra Connect wizard → Change user sign-in →** select the target method and
   let the wizard **convert the domain** (it updates the domain authentication type and cleans up the
   federation trust). Do this in the change window.
2. **PowerShell alternative:** `Update-MgDomain -DomainId <domain> -AuthenticationType "Managed"`
   (Microsoft Graph). **Legacy equivalent:** `Set-MsolDomainAuthentication -DomainName <domain>
   -Authentication Managed` (MSOnline — deprecated; verify availability).
3. **Remove Staged Rollout** for that method afterwards (with the domain managed, the whole domain is on
   cloud auth; leaving Staged Rollout configured is redundant).
4. Allow time for propagation; validate broadly (Phase 5).

- **Rollback:** re-federate the domain by re-running the Entra Connect federation task (or
  `Update-MgDomain -AuthenticationType "Federated"` with the ADFS trust settings) — **keep ADFS running
  until the managed conversion is proven stable across a full business cycle.**

Use `Invoke-DomainConversionPlan.ps1 -WhatIf` to preview the conversion (and Staged Rollout state)
without changing anything.

### B4 — Decommission ADFS / WAP (`Decommission – ADFS/WAP – Prod`)

**Only after** all federated domains are converted, validated, and stable, and **all other
relying-party trusts** have been re-homed:

1. Confirm **no domain** is still federated (`Get-MgDomain` → all `Managed`) and no other relying party
   depends on the farm.
2. **Decommission in order:** remove WAP publishing → take ADFS servers out of the load balancer →
   monitor for any sign-in dependency for a soak period → uninstall ADFS / retire the servers → remove
   the ADFS DNS records (`sts.<domain>`) and the ADFS SSL/token certs from certificate stores.
3. Remove any now-unused ADFS service account and firewall rules.

**Decommission gate:** all domains managed, sign-in healthy through a full business cycle, no relying
party orphaned, ADFS/WAP servers retired, DNS/records cleaned. **Fail** = keep ADFS parked (not
uninstalled) until the dependency is resolved.

---

## Rollback summary

| Change | Rollback |
|---|---|
| Claims-rule edit (A1) | Restore exported rules to the relying-party trust |
| Token-signing rollover (A2) | Keep prior cert as secondary; revert Entra trust metadata |
| PHS/Seamless SSO enable (B1) | Disable in Entra Connect wizard (domain still federated) |
| Staged Rollout pilot (B2) | Remove user/group from Staged Rollout (instant per-user revert) |
| Domain conversion (B3) | Re-federate domain via Entra Connect; ADFS still running |
| ADFS decommission (B4) | Keep ADFS parked, not uninstalled, until stable |
