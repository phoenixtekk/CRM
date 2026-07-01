# Testing — Confirming the Fix

A fix is only real when the layer it targeted passes its gate **and** the layers below it come back healthy. Each gate below maps one-to-one to a branch in the Diagnostic Playbook (`03-implementation.md`). Run the gate for the branch you worked; if it passes, walk the remaining layers down to a live, authorized connection.

All confirmation checks here are **read-only** — you observe recovery, you don't force it. Use `CISEDIAG-Report.ps1` at the end to produce a single consolidated pass/fail view across all layers.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Pilot-Devices**.

---

## Gate A — Certificate now present (L1)

**Confirms:** Branch A fix (certificate delivery).

**Pass when:**
- `CISEDIAG-Validate-Certificate.ps1` lists a **VPN client-authentication certificate** from the expected issuer in the device store, **with a private key**.
- In Intune → the device → **Configuration**, the **certificate configuration profile** shows **Succeeded**.

**Fail when:** still no certificate, or profile status is Error/Not applicable/Pending → return to Branch A.

---

## Gate B — Chain and trust valid (L1)

**Confirms:** Branch B fix (chain/trust).

**Pass when:**
- `CISEDIAG-Validate-Certificate.ps1` reports, for the VPN certificate: **not expired**, **Client Authentication EKU present**, **chains to a trusted root**, **no chain error**, **not revoked** (or revocation reachable and good).
- The **trusted-root certificate profile** shows **Succeeded** in Intune.
- Issuer/template match the known-good reference (R7).

**Fail when:** any chain error, missing private key, untrusted root, or expiry remains → return to Branch B.

---

## Gate C — Client configured and reaching the head-end (L2)

**Confirms:** Branch C fix (client/profile/transport).

**Pass when:**
- `CISEDIAG-Check-VpnClient.ps1` shows the **Cisco Secure Client/VPN service present**, the **VPN configuration profile** present, and the **correct gateway/head-end**.
- The **VPN configuration profile** shows **Succeeded** in Intune.
- The client can resolve and reach the gateway, and (Cisco-side evidence) the Secure Client loads the expected profile and presents a certificate.

**Fail when:** wrong/absent profile, wrong gateway, or the client cannot reach the head-end → return to Branch C (or escalate to Cisco with a DART bundle).

---

## Gate D — EAP-TLS authenticates (L3)

**Confirms:** Branch D fix (mutual authentication).

**Pass when (vendor evidence):**
- In the ISE authentication live log, the attempt now shows **authentication success** (EAP-TLS passed) for the device.
- No chain/revocation/unknown-CA/identity-mapping failure reason remains in the detailed report.
- `CISEDIAG-Validate-Certificate.ps1` still confirms a clean chain device-side.

**Fail when:** ISE still logs an EAP-TLS failure → read the reason and loop back (usually Branch B for chain/trust, or ISE-side trust on the Cisco side).

---

## Gate E — Authorized by posture (L4)

**Confirms:** Branch E fix (posture/authorization).

**Pass when:**
- `CISEDIAG-Check-Compliance.ps1` reports the device **Compliant**, **Enrolled/Managed**, with the expected ownership.
- In the ISE detailed report (vendor evidence), the session now matches the **permit/compliant** authorization rule — not quarantine/redirect.
- The user gets the intended full access on the tunnel.

**Fail when:** Intune says compliant but ISE still quarantines → connector/identity-match problem (Branch F / Branch E step 3). Intune says non-compliant → the genuine compliance policy still fails; remediate it and re-test.

---

## Gate F — Service restored (shared)

**Confirms:** Branch F fix (shared/service break).

**Pass when:**
- The **known-good reference device (R7)** connects and is authorized again.
- Fleet-wide **certificate configuration profile** status is no longer erroring across devices.
- (Vendor evidence) ISE is up with a **valid, unexpired server certificate**; the Entra↔ISE compliance connector reports healthy.
- `CISEDIAG-Check-Compliance.ps1` against several devices shows compliant devices being authorized (not universally quarantined).

**Fail when:** the reference device still fails → the shared service isn't fully restored; keep working Branch F.

---

## End-to-end confirmation (all layers)

After any single-layer gate passes, prove the **whole path** end to end on the device:

1. Run the consolidated report:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Report.ps1
   ```
   Expect **PASS** on: certificate present + valid chain (L1), VPN client/profile correct (L2), compliance/enrollment good (L4-Intune).
2. **Connect the tunnel** and confirm the user reaches intended resources.
3. **Read the ISE live log** for that fresh attempt (vendor evidence): authentication **success** (L3) and a **permit** authorization result (L4).

A fix is **done** only when the report is green, the tunnel is up, and ISE shows success + permit for that exact connection — not before.
