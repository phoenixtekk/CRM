# Troubleshooting

Work top to bottom — the first sections cover the failures that block everything else
(authentication and connector), the later sections cover the two dangerous logic failures
(compliant device denied, non-compliant device allowed). For the Intune/Entra/Graph side use
the diagnosis steps below; for anything inside the **Cisco ISE console**, follow **Cisco's
official documentation** — those internals are deferred to the vendor.

---

## 1. App registration / permission errors

**Symptom:** ISE's Test Connection fails with an authentication or authorization error; or
`ISEPOST-Discovery.ps1` reports the app, secret, or permissions as FAIL.

**Diagnose:**
- Run `ISEPOST-Discovery.ps1`. It checks the app `ISE-Intune-Compliance-Connector`, secret
  expiry, the Graph permissions, and admin consent.

**Common causes and fixes:**
- **Wrong client/tenant id or secret in ISE** — re-copy the Application (client) ID and
  Directory (tenant) ID from the app's Overview, and re-generate the client secret if unsure;
  paste the secret **Value** (not the Secret ID) into ISE. (Implementation Steps 1, 3.)
- **Expired client secret** — Discovery flags this as FAIL/WARN. Create a new secret and update
  it in ISE. An expired secret is the most common "it worked last quarter" outage.
- **Permission missing or not consented** — the Graph permissions
  `DeviceManagementManagedDevices.Read.All` and `DeviceManagementConfiguration.Read.All` must be
  present **and** show "Granted for &lt;tenant&gt;". Add them and click **Grant admin consent**
  (Implementation Step 2).
- **Delegated instead of Application permissions** — ISE runs unattended; the permissions must
  be **Application** type, not Delegated. Remove delegated, add application, re-consent.

---

## 2. Connector not reporting (ISE reads no compliance state)

**Symptom:** ISE authenticates but gets no device data, or every device looks unmanaged;
Test Connection may pass yet authorization sees empty MDM attributes.

**Diagnose:**
- Confirm the device is actually enrolled: run `ISEPOST-Validation.ps1` on the device (or check
  Intune → Devices → All devices).
- Confirm reachability: the connector is an outbound HTTPS call from ISE to Microsoft Graph /
  Entra (Requirement R5).

**Common causes and fixes:**
- **Egress / TLS interception** — a firewall blocking 443 to Microsoft, or a proxy that breaks
  the TLS chain, stops the connector. Open outbound 443 to the Graph/Entra endpoints and ensure
  no TLS interception on that path.
- **Missing Microsoft CA in ISE trust store** — import the required Microsoft root/intermediate
  CAs into ISE's trusted certificate store (per Cisco's documentation), then retest.
- **Device not enrolled** — an unenrolled device has no state to report; enroll it (R1).
- **Read permission missing** — without `DeviceManagementManagedDevices.Read.All` the connector
  authenticates but reads nothing. Re-check Section 1.

---

## 3. Compliant device denied (false lockout — positive path broken)

**Symptom:** A device that Intune shows as **compliant** is still denied network / VPN access
by ISE. This generates user complaints and must be fixed fast.

**Diagnose:**
- Run `ISEPOST-Validation.ps1` on the device. If it reports **enrolled + compliant** but ISE
  still denies, the break is between the compliance verdict and the ISE decision.
- Check the device's **last Intune sync** time (Validation prints it). A stale device may have
  an old non-compliant verdict cached.

**Common causes and fixes:**
- **Stale compliance state** — the device fixed the issue but hasn't re-synced. Force a sync
  (`ISEPOST-Remediation.ps1`, or Company Portal → sync) and retry.
- **Grace vs compliant mismatch** — if you intended in-grace devices to be granted, confirm the
  ISE rule treats `inGracePeriod` as compliant; if it only permits strict `compliant`, in-grace
  devices are denied. Align the rule or the grace policy (Best Practices).
- **ISE authorization rule mismatch** — the rule's registered/compliant condition or rule order
  may be wrong so a compliant device falls through to a deny. Review the ISE authorization
  policy per **Cisco's documentation** (rule order, condition attributes, the permit profile).
- **Policy not assigned to the device** — if no compliance policy targets the device, Intune may
  report "not evaluated" rather than compliant. Confirm the baseline policy is assigned to the
  device's group (`ISEPOST-Discovery.ps1` shows assignment counts).

---

## 4. Non-compliant device allowed (enforcement gap — critical)

**Symptom:** A device that Intune shows as **non-compliant** still gets full network / VPN
access. **This defeats the entire solution — stop the rollout and fix it before expanding.**

**Diagnose:**
- Run `ISEPOST-Validation.ps1` on the offending device — confirm Intune actually marks it
  non-compliant (if Intune says compliant, the problem is your compliance policy, not ISE).
- Confirm the connecting path is actually ISE-mediated (that the VPN/switch/WLC sends auth to
  ISE and honors the returned authorization result).

**Common causes and fixes:**
- **Compliance policy too weak / not assigned** — if the device is non-compliant only in
  intent but Intune reports it compliant, the baseline policy is missing the rule or isn't
  assigned to the device. Tighten and assign the `Compliance – <platform> – Baseline` policy
  (Implementation Step 5); `ISEPOST-Discovery.ps1` confirms presence and assignment.
- **Grace period masking it** — an `inGracePeriod` device is intentionally still granted. If you
  need immediate denial for a high-risk signal (encryption off, jailbreak/root), remove or
  shorten grace on that rule (Best Practices).
- **ISE rule not evaluating MDM compliance** — the authorization rule may permit before checking
  the compliant attribute, or a broader permit rule sits above it. Fix rule order/conditions in
  the ISE authorization policy per **Cisco's documentation** so the non-compliant path reaches a
  deny/quarantine result.
- **Network device bypassing ISE** — a VPN headend or switchport not enforcing the ISE result
  (or a fallback/open-auth mode) lets devices on regardless. Confirm enforcement on the network
  access device per its vendor documentation.

---

## 5. Quick reference — which tool for which symptom

| Symptom | First tool |
|---------|-----------|
| Auth / permission / secret error | `ISEPOST-Discovery.ps1` |
| One device's state wrong | `ISEPOST-Validation.ps1` |
| Fleet-wide granted/denied split off | `ISEPOST-Report.ps1` |
| Non-compliant devices need nudging | `ISEPOST-Remediation.ps1` (`-WhatIf` first) |
| Pilot/prod scope group missing | `ISEPOST-Set-ScopeTargeting.ps1` |
| Anything inside the ISE console | Cisco's official ISE documentation |
