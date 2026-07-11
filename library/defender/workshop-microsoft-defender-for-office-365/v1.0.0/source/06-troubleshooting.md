# Troubleshooting — Workshop: Microsoft Defender for Office 365

The common failure modes, each as **symptom → cause → fix**. Most workshop issues are licensing,
email-table freshness, or an approval-posture surprise — not a broken feature.

---

## 1. "Explorer" is missing — I only see "Real-time detections"

- **Symptom:** Under Email & collaboration there is **Real-time detections** but no **Explorer**.
- **Cause:** The tenant/user is on **MDO Plan 1**; Threat Explorer is a Plan 2 feature.
- **Fix:** Verify licensing (R1) — assign MDO **Plan 2** and allow provisioning time; confirm with
  `WSMDO-Discovery.ps1`. On Plan 1 run the Real-time-detections + protection-stack labs. *Verify
  plan-to-feature mapping.*

## 2. Attack Simulation Training blade is absent or greyed out

- **Symptom:** No **Attack simulation training** blade, or "not available".
- **Cause:** Missing Plan 2, still provisioning, or the account lacks the role.
- **Fix:** Confirm Plan 2 (R1); wait for provisioning; confirm the instructor holds the role (R5).
  *Feature availability can differ by cloud (GCC/GCC High) — verify.*

## 3. Email advanced-hunting tables return nothing (EmailEvents empty)

- **Symptom:** `EmailEvents | count` returns 0; hunts come back empty.
- **Cause:** Plan 2 not provisioned, no mail flowing yet, or table/column names differ in your cloud.
- **Fix:** Confirm Plan 2 and that mail is flowing; check freshness with `WSMDO-Discovery.ps1`. If a
  query errors on a column, **verify the schema for your tenant/cloud** — Microsoft renames hunting
  tables periodically.

## 4. A hunting query errors ("unknown table/column")

- **Symptom:** A Lab 5 query fails to resolve a table/column (e.g. `UrlClickInfo`, `IsClickedThrough`).
- **Cause:** Schema drift — the pack uses representative names that evolve.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant’s current schema.
  *Verify current schema.*

## 5. The protection-stack policies aren’t there to inspect (Lab 3)

- **Symptom:** **Threat policies** has no anti-phish / Safe Links / Safe Attachments to open.
- **Cause:** The prevention stack hasn’t been deployed.
- **Fix:** Deploy the **Mail Hygiene** solution first (R2); Lab 3 needs existing policies to read. This
  workshop inspects but does not create them.

## 6. AIR auto-deleted mail during the lab

- **Symptom:** Mail was removed without anyone approving it.
- **Cause:** AIR automation is set **higher than approval-required**.
- **Fix:** Set AIR back to **approval-required** (Step 1.2) so actions land in **Action center →
  Pending**. The workshop must not auto-remediate (R6). Raising automation is the implementation
  solution’s decision, not this workshop’s.

## 7. AIR actions never appear for approval

- **Symptom:** Nothing shows in **Action center → Pending** even after an alert.
- **Cause:** AIR not enabled, no qualifying alert fired, or the account can’t see the Action center.
- **Fix:** Confirm AIR is enabled; trigger it the safe way (have a lab user **Report** a benign
  message); confirm the account has rights to view the Action center (R5).

## 8. Simulated phish was blocked / never delivered to the lab users

- **Symptom:** Lab users didn’t receive `Sim-MDOLab-Pilot`; results are empty.
- **Cause:** The simulation URLs/domains aren’t allowed, or advanced delivery isn’t configured for the
  simulation source.
- **Fix:** Configure the **Advanced delivery** policy for simulation URLs so simulations bypass
  filtering as intended. *This is a prevention-layer setting — confirm with the Mail Hygiene solution;
  verify current steps.*

## 9. "Create detection rule" is greyed out, or the detection is noisy

- **Symptom:** You can’t create `Detect-MDOLab-Pilot`, or once created it floods with alerts.
- **Cause:** The account lacks the authoring role; or the underlying hunt wasn’t tuned before promotion.
- **Fix:** Have the **instructor** author it (R5); ensure the query projects the mapped entities. If
  noisy, disable it, tighten the Lab 5 query, and recreate it **alert-only**. Never promote a noisy
  hunt.

## 10. Attack-sim report is empty from PowerShell but present in the portal

- **Symptom:** `WSMDO-Report.ps1` shows no simulations, but the portal does.
- **Cause:** The Graph **attack-simulation endpoints are beta** and may be unavailable, permission-
  gated, or absent in your cloud.
- **Fix:** Use the portal report for authoritative per-user detail; grant `AttackSimulation.Read.All`
  where the beta API is available. *Verify current API availability for your cloud.* The script
  degrades gracefully by design.

## 11. Graph/EXO connection or permission errors

- **Symptom:** `Connect-MgGraph` / `Connect-ExchangeOnline` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement`; connect with the correct
  `-Environment` for Government cloud; consent the read/hunt scopes in each script header; confirm the
  account holds a read/hunt role (R5). *Verify the correct endpoints for your cloud.*
