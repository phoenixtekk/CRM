# 1. Solution Overview — Microsoft Purview Automation Framework

## What this solution is
Purview administration done by hand does not scale and does not repeat. Policies get created differently
by different admins, DLP rules drift from what was designed, a label that should exist in test is quietly
missing, and when an auditor asks "show me every DLP/retention/label policy and its current state" the
answer is a manual scavenger hunt across the portal. This solution delivers a **configuration-as-code
automation framework** for Microsoft Purview operations: a **declarative desired-state config** describes
the DLP policies, sensitivity labels, and retention policies your organization intends to run; **PowerShell
tooling** then **discovers** the current tenant state, **deploys** the config **into simulation/test/
unpublished mode first**, **validates** deployed state against the desired config (drift detection), and
**reports** a coverage scorecard and policy inventory as evidence. It uses only the **Microsoft Purview
portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no
third-party tooling and no secrets in code.

This is a **framework**, not a specific policy pack: it operationalizes *how* Purview policy objects are
deployed, reviewed, and evidenced repeatably. *What* each policy must contain (which sensitive info types,
which retention schedule, which labels) remains a compliance/records/legal determination — the framework
carries those decisions faithfully into the tenant and proves they landed; it does not make them.

## Why this matters
- **Repeatability is the whole point.** A DLP or retention policy created by clicking is hard to reproduce, review, or roll back. A policy defined in a config file and deployed by script is reviewable in change control, identical across pilot and production, and rebuildable after a mistake.
- **Purview changes are high-impact and must be piloted.** DLP, sensitivity-label, and retention changes affect real users and real data the moment they enforce. Every Purview policy type supports a **safer-than-enforce** first state — DLP **test/simulation mode**, labels **created-but-unpublished**, retention **created-but-scoped/unpublished** — and this framework deploys into that state **by default**, only enforcing on an explicit, separate, committed action.
- **Drift is invisible until it bites.** Someone edits a rule in the portal, a policy gets disabled "temporarily," a label falls out of a label policy — and nobody notices until an incident or audit. Scheduled **desired-state validation** turns silent drift into a caught, reported difference.
- **Evidence on demand.** A **policy inventory** and **coverage scorecard** produced by script — rather than assembled by hand before every audit — is what makes the compliance posture defensible.

## How it works
1. **Establish the desired-state config.** A single, human-readable JSON config — `Automation Config – Purview Ops – Baseline` — lists the DLP policies, sensitivity labels, and retention policies that should exist, each with the attributes the framework manages (name, scope/locations, mode, and the identifying settings). Compliance/records/legal own the *content*; the config is the reviewable record of it.
2. **Discover the current state.** `OPSAUTO-Discovery.ps1` (read-only) inventories what actually exists in the tenant — DLP policies and their **mode**, sensitivity labels and label policies, retention policies and rules — and exports a state snapshot.
3. **Deploy into a safe first state.** `OPSAUTO-Deploy.ps1` reconciles config → tenant. It runs **`-WhatIf` by default** (prints the exact `New-/Set-*` it would run), creates DLP policies in **test/simulation mode**, labels **unpublished**, and retention **unenforced/pilot-scoped** on `-Commit`, and only moves an object to **enforce** on a deliberate, separate `-Enforce -Commit`.
4. **Validate against desired state.** `OPSAUTO-Validate.ps1` (read-only) compares deployed objects to the config and reports **drift** — missing, extra, mode-mismatched, or altered policies — with a pass/fail gate.
5. **Report the posture.** `OPSAUTO-Report.ps1` (read-only) produces the **policy inventory** and a **coverage scorecard** (what exists, in what mode, against what the config expects) as the audit-ready evidence artifact.
6. **Run on a cadence.** The read-only chain (Discovery → Validate → Report) is scheduled so drift and gaps surface early; Deploy is run under change control when the config changes.

## The Purview objects this framework manages
- **DLP compliance policies & rules** — `*-DlpCompliancePolicy` / `*-DlpComplianceRule`, including the policy **mode** (test/simulation vs enforce). **Verify your tenant** for the exact mode values it accepts.
- **Sensitivity labels & label policies** — `*-Label` / `*-LabelPolicy` (labels created before they are published; publishing is the enforce step).
- **Retention (data lifecycle) policies & rules** — `*-RetentionCompliancePolicy` / `*-RetentionComplianceRule` (created and pilot-scoped before tenant-wide publish).
- All are **Security & Compliance PowerShell** objects (`Connect-IPPSSession`); **Graph** is used for licensing and reporting reads. **Records-management file plans, insider-risk, and communication-compliance objects are intentionally out of scope for automated deploy** — they carry legal/HR/records determinations and are managed under their own governance (see Limitations).

## What you can control
- The **desired-state config** — which DLP/label/retention policies the framework knows about and their managed attributes.
- The **deploy mode** — nothing enforces without an explicit, separate `-Enforce -Commit`; the default deploy lands everything in test/simulation/unpublished.
- The **pilot scope** — `Automation Pilot – Ops Scope – Stage1` (a bounded set of locations/users/policies) validated before any enforce/publish.
- The **validation and reporting cadence** — how often drift is checked and the scorecard regenerated.

## Limitations (be honest with buyers)
- **The framework carries decisions; it does not make them.** *Which* sensitive info types, *which* retention duration, *which* labels — and whether a policy is legally adequate — are **compliance/records/privacy/legal determinations**. The config is only as correct as those inputs.
- **Purview is licensing-/plan-dependent and evolving.** Advanced DLP, auto-labeling, and several retention capabilities require **Microsoft 365 E5 / E5 Compliance**; some features are in preview and cmdlet parameters (notably DLP **simulation/mode** values) change. Capabilities and parameters are **flagged "verify your licensing/tenant,"** never invented.
- **Cmdlet coverage, not portal parity.** Some Purview settings are portal-only or only partially exposed to Security & Compliance PowerShell; the framework manages the attributes the cmdlets expose and flags where a setting must be confirmed in the portal.
- **Records/insider-risk/communication-compliance are out of automated scope.** Their objects encode legal/HR/records determinations and file-plan structure; this framework inventories and reports on the automatable policy types (DLP, labels, retention) and defers those sensitive domains to their own governance.
- **Deploy is high-impact even in test mode.** Creating dozens of objects touches the tenant; that is why deploy is `-WhatIf` first, test/unpublished by default, pilot-scoped, and reversible.

## Naming convention (used in every doc and script)
Every artifact this framework creates or produces is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, config, and portal. The standard set:

| Artifact | Name |
|---|---|
| Declarative desired-state config (JSON) | `Automation Config – Purview Ops – Baseline` |
| Current-state snapshot (Discovery export) | `Automation Snapshot – Tenant State – Current` |
| DLP/label/retention deploy (safe first state) | `Automation Deploy – Purview Policies – Simulation` |
| Desired-state / drift validation | `Automation Validate – Desired State – Drift` |
| Policy inventory report | `Automation Report – Policy Inventory – Tenant` |
| Coverage scorecard | `Automation Report – Coverage Scorecard – Tenant` |
| Pilot scope | `Automation Pilot – Ops Scope – Stage1` |

## The standard deployment model
> Assess the current tenant policy state and the desired-state config → design the config and pilot scope →
> configure by deploying **into test/simulation/unpublished mode** → **pilot** on a bounded scope and
> validate against desired state → validate drift is clean and the scorecard is green → expand by enforcing/
> publishing under change control. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
