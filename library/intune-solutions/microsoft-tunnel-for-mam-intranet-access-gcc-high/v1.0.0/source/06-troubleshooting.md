# Troubleshooting — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG

Symptom → likely cause → fix. Government-specific issues are marked **[GOV]** and appear first because they are the most common cause of "it worked in Commercial but not here."

---

## Government-specific issues **[GOV]**

### The Tunnel Gateway installed successfully but never appears in `intune.microsoft.us`
**Cause:** The gateway was installed **without** the Government cloud flag, so it registered against the **Commercial** Intune service.
**Fix:** Reinstall referencing the Government cloud: `sudo intune_env=FXP ./mstunnel-setup`. Confirm under **Tenant administration → Microsoft Tunnel Gateway → Health status** in `intune.microsoft.us`. This is the single most frequent Government failure.

### Scripts return no data / authenticate to the wrong tenant
**Cause:** Connected to **Commercial** Graph (`graph.microsoft.com`) instead of US Gov.
**Fix:** Reconnect with `Connect-MgGraph -Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD). The provided scripts default to `USGov`; pass DoD parameters for DoD. Verify with `(Get-MgContext).Environment` and confirm the endpoint host ends in `.us`.

### Admin can't find Tunnel settings / "the portal looks different"
**Cause:** Signed in to a `*.com` portal.
**Fix:** Use `https://intune.microsoft.us` and `https://portal.azure.us`. Sign-in should route through `login.microsoftonline.us`.

### Gateway can reach the internet but can't register with Intune
**Cause:** Firewall allows only Commercial endpoint ranges.
**Fix:** Allow the **US Government** Office 365/Intune/Entra/Graph endpoint ranges (`*.manage.microsoft.com` and the Gov `login`/`graph` `*.us` hosts). Re-verify against the current Government endpoint list.

### First-time sign-in fails in Edge/LOB app on a federated Government tenant
**Cause:** The federation **STS** URL is being routed through the tunnel before authentication completes.
**Fix:** In the Edge/LOB app configuration policy add General config key `com.microsoft.tunnel.custom_configuration` = `{"bypassedUrls":["<your-federation-STS-host>"]}`. Many Government tenants are federated — do not skip this.

### Compliance flags the deployment for FIPS
**Cause:** Tunnel for MAM does **not** support FIPS (Android or iOS) — expected behavior, not a misconfiguration.
**Fix:** This cannot be enabled. Obtain ISSO/ISSM acceptance for the data classification, or select a FIPS-validated alternative for this path.

### Planned to issue certificates from Cloud PKI — it's not available
**Cause:** Cloud PKI is **GCC High only and "planned"** (not GA in DoD; verify in GCC High).
**Fix:** Issue the TLS server cert (and trusted-root material) from an **enterprise/on-premises CA** or a supported **public CA**.

---

## Gateway / infrastructure

### Server shows offline or "Internal network accessibility" unhealthy
**Cause:** Gateway service down, network path blocked, or the internal check URL unreachable.
**Fix:** On the host run `mst-cli server restart` (required after install on RHEL 8.4+). Confirm inbound **TCP/UDP 443** reach the server and the site's **internal network access check URL** resolves from the server.

### TLS certificate errors when devices connect
**Cause:** SAN mismatch, incomplete chain, expired cert, or unreachable OCSP/CRL.
**Fix:** Ensure the cert **SAN = the site's public FQDN/IP**, the **full chain** is installed (`site.crt` root+intermediates, `site.key` unencrypted), it isn't expired (iOS ≤ 398 days for public certs), and the revocation endpoint is reachable from the server. Update with `mst-cli import_cert` → `mst-cli server restart`.

### Upgrades not applying
**Cause:** Manual-approval upgrade mode or a maintenance window.
**Fix:** Approve pending upgrades, or check the site's maintenance-window settings. Stay within one version of the current release.

---

## Android device issues

### Defender: "Invalid Licensing, please contact administrator"
**Cause:** Defender for Endpoint version predates Tunnel support.
**Fix:** Install Defender **v1.0.4722.0101+** from Google Play. (Also confirm Intune Plan 2 / advanced-capability licensing is assigned.)

