# Testing & Validation — Universal Print on GCC High

Testing follows the same **Assess → Configure → Pilot → Validate → Expand** gates as the
implementation. Each phase has explicit **pass/fail** criteria. Do not advance a phase until its
tests pass. All Graph-based checks run against **`graph.microsoft.us`** via
`-Environment USGov`; all portal checks use **`.us`** URLs.

> Run the bundled scripts in this order at each gate: **Discovery → Validation → Report**.
> `UPRTG-Discovery.ps1`, `UPRTG-Validation.ps1`, and `UPRTG-Report.ps1` are all **read-only**.

---

## Test set A — Assess gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| A1 | Correct cloud | Open `portal.office365.us` and `portal.azure.us`; both load with your account | Both `.us` portals load | If only `.com` works, you are on Commercial — wrong edition |
| A2 | Licensing (users + admin) | `portal.office365.us` → Licenses / Users | GCC High UP SKU assigned to admin **and** pilot users | Assign SKU; wait ≤24 h (R2) |
| A3 | UP reachable via US Gov Graph | `UPRTG-Discovery.ps1` | Script signs in at `login.microsoftonline.us`, reports UP reachable | See `06-troubleshooting.md` T1/T2 |
| A4 | Endpoint reachability | Discovery script endpoint check + manual 443 test to `*.print.azure.us` | All GCC High endpoints reachable | Open firewall/proxy (R6) |

**Gate:** A1–A4 all pass.

---

## Test set B — Configure gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| B1 | Connector registered | `portal.azure.us` → Universal Print → Connectors | `UP-Connector-Site1` shows **Registered** | Re-register (Impl. Step 5); check LocalSystem proxy |
| B2 | Printer registered | UP → Printers | Printer listed | Re-register from connector app |
| B3 | Printer shared | UP → Printer → Share | Share `UP-Pilot-Printer-01` shows **Shared** | Re-share (Impl. Step 6) |
| B4 | Targeting group exists | `entra.microsoft.us` → Groups | `UP-Pilot-Users` exists, has members, granted on share | `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply |

**Gate:** B1–B4 all pass.

---

## Test set C — Pilot gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| C1 | Client readiness | `winver` on each pilot device | Win 11 22H2+ **or** three US Gov registry keys present (pre-22H2) | Deploy registry keys (Impl. Step 8) |
| C2 | Printer visible to user | Pilot user: Add a Universal Print printer | `UP-Pilot-Printer-01` appears | Confirm group membership + share grant |
| C3 | End-to-end print | Print mono, color, duplex | All jobs complete at the device | See `06-troubleshooting.md` |
| C4 | Job accounting | `portal.azure.us` → UP → Usage and Reports | Pilot jobs appear | Wait for report refresh; recount |
| C5 | Automated validation | `UPRTG-Validation.ps1` | Script reports PASS for pilot scope | Follow the script's per-check remediation hint |

**Gate:** C1–C5 all pass.

---

## Test set D — Validate gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| D1 | Evidence report | `UPRTG-Report.ps1` | HTML/CSV report generated with printers, shares, connector, targeting | Re-run; check output path |
| D2 | Success rate | Review pilot job outcomes | Acceptable success rate, no recurring failures | Root-cause via troubleshooting |
| D3 | Secure release (if used) | QR/badge release test | Job releases correctly | Verify secure-release config |
| D4 | No open Sev-1/Sev-2 | Issue log review | None open | Resolve before Expand |
| D5 | Sign-off | Record approver + date | Sign-off captured | — |

**Gate:** D1–D5 all pass; pilot signed off.

---

## Test set E — Expand & retirement gate (per wave)

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| E1 | Wave targeting | `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply | `UP-WaveN-Users` populated, granted on wave shares | Re-run apply |
| E2 | Wave printers shared | UP → Printers | Each wave printer **Shared** | Re-share |
| E3 | Wave validation | `UPRTG-Validation.ps1` + `UPRTG-Report.ps1` | PASS for wave scope | Troubleshoot before next wave |
| E4 | No residual server dependency | Client print test with old share removed | Prints via cloud, not `\\server\printer` | Remove GPO/mapped print deployment |
| E5 | Retirement safety (parity) | Confirm no reliance on **Delegated Admin** / **macOS** that is not yet in GCC High | Confirmed not blocking | Keep server until GCC High parity confirmed (*verify for GCC High*) |

**Gate per wave:** E1–E5 pass **before** starting the next wave and **before** decommissioning
the print server whose printers that wave covered.

---

## Regression / ongoing checks

- **Monthly:** `UPRTG-Report.ps1` for a current inventory; review **Usage and Reports** against
  the licensed job pool so you don't exhaust it.
- **After any change:** re-run **Discovery → Validation → Report**.
- **After OS upgrades:** re-check `winver`; devices upgraded **to** Win 11 22H2+ no longer need
  the registry keys, but leaving them in place is harmless.
