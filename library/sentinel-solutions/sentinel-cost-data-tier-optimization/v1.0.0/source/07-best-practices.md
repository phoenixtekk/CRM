# 7. Best Practices — Microsoft Sentinel Cost & Data-Tier Optimization

Field-proven guidance for cutting the Sentinel bill without losing coverage.

## Optimize the biggest tables first, one at a time

- Cost is concentrated: a handful of tables usually drive most of the bill. Rank with `SENTCOST-Audit.ps1` and start at the top — the first few tables deliver most of the savings.
- Change **one table at a time** and re-measure. Batching changes makes it impossible to tell which one saved money or which one broke a detection.

## Never trade coverage for cost — check dependencies first

- Before retiering or filtering any table, confirm no active analytics rule, workbook, or hunting query depends on it (`SENTCOST-Tiering.ps1`). A silent gap in detection is far more expensive than the data.
- Remember Basic/Auxiliary tiers limit scheduled analytics and full KQL — keep tables your detections query on **Analytics**. *Verify current tier query limits in your tenant.*

## Filter at the source — the DCR is your highest-leverage lever

- Dropping noise at the DCR means you never pay to ingest it. This beats retiering, because retiered data still costs something.
- Filter only **genuine, well-understood noise** (health/heartbeat chatter, verbose informational events you never query, unused columns). Dropped rows are gone for good — pilot every filter narrowly first.
- Trim unused **columns** as well as rows where the transformation supports it; wide verbose tables often carry fields nobody queries.

## Right-size retention deliberately, and let the customer own the policy

- Interactive retention is expensive; archive is cheap but has restore/search costs. Match interactive retention to how far back you actually query, and push the rest to archive.
- The **length** of retention is a compliance/records/legal decision — the customer owns it. Your job is to set the levers to that policy and show the cost of each option, not to decide the policy.

## Size commitment tiers from a real forecast, not a guess

- Only commit when steady daily volume comfortably exceeds a tier threshold (`SENTCOST-Forecast.ps1`). Spiky or shrinking volume is safer on pay-as-you-go.
- Re-forecast after each round of tiering/filtering — your optimizations lower the volume, which can change the best commitment tier.

## Measure, forecast, and review on a cycle

- Re-run the audit and forecast every billing cycle. Tables grow, new connectors add volume, and a table that was fine last quarter can become the top cost driver.
- Track savings against the agreed budget target so the optimization is visible and defensible to the budget owner.

## Verify pricing and tier availability for your region

- Tier names, table eligibility, thresholds, and per-GB rates change over time and by region and cloud. Always confirm current numbers in the Azure Pricing Calculator before committing money. *Verify current availability in your tenant.*

## Where to go next

- **Sentinel Analytics Rules & MITRE ATT&CK Coverage** — make sure the coverage you are protecting is actually mapped and complete before you optimize around it.
- **Deploy Microsoft Sentinel — Workspace & Connectors** — apply DCR filtering and tier decisions to new sources as you onboard them, so cost discipline starts at ingestion.
- **Sentinel SOAR — Automation Rules & Playbooks** — automate the routine SOC work on top of the lean, well-tiered data you now pay less for.
- **SOC Onboarding — Sentinel & Defender XDR** — a unified queue on cost-optimized data keeps both coverage and spend under control.
