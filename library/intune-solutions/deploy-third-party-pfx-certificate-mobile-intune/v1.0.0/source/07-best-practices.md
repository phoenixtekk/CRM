# 7. Best Practices — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

- **Never use SCEP/PKCS *templates* for a static third-party PFX.** Those issue *new* certificates
  from your CA; they cannot deliver a pre-existing file. Use a PKCS imported certificate profile (Path
  A) or a custom PKCS12 profile (Path B). This is the single most important practice.
- **Deliver the chain before the leaf.** A leaf identity is useless without a trusted root/intermediate
  chain — assign `Trusted Root – Org CA – iOS` first.
- **Remember the object-vs-profile distinction.** An imported PFX object existing in Graph does *not*
  reach a device. A delivery *profile* must be assigned to the user/group; importing and assigning are
  two separate actions.
- **Keep the Certificate Connector healthy (Path A).** It decrypts the imported PFX at delivery time;
  if it is unhealthy, the imported-PFX profile silently never deploys.
- **Match intended purpose to the app.** The imported-PFX intended-purpose options are S/MIME-oriented;
  for a non-S/MIME app cert set what the app expects, and switch to Path B if the S/MIME framing does
  not fit.
- **Confirm the app can actually use the cert.** "Delivered" is not "usable" — verify the app reads
  the identity, and apply the vendor's keychain access group / App Configuration requirement.
- **Defer app internals to the vendor.** Make Intune delivery correct; let the app vendor own which
  keychain group the app reads.
- **Protect the PFX password.** Treat it as a secret — secure input in scripts, never hardcoded, never
  in docs or logs.
- **Pilot before you expand.** Validate on `iOS App Cert – Pilot` (chain + identity + app use) before
  adding `iOS App Cert – Broad`; keep a clean rollback by unassigning the profile.
- **Use the naming convention.** `<Purpose> – <Scope> – <Stage>` across profiles and groups keeps the
  deployment auditable and repeatable.
