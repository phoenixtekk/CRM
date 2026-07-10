# 5. Testing Guide — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

Run after the pilot is configured (Implementation Step 8) and after each expansion. Scripts referenced: `SOCXDRG-Discovery.ps1`, `SOCXDRG-Validate.ps1`, `SOCXDRG-Report.ps1`, `SOCXDRG-IncidentQueue.ps1`, `SOCXDRG-Set-SocRbacScope.ps1`.

## Test 1 — Connector connected and syncing

**Do:** `portal.azure.us` → `Microsoft Sentinel` → `Security Telemetry - SOC - Workspace` → `Data connectors` → `Microsoft Defender XDR`, or run `SOCXDRG-Validate.ps1`.
**Expected:** Connector status is `Connected` (`Microsoft Defender XDR - SOC - Pilot`); the data-received indicator is recent; incidents & alerts sync is on.

## Test 2 — Defender incidents appear in Sentinel

**Do:** `Microsoft Sentinel` → `Threat management` → `Incidents`; or `Logs` → `SecurityIncident | where TimeGenerated > ago(24h) | take 10`.
**Expected:** Recent Defender XDR incidents are present in the Sentinel queue with their source workload shown.

## Test 3 — No duplicate incidents (de-duplication holds)

**Do:** `Microsoft Sentinel` → `Analytics` → `Active rules` → filter `Microsoft incident creation rule`; or run `SOCXDRG-Report.ps1`.
**Expected:** The Microsoft incident-creation rules for the synced products are `Disabled`. A single test detection (Test 6) produces **one** incident, not a pair.

## Test 4 — Severity / ownership / tags applied on arrival

**Do:** Open the newest incident in the queue, or run `SOCXDRG-IncidentQueue.ps1`.
**Expected:** The incident already has an owner (or SOC group) and the priority/`SOC-Triage` tags from `Incident Alignment - SOC - Pilot`; severity matches the agreed scheme.

## Test 5 — Bi-directional status sync

**Do:** In Sentinel, set a test incident's `Status` to `Active`, then `Closed` with a classification. Open the same incident in `security.microsoft.us` → `Incidents`.
**Expected:** The status/owner/classification change is reflected in the Defender portal (and a change made in Defender reflects back in Sentinel).

## Test 6 — Single-incident end-to-end (the correlation drill)

**Do:** Generate a benign Defender test detection (for example the Defender for Endpoint test/EICAR alert per Microsoft's guidance) on a pilot device.
**Expected:** Exactly one Sentinel incident is created, correlating the related alert(s) and entities (device/user), already owned and tagged — no duplicate from a Microsoft incident-creation rule.

## Test 7 — Triage and hand-off runbook

**Do:** Walk one incident through the runbook (Implementation Step 7): triage → escalate → hand-off comment → re-assign to next shift. Run `SOCXDRG-Report.ps1` for the open-incident hand-off list.
**Expected:** The incident carries the escalation tag, a hand-off comment, and the new owner; the hand-off list shows no untriaged incident older than the SLA.

## Test 8 — RBAC scope correct

**Do:** Sign in as a `SOC-Analysts` member (or run `SOCXDRG-Set-SocRbacScope.ps1` in report mode).
**Expected:** Analysts can triage/respond on incidents (`Microsoft Sentinel Responder`); read-only stakeholders cannot modify; leads hold `Microsoft Sentinel Contributor`.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass: connector syncing, Defender incidents in the queue, duplicate rules disabled, severity/owner/tags applied, bi-directional sync works, and one test detection = one incident |
| Expand pass | Tests 2, 3, 4, 7 pass across all Defender products and the full analyst roster, with the hand-off list clean, before retiring the two-console workflow |
