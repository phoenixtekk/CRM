# 7. Best Practices — Cloud PKI Integration with Intune

- **Chain before leaf, always.** Deploy the trusted root/intermediate (`Trusted Root – Cloud PKI –
  All Devices`) *before* assigning any SCEP/PKCS profile — a leaf certificate with no trusted chain is
  useless and silently fails the scenario.
- **Pilot the issuance, gate the migration.** Issue to `Cloud PKI Cert – Devices – Pilot` first and
  prove the Wi-Fi/VPN/auth scenario works on the cloud certificate before touching production or the
  legacy CA. This is the single most important practice — certificate mistakes lock users out.
- **Migrate by coexistence, never by switch-flip.** Keep both the legacy and cloud PKI roots trusted
  during migration, re-point one scenario at a time, validate, then drain the legacy CA. Retire only
  when `CPKI-Report.ps1` shows zero legacy dependency.
- **Set a renewal threshold.** Configure auto-renew (e.g. 20%) so certificates renew before expiry —
  expired client certificates are a self-inflicted Wi-Fi/VPN outage.
- **Match subject/SAN and EKU to the scenario.** Wi-Fi/VPN/auth needs the right SAN and the **Client
  Authentication** EKU; confirm the cloud PKI template allows exactly what the Intune profile requests.
- **Use SCEP for device, PKCS (or SCEP-user) for user.** SCEP keeps the private key on the device;
  use PKCS for user certificates where the cloud PKI supports it — confirm PKCS support in vendor docs.
- **Scope with groups, name everything.** Use the `<Purpose> – <Scope> – <Stage>` naming for
  connector, trust, SCEP/PKCS, and scenario profiles so the integration is auditable and repeatable.
- **Keep the connector healthy.** A down connector stops all issuance; monitor it (`CPKI-Discovery.ps1`)
  and treat connector health as a production dependency.
- **Defer product internals to the vendor.** The cloud PKI console, connector install, and CA template
  follow the vendor's documentation; keep your Intune-side procedure consistent regardless of vendor.
- **Report coverage + expiry continuously.** Run `CPKI-Report.ps1` on a cadence to catch laggards,
  near-expiry certificates, and devices still depending on the legacy CA.
- **Document the cadence and rollback.** Record issuing CA/template, profile settings, scope groups,
  and the rollback step for audits and repeatability.
