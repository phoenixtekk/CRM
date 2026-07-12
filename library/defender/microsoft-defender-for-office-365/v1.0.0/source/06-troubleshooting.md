# Troubleshooting — Microsoft Defender for Office 365

The common failure modes, each as **symptom → cause → fix**. Most issues are licensing, email-table
freshness, an approval-posture surprise, or a benign-signal timing/scope question — not a broken
feature. Run `MDOFULL-Discovery.ps1` and `MDOFULL-Validate.ps1` first — most causes surface there. All
PoC signal is benign (Attack Simulation / GTUBE / EICAR / benign test URL).

---

## 1. "Explorer" is missing — I only see "Real-time detections"

- **Symptom:** Under Email & collaboration there is **Real-time detections** but no **Explorer**.
- **Cause:** The tenant/user is on **MDO Plan 1**; Threat Explorer is a Plan 2 feature.
- **Fix:** Verify licensing (R1) — assign MDO **Plan 2** and allow provisioning time; confirm with
  `MDOFULL-Discovery.ps1`. On Plan 1 run the Real-time-detections + protection-stack labs and the
  GTUBE/EICAR/Safe Links PoC path. *Verify plan-to-feature mapping.*

## 2. Attack Simulation Training blade is absent or greyed out

- **Symptom:** No **Attack simulation training** blade, or "not available".
- **Cause:** Missing Plan 2, still provisioning, or the account lacks the **Attack Simulation
  Administrator** role.
- **Fix:** Confirm Plan 2 (R1); wait for provisioning; confirm the instructor holds the role (R5). If
  P2 is unavailable, run the GTUBE/EICAR/Safe Links signal only and record the simulation demo as "not
  licensed," not "failed." *Feature availability can differ by cloud (GCC/GCC High) — verify.*

## 3. Email advanced-hunting tables return nothing (EmailEvents empty)

- **Symptom:** `EmailEvents | count` returns 0; hunts and PoC validation come back empty.
- **Cause:** Plan 2 not provisioned, no mail flowing yet, or table/column names differ in your cloud.
- **Fix:** Confirm Plan 2 and that mail is flowing; check freshness with `MDOFULL-Discovery.ps1`. If a
  query errors on a column, **verify the schema for your tenant/cloud** — Microsoft renames hunting
  tables periodically.

## 4. A hunting query errors ("unknown table/column")

- **Symptom:** A Lab 5 or validation query fails to resolve a table/column (e.g. `UrlClickInfo` vs
  `UrlClickEvents`, `IsClickedThrough`).
- **Cause:** Schema drift — the pack uses representative names that evolve and can differ by plan/cloud.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant's current schema.
  *Verify current schema.*

## 5. The protection-stack policies aren't there to inspect (Lab 3), or don't cover the pilot users

- **Symptom:** **Threat policies** has no anti-phish / Safe Links / Safe Attachments to open, or the
  PoC signal isn't actioned for the pilot users.
- **Cause:** The prevention stack hasn't been deployed, or it isn't scoped to
  `Grp-MDOFULL-PilotUsers-Pilot`.
- **Fix:** Deploy/scope the **Mail Hygiene** solution first (R2); Lab 3 needs existing policies to read
  and the PoC needs them applied to the pilot users. This solution inspects but does not create or scope
  them.

## 6. AIR auto-deleted mail during a lab or the PoC

- **Symptom:** Mail was removed without anyone approving it.
- **Cause:** AIR automation is set **higher than approval-required**.
- **Fix:** Set AIR back to **approval-required** (Step 1.2) so actions land in **Action center →
  Pending**. This solution must not auto-remediate (R6). Raising automation is the **Defender for Office
  365 (Plan 2)** solution's decision, not this one's.

## 7. AIR actions never appear for approval

- **Symptom:** Nothing shows in **Action center → Pending** even after an alert.
- **Cause:** AIR not enabled, no qualifying alert fired, or the account can't see the Action center.
- **Fix:** Confirm AIR is enabled; trigger it the safe way (have a pilot user **Report** a benign
  message); confirm the account has rights to view the Action center (R5).

## 8. Benign test message not delivered (GTUBE / EICAR / Safe Links)

