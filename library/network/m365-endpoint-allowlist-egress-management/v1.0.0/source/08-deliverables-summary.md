# Deliverables Summary

This solution is a complete, repeatable operating package for administering the IP/Port/URL
allow-lists and proxy/firewall exceptions that let Microsoft 365, Intune, Autopilot, Defender, and
Entra required endpoints work through tight egress filtering — derived from Microsoft's live published
set, validated, and kept current.

## Documents

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | Why cloud-managed endpoints need egress access; the Microsoft required-endpoints model (M365 IP/URL web service, Intune, Autopilot, Defender, Entra); the allow-list lifecycle and staged deployment model. |
| `02-requirements.md` | Every prerequisite (proxy/firewall you administer, the required-endpoints source, change control, a pilot scope, Entra/Intune reachability) with Description / Why / Verify / Implement-if-missing. |
| `03-implementation.md` | The ordered build: derive the required set, build the named allow-list / proxy exceptions, pilot, validate, expand, and operate the keep-current drift loop — with a pass/fail gate at each phase. |
| `05-testing.md` | Pass/fail gates: required-set correctness, per-endpoint reachability, coverage/gap clean, and real-workflow success (enrollment/Autopilot, policy sync, update/app delivery, Defender). |
| `06-troubleshooting.md` | Symptom-to-endpoint mapping — enrollment stalls, sync fails, update fails — tracing each failure to the missing endpoint and the fix. |
| `07-best-practices.md` | Change control, derive-never-hardcode, and drift review disciplines that keep the list healthy over time. |
| `global-requirements-network.md` | Category-level prerequisites shared by all Network solutions. |
| `executive-summary.md` | One-page summary for decision-makers. |

## PowerShell scripts (`.\scripts\`)

| Script | Role | Safety |
|---|---|---|
| `EGRESS-Discovery.ps1` | Pulls the current required IP/Port/URL set from the Microsoft 365 web service (for your instance) plus Intune/Autopilot/Defender endpoints; captures current filter state; supports baseline-version drift detection. | Read-only |
| `EGRESS-Validation.ps1` | Tests per-endpoint reachability of each required IP/Port/URL from a device behind the filter. | Read-only |
| `EGRESS-Report.ps1` | Produces an allow-list coverage / gap report from the required set and validation results. | Read-only |
| `EGRESS-Remediation.ps1` | Generates the allow-list update entries (and drift deltas) for import into the proxy/firewall. | Preview / `-WhatIf` by default |
| `EGRESS-Set-ScopeTargeting.ps1` | Builds/populates the `SG-EGRESS-Pilot` Entra group for staged rollout. | Preview / `-WhatIf` by default |

## Named objects you will create (verbatim)

- Entra pilot group: `SG-EGRESS-Pilot`
- Proxy/firewall allow rule: `AllowList-M365-Endpoints`
- Address/URL object group: `M365-Required-Endpoints`
- Derived required set: `egress-required-set.json`
- Baseline version: `egress-baseline-version.json`
- Coverage report: `egress-coverage-report.html`
- Proposed update: `egress-allowlist-update.txt`

## What "done" looks like

Behind your real filter, on the pilot: the required set is derived for the correct instance, every
required endpoint is reachable, the coverage report shows zero gaps, and enrollment/Autopilot, policy
sync, and update/app delivery all succeed — after which you expand to the fleet and run the scheduled
drift check so the live allow-list never silently diverges from Microsoft's published set.

## Important notes

- **Vendor-neutral on the proxy/firewall.** This solution specifies *what* to allow and *how to name
  it*; the exact console steps for your specific proxy/firewall are deferred to that vendor's
  documentation.
- **No hardcoded IPs.** The required set is always derived live from Microsoft's web service — the
  scripts never ship a fixed list of addresses, because Microsoft's endpoints change.