### Tunnel doesn't auto-connect when Edge launches
**Cause:** The three Android policies don't all target the **same** group, or the app protection "Start Microsoft Tunnel connection on app-launch" is not set.
**Fix:** Confirm `AC-TUNMAMG-Defender-Android`, `AC-TUNMAMG-Edge-Android`, and `AP-TUNMAMG-Edge-Android` all target the same group; set app-launch start = **Yes** in the protection policy.

### Tunnel connects then drops / behaves erratically
**Cause:** Multiple Defender app-config policies with different Sites (race condition), or Always-on VPN enabled.
**Fix:** Target **one** Defender policy per device with **one** Site. Do **not** enable Always-on VPN with MAM Tunnel — use **Strict Tunnel Mode** in the Edge policy instead.

### Strict Tunnel Mode not blocking traffic
**Cause:** `StrictTunnelMode` key missing/mistyped or has a **trailing space**; or device isn't AM-API enrolled (for device-wide strict mode).
**Fix:** Set `com.microsoft.intune.mam.managedbrowser.StrictTunnelMode` = `True` with no trailing space in `AC-TUNMAMG-Edge-Android`.

### The three required apps aren't visible in Company Portal
**Cause:** Expected on unenrolled devices.
**Fix:** Have users install Defender, Edge, and Company Portal **manually** from Google Play (links in `02-requirements.md`).

### Edge can't reach internal resource immediately after launch
**Cause:** Edge attempts the connection before the tunnel establishes.
**Fix:** Refresh the page once the tunnel connects — expected transient behavior.

### Private-CA internal site fails (WebView LOB app / Defender cert error)
**Cause:** Missing intermediates or Defender not yet trusting the private root.
**Fix:** Deploy `CERT-TUNMAMG-Root` with **root + all intermediates**; if a WebView LOB app still fails, manually install the root on the device. For Defender's private-CA TLS error, manually install the corresponding root on the device.

---

## iOS/iPadOS device issues

### No VPN entry appears in iOS Settings
**Cause:** Expected — the Tunnel for MAM iOS SDK provides a Per-App VPN scoped to the app's networking layer; it is not a system VPN.
**Fix:** None needed. Verify via `mst-cli` active client connections instead.

### LOB app can't use the tunnel
**Cause:** App not integrated with the required SDKs, or Entra app registration mismatch.
**Fix:** Ensure the app links **Tunnel for MAM iOS SDK + Intune App SDK + MSAL** (Xcode 14+, MAM-SDK 16.1.1+, MSAL 1.2.3+); the app's **Bundle ID** must match the Entra app registration; grant admin consent to **Microsoft Tunnel Gateway (`Tunnel_Allow`)** and **Microsoft Mobile Application Management** API permissions; add the **`acct`** optional access-token claim.

### MFA Conditional Access breaks the iOS tunnel
**Cause:** Known issue — the Authenticator app doesn't complete the token flow for Tunnel-for-MAM CA MFA.
**Fix:** Implement `onTokenRequiredWithCallback` in the LOB app's Tunnel Delegate class.

### Edge on iOS can't authenticate to an on-prem site
**Cause:** Kerberos and certificate-based auth to on-prem sites are **not supported** by Tunnel for MAM on iOS Edge.
**Fix:** Use a supported auth method (NTLM SSO is supported for Edge, not LOB apps). No workaround for Kerberos/cert-based.

### Both Tunnel VPN and Defender VPN drop on sleep (iOS combined mode)
**Cause:** "Disconnect on Sleep" without properly configured On-Demand rules.
**Fix:** Configure On-Demand rules (Per-App VPN recommended); note SSO conflicts with an all-domains connect rule + Disconnect-on-Sleep.

---

## General

### A device using both MDM Tunnel and MAM Tunnel has networking failures
**Cause:** A device may use **either** MDM Tunnel or MAM Tunnel, never both simultaneously.
**Fix:** Separate the groups so no device receives both an MDM Tunnel VPN profile and MAM Tunnel app-config settings.

### Newly added custom (LOB) app doesn't show in the policy UI
**Cause:** Known admin-center UX refresh issue.
**Fix:** Refresh the Intune admin center and reopen the policy; the Bundle ID should then appear.

---

*If a symptom isn't listed, re-run `TUNMAMG-Validation.ps1` (US Gov Graph) to localize the fault to control plane vs data plane, then consult the matching section above. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation.*
