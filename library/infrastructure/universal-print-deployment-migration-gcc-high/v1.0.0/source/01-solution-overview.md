# Solution Overview — Universal Print Deployment & Print-Server Retirement (Government / GCC High)

## Availability up front — read this first

**Universal Print IS available in GCC High.** Microsoft announced **general availability of
Universal Print in GCC and GCC High**, and the service is documented as running on the US
sovereign cloud with its own `*.print.azure.us` service endpoints and US Gov identity
(`login.microsoftonline.us`). This solution is written for a **GCC High** tenant.

Two availability facts you must internalize before you begin — both are current Microsoft
statements (see `gcc-high-parity-notes.md` for citations):

- **DoD is NOT supported.** Universal Print is *not* available in the Microsoft 365 **DoD**
  cloud at time of authoring. If your tenant is DoD (not GCC High), **stop** — this solution
  does not apply, and there is no supported Universal Print deployment for you yet. *Verify for
  GCC High/DoD before scoping.*
- **GCC High has feature-parity gaps vs Commercial.** Microsoft states it is "aiming for
  feature parity," but at authoring time specific features lag in GCC High — notably
  **Delegated Administration** ("coming to GCC High soon") and **macOS client printing** ("not
  yet available for GCC High"). These are called out inline where they matter and consolidated
  in `gcc-high-parity-notes.md`. Do not assume a Commercial how-to step works unchanged.

If you were handed the Commercial edition of this solution by mistake, it will point you at
`portal.azure.com`, `graph.microsoft.com`, and `login.microsoftonline.com` — **none of which
serve a GCC High tenant.** This edition corrects every portal, endpoint, and Graph environment
for the US sovereign cloud.

## What this solution does

Universal Print is Microsoft's cloud-based print service. It removes the need for on-premises
**Windows print servers**, print-server OS patching, and per-site print infrastructure by
publishing printers from Microsoft Entra ID and delivering print jobs through the cloud to
Entra-joined Windows endpoints. This solution takes a GCC High tenant from "we still run
print servers" to "printers are published in Universal Print, endpoints print through the
cloud, and the legacy print server is retired" — safely, on a pilot-first path, with a
rollback at every gate.

The deployment follows the standard repeatable model used across all Infrastructure
solutions:

**Assess → Configure → Pilot → Validate → Expand**

Each phase has an explicit **gate** — you do not proceed until the prior phase passes its
validation criteria. The five bundled PowerShell scripts (all connecting to **US Gov Graph**
with `-Environment USGov`) automate discovery, validation, reporting, and safe remediation so
a novice administrator can execute the whole sequence and prove each gate.

## The deployment model at a glance

| Phase | Goal | Gate to pass before moving on |
| --- | --- | --- |
| **Assess** | Inventory current print servers, printers, drivers, and per-printer job volume; confirm GCC High licensing and endpoints. | `UPRTG-Discovery.ps1` runs clean; every prerequisite in `02-requirements.md` verified. |
| **Configure** | Enable Universal Print, register the connector, publish and share the first printers, set targeting groups. | Printers appear as **Shared** in the Universal Print portal (`portal.azure.us`). |
| **Pilot** | Add one pilot printer + the pilot security group; users print end-to-end through the cloud. | Pilot users complete real print jobs; `UPRTG-Validation.ps1` passes for the pilot scope. |
| **Validate** | Confirm print success rate, driver behavior, secure release, and reporting for the pilot. | No open Sev-1/Sev-2 issues; sign-off recorded. |
| **Expand** | Roll out remaining printers/sites in waves; retire the legacy print server(s). | Each wave validated before the next; print server decommissioned only after its printers are proven in Universal Print. |

## Commercial vs GCC High — what's different

This is the section that keeps a government tenant from being configured with Commercial
steps that silently fail. Everything below is specific to the **US sovereign cloud**.

| Area | Commercial | GCC High (this edition) |
| --- | --- | --- |
| Azure / Universal Print admin portal | `portal.azure.com` | **`portal.azure.us`** (Azure Government) |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |
| Microsoft Intune / Endpoint admin | `intune.microsoft.com` | **`intune.microsoft.us`** (endpoint.microsoft.us) |
| Microsoft Entra admin | `entra.microsoft.com` | **`entra.microsoft.us`** (or Entra blade in `portal.azure.us`) |
| Sign-in / identity authority | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph endpoint | `graph.microsoft.com` | **`graph.microsoft.us`** |
| Graph PowerShell environment | `-Environment Global` (default) | **`-Environment USGov`** |
| Universal Print service endpoints | `*.print.microsoft.com` | **`*.print.azure.us`** (print, register, discovery, notification, graph) |
| Licensing SKUs | M365 E3/E5, Windows E3/E5 | **G3/G5 Gov** — `SPE_E3_USGOV_GCCHIGH`, `SPE_E5_USGOV_GCCHIGH`, or `Universal_Print_for_GCCHIGH` standalone |
| Windows client support | All supported Windows | **Windows 11 22H2+ native**; Windows 10 / older Win 11 require three registry keys to point at the US Gov authority/Graph (see `03-implementation.md`) |
| Delegated Administration | Available | **Coming to GCC High "soon"** — *verify for GCC High* before designing scoped admin |
| macOS client printing | Available | **Not yet available for GCC High** — *verify for GCC High* |
| DoD availability | N/A | **Universal Print not available in DoD at all** |

Three practical consequences of that table:

1. **Every portal URL in this edition ends in `.us`.** If a screen you land on ends in `.com`,
   you are in the wrong cloud and your GCC High credentials will not work there.
2. **Every script connects with `-Environment USGov`.** A script that omits this authenticates
   against the Commercial identity endpoint and fails for a GCC High account.
3. **Licensing is mandatory for administrators too.** In Government, **all users — including
   the admins who configure Universal Print — must hold an eligible Universal Print license**
   (G3/G5 Gov or the standalone SKU). This is a stricter rule than many admins expect.

## Who this is for

A novice-to-intermediate administrator on a **GCC High** Microsoft 365 tenant who needs to
stand up Universal Print correctly the first time and retire aging print servers without an
outage — and without being tripped up by Commercial documentation that points at the wrong
cloud.

## What you get

- **This overview** and a full **Requirements Guide** (`02-requirements.md`) with verify +
  implement steps for every prerequisite on GCC High.
- A step-by-step **Implementation Guide** (`03-implementation.md`) using the `.us` portals,
  with GCC-High-only caveats placed at the exact step where they bite.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation, and
  Set-ScopeTargeting — all US-Gov-Graph aware.
- A **Testing guide** (`05-testing.md`), a **Troubleshooting guide** (`06-troubleshooting.md`),
  **Best practices** (`07-best-practices.md`), a **Deliverables summary** (`08-deliverables-summary.md`),
  an **Executive summary**, and the cited **`gcc-high-parity-notes.md`** parity reference.

## The bottom line

Universal Print deployed correctly on GCC High — right portals, right endpoints, parity gaps
handled — and proven on a pilot before you scale, so the legacy print server is retired only
after its printers work in the cloud.
