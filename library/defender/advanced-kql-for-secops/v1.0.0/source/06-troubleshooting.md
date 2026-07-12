# Troubleshooting — Guide: Advanced KQL for SecOps

The common failure modes, each as **symptom → cause → fix**. Most guide issues are empty tables,
schema drift, or a join written the wrong way round — not a broken platform.

---

## 1. A lab query returns nothing (empty result)

- **Symptom:** A lab query runs without error but returns 0 rows.
- **Cause:** The table has no data in the chosen window, the filter is too tight, or the pillar isn’t
  onboarded.
- **Fix:** Widen the time window (`ago(7d)`), relax the filter, and confirm the table is live with
  `WSKQL-Discovery.ps1`. If the table is genuinely empty, run the lab on a table that has data (**R2**).

## 2. "Unknown table" or "unknown column" error

- **Symptom:** A query fails to resolve a table or column (e.g. `DeviceProcessEvents`, `RemoteIP`).
- **Cause:** **Schema drift** — the delivered pack uses representative names that Microsoft renames or
  reshapes over time, and some tables differ by cloud (GCC/GCC High).
- **Fix:** Open **Advanced hunting → schema** (or Sentinel **Logs → schema**) and correct the name to
  your tenant’s current schema. The lab pack is a starting point, not a frozen contract. *Verify
  current schema.*

## 3. A `join` returns far too many (or too few) rows

- **Symptom:** A join explodes to a huge result, or unexpectedly returns nothing.
- **Cause:** Wrong `join kind`, joining on a non-unique key, or the left side isn’t filtered first.
- **Fix:** Filter and `project` the **left** side down before joining; pick the right kind
  (`inner` = both, `leftouter` = keep all left, `leftanti` = in-left-not-right); confirm the join key
  is the same entity in both tables (e.g. `DeviceId`, `NetworkMessageId`). Re-run Lab 4.

## 4. The same hunt behaves differently in Defender vs Sentinel

- **Symptom:** A query works in Advanced hunting but errors or returns different data in Sentinel (or
  vice-versa).
- **Cause:** They query **different schemas** — Defender XDR tables (`IdentityLogonEvents`) are not
  the Sentinel workspace tables (`SigninLogs`), and the timestamp column differs (`Timestamp` vs
  `TimeGenerated`).
- **Fix:** Use the surface’s own table and timestamp column (Lab 5). The **language** is the same; the
  **tables** are not. *Verify each surface’s schema.*

## 5. `WSKQL-RunLab.ps1` fails to run a lab query

- **Symptom:** The helper errors instead of returning rows.
- **Cause:** Not connected, missing the hunting scope, wrong cloud endpoint, or the pack’s query uses
  a table absent in your tenant.
- **Fix:** Confirm `Connect-MgGraph` succeeds with `ThreatHunting.Read.All`; pass the correct
  `-Environment` for Government cloud; if a specific lab’s table is absent, correct the schema in
  `WSKQL-Labs.kql` and re-run.

## 6. "Create detection rule" is greyed out

- **Symptom:** In Lab 7 you cannot create the custom detection.
- **Cause:** The account lacks the detection-authoring role — this is the one elevated step.
- **Fix:** Have the **instructor** (holding Security Administrator or the granular equivalent) author
  `Detect-KQLLab-Pilot`; learners run read-only (**R4**). Keep it **alert-only**.

## 7. The custom detection is firing constantly (noisy)

- **Symptom:** `Detect-KQLLab-Pilot` generates a flood of alerts.
- **Cause:** The underlying hunt wasn’t tuned to a small, explainable result before it was promoted.
- **Fix:** Disable the detection, tighten the Lab 6 query (more selective filters, aggregation
  thresholds) until it returns few, justified rows, then recreate the alert-only rule. Never promote a
  noisy hunt.

## 8. Sentinel labs can’t run — no workspace

- **Symptom:** Lab 5’s Sentinel half has nowhere to run.
- **Cause:** No Microsoft Sentinel workspace is enabled in the tenant.
- **Fix:** Run the Defender-only labs in full and defer the Sentinel comparison, or use a demo/eval
  workspace. Standing up Sentinel is a separate catalog solution (**R3**). *Sentinel is a metered
  service — verify cost/availability.*

## 9. Graph connection or permission errors

- **Symptom:** `Connect-MgGraph` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph` (and `Az` for the Sentinel labs); connect with the correct
  `-Environment` for Government cloud; consent the read/hunt scopes in each script header; confirm the
  account holds a read/hunt role (**R4**). *Verify the correct endpoints for your cloud.*

## 10. Knowledge-check score looks wrong

- **Symptom:** `WSKQL-Validate.ps1` reports a score that doesn’t match expectations.
- **Cause:** The check is answered against the delivered answer key; a tenant-specific schema change
  can make a “correct” query look different.
- **Fix:** The knowledge-check tests **concepts** (operators, join kinds, aggregation functions,
  choosing a surface), not tenant-specific table names. Review the mapped lab for any question a
  learner missed; adjust the answer key only if your schema genuinely differs.
