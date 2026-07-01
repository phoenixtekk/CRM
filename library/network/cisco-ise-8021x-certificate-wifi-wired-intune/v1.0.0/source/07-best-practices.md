# Best Practices

Operating 802.1X EAP-TLS well is mostly about **the supplicant**, **certificate lifecycle**, and
choosing the right **failure behavior**. The practices below keep the deployment reliable and
reversible.

## Supplicant configuration

- **Prefer device (machine) certificates for unattended access.** A machine certificate authenticates
  the device before/without a logged-in user, which is essential for kiosks, headless devices, and
  boot-time network access. Reserve user certificates for scenarios that truly need per-user identity
  on the network.
- **Always enable server-certificate (server-name) validation.** Configure the Wi-Fi and wired
  profiles to validate ISE's server certificate **and** match ISE's server name(s). Without this the
  supplicant will trust *any* server presenting a cert from the trusted root — a rogue-RADIUS risk.
- **Deliver the supplicant config from Intune, never by hand.** Both `Corp Wi-Fi – EAP-TLS` and
  `Wired 802.1X – EAP-TLS` should be the single source of truth. Manual `netsh`/GUI edits drift and
  are impossible to audit at fleet scale.
- **Ensure Wired AutoConfig (dot3svc) is running** on every wired-802.1X device — the wired profile
  should start/enforce it. A stopped dot3svc is the classic "wired profile applied but port never
  authenticates" cause.
- **Keep the certificate ↔ profile linkage intact.** The Wi-Fi/wired profiles must reference
  `Cisco 802.1X – SCEP Cert` (identity) and `Cisco 802.1X – Trusted Root` (server trust). If you
  rebuild a cert profile, re-point the network profiles at it.

## Certificate lifecycle & renewal

- **Set a sensible validity + renewal threshold.** Typical: 1-year device certificates with SCEP
  renewal starting at ~20% remaining lifetime, so devices re-enroll well before expiry. Verify
  renewal actually happens during the pilot — expired certs are the most common cause of a device
  silently dropping off the network.
- **Watch the Certificate Connector / Cloud PKI health.** Renewals fail silently if the connector is
  down or the SCEP endpoint is unreachable. Monitor connector status; alert on it.
- **Plan for CA rotation.** If ISE's issuing CA or your device CA is rotated, deploy the **new root**
  via a new/updated `Cisco 802.1X – Trusted Root` **before** the old chain is retired, and ensure ISE
  trusts the new device CA — otherwise a rotation locks the fleet off the network.
- **Protect keys with the TPM.** Prefer **Enroll to TPM if present** so the private key is
  non-exportable and bound to the device.

## Fail-open vs fail-closed (choose deliberately)

This is a network-infrastructure decision (configured on the **switch/WLC**, Cisco-side) but you must
choose it consciously:

- **Fail-closed (default-deny):** an unauthenticated device gets **no access**. Most secure; also the
  most disruptive if certificates or ISE break. Appropriate for high-security segments once the
  deployment is proven.
- **Fail-open / low-impact modes:** during rollout, network teams often run 802.1X in **monitor
  mode** (a.k.a. open/low-impact) or with a **MAB (MAC Authentication Bypass) fallback** and/or a
  **critical-VLAN** so that an ISE outage or a cert problem doesn't strand devices. Use this during
  **Pilot and early Expand**, then tighten toward fail-closed once confidence is high.
- **Always have a rollback.** Keep the ability to remove the Intune profile assignment *and* a
  network-side fallback (fail-open/MAB/critical-VLAN) so a bad change never becomes an outage. This
  satisfies the category rollback requirement (`global-requirements-network.md`, G7).

> **Vendor boundary:** the exact monitor-mode/MAB/critical-VLAN configuration lives on the Cisco
> switch/WLC and in ISE — configure it per **Cisco documentation**.

## Rollout discipline

- **Pilot first, expand in waves.** Assign to `PILOT – 802.1X Devices`, prove all three gates on
  Wi-Fi and wired, then widen to the production group in batches — never the whole fleet at once.
- **Test both transports and multiple OS types.** Wi-Fi and wired behave differently (different
  supplicant, dot3svc for wired); validate each.
- **Keep names consistent.** Reuse the exact object names so reports, remediation, and troubleshooting
  line up across tools and teammates.

## Operations & monitoring

- **Run the coverage report regularly.** `ISE8021X-Report.ps1` surfaces devices missing a cert or a
  profile before users notice. Feed gaps into `ISE8021X-Remediation.ps1` (default `-WhatIf`).
- **Watch ISE Live Logs after every wave and every ISE/CA change** (Cisco-side) — a spike in rejects
  is the earliest warning of a trust-chain or policy regression.
- **Document the trust chain.** Record which CA issues device certs, which CA signs ISE's server
  cert, and the SAN/CN format ISE reads — so a future admin can reason about a reject in minutes.
