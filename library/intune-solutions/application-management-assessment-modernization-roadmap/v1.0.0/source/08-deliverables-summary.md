# 8. Deliverables Summary — Application Management Current-State Assessment & Modernization Roadmap

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The business case and what is in the box |
| 1. Solution Overview | What the assessment is — the 9-dimension × 5-level maturity model, the discovery method, the gap analysis, and the roadmap — with benefits and limitations |
| 2. Requirements Guide | Every assessment-specific prerequisite with Verify / Implement-if-missing (least-privilege read-only access, read scopes, charter, stakeholders, Government endpoints) |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | The assessment run as eight ordered phases — charter, access, artifacts, interviews, technical collection, scoring against the nine evidence tables, findings, roadmap & readout |
| 5. Testing Guide | How to prove the assessment is trustworthy — read-only, evidence-backed, repeatable, complete — with pass/fail gates |
| 6. Troubleshooting Guide | Field issues — incomplete data, uncooperative stakeholders, tenant access gaps — and how to keep the assessment honest through them |
| 7. Best Practices | Field-proven recommendations for a defensible, credible assessment |

## PowerShell scripts (all READ-ONLY)
| Script | What it does |
|---|---|
| `APPASMT-Estate-Inventory.ps1` | Inventories and classifies the Intune app estate by type, publisher, and assignment intent; builds the baseline "how many apps, of what kind" picture (D1, D9). Also runs the read-only access check. |
| `APPASMT-Assignment-Analysis.ps1` | Finds assignment sprawl and conflicts — All-Devices/Users targeting, conflicting intents, orphaned assignments to empty groups (D1, D3). |
| `APPASMT-Install-Health.ps1` | Baselines per-app install success/failure/pending and the version-drift picture (how many live versions per title) (D4, D7). |
| `APPASMT-Unmanaged-Detection.ps1` | Detects unmanaged / sideloaded software — present on managed devices but not deployed by Intune — the shadow estate (D5, D6, D9). |
| `APPASMT-Maturity-Evidence.ps1` | Aggregates the four evidence files plus app-control / co-management / app-policy signals into a scored data pack (`APPASMT-EvidencePack.json`) with a suggested level and the signal behind each of the nine dimensions. |

Every script uses Microsoft Graph read-only (`.Read.All`) scopes only, aligns to the Intune **Read Only
Operator** role, and targets Government tenants with `-Environment USGov` (GCC High) / `USGovDoD` (DoD).
No script writes to the tenant.

## Reusable templates and named artifacts
The assessment produces a consistent, named artifact set (defined in the Solution Overview and used
verbatim throughout): `APPASMT – Assessment Charter`, `APPASMT – Maturity Model (9 Dimensions x 5
Levels)`, `APPASMT – Artifact Request List`, `APPASMT – Discovery Interview Guide`, `APPASMT – Evidence
Pack`, `APPASMT – Scoring Sheet`, `APPASMT – Findings Register`, `APPASMT – Risk Matrix`, `APPASMT –
Roadmap One-Pager`, `APPASMT – Wave Plan`, and `APPASMT – Executive Readout`.

## What the buyer receives
- The full assessment documentation set as a Word document and PDF.
- All five read-only PowerShell scripts in a single ZIP.
- A repeatable maturity model, scoring method, findings register, and modernization roadmap following
  the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — where this product
  owns the **Assess** stage and produces the **Design** input for every downstream workstream, with
  explicit pass/fail gates and a read-only guarantee.

## Outcome
A defensible, evidence-based answer to "how good is our application management, and what do we fix
first?" — a 1–5 score across nine dimensions, a findings register rating business impact and risk, and a
three-wave modernization roadmap plotted on effort vs impact with dependencies mapped and a 30/60/90 +
12-month view. Re-run the same model to prove the trend and the return on the investment.
