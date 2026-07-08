# 7. Best Practices — Data Lineage Implementation (Microsoft Purview)

- **Connect the integration sources early — lineage is not retroactive.** Automatic lineage (ADF,
  Synapse, Data Share, Power BI) is captured only on **runs after** the source is connected to Purview;
  historical runs are never back-filled. Connect first, then run — a pipeline that ran before the
  connection leaves a permanent hole.
- **Scan both ends before expecting an edge.** A lineage edge only renders when **both** the source and
  the sink asset are known to the Data Map (scanned, or referenced by qualified name). "Connect the
  pipeline" and "scan the stores" are one task, not two — half of it produces a half-drawn graph.
- **Always dry-run custom lineage.** Run `DGLINE-Configure.ps1 -WhatIf` and read the `Process` payload —
  the input/output qualified names — before `-Commit`; the script prints the created GUID and the exact
  reverse `DELETE` so removing a wrong `Process` is trivial and never touches the underlying data.
- **Prove both mechanisms on the pilot scope first.** Pick a pilot that exercises **one automatic** and
  **one custom** path, so you validate the connector *and* the Atlas push before touching the estate.
  Lineage is cheap to fix on one path and expensive to unpick tenant-wide.
- **Measure coverage — a graph with silent holes is a liability.** Run `DGLINE-Report.ps1` and treat
  every without-lineage asset as an explicit follow-up (missing scan, missing connection, or a `Process`
  to push). Trusting an incomplete lineage graph during an incident is worse than knowing it's
  incomplete.
- **Validate correctness, not just presence.** Have a data owner confirm the graph shows the **right**
  sources and consumers. A lineage edge that renders but points at the wrong authoritative source is a
  confident wrong answer.
- **Reference assets by stable qualified names.** Custom-lineage `Process` entities reference their
  inputs/outputs by **qualified name** — use the catalog's canonical qualified names (from a scan), not
  hand-typed paths, so the edge binds to the real asset and survives re-scans.
- **Keep data-plane roles least-privilege and collection-scoped.** Assign Data source admin / Data
  curator at the **collection** in scope, not root-collection admin for everyone; the Data Map role model
  is collection-scoped for a reason.
- **Treat portal paths and REST `api-version` values as provisional.** The Data Governance area is
  actively evolving (classic Data Map vs. the unified Unified Catalog experience) — verify each portal
  path and every `api-version` in your tenant against Microsoft's current docs rather than trusting a
  value from last quarter.
- **Deliver the capability; defer the determination.** What lineage coverage is *required* for a
  regulatory/records obligation, and which source is *authoritative* for a data element, are decisions
  for data governance, records, privacy, and compliance. You provide the graph and the measured
  coverage — they own the target.
