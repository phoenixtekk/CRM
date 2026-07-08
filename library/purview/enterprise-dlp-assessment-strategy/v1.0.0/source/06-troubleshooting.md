# 6. Troubleshooting — Enterprise DLP Assessment & Strategy (Microsoft Purview)

Symptom-first fixes for the failures you actually hit running a DLP assessment. Most problems are one of:
Content Explorer empty or access-denied, the simulation baseline not producing matches, no movement data in
reports, or the exposure ranking coming out unusable.

---

## Discovery — data at rest (Content Explorer)

**Content Explorer / `DLPASSESS-DataScan.ps1` returns nothing or "access denied."**
- **Roles:** Content Explorer needs the **Content Explorer List Viewer** and **Content Explorer Content
  Viewer** roles — these are **separately assigned** from other compliance roles and are the #1 blocker.
  Confirm both in **Purview portal → Settings → Roles & scopes → Permissions** (Req 2.2). Run
  `DLPASSESS-Validation.ps1` — it reports whether `Export-ContentExplorerData` is reachable.
- **Licensing:** Content Explorer is **E5 / E5 Compliance** and evolves — **verify your licensing/tenant.**
  If it isn't available, the assessment is limited to data-in-motion (simulation) + built-in-SIT posture.
- **Tag name mismatch:** `-Tags` must match the **exact SIT/label name** as Purview lists it (e.g.
  `U.S. Social Security Number (SSN)`, not `SSN`). A wrong name returns nothing.

**A candidate category returns zero items.**
- It may be **genuine** (you don't hold that data) — record it as such.
- Or the content **hasn't been classified yet** — classification is a background process; newly added
  content or never-scanned stores may not appear. Note it and consider **on-demand/auto-classification**
  (plan-dependent — verify your tenant).
- Or there is **no detector** for the category (e.g. an internal ID with no matching SIT) — record it as a
  **detector-to-build** backlog item for the roadmap, not a hole.

## Configuration — the monitor-only simulation baseline

**`DLPASSESS-Baseline.ps1` makes no change.**
- That is **correct by default** — it runs in `-WhatIf` unless you pass **`-Commit`**. Re-run with
  `-Commit` to actually create the policy.

**Policy creation fails with a permissions error.**
- Creating a DLP policy needs **Compliance Administrator** or **Compliance Data Administrator** (Req 2.2).
  View-only roles can read but not create — assign the author role under change control, then re-run.

**The baseline was created but shows no matches after days.**
- Confirm it is actually **in simulation and evaluating**: `DLPASSESS-Discovery.ps1` should show it as
  `TestWithoutNotifications`. A **disabled** policy does nothing.
- **Propagation latency:** new DLP policies can take **up to ~1 hour (longer for some locations)** to start
  evaluating. Wait before concluding it's broken.
- Confirm the rule's **SITs and minCount** are inclusive enough — for an assessment you want a **low**
  instance count so you *see* movement (tuning comes later, in the enforcement project).
- Confirm **audit logging is on** (`DLPASSESS-Validation.ps1`) — matches surface through the audit log.

**I need the baseline gone.**
- `.\DLPASSESS-Baseline.ps1 -Remove -Commit` (or delete in the portal). Because it is simulation-only,
  removal is instant with **zero** user impact and no data change.

## Discovery — data in motion (reporting)

**`DLPASSESS-Report.ps1` returns no matches.**
- **No baseline / not simulating:** confirm `DLP Baseline – All Locations – Simulation` exists and is in a
  `Test*` mode (`DLPASSESS-Discovery.ps1`).
- **Audit log latency / dwell:** DLP events take time to appear; widen `-Days` and re-run, and allow the
  agreed **dwell time** (Req 2.6) before expecting representative data.
- **Audit logging off / missing role:** confirm audit ingestion is on and your account holds a
  **View-Only DLP / audit** role.

**The external-exposure count looks wrong.**
- The report infers external exposure from sharing type / recipient domain and treats non-`contoso.com`
  recipients as external — **edit the internal-domain check** in the script to your real domain(s) so the
  external signal is accurate for your tenant.

## Ranking & roadmap

**The exposure ranking is dominated by one noisy SIT.**
- A broad built-in SIT (e.g. a permissive number pattern) can over-count. For the assessment that's fine —
  note it as a **tuning item** for the enforcement project (raise confidence/instance count there). Don't
  tune the assessment baseline into an enforcement policy; keep it monitor-only.

**Data at rest and data in motion don't reconcile.**
- Expected and useful: a category with lots of data at rest but little movement is a *storage* risk; one
  with little at rest but high external movement is an *egress* risk. Record **both** — they inform
  different rollout priorities. A category with neither may be a coverage gap (dwell too short, location not
  covered, not yet classified).

## Connectivity / tooling

**`Connect-IPPSSession` or a cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin. A missing role surfaces as "cmdlet not recognized" or access denied — confirm the
  role for the specific cmdlet (DLP author vs Content Explorer viewer vs audit).

**A script made an unexpected change.**
- Only `DLPASSESS-Baseline.ps1` writes, only with `-Commit`, and only ever creates a **simulation** policy —
  the safe recovery is always to **remove** it (`-Remove -Commit`), which is clean and user-impact-free. The
  other four scripts are read-only.

---

### Fast triage table

| Symptom | First check |
|---|---|
| Content Explorer empty / denied | Content Explorer **viewer roles** (both), licensing, exact tag name |
| Category returns zero at rest | Genuine zero, not-yet-classified, or a detector gap — record which |
| Baseline makes no change | Missing **`-Commit`** (WhatIf is the default) |
| Policy create fails | Need Compliance (Data) Administrator role |
| Baseline shows no matches | Mode = Test\*? propagation latency, minCount, audit on |
| Report returns nothing | Baseline live+simulating, audit on, dwell time, `-Days` |
| External count wrong | Edit the internal-domain check to your real domain |
| Ranking skewed by one SIT | Note as enforcement-project tuning; keep baseline monitor-only |
| Cmdlet/connect fails | Module updated, modern auth, correct role for that cmdlet |
