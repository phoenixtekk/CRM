# Deliverables Summary — AWS Landing Zone & Organizations Baseline

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the single-account breach/billing problem, the governed multi-account foundation solution, and the boundary (foundation only; detection/federation/networking are separate; plan-first, production apply is the customer's decision). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (Organizations, OUs, landing zone Control Tower vs Terraform, account vending, SCPs, centralized CloudTrail/Config, account baseline), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Organizations All-features, the Control-Tower-vs-Terraform decision, dedicated core accounts, an OU model + region-allow list, a tagging/naming standard, encrypted remote state, the pinned IaC toolchain) — layered on the shared `global-requirements-aws.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | Exact, ordered build: discover state, author the baseline as code, plan-first apply of OUs/logging/SCPs to a non-prod scope, vend a test account, validate the guardrails deny/allow correctly, then expand SCPs and vending org-wide — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Eight pass/fail gates from org-All-features and OU-hierarchy through centralized-logging, SCPs-attached-to-pilot-OUs, guardrails-actually-deny, vended-account-baselined, and plan-first-with-protected-state, referencing the helpers by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (consolidated-billing mode, root refusal, SCP lockout, region-lockdown blocking globals, CloudTrail delivery perms, empty Config aggregator, Control-Tower/Terraform conflict, local state, unbaselined account, unexpected cost) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Foundation-as-code, guardrails-prevent-and-exempt-the-exits, centralize-logging-out-of-reach, vend-don't-hand-build, baseline-everything, mind-the-cost — plus where to go next in the catalog. |

## Infrastructure-as-Code + helpers (5)

The core is **real Terraform**; the helpers are **read-only or plan-first** AWS CLI scripts. Nothing
uses static credentials — everything authenticates via an **assumed role / permission set / OIDC**
(never root). *Verify current provider/CLI versions, feature availability, and pricing for your AWS
partition (Commercial vs GovCloud).*

| File | Type | What it does |
| --- | --- | --- |
| **`main.tf`** | Terraform (plan-first) | Declares the foundation as code: the OU hierarchy, central encrypted log bucket + `kms-org-logs`, `Trail-Org-CloudTrail`, `Config-Org-Aggregator`, and the five SCP guardrails — attached to the **pilot OUs only** until validated. Applied only through the wrapper. |
| **`AWSLZ-Discovery.sh`** | Read-only | Inventories current state: org feature set, OUs and accounts + placement, existing SCPs, CloudTrail, and Config. Calls only describe/list APIs. |
| **`AWSLZ-Deploy.sh`** | Plan-first, approval-gated | The **only** sanctioned way to apply `main.tf`: `plan` changes nothing; `apply` re-plans, shows the plan, and requires a **typed confirmation**; `destroy` is double-confirmed. Refuses to run as root. Never unattended. |
| **`AWSLZ-Validate.sh`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL: org All-features, OU hierarchy, org CloudTrail centralized, Config aggregating, SCPs on pilot OUs, and a guardrail-deny probe prompt. |
| **`AWSLZ-Report.sh`** | Read-only | Posture snapshot for governance: accounts by OU, SCP attachments per OU, central-logging status, and an account-baseline (password-policy) signal. |

## Named objects (verbatim — used across docs, IaC, and tests)

- **OUs:** `Security`, `Infrastructure`, `Workloads-Prod`, `Workloads-NonProd`, `Sandbox`
- **Core accounts:** `Log-Archive`, `Security-Tooling`
- **SCP guardrails:** `SCP-DenyLeaveOrg-Guardrail`, `SCP-DenyRootActions-Guardrail`,
  `SCP-RegionLockdown-Guardrail`, `SCP-ProtectSecurityServices-Guardrail`,
  `SCP-RequireEncryption-Guardrail`
- **Central logging:** `Trail-Org-CloudTrail`, `Config-Org-Aggregator`,
  `org-log-archive-<mgmt-account-id>` (S3), `kms-org-logs` (CMK)

## What this solution deliberately does NOT do

- It does **not** provide security-finding detection/triage (GuardDuty/Security Hub), identity
  federation (IAM Identity Center ↔ Entra), or networking/data-perimeter design — those are separate
  catalog solutions this foundation makes deployable org-wide.
- It does **not** apply anything without a plan — every change is **plan-first, non-prod-first**, and
  production apply requires the customer's change approval.
- It does **not** decide **which regions are allowed, the tagging standard, or the OU-model
  specifics** — those are cloud-governance determinations; the solution enforces what you set.
- It does **not** run as root or use static admin keys — the wrapper refuses root and expects an
  assumed role.
- It does **not** invent version, feature, or pricing facts — where these differ by partition it says
  **verify current provider/CLI versions, feature availability, and pricing**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the Terraform and AWS CLI files, in a single
ZIP (`AWSLZ-Complete-Solution.zip`) — yours to keep and reuse on every rollout.
