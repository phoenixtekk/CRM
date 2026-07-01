# 6. Troubleshooting — Certificate-Based VPN Authentication for Cisco ISE with Intune

Work top-down: confirm the **certificate is on the device (A)**, then the **chain is complete (B)**,
then that **ISE accepts EAP-TLS (C)**, then **renewal (D)**. Most "ISE rejects" cases are actually a
device-side chain or identity problem — fix A/B before touching ISE.

> Diagnostic scripts: `CISECERT-Discovery.ps1` (tenant readiness), `CISECERT-Validation.ps1`
> (this device), `CISECERT-Report.ps1` (fleet), `CISECERT-Remediation.ps1` (safe re-trigger).

---

## A. No certificate on the device
**Symptom:** `CISECERT-Validation.ps1` reports no leaf in `LocalMachine\My` (or user store); the
SCEP/PKCS profile shows **Error**/**Pending** in Intune.

**Check and fix:**
1. **Assignment.** Is the device/user actually in `PILOT – Cisco Cert VPN Users`, and is that group
   assigned to the SCEP/PKCS profile? (`CISECERT-Discovery.ps1` shows assigned groups.)
2. **Device check-in.** Force an Intune sync; issuance only happens on check-in. Devices offline will
   not receive the cert.
3. **Connector health.** In **Intune → Tenant administration → Connectors and tokens → Certificate
   connectors**, confirm the connector is **Active** with a recent last-connection. A stale/errored
   connector blocks all SCEP/PKCS issuance.
4. **SCEP URL / NDES.** For SCEP, verify the SCEP Server URL in the profile is correct and NDES is
   reachable/healthy. For PKCS, verify the CA name and template name are correct and the CA is online.
5. **Template permissions (PKCS/AD CS).** The connector's service account must have **Enroll** rights
   on the client-auth template.
6. **Re-trigger.** Run `CISECERT-Remediation.ps1 -CertProfileMatch "Cisco VPN" -Apply` to send a
   sync and re-evaluate issuance, then re-check with `CISECERT-Report.ps1`.

---

## B. Chain incomplete / certificate not trusted on the device
**Symptom:** The leaf is present but `CISECERT-Validation.ps1` reports **chain valid = FAIL**, or the
root is not found in the Trusted Root store.

**Check and fix:**
1. **Trusted Root profile assigned?** Confirm `Cisco VPN – Trusted Root` is assigned to the same
   group and has reached the device (`certlm.msc → Trusted Root`).
2. **Missing intermediate.** If your CA has an intermediate, you need
   `Cisco VPN – Trusted Root (Intermediate)` deployed to the **Intermediate** store. A missing
   intermediate is the most common broken-chain cause.
3. **Right store.** Windows device certs must chain via the **Computer** (LocalMachine) stores; a
   root deployed to the user store won't help a machine cert.
4. **Correct root.** Verify the deployed root is the CA that actually **issued** the leaf (issuer of
   the leaf == subject of the root).
5. Re-run `CISECERT-Validation.ps1` until **chain valid = PASS** before testing ISE.

---

## C. ISE rejects the EAP-TLS handshake
**Symptom:** VPN connects with a certificate but fails; ISE Live Logs show EAP-TLS failure /
Access-Reject (or no EAP-TLS at all). *(ISE console steps are Cisco's — this section tells you what
to check and where the boundary is.)*

**Device-side first (fix before blaming ISE):**
1. **Chain valid on device?** Confirm Test 2/3 PASS — a device that can't build its own chain will
   fail EAP-TLS.
2. **Client Authentication EKU present?** `CISECERT-Validation.ps1` reports this. Missing EKU → fix
   the SCEP/PKCS profile EKU (Implementation Step 3) and reissue.
3. **Identity match (the classic).** The leaf **Subject/SAN** must match the attribute the ISE
   **Certificate Authentication Profile** keys on (Test 4). A UPN-in-SAN cert against an ISE profile
   keyed on Subject CN silently fails.

**ISE-side (per Cisco documentation):**
4. **ISE trusts the CA.** The same **root/intermediate** must be imported into ISE's trusted-
   certificate store. If ISE doesn't trust the issuing CA, every EAP-TLS attempt is rejected. *(Cisco
   docs — ISE trusted certificates.)*
5. **EAP-TLS allowed in the policy set** and the identity authorized for VPN. *(Cisco docs — policy
   sets / authorization.)*
6. **Revocation reachability.** If ISE enforces CRL/OCSP, ISE must reach the CA's CRL/OCSP endpoints
   (R9); an unreachable CRL causes rejects even for valid certs. *(Cisco docs — revocation settings.)*
7. **Head-end passing EAP-TLS.** The ASA/Secure Firewall VPN connection profile must forward
   certificate/EAP-TLS auth to ISE as RADIUS. *(Cisco docs — VPN connection profile / RADIUS.)*
8. **Read the ISE Live Log detail** — it names the exact failure reason (unknown CA, identity not
   found, revocation, expired), which maps back to one of the checks above.

---

## D. Renewal failures
**Symptom:** Certificates expire instead of renewing; users lose VPN at cert expiry;
`CISECERT-Report.ps1` shows devices trending to expiry or dropping to Error.

**Check and fix:**
1. **Renewal threshold set?** Confirm the SCEP/PKCS profile has a **renewal threshold (%)** (e.g.
   20%). Without it, no auto-renewal.
2. **Device checking in?** Renewal only fires on Intune check-in; offline/stale devices miss the
   window. Chase stale check-ins.
3. **Connector/CA still healthy?** Renewal re-requests through the same connector/CA path as initial
   issuance — re-run Section A checks 3–5.
4. **Same identity on renewal.** Confirm the renewed cert keeps the **same Subject/SAN** so ISE still
   accepts it; a changed SAN format breaks a previously working device.
5. **ISE revocation of the old cert.** Renewal issues a new cert; ensure the superseded cert isn't
   still being presented (clear old certs if a device accumulates multiples with the same EKU).

---

## Quick reference: symptom → section
| Symptom | Go to |
| --- | --- |
| No leaf certificate on device; profile Error/Pending | A |
| Leaf present but chain invalid / root not trusted | B |
| VPN cert connects but ISE rejects / Access-Reject | C |
| Cert expires instead of renewing | D |
| Not sure if profiles/connector are even set up | Run `CISECERT-Discovery.ps1` |
| Need fleet-wide coverage/expiry picture | Run `CISECERT-Report.ps1` |
