# Implementation — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Configure → Pilot → Validate → Expand**) and is **pilot-first**: you map coverage, enable a
small high-value rule set, run it in a **low-impact** posture (alerts you triage, incident creation held
back) so you can measure noise, **tune** until the false-positive rate is acceptable, validate, then
expand across the ATT&CK matrix. Every object is named verbatim so the scripts, testing, and
troubleshooting line up. Replace `contoso.com` and the sample user/IP values with your own.

> **Portal note.** Sentinel is reached from `portal.azure.com` → **Microsoft Sentinel**, or from the
> unified **Defender portal** (`security.microsoft.com`) once onboarded. Analytics rules live under
> **Analytics**; templates under **Analytics → Rule templates**; the coverage view under **MITRE
> ATT&CK**; reference data under **Watchlists**. Portal paths and the template/NRT sets evolve — **verify
> against your tenant.**

> **Trust gate before incidents.** Do **not** let a new rule create incidents (or drive automation)
> until it has run in the low-impact pilot posture and its false-positive rate meets the agreed
> tolerance (**R5**). A rule the SOC does not trust is worse than no rule.

## Object naming (used verbatim throughout)

| Object | Name | ATT&CK (example) |
| --- | --- | --- |
| VIP/high-value users watchlist | `WL-VIPUsers-Tenant` | — |
| Authorized admin IPs watchlist | `WL-AuthorizedAdminIPs-Tenant` | — |
| Terminated users watchlist | `WL-TerminatedUsers-Tenant` | — |
| High-value assets watchlist | `WL-HighValueAssets-Tenant` | — |
| Scheduled rule — sign-in brute force | `Rule-BruteForce-Entra-Pilot` | T1110 (Credential Access) |
| Scheduled rule — atypical travel | `Rule-AtypicalTravel-Entra-Pilot` | T1078 (Defense Evasion / Initial Access) |
| NRT rule — new privileged role assignment | `Rule-NewAdminRole-Entra-Pilot` | T1098 (Persistence) |
| Suppression automation rule | `AR-Suppress-KnownScanners-Pilot` | — |
| MITRE coverage workbook | `Workbook-MITRECoverage-Tenant` | — |
| Detection-as-code repo connection | `Repo-Detections-Main` | — |

*(These three rules are worked examples of the map→enable→tune loop; apply the same pattern to the rest
of your prioritized gaps.)*

---

## Phase 0 — Assess (map coverage, rank gaps)

1. **Confirm the baseline (G1–G7) and R1** — the detection tables the rules need actually have data.
2. **Inventory current rules and templates.** Run **`SENTRULE-Discovery.ps1`** (read-only): enabled
   analytics rules, available rule templates (from installed Content hub solutions), and existing
   watchlists.
3. **Build the ATT&CK coverage map + gap list.** Run **`SENTRULE-Coverage.ps1`** — it aggregates the
   tactics/techniques of enabled rules into a coverage matrix and lists the **uncovered** (gap) cells.
   Cross-check with Sentinel → **MITRE ATT&CK** (the in-portal coverage view).
4. **Rank gaps by risk against R5.** Order the gaps using leadership's priority (R5). Pick the **top few
   high-risk gaps** for the pilot — do not try to close everything at once.
   - **Gate 0:** you have a measured coverage map, a risk-ranked gap list, and an agreed false-positive
     tolerance → continue.

## Phase 1 — Configure (watchlists, then enable a small high-value set)

### Step 1 — Import the enrichment watchlists (R4)

1. Sentinel → **Configuration → Watchlists → Add new** → create each from its CSV, naming them exactly:
   - **`WL-VIPUsers-Tenant`** (SearchKey = user principal name).
   - **`WL-AuthorizedAdminIPs-Tenant`** (SearchKey = IP/CIDR).
   - **`WL-TerminatedUsers-Tenant`** (SearchKey = user principal name).
   - **`WL-HighValueAssets-Tenant`** (SearchKey = asset/host name).
2. Note each watchlist's alias — rules reference it as `_GetWatchlist('<alias>')`.

### Step 2 — Enable the pilot rules against the top-risk gaps

For each pilot rule, enable from a template where one exists, otherwise author a scheduled/NRT rule; in
all cases set **entity mappings** and, critically, start in a **low-impact** posture (Step 3).

1. **`Rule-BruteForce-Entra-Pilot` (T1110).** Sentinel → **Analytics → Rule templates** → find a
   sign-in brute-force / failed-logon template (or **Create → Scheduled rule**). Query `SigninLogs` for
   repeated failures per account/IP over a window; **join `WL-AuthorizedAdminIPs-Tenant` to exclude
   sanctioned sources**; map entities **Account**, **IP**, **Host**.
