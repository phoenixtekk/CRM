# 5. Testing & Validation — Azure Landing Zone with Terraform

Validate against the **non-production** scope (`mg-sandbox` / sandbox subscription) first. Each test has a
**pass/fail** signal. Everything is **plan/what-if first** — do not promote to production or enforce
`Deny` until all four gates pass. Reference scripts are named in each row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Clean plan** | Run `terraform plan` (or the pipeline `plan` stage) against non-prod | What-if matches intent; **no unexpected destroys/changes** | Plan proposes surprise deletes / drift |
| 2 | **G1 Reviewed** | Open the plan as a PR; a second person reviews | Plan reviewed + approved before apply | Apply run without review |
| 3 | **G2 State lock** | Start two `apply`s against the same state | Second is **blocked** by the blob lease | Both proceed (no locking) |
| 4 | **G2 Backend** | Run `IACTF-Validate.ps1 -BackendOnly` | State storage account/container reachable + versioned | Backend missing / not reachable |
| 5 | **G3 Hierarchy** | After apply, `IACTF-Discovery.ps1` | `mg-corp-root` + children exist as designed | Hierarchy missing/incorrect |
| 6 | **G3 Policy (audit)** | `IACTF-Report.ps1` | `IACTF-Policy-*` assigned at MG scope, effect **Audit**, inherited | Policy absent / already in Deny |
| 7 | **G3 Tag/region compliance** | Create a test resource violating a tag/region rule | Audit policy **reports** it non-compliant | Not evaluated |
| 8 | **G4 Approval gate** | Run the pipeline to the `apply` stage | `apply` **waits for manual approval** | Apply runs unattended |
| 9 | **G4 Drift detection** | Run the scheduled `plan` on an unchanged env | Plan is **empty (no drift)**; a manual portal change is then **detected** | Drift not surfaced |

## Automated checks
- **`IACTF-Discovery.ps1`** — inventories the management-group hierarchy, subscriptions, policy
  assignments, and RBAC so you can confirm the built structure matches the design.
- **`IACTF-Validate.ps1`** — pre-flight and post-apply checks: backend reachability + locking, a
  `terraform plan` in **check/detailed-exitcode** mode (non-zero = pending changes/drift), and provider
  version pinning. **Read-only / plan-only — never applies.**
- **`IACTF-Report.ps1`** — governance report: policy **compliance state** per assignment and scope, and a
  drift summary (resources changed outside Terraform) for the audit trail.
- **`azure-pipelines.yml`** — the plan→approve→apply pipeline itself; its `plan` stage is the primary
  what-if gate, its scheduled run is the drift check.

## Evidence to capture
- The reviewed **`terraform plan`** output (PR artifact) for the pilot apply.
- `IACTF-Discovery.ps1` output showing the management-group hierarchy.
- `IACTF-Report.ps1` compliance CSV (policy assignments + compliance state) — the governance evidence.
- A pipeline run screenshot showing the **manual approval** gate before `apply`.
- A scheduled-`plan` run showing **no drift**, plus one showing a **detected** out-of-band change.

## Exit criteria (before Expand / before `Deny`)
- [ ] G1 — plan is clean, reviewed, and matches intent (no surprise destroys)
- [ ] G2 — remote state backend reachable **and** locking blocks concurrent applies
- [ ] G3 — hierarchy built; policy assigned in **Audit** and inheriting; violations reported
- [ ] G4 — pipeline `apply` waits for approval; scheduled `plan` detects drift
- [ ] `IACTF-Validate.ps1` and `IACTF-Report.ps1` run clean against non-prod
