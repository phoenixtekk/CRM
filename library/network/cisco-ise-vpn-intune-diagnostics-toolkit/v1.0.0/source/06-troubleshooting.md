# Troubleshooting — Edge Cases and Escalation to Cisco

The Diagnostic Playbook (`03-implementation.md`) resolves the common failures. This section covers the **edge cases** that don't fall cleanly onto a branch, and the **evidence checklist** to hand Cisco when the fault proves to live inside Cisco Secure Client or ISE. Everything here stays **read-only**.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

## Edge cases

### 1. Two certificates, wrong one selected
The device has more than one client-authentication certificate (e.g. an old and a renewed one, or a user and a device cert). Secure Client presents the wrong one, and ISE rejects it at L3. `CISEDIAG-Validate-Certificate.ps1` will list **multiple PASS certs** — that's the tell. Compare issuer/template/validity to the R7 reference to identify the intended cert. The selection rule (which cert Secure Client presents) is Cisco-side profile logic — deferred to Cisco docs — but the presence of a stale duplicate is your L1 evidence.

### 2. Certificate valid on the device but revoked/unknown at ISE
`CISEDIAG-Validate-Certificate.ps1` shows a clean chain locally, yet ISE logs *"revocation check failed"* or *"unknown CA."* Two distinct causes: (a) **CRL/OCSP reachable from the device but not from ISE**, or vice-versa — revocation is checked at *both* ends; (b) ISE's own **CA trust store** doesn't include your issuing CA. Both are resolved on the ISE/network side; your evidence is the local clean chain plus the issuer name to give the ISE admin.

### 3. Clock skew
A device whose clock is off makes an in-date certificate appear **not-yet-valid** or **expired**, and breaks TLS. The validator flags `NotYetValid`/`Expired`; if the cert dates look fine but validation still fails on time, check device time sync. This masquerades as an L1 cert fault and an L3 EAP-TLS fault simultaneously.

### 4. Compliant device, still quarantined (grace / staleness)
Intune reports **compliant** (confirmed by `CISEDIAG-Check-Compliance.ps1`) but ISE quarantines. Beyond a broken connector (Branch F), the compliance signal ISE holds can be **stale** — the device just became compliant and ISE hasn't received the update, or a compliance **grace period** is in play. Check `LastSyncDateTime` in the compliance output; a device that hasn't synced recently may be compliant locally but not yet reflected to ISE. Force a device check-in (user-initiated, not a script action) and re-read.

### 5. Duplicate / mismatched device identity
A device re-enrolled or re-imaged can leave a **duplicate object**; ISE may query Entra for a device ID that maps to the stale, non-compliant record. `CISEDIAG-Check-Compliance.ps1` returning **more than one device** for the name is the tell. Confirm the `AzureAdDeviceId` ISE is asking about matches the *compliant* record.

### 6. Always-on / trusted-network detection
If Secure Client is configured always-on or with trusted-network detection, it may **decline to connect** on a network it considers "trusted," which looks like an L2 failure but is expected behavior. This is Cisco-side profile logic (deferred to Cisco docs); rule it out before deep-diving L2.

### 7. Per-user vs. per-device certificate/profile scope
A **certificate configuration profile** or **VPN configuration profile** assigned to a *user* group won't apply when the failing context is the *device* (or vice-versa). In Intune, confirm the profile's **assignment target** matches how the device is used (user-affinity vs. shared device). Status **Not applicable** with correct group membership often means a scope/target mismatch.

### 8. NDES / SCEP connector intermittent
Fleet-wide but *intermittent* certificate failures (some devices get a cert, some error) point at an overloaded or flapping SCEP/NDES connector rather than a single-device fault. Check the **certificate configuration profile** status across several devices in Intune; a scattered mix of Succeeded/Error implies the issuing pipeline. This is Branch F territory even though not everyone fails.

## Escalation to Cisco — evidence checklist

When L2 (Secure Client) or L3/L4 (ISE) internals are the fault, escalate **once, complete**. Cisco console navigation and DART/live-log specifics are **deferred to Cisco's official documentation**; your job is to hand over a package that proves your side is clean and pinpoints the Cisco-side symptom. Include:

- [ ] **`CISEDIAG-Report.ps1` output** — proves L1, L2, and L4-Intune are healthy on your side (or names exactly what isn't).
- [ ] **`CISEDIAG-Validate-Certificate.ps1` output** — the device certificate chain, **issuer, template, EKU, validity, private-key presence, revocation status**.
- [ ] **`CISEDIAG-Check-VpnClient.ps1` output** — the **VPN configuration profile** present on the device and the **gateway** it names.
- [ ] **`CISEDIAG-Check-Compliance.ps1` output** — the Intune **compliance/enrollment** verdict ISE should be reading, with `AzureAdDeviceId` and `LastSyncDateTime`.
- [ ] **Cisco Secure Client DART bundle** — collected per Cisco docs (L2 evidence: profile loaded, certificate selected, transport result).
- [ ] **ISE detailed authentication report** — for the **exact failing attempt** (timestamp / username / MAC), with the **EAP-TLS failure reason** or **matched authorization rule** highlighted.
- [ ] **Known-good reference facts (R7)** — the working device's issuer/template/gateway, so Cisco can diff working vs. failing.
- [ ] **A one-line statement of the isolated layer** — e.g. "L1/L2/L4-Intune confirmed healthy; ISE logs EAP-TLS 'unknown CA' for issuer *your-issuing-ca-name* — requesting ISE CA trust-store review."

A package like this turns a multi-round Cisco case into a single decisive one — the whole point of isolating the layer before you escalate.

## When to stop diagnosing and change something

Diagnosis is read-only by design, but the *fix* changes state. Escalate to a change window (and the owning admin) before:
- Touching any **shared/outward-facing** service (issuing CA, ISE server certificate, the Entra↔ISE connector, RADIUS/network path) — these affect every user at once.
- Reissuing or revoking certificates fleet-wide.
- Modifying a **VPN configuration profile** or **compliance policy** that's assigned broadly.

Confirm any change with the matching gate in `05-testing.md`, then re-run `CISEDIAG-Report.ps1` to prove the layer cleared without opening a new one.
