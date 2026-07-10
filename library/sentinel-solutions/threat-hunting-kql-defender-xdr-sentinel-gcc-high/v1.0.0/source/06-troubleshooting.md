# Troubleshooting — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

Common failures, each as **symptom → cause → fix**. Start with `THREATHUNTG-Discovery.ps1` (surface
inventory + table freshness), `THREATHUNTG-RunHuntLibrary.ps1` (runs the whole library and shows which
hunt fails), and `THREATHUNTG-Validate.ps1` (the program gates) — most issues here surface in one of the
three. Every tool is **read-only**; none of these fixes involves a response action.

---

## A hunt returns nothing (and you expected activity)

- **Symptom:** A hunt runs cleanly but returns zero rows, even for behavior you believe exists.
- **Cause:** The target table has no data on that platform (source not onboarded/connected), the
  lookback is beyond retention (advanced hunting is ~30 days), the filter is too tight, or you ran a
  Defender-side hunt against Sentinel (or vice-versa) where that table does not exist.
- **Fix:** Confirm the table has data on the **right** surface (`<Table> | where Timestamp/TimeGenerated
  > ago(1d) | count`; Gate 1 / R1–R2). Widen the window (within retention) and loosen the filter to
  confirm the logic returns *something*, then re-tighten. Remember: a true null over a valid window is a
  legitimate "not found this window" — record it in the register.

## A hunt returns far too much to triage

- **Symptom:** A hunt returns thousands of rows, most of them obviously benign.
- **Cause:** The hypothesis is too broad, no known-good baseline is excluded, or the window is too wide
  for a first pass.
- **Fix:** Scope narrower (shorter window, high-value assets/identities first). Add a baseline exclusion
  (e.g. summarize by a rare command line / rare process count and keep only the uncommon). Iterate the
  KQL toward *rare and interesting*, not *everything*. Broad-and-benign is a signal to refine the hunt,
  not to promote it.

## A hunt errors on a missing column or unknown table

- **Symptom:** The KQL fails with "unknown column" / "unresolved table" in advanced hunting or Sentinel.
- **Cause:** The advanced-hunting **schema evolves** — a table or column was renamed, or the column
  exists on Defender XDR but not in the Sentinel copy of the table (or vice-versa). Some tables are
  preview/`*Beta` and differ by tenant.
- **Fix:** Hover the table in advanced hunting to see its **current** columns; adjust the hunt to the
  live schema. Run the hunt on the surface whose schema it was written for (the library header notes
  XDR-vs-Sentinel). *Verify current schema in your tenant* — treat schema drift as expected maintenance
  of the library.

## Results look truncated / a limit was hit

- **Symptom:** Advanced hunting warns about a result or time limit; the row count looks capped.
- **Cause:** Advanced hunting enforces **per-query row and time limits**; a hunt that returns more than
  the cap is truncated.
- **Fix:** Aggregate instead of returning raw rows (`summarize`/`count` first, then drill into the
  interesting buckets); narrow the window; add filters before the expensive operators. Keep hunts within
  retention (R8). *Verify current limits in your tenant.*

## `Invoke-MgSecurityRunHuntingQuery` throttles or errors

- **Symptom:** `THREATHUNTG-RunHuntLibrary.ps1` fails on the Defender-side hunts with a 429 / throttling
  or a permissions error.
- **Cause:** The **`runHuntingQuery`** API has its own rate limits, or the app/user lacks the
  **`ThreatHunting.Read.All`** scope, or the wrong national-cloud endpoint was used (e.g. connecting to
  commercial `graph.microsoft.com` from a GCC High tenant).
- **Fix:** Let the runner back off and retry (it treats 429 as expected). Consent
  `Connect-MgGraph -Environment USGov -Scopes ThreatHunting.Read.All` (GCC High, `graph.microsoft.us`);
  for **DoD** use `-Environment USGovDoD` (`dod-graph.microsoft.us`) — *verify the correct endpoint and
  scopes for your cloud against current Microsoft Government documentation* (R7).

## The hunter group can change things (or cannot query)

- **Symptom:** Hunters can disable rules / isolate devices (too much), **or** hunters get "access
  denied" running advanced hunting (too little).
- **Cause:** `Threat Hunters - Tenant - Group` was granted a **contributor/write** role (too broad), or
  it lacks **Security Reader** (Defender) / **Microsoft Sentinel Reader** (workspace) (too narrow).
- **Fix:** Reassign to **read-only** exactly: **Microsoft Sentinel Reader** on the workspace and
  **Security Reader** in Defender. Keep promotion rights in a **separate, smaller** admin set (Phase 1,
  Step 1 / R3). `THREATHUNTG-Validate.ps1` flags a hunter group that holds a write role.

## A bookmark loses its evidence or entities

- **Symptom:** A `Bookmark-<Hunt>-Finding` exists but has no usable entities, or the underlying row is
  gone.
- **Cause:** Entities were not mapped when the bookmark was created, or the raw data rolled off retention
  before it was bookmarked (advanced hunting ~30 days).
- **Fix:** Bookmark **promptly** and **map entities** (account/host/IP) at creation. For long-lived
  evidence, prefer the Sentinel copy of the table (often longer retention) or export the row. A finding
  worth keeping should be bookmarked the moment it is triaged (Gate 6).

## A confirmed true positive — but no clean hand-off

- **Symptom:** A hunt confirmed malicious activity but responders had to reconstruct the context, or a
  hunter started containing it themselves.
- **Cause:** The read-only boundary was crossed, or the finding was not turned into an incident with
  evidence attached.
- **Fix:** **Do not respond from the hunt.** Create a Sentinel **incident** from the bookmark, attach the
  register entry and evidence, and trigger the *M365 & Azure Incident Response & Escalation Runbook*
  intake (Phase 3 / Gate 7). Containment, disablement, and escalation happen **there**, with authority
  and change control.

## A promoted detection floods the queue

- **Symptom:** A hunt was quiet when run by hand, but the promoted `Rule-<Hunt>-Prod` /
  `CD-<Hunt>-Prod` floods incidents once live.
- **Cause:** It was promoted straight to full incident creation without tuning — a manual hunt tolerates
  noise a running detection does not.
- **Fix:** Return the Sentinel rule to **low-impact posture** (incident creation disabled) and tune it in
  the *Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage* solution (allow-list →
  suppression → threshold → grouping) before it creates incidents. For a Defender custom detection, tune
  frequency/logic before relying on it.

## PowerShell / connection errors

- **Symptom:** A script errors on connect, on the workspace, or on the Graph call.
- **Cause:** Wrong subscription/tenant context, missing `Microsoft.Graph.Security` or
  `Az.SecurityInsights`/`Az.OperationalInsights`, insufficient read role, or (Gov cloud) the wrong
  environment/endpoint.
- **Fix:** `Connect-AzAccount -Environment AzureUSGovernment` + `Set-AzContext` (Sentinel) and
  `Connect-MgGraph -Environment USGov -Scopes ThreatHunting.Read.All` (Defender, GCC High);
  `Install-Module Microsoft.Graph, Az`; confirm **Microsoft Sentinel Reader** / **Security Reader**. For
  **DoD** use `-Environment USGovDoD` (Graph) alongside `AzureUSGovernment` (Az) (R7) — *verify endpoints
  for your cloud against current Microsoft Government documentation.*
