# 2. Requirements Guide — Technical Blocker Mitigation: Defender for Endpoint

Verify **every** requirement before diagnosing. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access to service endpoints, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running the MDE blocker diagnostics**. Objects you create are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Read-only access to the Defender portal and Graph
**Description:** **Security Reader** (or higher) in the Defender portal and consent to the read-only Microsoft Graph scopes the diagnostic scripts use (`SecurityEvents.Read.All`, `ThreatHunting.Read.All`, `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`, `Directory.Read.All`).
**Why:** Every script in this solution is read-only; it needs read access to device health, advanced hunting, and the Intune connector/policy state to pinpoint the blocker.
**Verify:** Sign in to `security.microsoft.com`; confirm **Assets → Devices** and **Advanced hunting** load. Run `TBMMDE-Discovery.ps1` — it reports the roles and scopes it resolved.
**Implement-if-missing:** Assign **Security Reader**; grant admin consent to the read scopes above (the script requests them on first run).

## 2.2 The stalled rollout's onboarding channel identified
**Description:** Know which channel was used to onboard the affected devices — **Intune** (default), Configuration Manager, Group Policy, or the local onboarding script.
**Why:** The fix for "device not onboarding" differs by channel; you cannot diagnose a connector you are not using, and you must check the right policy object.
**Verify:** In `intune.microsoft.com` → **Endpoint security → Endpoint detection and response**, confirm whether an EDR onboarding policy exists; note the channel. `TBMMDE-Discovery.ps1` reports the Intune connector state and any EDR policy it finds.
**Implement-if-missing:** Confirm the channel with whoever started the rollout; if no channel exists at all, this is a *first-time onboarding* task (adjacent solution), not a blocker.

## 2.3 The affected device subset defined
**Description:** A named subset of the devices exhibiting the blocker — the ones you will re-test the fix against before resuming the whole rollout. Name it `MDE Blocker Triage – Affected Ring – Diagnose`.
**Why:** Fixes are validated on the affected subset first (per `global-requirements-defender.md` G6), so you prove the fix before touching the rest of the fleet.
**Verify:** The group exists in Entra/Intune and contains the affected devices; `TBMMDE-Validate.ps1` checks membership and per-device state.
**Implement-if-missing:** Create the Entra/Intune group `MDE Blocker Triage – Affected Ring – Diagnose` and add the devices that show the symptom.

## 2.4 Outbound reachability to the Defender service endpoints (from a sample affected device)
**Description:** The ability to test, from a representative affected device, outbound HTTPS to the documented Defender for Endpoint service URLs/IP ranges.
**Why:** The single most common cause of **Inactive / Impaired communication** is a proxy or firewall blocking the service endpoints; you must be able to test this from where the device actually sits.
**Verify:** Run `TBMMDE-Connectivity.ps1` on (or against) a sample affected device to check reachability to the documented endpoints. *Verify the current Defender endpoint URL/IP list in your tenant — Microsoft updates it.*
**Implement-if-missing:** Obtain access to a sample device (or its network path) and the current allow-list; work with networking to test the documented endpoints.

## 2.5 The local MDE diagnostic tooling available (where the fix needs it)
**Description:** On Windows devices, the built-in **`MpCmdRun.exe`** and the Microsoft **Defender client analyzer** are available for local, on-device confirmation when a fix requires it.
**Why:** Some sensor-health blockers are only confirmable on the device itself (agent version, connectivity self-test); the analyzer produces the exact bundle Microsoft support asks for.
**Verify:** Confirm `%ProgramFiles%\Windows Defender\MpCmdRun.exe` exists on a sample device; know where to obtain the current client analyzer. *Verify the current analyzer download in your tenant.*
**Implement-if-missing:** Note the analyzer download location for the escalation step; no install is needed for the read-only cloud diagnostics.

## 2.6 A place to store the diagnostic output and support bundle
**Description:** A secure location for the JSON snapshots the scripts write and for the support bundle `MDE Support Bundle – <case> – Escalate`.
**Why:** The before/after snapshots prove the blocker was cleared, and the bundle is what you attach to a Microsoft support case.
**Verify:** A working folder exists with least-privilege access; `TBMMDE-Report.ps1` writes there.
**Implement-if-missing:** Create a restricted working folder; do not store tenant identifiers in shared/unsecured locations.

---
## Checklist
- [ ] Security Reader + read-only Graph scopes consented — `TBMMDE-Discovery.ps1`
- [ ] Onboarding channel of the stalled rollout identified (Intune / CM / GPO / script)
- [ ] Affected device subset `MDE Blocker Triage – Affected Ring – Diagnose` created
- [ ] Service-endpoint reachability testable from a sample affected device — `TBMMDE-Connectivity.ps1`
- [ ] Local MDE diagnostic tooling (`MpCmdRun.exe` / client analyzer) located
- [ ] Secure working folder for snapshots and the support bundle
