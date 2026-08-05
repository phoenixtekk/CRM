# Sales Content — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

**SOL code:** SNOWINT · **Category:** Intune Solutions · **Version:** v1.0.0 · **Branding:** OFF (white-label)

## Pricing (T3/T4 — two-platform integration + CMDB mapping)
| Tier | SKU | Price |
|---|---|---|
| Commercial | PTK-SNOWINT-COMM-001 | $2,795.00 |
| Non-Profit (−40%) | PTK-SNOWINT-NPO-001 | $1,677.00 |
| Government (−15%) | PTK-SNOWINT-GOV-001 | $2,375.75 |

## The hook
**Your Workspace ONE feed is retiring — keep the CMDB alive with Intune.** When endpoint management
moves from Workspace ONE (AirWatch) to Microsoft Intune, the ServiceNow data feed that keeps the CMDB
current goes dark. This solution re-establishes the *same* device-inventory feed — from Intune — so
ServiceNow keeps collecting managed devices, ownership, compliance, and installed apps into the CMDB
on a schedule, reconciled to one record per device.

## Run it yourself — simpler, cheaper, proven
- **Simpler** — exact ordered steps across the Entra admin center and ServiceNow: register the
  read-only app, consent the scopes, connect ServiceNow, map to the CMDB, schedule, validate.
- **Cheaper** — one fixed price vs an open meter; comparable integration work runs ~$1,500–$3,000/day.
- **Tested** — pilot-first (Assess → Configure → Pilot → Validate → Expand) with reconciliation scripts
  and pass/fail gates, so devices land correctly and without duplicates before you retire the WS1 feed.

## What's inside
- Solution Overview, Requirements (both platforms), Implementation, Testing, Troubleshooting, Best
  Practices (Word + PDF).
- 5 cloud-aware PowerShell scripts: `SNOWINT-Preflight`, `SNOWINT-Export-ManagedDevices`,
  `SNOWINT-Validate-Sync`, `SNOWINT-Report-Coverage`, `SNOWINT-Remediation` (guarded).

## The repeatable way
Every solution follows the same repeatable shape — buy once, deploy across the fleet, reuse the
playbook for the next integration.

## The bottom line
A scheduled, reconciled, least-privilege Intune → ServiceNow CMDB device feed that survives the
Workspace ONE cutover — keyed on serial number so every device is one trustworthy CI.

## Scope boundary (state honestly)
Re-establishes the **CMDB data feed only**. Deferred to dedicated solutions: the device migration
(WS1PROG), the ServiceNow SAM license workflow (SNOWSAM), and software entitlement reconciliation
(SWDISC).

## Government note
15% off for verified public-sector buyers. Sovereign-cloud endpoints documented inline
(`graph.microsoft.us` / `dod-graph.microsoft.us`, `login.microsoftonline.us`, `intune.microsoft.us`);
scripts run against USGov / USGovDoD. GCC High connector-endpoint specifics flagged "verify against
current documentation."
