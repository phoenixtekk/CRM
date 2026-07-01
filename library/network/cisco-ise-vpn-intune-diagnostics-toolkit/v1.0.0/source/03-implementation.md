# Diagnostic Playbook

This is the core deliverable: a **root-cause decision tree entered by symptom**. During an incident, start here. Each branch tells you the **layer it isolates**, the **exact checks to run** (Intune/Graph at click level; Cisco side pointed to vendor evidence), and the **typical fix**.

Work the tree **top-down**. The layered model (`01-solution-overview.md`) guarantees that a break high in the stack fakes failures below it — so always confirm the layer above is healthy before descending. Confirm each fix with the matching gate in `05-testing.md`.

> Names used verbatim (from `02-requirements.md`): **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

---

## Step 0 — Triage entry (always start here)

Before picking a branch, answer two questions; they cut the tree in half.

1. **Does anyone connect right now?** Test the known-good reference device (R7).
   - **No one connects** → suspect a **shared/service break** (issuing CA down, ISE unreachable, the Entra↔ISE compliance connector broken, an expired ISE server certificate). Skip the per-device branches and go to **Branch F**.
   - **Others connect, this device doesn't** → it is a **device-specific** fault. Continue.
2. **Run the collector once** to snapshot all layers at the device:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Collect.ps1
   ```
   It writes a bundle (cert state, VPN client/profile state, and — if you connect Graph — compliance/enrollment). Then pick the branch matching the **symptom** below.

**Symptom → branch:**

| Symptom | Branch | Layer it starts at |
|---------|--------|--------------------|
| No VPN certificate on the device at all | **A** | L1 Certificate/Profile |
| Certificate present, but chain/trust is broken | **B** | L1 Certificate/Profile |
| Client won't even try / can't reach the gateway | **C** | L2 Client Connect |
| EAP-TLS authentication fails | **D** | L3 EAP-TLS Chain |
| Authenticates, but is denied / quarantined by posture | **E** | L4 Posture/Authorization |
| No device connects (service-wide) | **F** | Shared/service |

---

## Branch A — No VPN certificate on the device (isolates L1)

**Symptom:** Cisco Secure Client has no certificate to present, or the certificate picker is empty. The **VPN client-authentication certificate** is missing from the device store.

**Checks:**

1. **Device store (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1
   ```
   Confirm whether any client-authentication certificate from the expected issuer exists in `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`. If **none**, this is a delivery failure — continue.
2. **Profile assignment (Intune).** In `https://intune.microsoft.com` → **Devices → All devices →** the failing device **→ Configuration**. Find the **certificate configuration profile** (SCEP or PKCS). Read its per-device status.
   - Status **Not applicable** → the device isn't in the profile's assignment scope. Check group membership (is it in the intended group / **CISEDIAG-Pilot-Devices**?).
   - Status **Error / Failed** → open the status detail; note the error (common: SCEP challenge/NDES connectivity, template permissions, key-storage-provider mismatch).
   - Status **Pending** → the device hasn't checked in / applied yet. Confirm the device is **enrolled** and syncing.
3. **Enrollment/compliance (Graph).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1
   ```
   Confirm the device is actually **enrolled and managed**. A device Intune doesn't manage will never receive the certificate.

**Layer isolated:** L1 — certificate delivery from Intune.

**Typical fix:** Correct the assignment (add device to the target group), remediate the SCEP/PKCS profile error (NDES/connector, template ACL, KSP), or fix enrollment. Force a sync and re-run `CISEDIAG-Validate-Certificate.ps1`. Confirm with **Gate A** in `05-testing.md`.

---

## Branch B — Certificate present, but the chain/trust is broken (isolates L1)

**Symptom:** A certificate exists, but it won't be accepted — wrong issuer, missing intermediate, expired, revoked, no private key, or the device doesn't trust the **ISE server certificate**.

**Checks:**

1. **Full chain (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1
   ```
   It reports, for each candidate certificate: **has private key**, **not expired**, **Client Authentication EKU present**, **chains to a trusted root**, and any **chain error status**. Look for:
   - **No private key** → the cert was imported without its key (PKCS export issue) or the SCEP key generation failed.
   - **Chain incomplete / untrusted root** → the issuing CA's **intermediate/root** isn't in the device's trusted stores. This is delivered by the **trusted-root certificate profile**.
   - **Expired / not-yet-valid** → clock or renewal problem.
2. **Trusted-root profile (Intune).** In Intune → the failing device → **Configuration**, confirm the **trusted-root certificate profile** shows **Succeeded**. If it's missing/failed, the device can't validate the ISE server cert (this later shows as an L3 EAP-TLS failure — but the root cause is here at L1).
3. **Issuer match to reference (R7).** Compare the certificate's **issuer** and **template** to the known-good reference device. A mismatch means the wrong CA/template issued it.
4. **Revocation.** The script flags a revoked status if reachable. If CRL/OCSP is unreachable from the device, note it — ISE may still reject on revocation-check failure at L3.

