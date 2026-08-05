# Testing & Validation

These are the pass/fail gates that prove the reporting layer is **trustworthy** — that the numbers on
the dashboard match reality and that alerts and ownership actually work. Run the gates in order; do
not widen scope (Implementation Step 13) until the pilot passes all of them. Each gate names the exact
object from Implementation.

---

## Gate 1 — The extractor authenticates and returns data

**Procedure:** Run `APPRPT-Export-AppInstallStatus.ps1 -Environment <your cloud> -OutputPath
C:\AppEstateReporting\Exports -Format Both`.

**Pass:** A file `app-install-status_<timestamp>.csv` appears with one row per app×device and a
non-zero row count that roughly matches your pilot apps × targeted devices.

**Fail:** Empty output or an auth error → check Graph scopes (R3), the `-Environment` value (R11), and
that the pilot apps have assignments.

---

## Gate 2 — Export counts match the Intune console (the trust gate)

**Procedure:** For one pilot app, read Installed / Failed / Not applicable / Pending from **Intune
admin center > Apps > All apps > (app) > Monitor > Device install status**, then count the same states
for that app in `app-install-status_*.csv`.

**Pass:** The four counts agree (allow a small drift if devices checked in between the two reads).

**Fail:** Material divergence → almost always a difference in how "applicable" is counted, or a stale
export. See Troubleshooting T2.

---

## Gate 3 — The KPI snapshot math is correct

**Procedure:** Run `APPRPT-Generate-KPISnapshot.ps1`. Take the console counts from Gate 2 and compute
`installed ÷ (installed + failed)` by hand for a single app; compare to the snapshot's
`InstallSuccessRatePct`.

**Pass:** The hand calculation equals the snapshot value, and each `*_Verdict` field is PASS/FAIL per
the healthy ranges in `App Estate KPI Set – v1` (success ≥ 97%, failure ≤ 3%, stale ≤ 5%).

**Fail:** Mismatch → confirm you compared the same scope (whole estate vs one app) and the same
snapshot time.

---

## Gate 4 — Top-failures ranking surfaces the right apps

**Procedure:** Run `APPRPT-Report-TopFailures.ps1 -Top 20`. Cross-check the #1 app against the console.

**Pass:** The app with the most failures in the console is at or near the top of the ranked list, and
any app above 3% is flagged `ATTENTION`.

**Fail:** A known-bad app is missing → confirm it has device-status data and is within any
`-AppNameLike` filter.

---

## Gate 5 — Version drift reflects reality

**Procedure:** Pick an app you know has mixed versions. Run `APPRPT-Report-VersionDrift.ps1
-AppDisplayNameLike "<app>" -ApprovedVersion "<known approved>"`. Spot-check two devices in the
histogram against **Intune > Devices > (device) > Discovered apps**.

**Pass:** The histogram version for each spot-checked device matches the device's discovered-apps
entry, and drift % / currency % carry the correct PASS/FAIL against 10% / 95%.

**Fail:** Versions disagree → detected-app inventory may be stale; confirm the device's last sync.

---

## Gate 6 — The Power BI dataset refreshes from storage

**Procedure:** In the Power BI service, open **`App Estate Reporting – Dataset – v1`** →
**Refresh now**. Then open **`App Estate Reporting – Report – v1`**.

**Pass:** Refresh completes without credential errors and the three pages render with current numbers
that match the latest export file.

**Fail:** Refresh fails → check the data source credentials / gateway (Implementation Step 9) and that
the export file is where the dataset expects it.

---

## Gate 7 — The three views answer their questions

**Procedure:** Open each page and confirm it answers its audience's question at a glance.

**Pass:**
- **Executive** — the three SLO cards (Availability, Timeliness, Currency) show a value and a
  target colour, and the error-budget gauge is populated.
- **Operations** — the failure-by-app bar and the failure-by-ring matrix highlight the same apps the
  scripts flagged in Gates 4–5.
- **Drill-down** — selecting an app in the slicer filters the failing-device table and version
  histogram to that app, and **drill-through from the Operations bar lands on this page filtered to
  the clicked app**.

**Fail:** A page is a wall of numbers, or drill-through doesn't filter → re-check Step 8's visual and
drill-through configuration.

---

## Gate 8 — The nightly export runs unattended

**Procedure:** In Task Scheduler, right-click **`App Estate Reporting – Nightly Export`** → **Run**.

**Pass:** A fresh export file appears in the storage location within a few minutes, produced with **no
interactive sign-in** (app-only auth), and the next scheduled Power BI refresh picks it up.

**Fail:** Interactive prompt or no file → the task is using the wrong identity or the app-only
credential/consent is missing (R4). See Troubleshooting T4.

---

## Gate 9 — An alert fires and reaches a human

**Procedure:** Temporarily lower the threshold on **`ALERT – App Failure Rate – High`** so it fires
against current data.

**Pass:** The rule triggers, **`AG – Endpoint Operations`** notifies (email/SMS/ticket), and the item
lands in the **`App Estate Triage`** queue. Restore the threshold afterward.

**Fail:** No notification → check the action group members and the alert rule's query/scope
(`law-endpoint-ops`).

---

## Gate 10 — The supportability loop closes

**Procedure:** Take one currently-failing app. Build the **evidence pack** from Page 3 (app + ID,
ring, failing-device list, install/detection state, log excerpt) and open a ticket in **`App Estate
Triage`** using the template.

**Pass:** The ticket is actionable on first read — the assigned owner can start work without asking
for more information — and the KPI it maps to has a named owner in `App Estate KPI Set – v1`.

**Fail:** The ticket bounces for missing information → the evidence-pack fields on the template are
incomplete (Implementation Step 12).

---

## Overall exit criteria (pilot → expand)

You may proceed to Implementation Step 13 (whole estate) only when: Gates 1–8 pass for at least **one
week of continuous exports**, Gate 9 has fired and notified at least once, and the daily/weekly review
cadences have run at least once each against real data.
