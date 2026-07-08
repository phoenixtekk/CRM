# Deliverables Summary — Pre-Logon VPN: First-Logon & Off-Network Password Reset

This solution is a complete, self-guided **decision + scenario + validation** package for pre-logon
VPN — it helps you **choose** the right approach (Always On VPN device tunnel vs. Cisco Secure Client
SBL/PLAP) for your fleet, explains the **two hard scenarios** by device join type, and **validates**
them end to end. It **references** the two deployment products by their object names but does not
re-teach their builds. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The problem (no cached creds for first logon; expired password can't reach a DC), the two approaches, the decision matrix, why join type is the whole story, both scenarios, break-glass, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — a chosen/deployed approach (or the companion product), segmentation groups, join-type inventory, DC reachability, machine cert + SKU (device tunnel only), optional SSPR, break-glass accounts. |
| `03-implementation.md` | The ordered procedure: run readiness, **choose the approach via the decision matrix**, segment the pilot, confirm the chosen companion object, then **validate the two scenarios** — with Gates A–E framed around scenario validation. Includes the decision matrix as a table. |
| `05-testing.md` | The validation matrix (T1–T8) with explicit **PASS/FAIL** gates — the two decisive scenario tests (first-time off-network logon; off-network password change) plus pre-logon-path, DC-reachability, machine-cert, Entra-joined-control, coverage, and break-glass tests. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: first logon still fails, password change fails, Entra-joined confusion, pre-logon path not present, script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for deciding by join type, keeping the three surfaces coherent, validating scenarios not plumbing, certs/SKU, SSPR as a complement, and break-glass. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Discovery/report use the **Microsoft Graph PowerShell SDK** (read-only); validation runs **locally on
a device** (no Graph); remediation and scope-targeting **default to `-WhatIf` (preview)** and change
nothing until you re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run
command, and required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `PREVPN-Discovery.ps1` | Fleet readiness: reports device **join types** (hybrid / domain-joined / Entra-joined), presence of a pre-logon capability (a device-tunnel ProfileXML profile **or** the SBL Win32 app), and pilot/prod group membership; recommends which approach fits the fleet. | Read-only |
| `PREVPN-Validation.ps1` | **On this device:** detects join type (`dsregcmd /status`), whether a pre-logon tunnel exists (device tunnel via `Get-VpnConnection -AllUserConnection` **or** PLAP `vpnplap64.dll`), the machine cert (LocalMachine\My), and a best-effort **DC reachability** check. PASS = pre-logon capability present AND a DC reachable. | Read-only (local) |
| `PREVPN-Report.ps1` | Fleet readiness roll-up — counts by join type and by pre-logon capability present/absent, with a **coverage %** of in-scope devices that have a pre-logon path. | Read-only |
| `PREVPN-Remediation.ps1` | Safely adds devices/users lacking a pre-logon path to the pilot group for the chosen approach and prints guidance. **Does NOT create VPN profiles** (that's the companion products). | Write, **default `-WhatIf`** |
| `PREVPN-Set-ScopeTargeting.ps1` | Creates/populates `PILOT – Pre-Logon First-Logon Users` (and optional PROD) as assignable security groups. Idempotent. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Segmentation groups: `PILOT – Pre-Logon First-Logon Users`, `PROD – Pre-Logon First-Logon Users`
- Referenced (created in companion products): the device-tunnel profile `AOVPN – Device Tunnel –
  ProfileXML – Windows` and the SBL app `Cisco Secure Client – Pre-Logon (SBL) – Win32`

## Scope boundary (what is deferred)

This is the **decision + scenario + validation** layer. The **step-by-step device-tunnel and SBL/PLAP
builds live in their companion products** and, with IKEv2/ProfileXML and Cisco head-end internals, are
**deferred to those products and the vendor's official documentation**. This solution chooses between
the two approaches, explains and validates the two scenarios by join type, and reports fleet readiness
— it consumes the companion products' objects rather than recreating them.
