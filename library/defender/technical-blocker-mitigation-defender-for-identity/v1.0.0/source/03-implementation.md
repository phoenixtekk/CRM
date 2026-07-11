# 3. Implementation Guide — Technical Blocker Mitigation: Defender for Identity

Follow these steps **in order**. This is a **diagnostic loop**, not a build: you assess to pinpoint the blocker, apply one targeted documented fix (in a change window, since it touches a domain controller), re-test the affected sensor, and only then resume the rollout. All scripts are **read-only**; every *fix* is a manual step you apply deliberately. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assess (pinpoint) → Configure (fix) → Pilot (re-test affected sensor) → Validate (confirm healthy + signal) → Expand (resume rollout). Never change a DC's audit policy or account outside a change window, and keep identity response actions approval-gated throughout.

## Naming (set once, reuse verbatim)
- Affected sensor/DC subset: `MDI Blocker Triage – Affected Sensors – Diagnose`
- Advanced-hunting saved query (sensor/telemetry check): `MDI Sensor Blocker Check – Tenant – Diagnose`
- Support bundle output: `MDI Support Bundle – <case> – Escalate`
- Discovery snapshot file: `MDI-blocker-discovery.json`

## Step 1 — Assess: pinpoint the blocker (read-only)
1. Sign in to `security.microsoft.com` as **Security Reader** and open **Settings → Identities → Sensors** to read current sensor health.
2. Run `TBMMDI-Discovery.ps1`. It captures the cloud side of the signal chain: licensed MDI plan, whether identity signal is arriving (`IdentityInfo` / `IdentityLogonEvents` presence), and identity-query signal as a proxy for a working DSA. It records the current state to `MDI-blocker-discovery.json`.
3. On a **sample affected DC** from `MDI Blocker Triage – Affected Sensors – Diagnose`, run `TBMMDI-AuditPolicy.ps1` (read-only) to capture the advanced-audit-policy and NNR readiness the sensor depends on.
4. Read both outputs top-down against the signal chain (Overview §"How signal actually works") and identify the **earliest broken link**:
   - No plan / workspace not activated → **licensing/activation blocker**
   - Sensor Unhealthy/disconnected → **sensor install/health blocker**
   - No identity-query signal → **DSA blocker**
   - NNR ports blocked / no traffic → **network-traffic blocker**
   - Audit subcategories not enabled → **event-collection blocker**

## Step 2 — Assess: confirm sensor reach (read-only)
1. In the sensor's own UI/logs on the affected DC, run its built-in connectivity test to confirm **outbound reach** to the MDI service. *Verify the current MDI service endpoints.*
2. Note whether the failure is service-reach (sensor link) or NNR-port/traffic (network link) — they have different fixes.

## Step 3 — Configure: apply the one targeted fix (manual, documented, in a change window)
Apply **only** the fix for the blocker you identified. Each is a deliberate manual step — the scripts never make these changes.

- **Licensing / activation:** Assign the MDI plan (**Billing → Licenses**) and activate the MDI workspace in **Settings → Identities**. *Verify the exact plan the feature needs in your tenant.*
- **Sensor install / health:** On the affected DC, confirm a **supported OS** and resources, allow the sensor's outbound **service endpoints** at the proxy/firewall (per `global-requirements-defender.md` G5), update to the current sensor version, and reinstall the sensor with a fresh access key if it is corrupt. Confirm the sensor service is running.
- **DSA permissions:** Create/register the read-only **DSA** (gMSA recommended) under **Settings → Identities → Directory Service accounts** with the current required permissions. *Verify current DSA requirements.*
- **Network traffic / NNR:** Open the required **NNR ports** from the DC to endpoints, and confirm the sensor binds the correct network adapter so it sees the DC's traffic. *Verify current NNR port requirements.*
- **Event-collection gaps:** Enable the required **advanced audit policy** subcategories on the DC (per current MDI guidance) so the sensor receives the needed Windows Security events; for non-DC sensors, configure the documented event forwarding.

## Step 4 — Pilot: re-test the fix on the affected sensor only
1. Apply the fix to the sensor/DC in `MDI Blocker Triage – Affected Sensors – Diagnose` only — not every DC.
2. Give the sensor time to reconnect and start reporting (health and tables populate over minutes to hours).
3. Move to validation before touching any other DC.

## Step 5 — Validate: confirm the sensor is healthy and signal flows
1. In **Settings → Identities → Sensors**, confirm the affected sensor shows **Running / Healthy**.
2. Run `TBMMDI-Validate.ps1`. It runs the saved query `MDI Sensor Blocker Check – Tenant – Diagnose` against `IdentityLogonEvents` / `IdentityDirectoryEvents` / `IdentityQueryEvents` and returns pass/fail for identity signal.
3. Re-run `TBMMDI-AuditPolicy.ps1` on the DC to confirm the audit subcategories are now enabled.
4. Run `TBMMDI-Report.ps1` for the before/after evidence.
5. Complete the **Testing Guide** for the blocker class before expanding.

## Step 6 — Expand: resume the stalled rollout
1. With the affected sensor healthy and streaming, roll the fix and remaining sensors out to the other domain controllers in change windows until all are healthy.
2. Re-run `TBMMDI-Validate.ps1` after each DC and compare with `TBMMDI-Report.ps1`.
3. If a DC re-introduces the symptom, return to Step 1 for that DC — audit policy or NNR can differ per site.

## Step 7 — Escalate (only if it is a service issue, not your config)
1. If the sensor is on a supported OS, has service reach, the DSA and audit policy are correct, and it still will not go healthy or stream, it may be a Microsoft service issue.
2. Run `TBMMDI-SupportBundle.ps1` to assemble `MDI Support Bundle – <case> – Escalate` — the discovery snapshot, the audit-policy readiness output, the affected DC list, and timestamps — and run the **sensor's own log-collection** on the DC to add its diagnostics.
3. Open a Microsoft support case, attach the bundle, and reference the escalation criteria in the Troubleshooting Guide. *Incident-response decisions remain the SOC's; this is a service-support escalation.*

---
### Order of operations
`Assess (discovery + audit-policy readiness) → identify earliest broken link → apply the one targeted fix in a change window → re-test the affected sensor → validate healthy + signal → resume rollout → escalate with a bundle only if it is a service issue`