**Layer isolated:** L1 — certificate validity and trust chain on the device.

**Typical fix:** Deploy/repair the **trusted-root certificate profile**; reissue the certificate from the correct template with an exportable-key/SCEP config that produces a private key; fix time sync; resolve CRL/OCSP reachability. Re-run the validator. Confirm with **Gate B**.

---

## Branch C — Client won't try, or can't reach the gateway (isolates L2)

**Symptom:** Cisco Secure Client shows no profile, the wrong head-end, "unable to contact," or never launches the authentication handshake. The certificate (L1) checked out in Branch A/B.

**Checks:**

1. **VPN profile on the device (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-VpnClient.ps1
   ```
   It reports: is a **Cisco Secure Client / VPN service** present and running, is there a **VPN configuration profile** on the device, and what **gateway/head-end** and connection state it reports. Look for a **missing profile** or the **wrong gateway**.
2. **VPN profile delivery (Intune).** In Intune → the failing device → **Configuration**, find the **VPN configuration profile** and confirm **Succeeded**. If it's **Error/Not applicable**, the client is running on stale/absent config — fix the assignment, exactly as in Branch A step 2.
3. **Client presence & reachability (device side + Cisco).** Confirm Secure Client is installed and can resolve/reach the gateway address (name resolution + basic reachability from the device). If the client launches but reports a transport/connection error to the head-end, that is a **network path** problem (DNS, firewall, egress), not Intune.
4. **Cisco Secure Client evidence (vendor-deferred).** Open the Secure Client status and, if needed, collect the **DART** bundle (R5). Read whether the client **loaded the expected profile** and **which certificate it selected**. **Exact DART collection and the profile-editor menus are deferred to Cisco's official documentation** — this toolkit only tells you the log should show the right profile name and a certificate being presented.

**Layer isolated:** L2 — client configuration and transport to the head-end.

**Typical fix:** Repair the **VPN configuration profile** assignment/delivery in Intune; correct the gateway address; resolve DNS/egress/firewall to the head-end; reinstall/repair Secure Client. For client-internal faults, escalate to Cisco with the DART bundle (see `06-troubleshooting.md`). Confirm with **Gate C**.

---

## Branch D — EAP-TLS authentication fails (isolates L3)

**Symptom:** The client reaches ISE and tries to authenticate, but authentication **fails** — the tunnel drops at login. L1 (Branch A/B) and L2 (Branch C) already checked out clean.

**Checks:**

1. **Confirm the attempt reached ISE (vendor evidence).** In the ISE authentication **live logs**, locate the failing attempt by username/MAC/timestamp. If **no event appears**, the request never arrived — drop back to **Branch C** (transport) or a network/RADIUS path issue. If an event **does** appear with an EAP-TLS failure, continue.
2. **Read the EAP-TLS failure reason (vendor evidence).** Open the **detailed authentication report** for that attempt and read the failure reason. **Exact ISE navigation is deferred to Cisco docs**, but the reason typically points squarely back to an L1 fact:
   - *"Certificate chain validation failed" / "unable to build chain"* → an **intermediate/root** ISE needs isn't trusted, or the device cert's chain is incomplete → return to **Branch B** (trusted-root profile) and confirm ISE's CA trust store on the Cisco side.
   - *"Revocation check failed" / "certificate revoked"* → CRL/OCSP problem or a genuinely revoked cert → **Branch B** step 4.
   - *"Unknown CA" / device cert issuer not trusted by ISE* → ISE isn't configured to trust your issuing CA (Cisco-side trust store) → escalate to ISE admin with the issuer name.
   - *"Identity not found" / subject-to-identity mapping failed* → the cert's SAN/CN doesn't map to a known identity in ISE's certificate-authentication profile → confirm the **template's subject/SAN** matches what ISE expects (compare to R7 reference).
3. **Device-side corroboration.** Re-run `CISEDIAG-Validate-Certificate.ps1` and confirm the chain the device builds matches what ISE expects (same root, complete intermediates, valid dates, private key present).

**Layer isolated:** L3 — mutual certificate authentication between device and ISE.

**Typical fix:** Almost always a chain/trust correction that lives at L1 (deploy the right **trusted-root certificate profile**, reissue from the right template with the right SAN/CN) **or** an ISE-side trust/identity-mapping correction (Cisco). Fix, reconnect, and read the ISE log again. Confirm with **Gate D**.

---

## Branch E — Authenticates, but is denied or quarantined by posture (isolates L4)

**Symptom:** Authentication **succeeds** (Branch D is clean) but the user gets **no access, limited access, a quarantine/redirect, or a remediation page.** ISE authorized the session to a restricted result.

**Checks:**

1. **Read the matched authorization result (vendor evidence).** In the ISE detailed authentication report, read **which authorization rule/profile matched** — e.g. a "compliant → permit" rule vs. a "non-compliant/unknown → quarantine" rule. **Exact ISE posture navigation is deferred to Cisco docs**; you only need which result matched and on what condition (typically the compliance/posture signal).
2. **Read Intune's compliance verdict (Graph — this is your side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1
   ```
   It reports the device's **compliance state**, **enrollment state**, **ownership**, and **management** as Intune holds them — i.e. the exact signal ISE reads through the Entra↔ISE connector. Compare:
   - **Intune says Compliant, ISE quarantined it** → the **compliance signal isn't reaching ISE**: the Entra↔ISE compliance connector is broken, or ISE is matching on a stale/absent value → **Branch F** connector checks, and confirm on the Cisco side that ISE received a compliance status.
   - **Intune says Non-compliant** → posture is working correctly; the device genuinely fails a compliance policy. Read *which* compliance policy failed in Intune (**Devices → the device → Compliance**) and remediate the policy setting (encryption, OS version, defender, etc.).
   - **Intune says Not enrolled / Unknown** → ISE can't get a compliant verdict for a device it doesn't see as managed → return to enrollment (**Branch A** step 3).
3. **Identity match.** Confirm the device object ISE is asking Entra about is the **same** object that's compliant in Intune (device ID / Entra device match). A mismatched or duplicate device record makes a compliant device look unknown to ISE.

**Layer isolated:** L4 — posture/authorization, split between the Intune compliance verdict (your side) and the ISE authorization policy + connector (Cisco side).

**Typical fix:** If genuinely non-compliant, remediate the failing Intune compliance policy on the device. If Intune says compliant but ISE disagrees, repair the **Entra↔ISE compliance connector** (Branch F) and the device-identity match. Confirm with **Gate E**.

---

## Branch F — No device connects (isolates a shared/service break)

**Symptom:** From Step 0, **nobody** connects — not the known-good reference. The fault is shared, not per-device.

**Checks (top-down, mostly vendor-side evidence):**

1. **Certificate issuance service.** Are *new* certificates being issued at all? A new pilot device from **CISEDIAG-Pilot-Devices** that gets no cert points at the issuing CA / SCEP (NDES) / connector. Check the **certificate configuration profile** status across several devices in Intune — a fleet-wide **Error** implies the issuing pipeline, not the device.
2. **ISE reachability & server certificate (vendor evidence).** With the ISE admin, confirm ISE is up and its **server certificate is valid (not expired)**. An expired ISE server certificate breaks EAP-TLS for **everyone** at L3 simultaneously — a classic fleet-wide outage. **Exact ISE checks are deferred to Cisco docs.**
3. **Entra↔ISE compliance connector.** If everyone authenticates but everyone is quarantined, the **compliance connector** between Entra and ISE is likely down — ISE sees every device as unknown/non-compliant. Confirm the connector/service health on both sides. Run `CISEDIAG-Check-Compliance.ps1` against several devices: if Intune reports them **compliant** but all are quarantined, the break is the connector, not compliance.
4. **Network/RADIUS path.** If no authentication events reach ISE at all, suspect the network/RADIUS path or the head-end itself (Cisco side).

**Layer isolated:** shared service — issuing CA, ISE availability/server cert, or the Entra↔ISE connector.

**Typical fix:** Restore the affected shared service (renew the ISE server certificate, repair NDES/connector, restore the compliance connector). Because these are outward-facing production services, coordinate change control before touching them. Confirm the reference device recovers, then re-run the per-device branches for any stragglers. Confirm with **Gate F**.

---

## Fast reference — the tree at a glance

```
Step 0: Does anyone connect?
  ├─ No one  ───────────────────────────────────► Branch F (shared/service)
  └─ Only this device fails → run Collect → symptom:
        No cert at all ............................ Branch A  (L1)
        Cert present, chain/trust broken ......... Branch B  (L1)
        Client won't try / no gateway ............ Branch C  (L2)
        EAP-TLS fails ............................ Branch D  (L3)  ── usually loops back to B
        Authenticated but quarantined ............ Branch E  (L4)  ── splits Intune vs. connector
```

Every descent obeys the rule: **prove the layer above is healthy first.** Most L3/L4 failures resolve to an L1 certificate/trust fact or an L4 connector fact — the tree is built to send you back there instead of chasing symptoms.
