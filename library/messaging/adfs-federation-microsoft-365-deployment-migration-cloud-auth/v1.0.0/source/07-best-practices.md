# Best Practices

Durable practices for running ADFS federation for Microsoft 365 and for migrating to managed cloud
authentication.

## Federation health (while you keep ADFS)

- **Track the token-signing certificate like a production expiry.** Its lapse is the single most common
  federation outage. Alert **60+ days** before `NotAfter`, and always keep the previous cert as a
  **secondary** signing cert during rollover overlap so Entra can validate tokens signed by either.
- **Keep AutoCertificateRollover behavior explicit.** Know whether `AutoCertificateRollover` is `True`
  (ADFS self-generates) or `False` (you manage an enterprise-CA cert). In auto mode you **still** must
  refresh the Microsoft Entra federation trust when the cert rolls — automate that refresh.
- **Never edit the Microsoft 365 claims rules blind.** Export the issuance transform rules before any
  change; the Microsoft 365 rule set (UPN, ImmutableID, issuerId) must stay intact or sign-in breaks.
- **Front the extranet with WAP, not by exposing ADFS directly.** Keep WAP and ADFS SSL certs on the same
  expiry cadence as the token-signing cert review.
- **Monitor federation metadata reachability** internally and externally as a synthetic check.

## Choosing and running managed auth

- **Prefer PHS as the default.** It removes the on-premises sign-in dependency and enables
  **leaked-credential detection**. Use **PTA** only when policy forbids syncing password hashes — and
  then deploy **multiple PTA agents** and enable **PHS as a backup** sign-in method so a single agent
  outage can't stop sign-in.
- **Add Seamless SSO** with either method to preserve the domain-joined silent-sign-in experience users
  expect from ADFS; roll the **Kerberos decryption key** for `AZUREADSSOACC` on a schedule.
- **Establish Conditional Access parity before conversion.** Recreate every ADFS access-control/MFA rule
  as an Entra Conditional Access policy and validate it in **report-only** first. Converting a domain
  without this **silently drops** those controls.

## Migration discipline

- **Always pilot with Staged Rollout first.** It is the reversible, per-user proof of the target path
  while the domain stays federated. Validate the pilot fully before converting the domain.
- **Convert with the Entra Connect wizard** where possible — it updates the domain type and cleans up the
  federation trust in one supported operation — rather than hand-editing with deprecated MSOnline cmdlets.
- **Keep ADFS parked, not deleted, until proven.** After conversion, leave ADFS/WAP running (able to
  re-federate) across a full business cycle before decommissioning.
- **Inventory every relying-party trust before decommission.** ADFS often serves apps beyond Microsoft
  365; retiring the farm breaks them all. Re-home the others first.

## Tooling & security hygiene

- **Use current cmdlets.** Prefer **Microsoft Graph PowerShell** (`Update-MgDomain`,
  `Get-MgDomainFederationConfiguration`) and the **Entra Connect** wizard; treat **MSOnline / AzureAD**
  as deprecated and verify availability before relying on them.
- **No credentials in scripts.** Connect interactively with `Connect-MgGraph` / `Connect-ExchangeOnline`
  using modern auth/MFA. Run change helpers with `-WhatIf` first; require an explicit `-Commit`/`-Apply`
  to write.
- **Change control for every auth change.** Mail flow and authentication are high-impact; every change
  goes through a window with a written, tested rollback.
- **Mind the cloud boundary.** On **GCC High / DoD**, use the `.us` portal/endpoints and verify Staged
  Rollout / managed-auth availability for your sovereign cloud before starting.
