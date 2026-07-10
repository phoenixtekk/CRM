# 8. Deliverables Summary — Microsoft Sentinel Cost & Data-Tier Optimization

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The cost model — what Sentinel/Log Analytics charge for, the data tiers (Analytics/Basic/Auxiliary), retention vs archive, DCR filtering, commitment tiers, scope, benefits, limitations |
| 2. Requirements Guide | Every cost-optimization prerequisite with Verify / Implement-if-missing |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — ingestion audit, dependency map, DCR filter, tier/retention change, commitment forecast, pilot-first |
| 5. Testing Guide | Validation procedures with pass/fail gates (savings AND coverage) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell / KQL scripts

| Script | What it does |
|---|---|
| `SENTCOST-Audit.ps1` | Ingestion-cost audit — ranks tables by billable GB over 31 days with a per-day trend and estimated cost at a supplied rate (read-only) |
| `SENTCOST-Tiering.ps1` | Tiering-recommendation analysis — cross-references top-volume tables against the tables your detections use and flags safe-to-retier vs keep-on-Analytics (read-only) |
| `SENTCOST-Validate.ps1` | Confirms each table's configured plan (Analytics/Basic/Auxiliary) and retention match the tier decisions, and that expected DCR filters are present (read-only) |
| `SENTCOST-Forecast.ps1` | Monthly cost forecast — compares pay-as-you-go vs commitment tiers at your region's rate and projects current-vs-optimized spend (read-only) |
| `SENTCOST-Set-TableRetention.ps1` | Safe retention/tier-change helper (default `-WhatIf`) — applies a table's interactive/archive retention per the tier decision only when explicitly confirmed |

## What the buyer receives

- This implementation guide as a branded Word document and PDF.
- All five PowerShell/KQL scripts in a single ZIP.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome

A leaner, forecast-backed Sentinel bill — top cost drivers identified, low-value tables retiered, noise filtered at the DCR, retention right-sized, and a commitment tier sized to steady volume — achieved without dropping the detection coverage your SOC depends on, and validated on a pilot table before workspace-wide rollout.
