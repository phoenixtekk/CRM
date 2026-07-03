# Troubleshooting — Cloud PKI Integration with Intune (Government / GCC High)

Work top-down. The first section covers the failures that are **unique to GCC High** — check these
before generic certificate troubleshooting, because in GCC High "it's not there" is often a **parity
gap** (above all, **Cloud PKI**), not a misconfiguration.

---

## A. GCC-High-specific gotchas

### A1. "Where is Cloud PKI? The blade/option isn't there."
**Symptom:** A Commercial guide says to create a **Cloud PKI** root/issuing CA in the Intune admin
center, but the option does not exist in `intune.microsoft.us`.
**Likely cause:** **Cloud PKI is not available in GCC High** — it is listed under *"Intune features
planned for GCC High and DoD"* (not yet GA), and is **not planned for DoD** at all. This is a
**parity gap, not a bug.**
**Check / fix:** Confirm in `gcc-high-parity-notes.md` §2 and the live *Intune Government Service
overview*. Use the **supported** path instead: **trusted-root + SCEP/PKCS certificate profiles via
the Intune Certificate Connector** (see `03-implementation.md`). **Do not file a support case for a
planned feature.** Re-check the roadmap periodically — Cloud PKI is planned for GCC High and may
become GA.

### A2. Wrong cloud — portal or script hit a `.com` host
**Symptom:** Sign-in loops, "tenant not found", empty portal, or a script authenticates but sees no
Intune objects.
**Likely cause:** You reached the **Commercial** cloud (`intune.microsoft.com`,
`login.microsoftonline.com`, or `Connect-MgGraph -Environment Global`) instead of GCC High.
**Fix:** Use the `.us` hosts only — `login.microsoftonline.us`, `intune.microsoft.us`,
`security.microsoft.us`, `entra.microsoft.us`, `portal.office365.us`. In scripts, connect with
**`Connect-MgGraph -Environment USGov`** (DoD: `USGovDoD`). Verify with `(Get-MgContext).Environment`
= `USGov`. Run `CPKIG-Discovery.ps1`, which reports the environment.

### A3. Endpoint blocked by filtering
**Symptom:** Portal will not load, the connector cannot reach the service, or devices cannot reach
the SCEP URL — on-network only.
**Likely cause:** Proxy/firewall allows the **Commercial** Office 365 endpoint list but not the
**Office 365 U.S. Government GCC High** list (the `.us` sovereign hosts are a separate published set),
or the NDES reverse-proxy URL is blocked.
**Fix:** Allow the GCC High URL/IP ranges (portals, `graph.microsoft.us`, `login.microsoftonline.us`,
the connector's endpoints and **`autoupdate.msappproxy.net:443`**), plus your published NDES/SCEP
URL. Re-test R8 reachability from an on-network workstation **and** a device.

### A4. Partner-CA connector unavailable in GCC High
**Symptom:** A non-Microsoft CA integration (e.g. DigiCert) you used in Commercial is missing or
non-functional in the GCC High tenant.
**Likely cause:** The partner integration is **Commercial-only** or not yet supported in the
government cloud (mirrors how MTD connectors are limited to vendors that support GCC High).
**Fix:** **Verify for GCC High** with the partner and in `intune.microsoft.us`. If unsupported, use
**AD CS** (R4/R5) instead. Record the decision.

---

## B. Certificate Connector not healthy

- **Cause:** Connector service down, out-of-support version (**Warning→Error**), service-account
  problem, or blocked outbound/`autoupdate.msappproxy.net`.
- **Fix:** `intune.microsoft.us → Tenant administration → Connectors and tokens → Certificate
  connectors` — check status. Update the connector (six-month support lifecycle; out-of-support
  connectors stop issuing/revoking). Confirm the service account, and the **Event logs**
  (Applications and Services → Microsoft → Intune → Certificate Connectors, event IDs 5xxx =
  health). Ensure auto-update reaches `autoupdate.msappproxy.net:443`.

## C. Trust chain not on the device

- **Cause:** `Trust-Root-CA` profile targets the wrong platform/store, or is not assigned to
  `SG-CPKI-Pilot`; or replication delay.
- **Fix:** Confirm a **per-platform** trusted certificate profile with the correct `.cer` and store,
  assigned to `SG-CPKI-Pilot`. Force a device sync; allow replication time. An intermediate needs its
  own trusted profile.

## D. SCEP certificate not issued

- **Cause:** NDES/SCEP URL unreachable, connector SCEP feature off, template EKU/permissions wrong,
  root not referenced, or an **unknown extension OID** tripped the SCEP validation allow-list.
- **Fix:** Verify the published **NDES/SCEP URL** from a device; confirm the connector's **SCEP**
  feature and health; match the SCEP profile to the AD CS template (EKU = Client Auth, service
  account Enroll rights); reference `Trust-Root-CA`; **remove any custom extension OIDs** (only the
  allow-listed extensions are honored on connector v6.2510.3.2002+). Connector **Event ID 4007** =
  SCEP issue failure — read the event detail.

## E. PKCS certificate not issued

- **Cause:** Connector PKCS feature off, CA name / template name mismatch, or service-account enroll
  rights missing.
- **Fix:** Confirm the connector **PKCS** feature; enter the **exact** CA FQDN, CA name, and template
  name in the profile; grant the service account **Enroll** on the template. Connector **Event ID
  1052** = PKCS issue failure.

## F. Wi-Fi / VPN authentication fails despite a valid certificate

- **Cause:** The Wi-Fi/VPN profile references the wrong client-cert source or trusted root; wrong EKU;
  or the RADIUS/VPN server does not trust the chain.
- **Fix:** In the Wi-Fi/VPN profile, select `SCEP-Device-ClientAuth` (or `PKCS-User-ClientAuth`) as
  the client certificate and `Trust-Root-CA` as the trusted root; confirm the certificate EKU is
  **Client Authentication**; ensure the network access server trusts the same CA chain.

## G. Renewal not firing

- **Cause:** Renewal threshold not set, or connector/CA unhealthy near renewal time.
- **Fix:** Set the SCEP/PKCS profile **renewal threshold** (e.g. 20% remaining); confirm connector
  and CA health; verify the device is still enrolled and receiving the profile.

## H. Revocation not taking effect

- **Cause:** Revocation did not reach the CA/CRL, or the relying party does not check the CRL/AIA.
- **Fix:** Confirm the connector processed revocation (**Event ID 3050** = success; **3051** =
  failure); confirm the CA published an updated CRL; ensure the RADIUS/VPN/relying party consults the
  CRL/AIA distribution points.

## I. Scripts fail or report nothing

- **Cause:** Connected to Commercial Graph, missing scopes, or insufficient role.
- **Fix:** Reconnect with `Connect-MgGraph -Environment USGov` and the scopes listed in each script's
  **HOW TO RUN** header; confirm **Intune Administrator** (R3). Run `CPKIG-Discovery.ps1` first to
  confirm the environment and connectivity.

---

**When in doubt about a GCC High specific:** re-open the Microsoft *Intune Government Service
overview* page and the Microsoft 365 Roadmap filtered to **GCC High**, and re-confirm the feature
status (especially **Cloud PKI**) before troubleshooting further. Never assume Commercial behavior
carries over.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
