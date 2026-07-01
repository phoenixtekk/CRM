# 8. Deliverables Summary — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the shared-device model, the DEM/no-affinity design, kiosk lock-down, the
  shared-account login model, benefits, and honest limitations.
- **Requirements Guide** — every prerequisite (DEM account, shared Webex account, APNs, ABM + ADE
  token, supervision, shared-device group, Cisco Webex app, Webex calling licensing, iOS version,
  network) with how to **verify** and how to **implement if missing**, plus the category-level Global
  Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: identity & Apple
  connection baseline, DEM/supervised no-affinity enrollment, kiosk lock-down to Cisco Webex, compliance
  & access, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate, proving a
  shared iPhone is DEM-enrolled, supervised, locked to Webex, and calling under the shared account.
- **Troubleshooting** — top-down diagnosis for enrollment, ownership, kiosk, app, and calling failures.
- **Best Practices** — enrollment/ownership model, kiosk discipline, shared-account hygiene, app
  deployment, and rollout.

## PowerShell scripts (Microsoft Graph) — `IOSSDM-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`IOSSDM-Discovery.ps1`** — tenant readiness: DEM account registered, APNs, ADE token, the shared
   group, kiosk/restrictions profiles, the Cisco Webex app, and a compliance policy.
2. **`IOSSDM-Validation.ps1`** — for a given shared iPhone, confirms it is **DEM-enrolled, no primary
   user, supervised**, in the shared group, kiosk applied, and **Cisco Webex installed**, with a
   PASS/FAIL summary.
3. **`IOSSDM-DeviceReport.ps1`** — tenant-wide CSV of shared iPhones: enrollment account, supervision,
   kiosk state, Webex install, compliance, and last check-in.
4. **`IOSSDM-Remediation.ps1`** — safe remediation: re-assign the shared-device policies/app to the
   group and flag devices with a stray primary user or missing kiosk/app. Read-only by default; changes
   require an explicit confirmation switch.
5. **`IOSSDM-Set-SharedDeviceTargeting.ps1`** — creates the **`iOS – Shared Devices`** group (dynamic,
   keyed on the ADE enrollment profile name) and optionally assigns the kiosk/restrictions/compliance
   policies and the Webex app to it — the mechanism that makes the fleet self-configure on enrollment.

## Hero image
- **`IOSSDM-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
