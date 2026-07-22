# 8. Deliverables Summary — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the proactive endpoint-side monitoring model, the "define healthy" health
  signals and thresholds, how it spans VPN types (Microsoft Tunnel, Always On device + user tunnel,
  third-party clients), the **explicit boundaries** (defers Microsoft Tunnel gateway-**server** health
  to the Tunnel Gateway product; defers VPN **deployment** to the deployment products; defers reactive
  break/fix to the Connectivity Toolkit; uses the Proactive Remediations detection model as its engine
  without reproducing it), benefits, and honest limitations. Emphasizes that the checks are **read-only**.
- **Requirements Guide** — every prerequisite (Proactive Remediations entitlement, an already-deployed
  VPN profile, a Log Analytics workspace and Azure Monitor for telemetry/alerting, enrolled Windows
  devices, the Intune Management Extension, run-context, pilot and production groups, a Graph-capable
  admin workstation, and certificate visibility) with how to **verify** and how to **implement if
  missing**, plus the category-level Global Requirements. Licensing, data paths, alert wiring, and
  per-vendor specifics are flagged **verify-with-Microsoft**.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: define the health
  signals and author the read-only check, package and scope to a pilot, read results and wire telemetry
  (Log Analytics/KQL) and alerts (Azure Monitor), and validate then expand in waves. Every object is
  named and reused, and the fleet-rollup **KQL** is included.
- **Testing & Validation** — seven tests with explicit PASS/FAIL gates and an acceptance gate: the check
  is proven **read-only**, the package reports **detection-only**, a **healthy device reports Healthy**,
  each **seeded break reports the correct red signal**, the **fleet rollup shows the cohort**, an
  **alert fires** on a seeded failure, and steady state shows no thrash.
- **Troubleshooting** — symptom → cause → fix for false red/false green, the script not running,
  telemetry not arriving in Log Analytics, alerts not firing, per-VPN-type detection nuance, and a
  scripts section — plus the **Triage runbook** mapping each red signal to the responsible layer and the
  product that owns the fix.
- **Best Practices** — keep monitoring and fixing separate, define "healthy" well, deploy/scope,
  telemetry & alerting, and operate/govern.

## PowerShell scripts (device probe + Microsoft Graph) — `VPNHEALTH-Scripts.zip`
Each script has a header explaining **Purpose · How to run · Required scopes · Expected results**. Every
device-side probe is **READ-ONLY** (never touches the tunnel); the single Graph state-changer deploys
the **monitoring package only** and defaults to `-WhatIf`.

1. **`VPNHEALTH-Detect-TunnelHealth.ps1`** — the **read-only** device-side health check: verifies
   adapter/profile present, tunnel connected, gateway reachable, key route + DNS through the tunnel, and
   certificate valid + expiry window; emits a structured verdict (Healthy/Degraded/Unhealthy) and the
   Proactive Remediations exit-code contract. VPN-type aware. **Makes no changes** — deploy it as the
   detection script with no remediation attached.
2. **`VPNHEALTH-Discovery.ps1`** — read-only (Graph): which VPN profiles are deployed, whether the
   health-check package exists/is assigned, and a telemetry-path hint.
3. **`VPNHEALTH-Validate.ps1`** — PASS/FAIL that the package is deployed, assigned, running, reporting,
   and **detection-only** (no remediation attached).
4. **`VPNHEALTH-Report.ps1`** — fleet health rollup export (per device: VPN type, verdict,
   cert days-to-expiry) to CSV, from Graph or collected on-device logs; includes the equivalent
   Log Analytics **KQL** as a comment.
5. **`VPNHEALTH-Deploy-HealthCheck.ps1`** — the one state-changer (Graph): creates/assigns the
   detection-only health-check package to the pilot group. **Defaults to `-WhatIf`** and says so. It
   deploys the **monitoring package only** — it never modifies a VPN.

## Hero image
- **`VPNHEALTH-hero.png`** — the product image (1200×1200) used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
