# 8. Deliverables Summary — Microsoft Entra: Secure Cloud Identity Reference Architecture

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, what a reference architecture is, and what is in the box |
| 1. Solution Overview | What a reference architecture is, the six design domains, how the blueprint relates to the builds, and the design method |
| 2. Requirements Guide | Every solution-specific input (read-only access, tooling, decision owners, licensing truth) with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Design & Decision Guide | The method that produces the three artifacts — Architecture Design Document, Decision Record (`ADR-0nn`), and phased Roadmap — across all six domains, each cross-referenced to its build |
| 5. Testing Guide | Validation of the evidence base and the design artifacts, with pass/fail gates |
| 6. Troubleshooting Guide | Evidence-gathering and design-completeness issues and remediation |
| 7. Best Practices | Field-proven design recommendations + where to go next (the builds) |

## PowerShell scripts (all read-only; Microsoft Graph / Az + KQL)
| Script | What it does |
|---|---|
| `ENTARCH-Discovery.ps1` | Inventories the current identity posture — verified domains/topology signals, identity source of authority, licensing (P1/P2, Governance, GSA, Verified ID — flagged *verify*), existing Conditional Access policies, named locations, and external-collaboration settings (read-only) |
| `ENTARCH-IdentityInventory.ps1` | Profiles the three identity types — human (members, stale accounts, MFA registration), workload (service principals, managed identities, credentials nearing expiry), and external (B2B guests, guest age, cross-tenant settings) (read-only) |
| `ENTARCH-PrivilegedAccessReview.ps1` | Enumerates privileged access — role assignments permanent vs. PIM-eligible, the Global Administrator count, highly-privileged service principals, and whether break-glass accounts exist (read-only) |
| `ENTARCH-Report.ps1` | Produces the identity posture & maturity report and emits the **KQL** queries (MFA coverage, legacy-auth, risky sign-ins, privileged sign-ins) to run against sign-in/audit logs — the evidence for the Decision Record (read-only) |
| `ENTARCH-Validate.ps1` | Checks the tenant against the target-state blueprint — break-glass presence, the mandated design groups (present or roadmap), the assumed licensing, and All-users CA policies without exclusions the design must reconcile (read-only) |

## What the buyer receives
- This design method and all its guides as a Word document and PDF.
- All five read-only PowerShell scripts (with embedded KQL) in a single ZIP.
- The output of running them: an **Architecture Design Document**, a **Decision Record** (`ADR-0nn`),
  and a **phased Roadmap** — the blueprint for a secure Entra cloud identity foundation.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

Delivered as a Complete Solution Package (PDF + Word + scripts).

## Outcome
A documented, defensible Entra identity architecture: a target-state design across six domains, a
numbered decision record with rationale and license/preview caveats, a canonical naming and
admin-tiering standard the builds reuse, and a phased roadmap that sequences the implementation
solutions (`ENTZTCA`, `ENTIDP`, `ENTPIM`, `ENTPAW`, `ENTIGA`, `ENTGSA`, `ENTAPPMIG`, `HYBID`) — the
identity foundation designed once, deliberately, before the risk and rework accrue.
