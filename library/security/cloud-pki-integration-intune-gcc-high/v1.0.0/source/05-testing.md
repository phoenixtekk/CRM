# Testing — Cloud PKI Integration with Intune (Government / GCC High)

Run these gates against the **pilot** (`SG-CPKI-Pilot`) before expanding. Each gate has an explicit
**PASS / FAIL** condition. A FAIL sends you to `06-troubleshooting.md`; do not expand scope until
every applicable gate is **PASS**. Portals are the GCC High `.us` hosts; scripts connect with
**`Connect-MgGraph -Environment USGov`**.

---

## Gate 0 — Sovereign-cloud sanity (must pass first)

- **Test:** In a browser, load `https://intune.microsoft.us`; run `CPKIG-Discovery.ps1` and confirm
  it connected to the **US Gov** Graph endpoint.
- **PASS:** Portal loads at a `.us` host; script reports environment `USGov` / `graph.microsoft.us`.
- **FAIL:** Any portal or script resolves to a `.com` host → you are targeting Commercial; stop and
  fix endpoint/environment before any other test.

## Gate 1 — Cloud PKI parity acknowledged (not assumed)

- **Test:** Confirm the design uses **SCEP/PKCS via the connector**, not Cloud PKI; and re-confirm in
  `gcc-high-parity-notes.md` §2 and the live *Intune Government Service overview* that **Cloud PKI is
  still "planned" (not GA)** in GCC High.
- **PASS:** Connector-based design recorded; Cloud PKI confirmed not-yet-available (or, if it has
  shipped, the design explicitly opts into it). **FAIL:** Design assumes a Cloud PKI issuing CA that
  does not exist in the tenant → re-scope to the connector model.

## Gate 2 — Licensing & roles present

- **Test:** `portal.office365.us → Billing → Licenses` shows G3/G5 / Intune Plan 1;
  `entra.microsoft.us → Roles and administrators` shows **Intune Administrator**.
- **PASS:** Both present. **FAIL:** Missing SKU or role → cannot author profiles / install connector.

## Gate 3 — CA + NDES + connector healthy

- **Test:** `intune.microsoft.us → Tenant administration → Connectors and tokens → Certificate
  connectors` shows **`CertConnector-01`** **Active/Healthy**; the AD CS issuing CA is online; the
  published NDES/SCEP URL responds from a device.
- **PASS:** Connector Active (not Warning/Error); CA online; SCEP URL reachable. **FAIL:** Connector
  Warning/Error (deprecated/out-of-support version), CA offline, or SCEP URL unreachable → fix
  before issuing.

## Gate 4 — Trust chain deployed

- **Test:** On a pilot device (after sync), inspect the trusted certificate store.
- **PASS:** The **`Trust-Root-CA`** root (and intermediate, if used) is present in the correct store.
- **FAIL:** Root missing → verify the trusted certificate profile platform/store and its assignment
  to `SG-CPKI-Pilot`.

## Gate 5 — SCEP certificate issued

- **Test:** A pilot device receives **`SCEP-Device-ClientAuth`** and requests a certificate.
- **PASS:** The leaf certificate installs on the device; Intune device certificate report shows it;
  connector **Event ID 4006** (SCEP issued success). Private key is on-device (never left it).
- **FAIL:** No certificate → check NDES/SCEP URL, connector SCEP feature, template EKU/permissions,
  and that no unknown extension OID tripped the SCEP validation allow-list.

## Gate 6 — PKCS certificate issued (if in scope)

- **Test:** A pilot user/device receives **`PKCS-User-ClientAuth`** (or imported PFX for S/MIME).
- **PASS:** Certificate installs; connector **Event ID 1050** (PKCS issued success).
- **FAIL:** No certificate → verify the connector PKCS feature, CA name/template name exactness, and
  service-account enroll rights.

## Gate 7 — Certificate consumed (Wi-Fi / VPN authenticates)

- **Test:** A pilot device connects to the certificate-protected **Wi-Fi (EAP-TLS)** or **VPN**.
- **PASS:** The device authenticates using the issued client certificate against `Trust-Root-CA`.
- **FAIL:** Auth fails → confirm the Wi-Fi/VPN profile references the correct client-cert source and
  trusted root, and the certificate's EKU is Client Authentication.

## Gate 8 — Renewal works

- **Test:** Confirm the SCEP/PKCS profile renewal threshold; simulate/verify renewal behavior before
  expiry (or shorten validity on a test template to observe renewal).
- **PASS:** A new certificate is issued before expiry without user action; old one is superseded.
- **FAIL:** No renewal → check the renewal-threshold setting and connector/CA health.

## Gate 9 — Revocation works

- **Test:** Retire/wipe the pilot device (or revoke on the CA) and re-test access.
- **PASS:** The connector processes revocation (**Event ID 3050**); the certificate is no longer
  trusted and access is denied.
- **FAIL:** Certificate still valid → verify revocation reached the CA/CRL and the relying party uses
  the CRL/AIA.

## Gate 10 — Script validation clean

- **Test:** Run `CPKIG-Validation.ps1` and `CPKIG-Report.ps1` (US Gov Graph).
- **PASS:** Validation reports `Trust-Root-CA`, `SCEP-Device-ClientAuth` (and `PKCS-User-ClientAuth`
  if in scope) present and assigned to `SG-CPKI-Pilot`; the connector is healthy; report lists issued
  certificates with no unexpected gaps.
- **FAIL:** Reported gaps → remediate (see `CPKIG-Remediation.ps1`, which defaults to `-WhatIf`) and
  re-run.

---

**Expansion gate:** proceed from Pilot to Expand **only** when Gates 0–5 and 7 are PASS (plus 6/8/9
where in scope), the connector is healthy, and any certificate/Wi-Fi/VPN assignment change has
change-control approval.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
