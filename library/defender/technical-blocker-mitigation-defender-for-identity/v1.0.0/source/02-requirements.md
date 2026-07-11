# 2. Requirements Guide — Technical Blocker Mitigation: Defender for Identity

Verify **every** requirement before diagnosing. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running the MDI blocker diagnostics**. Objects you create are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Read-only access to the Defender portal and Graph hunting
**Description:** **Security Reader** (or higher) in the Defender portal and consent to the read-only advanced-hunting scope (`ThreatHunting.Read.All`).
**Why:** The cloud diagnostics read sensor health context and the `Identity*` hunting tables — all read-only — to pinpoint the blocker.
**Verify:** Sign in to `security.microsoft.com`; confirm **Settings → Identities → Sensors** and **Advanced hunting** load. `TBMMDI-Discovery.ps1` reports the roles/scopes it resolved.
**Implement-if-missing:** Assign **Security Reader**; grant admin consent to `ThreatHunting.Read.All`.

## 2.2 Local read access on the affected domain controller
**Description:** The ability to run a **read-only** local check (as a local admin / audit reader) on the affected DC to inspect the advanced audit policy and NNR readiness.
**Why:** Event-collection and NNR blockers are only confirmable on the DC itself — `auditpol` and local configuration reads show whether the sensor is even being fed the events it needs.
**Verify:** You can run `TBMMDI-AuditPolicy.ps1` on the affected DC and it reports the audit subcategory states.
**Implement-if-missing:** Arrange local read access on the DC (the script makes no changes); coordinate with the AD team.

## 2.3 The affected sensor / domain-controller subset defined
**Description:** A named subset of the sensors/DCs exhibiting the blocker — the ones you will re-test the fix against before resuming. Name it `MDI Blocker Triage – Affected Sensors – Diagnose`.
**Why:** Fixes are validated on the affected sensor first (per `global-requirements-defender.md` G6) in a change window before touching every DC.
**Verify:** The list of affected DCs/sensors exists; `TBMMDI-Validate.ps1` checks identity signal for them.
**Implement-if-missing:** Document the affected DCs/sensors as `MDI Blocker Triage – Affected Sensors – Diagnose`.

## 2.4 Directory Service Account state known
**Description:** Know whether a read-only **DSA** (gMSA recommended) is configured under **Settings → Identities → Directory Service accounts**, and with what account.
**Why:** A missing or under-permissioned DSA is a top blocker for the AD-context detections; you must know its state to diagnose it.
**Verify:** `security.microsoft.com` → **Settings → Identities → Directory Service accounts**; `TBMMDI-Discovery.ps1` notes whether identity-query signal appears (a proxy for a working DSA). *Verify current MDI DSA requirements in your tenant.*
**Implement-if-missing:** Prepare the gMSA and its read permissions per current MDI guidance for the fix step.

## 2.5 Network / NNR reachability knowledge
**Description:** Know the sensor's outbound reach to the MDI service and the **NNR** ports the sensor uses to resolve endpoints from the DC.
**Why:** "Missing network traffic" blockers come from blocked NNR ports or blocked outbound service reach; you must be able to check both.
**Verify:** `TBMMDI-AuditPolicy.ps1` reports NNR-relevant local readiness; the sensor's own connectivity test (in the sensor UI/logs) confirms outbound reach. *Verify the current MDI service endpoints and NNR ports.*
**Implement-if-missing:** Obtain the current MDI endpoint/NNR port list and work with networking to test them.

## 2.6 A place to store the diagnostic output and support bundle
**Description:** A secure location for the JSON snapshots the scripts write and for the support bundle `MDI Support Bundle – <case> – Escalate`.
**Why:** The before/after snapshots prove the sensor became healthy, and the bundle is what you attach to a Microsoft support case.
**Verify:** A working folder exists with least-privilege access; `TBMMDI-Report.ps1` writes there.
**Implement-if-missing:** Create a restricted working folder; do not store DC names/tenant identifiers in shared/unsecured locations.

---
## Checklist
- [ ] Security Reader + `ThreatHunting.Read.All` — `TBMMDI-Discovery.ps1`
- [ ] Local read access on the affected DC — `TBMMDI-AuditPolicy.ps1`
- [ ] Affected sensor/DC subset `MDI Blocker Triage – Affected Sensors – Diagnose` documented
- [ ] DSA (gMSA) state known
- [ ] Network / NNR reachability checkable (service endpoints + NNR ports)
- [ ] Secure working folder for snapshots and the support bundle