- **Symptom:** A GTUBE / EICAR / Safe Links test message never arrives at the pilot mailbox.
- **Cause:** The message was **caught before delivery** (expected for EICAR/GTUBE — check quarantine),
  the sending account is not permitted, or mail flow is misrouted.
- **Fix:** Check **Review → Quarantine** — EICAR/GTUBE messages are *meant* to be caught; that is a
  **pass**, not a delivery failure. Confirm the `-From` sender is permitted (has `Mail.Send`) and
  Exchange Online mail flow. Re-run `MDOFULL-TestSignal.ps1`.

## 9. Safe Links not rewriting / Safe Attachments not detonating

- **Symptom:** The benign test URL isn't rewritten, or the EICAR attachment is delivered without action.
- **Cause:** The prevention preset isn't applied to the pilot users, Safe Links/Safe Attachments is off
  in the applied policy, the MDO plan isn't licensed, or the message bypassed policy (internal-sender
  exceptions).
- **Fix:** Confirm the prevention policy covers the pilot users and Safe Links/Safe Attachments is on
  (Gate 2 — deploy via **Mail Hygiene** if missing); send from an **external** test sender; allow a
  moment for time-of-click / detonation and re-check `UrlClickInfo` / `EmailAttachmentInfo` with
  `MDOFULL-Validate.ps1`. *Verify current plan features.*

## 10. Simulated phish was blocked / never delivered to the pilot users

- **Symptom:** Pilot users didn't receive `Sim-MDOFULL-Pilot`; results are empty.
- **Cause:** The simulation URLs/domains aren't allowed, or advanced delivery isn't configured for the
  simulation source.
- **Fix:** Configure the **Advanced delivery** policy for simulation URLs so simulations bypass
  filtering as intended. *This is a prevention-layer setting — confirm with the Mail Hygiene solution;
  verify current steps.*

## 11. "Create detection rule" is greyed out, or the detection is noisy

- **Symptom:** You can't create `Detect-MDOFULL-Pilot`, or once created it floods with alerts.
- **Cause:** The account lacks the authoring role; or the underlying hunt wasn't tuned before promotion.
- **Fix:** Have the **instructor** author it (R5); ensure the query projects the mapped entities
  (RecipientEmailAddress, Url). If noisy, disable it, tighten the Lab 5 query, and recreate it
  **alert-only**. Never promote a noisy hunt.

## 12. No Explorer / simulation visibility during the PoC demo

- **Symptom:** Threat Explorer or the simulation shows nothing during the live demo.
- **Cause:** Threat Explorer / Attack Simulation Training require **P2**, or the signal hasn't populated
  yet (detonation/ZAP act after delivery).
- **Fix:** Confirm **P2** licensing (*verify current availability*); allow warm-up time for
  `EmailEvents`; re-run `MDOFULL-Validate.ps1`. If P2 is unavailable, record the Explorer/simulation
  demos as "not licensed," not "failed."

## 13. Attack-sim report is empty from PowerShell but present in the portal

- **Symptom:** `MDOFULL-Report.ps1` shows no simulations, but the portal does.
- **Cause:** The Graph **attack-simulation endpoints are beta** and may be unavailable, permission-
  gated, or absent in your cloud.
- **Fix:** Use the portal report for authoritative per-user detail; grant `AttackSimulation.Read.All`
  where the beta API is available. *Verify current API availability for your cloud.* The script degrades
  gracefully by design.

## 14. Graph/EXO connection or permission errors

- **Symptom:** `Connect-MgGraph` / `Connect-ExchangeOnline` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement`; connect with the correct
  `-Environment` for Government cloud; consent the read/hunt (and `Mail.Send` for signal) scopes in each
  script header; confirm the account holds the right role (R5). *Verify the correct endpoints for your
  cloud.*

## 15. Teardown left residue

- **Symptom:** After `MDOFULL-TestSignal.ps1 -Teardown`, benign test messages or the simulation remain.
- **Cause:** Teardown ran in `-WhatIf` only, the quarantine purge needs the quarantine role, or the
  simulation must be ended in the portal.
- **Fix:** Run teardown **without** `-WhatIf`; confirm the **Quarantine / Security Administrator** role;
  end the campaign `Sim-MDOFULL-Pilot` in Attack Simulation Training; re-confirm with
  `MDOFULL-Validate.ps1`.
