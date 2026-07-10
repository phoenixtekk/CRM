# 8. Deliverables Summary — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Everything in this solution, at a glance. This is the *build and operate* side of AVD (imaging, IaC deployment, FSLogix storage, RBAC, scaling); end-user client access from Windows/macOS is the companion **AVD Remote Access** solution.

## Documentation (source/)
| Document | Purpose |
|---|---|
| `executive-summary.md` | What the solution is, the scope boundary vs. AVD Remote Access, what you get, and the effort. |
| `01-solution-overview.md` | How golden images, Compute Gallery versioning, image pipelines, IaC deployment, FSLogix, RBAC, drain/patch, and scaling work; the Assess → Configure → Pilot → Validate → Expand model; in/out of scope. |
| `02-requirements.md` | Build-specific prerequisites (license, Compute Gallery, build VM, FSLogix storage, Bicep tooling, networking, monitoring) with verify / implement-if-missing. References the shared `global-requirements-azure-solutions.md`. |
| `03-implementation.md` | Ordered, click-by-click build: resource groups + gallery, build VM, customize, capture version `1.0.0`, FSLogix storage, what-if-then-deploy pilot hosts by Bicep, RBAC, FSLogix config, scaling plan, drain/patch, then expand. Every object named `<Purpose> – <Scope> – <Stage>`. |
| `05-testing.md` | Eight pass/fail validation gates (image versioned, hosts trace to version, hosts healthy, FSLogix roams, RBAC least-privilege, scaling effective, what-if clean, drain safe) with exit criteria. |
| `06-troubleshooting.md` | Symptom → cause → fix for image/gallery, Bicep deployment, FSLogix, RBAC, scaling, and drain/patch failures. |
| `07-best-practices.md` | Golden-image discipline, FSLogix performance, change control, cost control, security, and where to go next in the catalog. |
| `08-deliverables-summary.md` | This inventory. |
| `global-requirements-azure-solutions.md` | Shared Azure category prerequisites (tenant, roles, licensing, connectivity, change control, rollback). |

## Automation (scripts/)
| Script | Purpose |
|---|---|
| `AVDDEP-Discovery.ps1` | **Read-only.** Inventories the Azure context, Compute Galleries/definitions/versions, host pools and session hosts (with image provenance), profile storage, and scaling plans — your pre-change baseline. |
| `AVDDEP-Validate.ps1` | **Read-only.** Runs the Testing gates: image provenance, host availability, FSLogix registry, least-privilege RBAC, and scaling-plan assignment, printing PASS/FAIL per check. |
| `AVDDEP-Report.ps1` | **Read-only.** Produces an inventory/cost-posture report — per-host size, drain state and active sessions, image versions in use, and scaling schedules (optional CSV export). |
| `AVDDEP-SessionHosts.bicep` | **Infrastructure-as-code.** Deploys the host pool, workspace + Desktop app group, N session hosts from a specified gallery image version, and a scaling plan — with a fresh registration token minted at deploy time. Always run `what-if` first. |
| `AVDDEP-Maintenance.ps1` | **Gated change (defaults to `-WhatIf` preview).** Drain-and-patch workflow: previews which hosts would be drained and their session counts; only `-Apply` sets/lifts drain mode, ahead of image-version replacement. |

## Package
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the eight guides above compiled to a Word document and a PDF, plus all five automation artifacts (three PowerShell scripts, one Bicep template, one gated PowerShell maintenance script) in a single ZIP — yours to keep and reuse on every AVD rollout.
