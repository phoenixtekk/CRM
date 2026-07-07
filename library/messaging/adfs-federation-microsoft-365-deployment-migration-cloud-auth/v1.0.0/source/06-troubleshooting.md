# Troubleshooting

Common failure modes for ADFS federation for Microsoft 365 and for the migration to managed auth, with
resolutions. Symptoms are grouped; work top-down.

## Federation sign-in fails for all users

**Symptom:** every federated user gets an error at the ADFS sign-in page or an "invalid token" style
failure returning to Microsoft 365.

- **Token-signing certificate mismatch/expiry (the #1 cause).** Entra rejects tokens signed with a cert
  it no longer trusts. Compare the ADFS primary token-signing thumbprint (`Get-AdfsCertificate
  -CertificateType Token-Signing`) with the Entra-trusted cert (`Get-MgDomainFederationConfiguration
  -DomainId <domain>`). If they differ or the cert expired, run the `Token-Signing Cert – ADFS –
  Rollover` (Implementation A2 / `Invoke-TokenSigningCertRollover.ps1`) and refresh the Entra trust.
- **ADFS or WAP service down / SSL cert expired.** Check the ADFS service and the WAP publishing; verify
  the ADFS SSL and WAP certs are valid. Restart the ADFS service only under change control.
- **Federation metadata unreachable.** Confirm
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` resolves internally and
  via WAP (Testing T4). DNS for `sts.<domain>` and the WAP publishing must be correct.

## Sign-in works internally but fails from outside (or vice-versa)

- **WAP problem.** External sign-in flows through WAP; internal goes direct to ADFS. If only extranet
  fails, check WAP health, its trust with the ADFS farm (re-establish the proxy trust if broken), and the
  WAP SSL certificate. If only intranet fails, check the internal DNS/load balancer to the ADFS farm.
- **Home-realm discovery / split DNS.** Ensure `sts.<domain>` resolves to WAP externally and to the ADFS
  farm (or its internal VIP) internally.

## Individual users can't sign in (but most can)

- **ImmutableID / sourceAnchor mismatch.** The claim ADFS emits must match the synced ImmutableID for the
  user. Duplicate/soft-matched accounts or a changed sourceAnchor break this user. Verify the user's
  on-premises `objectGUID`-derived ImmutableID matches Entra; fix the sync anchor.
- **Claims rule excludes the user.** If the Access Control Policy / issuance authorization rules restrict
  by group or attribute, a user outside the rule is denied. Review the Microsoft 365 relying-party
  trust's rules.

## After a claims-rule edit, sign-in breaks

- **Rules corrupted or missing required claims (UPN, ImmutableID, issuerId).** Restore the exported rules
  (`rules-backup.txt` from Implementation A1). Re-generate the standard Microsoft 365 rule set from
  Microsoft's published set or via the Entra Connect federation task if the backup is unavailable.

## Migration: Staged Rollout pilot user still hits ADFS

- **User not actually in the Staged Rollout group.** Confirm membership of `Staged Rollout – Pilot –
  Wave1` and that the correct method (PHS/PTA) + Seamless SSO toggles are on in the Entra admin center.
  Group membership changes can take time to apply.
- **Cached sign-in.** Have the user clear cached credentials / use a fresh session; confirm they land at
  `login.microsoftonline.com` without an ADFS redirect (Testing T5).

## Migration: Seamless SSO prompts instead of silent sign-in

- **`AZUREADSSOACC` computer object or Kerberos key stale.** Confirm the object exists in AD and roll its
  Kerberos decryption key on the documented schedule.
- **Browser not sending Kerberos ticket.** The corporate endpoint
  (`https://autologon.microsoftazuread-sso.com`) must be in the browser **intranet/trusted** zone —
  push via Group Policy. Non-domain-joined or off-network devices won't get Seamless SSO (expected).

## Migration: PTA sign-in fails or is intermittent

- **Too few / unhealthy PTA agents.** A single agent is a single point of failure. Confirm two or more
  **healthy** PTA agents in Entra ID → Connect → Pass-through authentication; enable **PHS as backup** so
  an agent outage doesn't stop sign-in.

## After domain conversion, some clients break

- **Legacy-auth client relied on ADFS behavior.** Reconfigure the client for modern auth, or account for
  it in Conditional Access. Confirm the conversion completed (`Get-MgDomain` → `Managed`, Testing T7/T8).
- **Lost access control.** If an ADFS access/MFA rule wasn't recreated in Entra Conditional Access
  (requirement R6), that control is now gone. Author and enable the equivalent Conditional Access policy.

## Decommission concerns

- **Another relying party still uses ADFS.** Sign-in for a non-Microsoft-365 app breaks after
  decommission. This is why Phase 0 inventories **all** relying-party trusts and Testing T9 gates on it —
  re-home other relying parties first, keep ADFS **parked** (not uninstalled) until confirmed clear.
- **Need to roll back post-conversion.** As long as ADFS is parked and running, re-federate the domain
  via the Entra Connect wizard (rollback in Implementation B3/B4). Do not uninstall ADFS until stable
  across a full business cycle.

## Cmdlet / tooling issues

- **MSOnline / AzureAD cmdlet not found or failing.** These modules are **deprecated/retiring**. Use
  **Microsoft Graph** (`Update-MgDomain`, `Get-MgDomainFederationConfiguration`) and the **Entra Connect**
  wizard instead. **Verify current cmdlet availability in your tenant/version.**
- **`Connect-MgGraph` scope errors.** Read operations need `Domain.Read.All`; writes need
  `Domain.ReadWrite.All`. Consent to the scope the script requests.
- **Government cloud endpoints.** On GCC High / DoD, connect Graph to the correct environment
  (`Connect-MgGraph -Environment USGov` / `USGovDoD`) and use the `.us` portals — **verify the endpoints
  and Staged Rollout / managed-auth availability for your cloud.**