2. **`Rule-AtypicalTravel-Entra-Pilot` (T1078).** Enable the Microsoft "atypical travel" / impossible-
   travel template if present, or author a scheduled rule; map **Account**, **IP**. *(Some travel/anomaly
   detections are Microsoft ML rules — enable rather than author; verify availability.)*
3. **`Rule-NewAdminRole-Entra-Pilot` (T1098).** Sentinel → **Analytics → Create → NRT rule** → query
   `AuditLogs` for privileged-role assignments (e.g. added to a directory role); map **Account** (actor
   and target). NRT gives low-latency notice of new admin. *(Confirm NRT limits/eligibility in your
   tenant.)*

### Step 3 — Put each pilot rule in the LOW-IMPACT posture

For every rule above, in its **Incident settings**:

1. Set **"Create incidents from alerts triggered by this analytics rule"** to **Disabled** for the
   pilot — the rule still generates **alerts** (visible under **Logs**/`SecurityAlert`) you can measure,
   but it does **not** flood the incident queue or drive automation yet.
2. Leave **alert grouping** configured so related alerts would later group into one incident.
3. Save. This is the analytics-rule equivalent of "report-only": full signal, no operational impact.

## Phase 2 — Pilot (let it run, measure the noise)

1. Let the pilot rules run for the agreed pilot window (typically several days).
2. Run **`SENTRULE-Report.ps1`** — for each pilot rule it reports **alert volume** and, where incidents
   or analyst dispositions exist, the **false-positive (benign) rate**, plus the top entities driving
   the alerts.
   - **Gate 1:** you have per-rule alert volume and a false-positive signal → proceed to tune.

## Phase 3 — Tune (make the alerts trustworthy)

For each noisy pilot rule, apply tuning **in this order** (cheapest, safest first):

1. **Allow-list known-good** — extend the watchlist join (e.g. add the scanner's IP to
   `WL-AuthorizedAdminIPs-Tenant`) so the rule stops matching sanctioned activity.
2. **Suppress with an automation rule** — create **`AR-Suppress-KnownScanners-Pilot`** (Sentinel →
   **Automation → Create → Automation rule**) to auto-close or suppress incidents matching a known-benign
   pattern, rather than weakening the detection logic.
3. **Raise the threshold / tighten the window** — increase the count threshold or shorten the lookback so
   only meaningful bursts fire.
4. **Refine grouping/entities** — group alerts by the right entity so 50 alerts become one incident, not
   50.
5. **Re-measure** with `SENTRULE-Report.ps1` after each change. Change **one thing at a time** so you
   know what worked.
   - **Gate 2:** each pilot rule's false-positive rate meets the R5 tolerance → it may be trusted.

## Phase 4 — Validate

1. Run **`SENTRULE-Validate.ps1`** — pass/fail lines aligned to `05-testing.md`: watchlists present and
   referenced; pilot rules enabled with **entity mappings** set; each pilot rule **still in low-impact
   posture** until signed off; false-positive rate within tolerance; and the ATT&CK coverage map shows
   the **targeted gaps now covered**.
2. Re-run **`SENTRULE-Coverage.ps1`** — confirm the coverage matrix improved on the tactics/techniques you
   targeted (the gap cells you picked are now covered).
   - **Gate 3 (go/no-go to trust):** all validation lines PASS and coverage improved → promote the rules.

## Phase 5 — Expand (promote, export as code, repeat the loop)

1. **Promote the tuned rules.** For each rule that passed Gate 2/3, set **Incident settings → Create
   incidents** to **Enabled**, and rename the `-Pilot` suffix to your production stage in a change window
   if you standardize on `-Prod` (keep the convention consistent). Now they create incidents the SOC
   trusts.
2. **Export as code.** Run **`SENTRULE-Export.ps1`** to export the enabled rules to ARM/JSON (or feed
   Sentinel **Repositories** `Repo-Detections-Main`); commit to version control so detections are
   reviewable and portable.
3. **Deploy the coverage workbook.** Deploy **`Workbook-MITRECoverage-Tenant`** (start from the Content
   hub MITRE/coverage workbook) so coverage is visible on an ongoing basis.
4. **Repeat the loop** — take the next batch of high-risk gaps and run Phase 1→4 again. Detection
   coverage is a program, not a one-time task.

## Rollback (for any step)

- **A rule:** disable it (Analytics → the rule → **Disable**) — it stops evaluating immediately. Its
  exported code remains in the repo.
- **A promotion:** set **Create incidents** back to **Disabled** to return a rule to low-impact posture
  without deleting it.
- **A watchlist:** delete it; rules that reference it will error until updated — so remove the
  reference first.
- **Tuning:** because rules are exported as code, revert to the previous committed version to undo a
  tuning change cleanly.
