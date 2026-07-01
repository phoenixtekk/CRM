# 7. Best Practices — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

- **Inventory before you touch anything.** Capture the installed client **version**, the authoritative
  **profile XML**, the **certificate** template intent, and every SCCM/GPO mechanism and its scope
  first — the legacy delivery encodes working connectivity you must not lose.
- **One source of truth for the profile.** Treat a single copy of the profile XML as authoritative and
  deliver that same XML from Intune, byte-identical, so a coexistence overlap is a no-op rather than a
  fight.
- **One authority per device — always.** The cardinal rule against double-deployment: a device leaves
  the SCCM collection and the GPO scope **in the same change** it joins its Intune wave. Coexistence is
  fleet-wide, never device-wide.
- **Match versions before you overlap.** Standardize on one Cisco-provided client version so that any
  brief pilot overlap does not trigger a reinstall or version tug-of-war.
- **Migrate in waves, pilot first.** Prove the full Intune-delivered VPN (client + profile + cert +
  tunnel) on a small `PILOT – VPN Migration Wave 1` before expanding — a bad rebuild never reaches the
  fleet.
- **Certificate parity is exact work.** The Intune SCEP/PKCS profile must issue a certificate the
  head-end accepts — same subject/SAN, EKUs, and key usage as the legacy AD CS template. Validate
  issuance and acceptance before cutover.
- **Validate the tunnel, not just the files.** The gate is a working connection, not merely the client
  and profile being present — always confirm the VPN actually connects on Intune-only delivery.
- **Cut over and clean up together.** As each wave passes, remove it from SCCM and GPO immediately;
  don't let legacy targeting linger and re-assert itself.
- **Name everything and reuse the names.** `Cisco Secure Client – Win32`, `Cisco VPN – Profile`,
  `Cisco VPN – Client Cert (SCEP)`, `Cisco VPN – Trusted Root CA`, `PILOT – VPN Migration Wave 1` — so
  the migration is searchable and auditable.
- **Prove progress with a report.** Track legacy-vs-Intune coverage each cycle with
  `CVPNMIG-Report.ps1`; chase laggards with `CVPNMIG-Remediation.ps1` (default `-WhatIf`) before
  decommissioning legacy.
- **Have a rollback per wave.** If a wave misbehaves, re-add it to the SCCM collection / GPO scope and
  remove the Intune assignment — coexistence means the VPN never disappears. Fix, then retry cutover.
- **Retire legacy last.** Remove the SCCM deployment/package and unlink the GPO(s) only after every
  wave is Intune-managed and validated — never both authorities enforcing the client at once.
- **Defer Cisco internals to Cisco.** Installer switches, profile XML schema, head-end (ASA/Firepower)
  and ISE posture are Cisco's domain — rebuild *delivery* in Intune and follow Cisco's documentation
  for the product's own configuration.
