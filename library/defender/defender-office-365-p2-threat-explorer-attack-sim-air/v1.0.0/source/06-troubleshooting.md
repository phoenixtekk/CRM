# Troubleshooting — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

The common failure modes, each as **symptom → cause → fix**. Most issues are licensing, table
freshness, or an approval-posture surprise — not a broken feature.

---

## 1. "Explorer" is missing — I only see "Real-time detections"

- **Symptom:** Under Email & collaboration there is **Real-time detections** but no **Explorer**.
- **Cause:** The tenant/user is on **Defender for Office 365 Plan 1**, not Plan 2. Threat Explorer is
  a Plan 2 feature.
- **Fix:** Verify licensing (R1) — assign MDO **Plan 2** to the users in scope and allow provisioning
  time. Confirm with `DEFMDOP2-Discovery.ps1`. *Verify current plan-to-feature mapping in your tenant.*

## 2. Attack Simulation Training blade is absent or greyed out

- **Symptom:** No **Attack simulation training** blade, or "not available".
- **Cause:** Missing Plan 2, or the feature is still provisioning, or the account lacks the role.
- **Fix:** Confirm Plan 2 (R1); wait for provisioning; confirm the account holds the required role
  (R3). *Feature availability can differ by cloud (GCC/GCC High) — verify.*

## 3. Advanced Hunting email tables return nothing (EmailEvents empty)

- **Symptom:** `EmailEvents | count` returns 0, hunts and reports come back empty.
- **Cause:** Plan 2 not provisioned, no mail flowing yet, or the table/column names differ in your
  cloud.
- **Fix:** Confirm Plan 2 and that mail is actually flowing; check freshness with
  `DEFMDOP2-Discovery.ps1`. If a query errors on a column, **verify the schema for your tenant/cloud**
  — Microsoft renames/reshapes hunting tables periodically.

## 4. A hunting query errors ("unknown table/column")

- **Symptom:** `DEFMDOP2-Hunt.ps1` or a portal query fails to resolve a table or column
  (e.g. `UrlClickInfo`, `IsClickedThrough`).
- **Cause:** Schema drift — the delivered KQL uses representative names that evolve.
- **Fix:** Open **Advanced hunting → schema** and correct the table/column to your tenant's current
  names; the library is a starting point, not a frozen contract. *Verify current schema.*

## 5. AIR opened an investigation but **auto-deleted** mail during the pilot

- **Symptom:** Mail was removed without anyone approving it.
- **Cause:** AIR automation is set **higher than approval-required**; the pilot should hold actions.
- **Fix:** Set AIR back to an **approval-required** posture (Step 1.2) so actions land in the **Action
  center → Pending**. `DEFMDOP2-Validate.ps1` flags auto-applied actions as a FAIL. Only raise
  automation later as a **documented operations decision (R6)**.

## 6. AIR actions never appear for approval

- **Symptom:** Nothing shows in **Action center → Pending** even after an alert.
- **Cause:** AIR not enabled, no qualifying alert fired, or the account cannot see the Action center.
- **Fix:** Confirm AIR is enabled; trigger it the safe way (have a pilot user **Report** a
  test/benign message); confirm the account has rights to view/approve actions (R3).

## 7. `DEFMDOP2-Remediate.ps1` "won't do anything"

- **Symptom:** The script prints a preview and exits without remediating.
- **Cause:** **Working as designed.** Preview (`-WhatIf`) is the default; execution is double-gated.
- **Fix:** To act, re-run with **`-Execute -Confirm`** (and **`-IUnderstandHardDelete`** for
  hard-delete), then **approve the batch in the Action center**. Start with **SoftDelete**
  (recoverable) before ever using HardDelete. This gating is intentional — never wire it to run
  unattended.

## 8. Simulated phish was blocked / never delivered to targets

- **Symptom:** Users did not receive the simulation; results are empty.
- **Cause:** The simulation URLs/domains are not allowed for simulation, or advanced delivery isn't
  configured for the simulation source.
- **Fix:** Configure the **Advanced delivery** policy for third-party/simulation URLs so simulations
  bypass filtering as intended. *This is a prevention-layer setting — confirm it with the companion
  Mail Hygiene solution; verify current configuration steps.*

## 9. Attack-simulation report is empty from PowerShell but present in the portal

- **Symptom:** `DEFMDOP2-Report.ps1` shows no simulations, but the portal does.
- **Cause:** The Graph **attack-simulation endpoints are beta** and may be unavailable, permission-
  gated, or absent in your cloud.
- **Fix:** Use the portal report for authoritative per-user detail; grant `AttackSimulation.Read.All`
  where the beta API is available. *Verify current API availability for your cloud.* The script
  degrades gracefully by design.

## 10. Graph/EXO connection or permission errors

- **Symptom:** `Connect-MgGraph` / `Connect-ExchangeOnline` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement`; connect with the correct
  `-Environment` for Government cloud; consent the read scopes listed in each script header; confirm
  the operating account holds the role (R3). *Verify the correct endpoints for your cloud.*
