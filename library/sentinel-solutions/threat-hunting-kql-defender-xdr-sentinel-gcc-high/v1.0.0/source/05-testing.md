# Testing & Validation — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

Work these gates **in order**. Each is **pass/fail**: do not advance a phase until its gate passes. Run
**`THREATHUNTG-Validate.ps1`** for a consolidated pass/fail summary, **`THREATHUNTG-Discovery.ps1`** for
the hunting-surface inventory, **`THREATHUNTG-RunHuntLibrary.ps1`** to execute the library across both
platforms, and **`THREATHUNTG-Report.ps1`** for hunt-program metrics. KQL runs in advanced hunting
(`security.microsoft.us` in GCC High → **Hunting → Advanced hunting**) and in Sentinel → **Logs** (Azure
Government, `portal.azure.us`). Connect the scripts to the US Gov cloud first (`Connect-MgGraph
-Environment USGov`; `Connect-AzAccount -Environment AzureUSGovernment`). **Every check is read-only** —
testing this solution never changes or contains anything.

---

## Gate 1 — The hunting surface has data (both platforms)

- **Check (KQL):** advanced hunting `DeviceProcessEvents | where Timestamp > ago(24h) | count` → non-zero;
  Sentinel `SigninLogs | where TimeGenerated > ago(24h) | count` → non-zero (repeat per table your pilot
  hunts need).
- **Automated:** `THREATHUNTG-Discovery.ps1` reports which advanced-hunting and Sentinel tables have
  recent data.
- **Pass:** every table a pilot hunt depends on has recent data on the platform that hunt targets.
  **Fail:** onboard/connect the source first (R1/R2) — do not hunt an empty table.

## Gate 2 — Read-only hunter access is in place (and only read-only)

- **Check:** Entra → **Groups** shows `Threat Hunters - Tenant - Group`; the workspace **IAM** shows it
  holding **Microsoft Sentinel Reader**; the Defender portal shows members with **Security Reader**.
  Promotion rights (Sentinel Contributor / Defender security settings) belong to a **separate, smaller**
  admin set — not to the hunter group.
- **Automated:** `THREATHUNTG-Validate.ps1` reports the group's workspace role and flags it if the hunter
  group holds any write/contributor role.
- **Pass:** hunters can query both surfaces and can change nothing. **Fail:** correct the role
  assignments (Phase 1, Step 1).

## Gate 3 — The KQL hunt library is saved and MITRE-tagged on both surfaces

- **Check:** Sentinel → **Hunting → Queries** lists the Sentinel-side hunts (e.g.
  `Hunt-RareServiceSignin-Entra-Pilot`) **with Tactics & techniques tags**; advanced hunting → saved
  queries lists the Defender-side hunts (e.g. `Hunt-LOLBins-Devices-Pilot`).
- **Automated:** `THREATHUNTG-Discovery.ps1` lists existing Sentinel hunt queries; `THREATHUNTG-Validate.ps1`
  checks the expected hunt names are present and tagged.
- **Pass:** all five pilot hunts are saved on the correct surface and tagged to a technique. **Fail:**
  import/tag them (Phase 1, Step 2).

## Gate 4 — The library runs clean on both platforms

- **Check:** `THREATHUNTG-RunHuntLibrary.ps1` executes every hunt in `THREATHUNTG-HuntLibrary.kql` —
  Defender-side hunts via `Invoke-MgSecurityRunHuntingQuery`, Sentinel-side via
  `Invoke-AzOperationalInsightsQuery` — and prints a per-hunt **row count** with no query errors
  (schema/columns resolve).
- **Pass:** every hunt returns a result set (zero rows is a valid result — it means *not found this
  window*), no hunt errors on a missing column or a lookback beyond retention. **Fail:** fix the failing
  hunt's schema/lookback (R8) — see troubleshooting.

## Gate 5 — Pilot hunts are documented (hypothesis → outcome → decision)

- **Check:** `Hunt Register - Tenant - Main` has an entry per pilot hunt with **hypothesis, scope, the
  exact KQL, outcome (found / not found / follow-up), and decision (promote / hand-off / close)**.
- **Pass:** every pilot hunt has a complete register entry. **Fail:** a hunt with no documented outcome
  is not finished — complete the entry (Phase 2, Step 5).

## Gate 6 — Findings are preserved as bookmarks with entities

- **Check:** Sentinel → **Bookmarks** — any suspicious/confirmed finding is bookmarked as
  `Bookmark-<Hunt>-Finding` with **entities mapped** (account/host/IP).
- **Pass:** every finding worth keeping is a named, entity-mapped bookmark (evidence survives the query
  window). **Fail:** bookmark and map the finding (Phase 2, Step 5).

## Gate 7 — Confirmed true positives are handed off (not acted on here)

- **Check:** each confirmed finding is a Sentinel **incident** (created from its bookmark) with evidence
  attached, and the *M365 & Azure Incident Response & Escalation Runbook* intake was triggered. No
  response action (isolation, disablement, purge) was taken from within the hunt.
- **Pass:** confirmed findings are incidents in the reactive queue with full context; the read-only
  boundary held. **Fail:** create the incident and hand off (Phase 3) — do not respond from the hunt.

## Gate 8 — At least one successful hunt is promoted to a detection

- **Check:** a successful hunt exists as a permanent detection — a Defender **custom detection rule**
  `CD-<Hunt>-Prod`, or a Sentinel **scheduled analytics rule** `Rule-<Hunt>-Prod` (started in low-impact
  posture and pointed at the tuning solution).
- **Automated:** `THREATHUNTG-Validate.ps1` checks for at least one promoted `-Prod` detection whose logic
  traces back to a library hunt.
- **Pass:** the program has captured at least one win as standing coverage. **Fail:** promote a
  reliable hunt (Phase 4, Step 2).

## Gate 9 — The cadence and trend are established

- **Check:** `Hunt Cadence - Tenant - Monthly` is scheduled with an owner; `THREATHUNTG-Report.ps1` shows
  hunts-run, findings, hand-offs, and promotions for the cycle.
- **Pass:** the program runs on a cadence and its metrics are visible (a growing tagged-hunt count and
  promotions are the signs it is working). **Fail:** schedule the cadence and generate the first report.

---

### Consolidated pass criteria

The hunt program is **stood up and working** when **Gates 1–9 pass**: the surface has data, hunter
access is read-only, the library is saved and MITRE-tagged, it runs clean on both platforms, pilot
hunts are documented, findings are bookmarked, confirmed true positives are **handed off** (never acted
on from the hunt), at least one hunt is **promoted** to a detection, and the program runs on a cadence
with visible metrics. Then repeat the loop for the next batch of techniques.
