# 7. Best Practices — Classification Reporting & Analytics (Microsoft Purview)

- **Report; don't rule.** This solution makes the *existing* classification signal visible. A low coverage
  number, a suspicious egress pattern, or an under-labeled site is a **finding to route to governance** —
  *which* content must be relabeled, retained, or investigated is a compliance/records/privacy/legal call
  (GR §5). Hand over the evidence; let the owning function own the determination.
- **Separate "seeing that content exists" from "reading it."** Grant **`Content Explorer List Viewer`**
  broadly to analysts who need coverage numbers, and **`Content Explorer Content Viewer`** — which exposes
  real sensitive data — only to the minimal approved set. Keep both separate from the people who *author*
  labels/DLP and from records/legal. `CLSREPORT-Configure.ps1` grants each role independently for exactly
  this reason.
- **Preview every governed change before you commit it.** `CLSREPORT-Configure.ps1` defaults to preview;
  read every intended audit-enable and role-grant action, then re-run with `-Commit` under change control.
  Enabling audit ingestion and granting Content Viewer are the only two changes this solution makes — treat
  them accordingly.
- **Pilot before the full audience.** Grant the viewer roles to a small named analyst subset, prove both
  explorers return data and the dashboards render, then expand to the full
  `Purview Classification Reporting - Analysts` group. Reporting is low-risk, but the sensitive-data grant
  is not — earn the broad grant with a validated pilot.
- **Keep auditing on, and give it time.** Activity Explorer and the activity exports are only as complete
  as the unified audit log feeding them. Enable ingestion early, and after enabling it, allow the pipeline
  to backfill before judging activity coverage — an empty window right after enablement is **ingestion
  lag**, not a failure.
- **Treat an empty/baseline estate as a valid finding.** A tenant with few published labels or SIT
  detections will show near-empty explorers. Record that as **baseline coverage** and reference the
  labeling/SIT solutions — it is the honest starting number, not a broken report.
- **Verify availability; never assume it.** Content-item viewing, Activity Explorer, trainable classifiers,
  and `Export-ContentExplorerData` are licensing-gated and the portal is moving surfaces between the classic
  compliance portal and the new Purview portal. When a blade or cmdlet isn't where this guide says, confirm
  the current equivalent in your tenant and flag **"verify your licensing/tenant"** in the report footnote
  rather than forcing a path that isn't there.
- **Parameterize the volatile values.** Audit **RecordTypes** and Content Explorer **TagTypes** evolve and
  differ across tenants. Pass `-RecordTypes` / `-TagTypes` after confirming the current values in Purview →
  Audit rather than trusting a default blindly — the scripts parameterize these precisely because they drift.
- **Bind the dashboard to the export shape, not the portal screenshot.** The Coverage and Activity views
  bind to the column names `CLSREPORT-Report.ps1` writes (`coverage-by-tag.csv`, `activity-summary.csv`).
  Keep the dashboard pointed at the current script output so a column rename never silently breaks a tile.
- **Make it recurring, and watch for drift.** Schedule `CLSREPORT-Report.ps1` and `CLSREPORT-ScopeHealth.ps1`
  (e.g. weekly) so the numbers refresh and you catch **role-group drift** (an unexpected new Content Viewer),
  **audit lag**, a **workload dropping out** of reporting, and **tag-inventory changes** that reshape the
  report — classification coverage is a trend to watch, not a one-time snapshot.
- **Keep it reproducible.** Retain the dated CSV exports as the baseline; each later run compares against it
  to show whether coverage is trending up and activity is within expectation as labeling (separately) expands.
