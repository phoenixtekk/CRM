# 1. Solution Overview — Microsoft Purview Administrator Training

## The problem this solves
Most teams learn to run **Microsoft Purview** by trial and error in a live tenant — clicking through
the portal on a real incident, guessing at label scope, publishing a DLP policy straight to
enforcement, and discovering the blast radius afterward. Purview is broad (sensitivity labels, DLP,
data lifecycle & records, insider risk, communication compliance, audit, eDiscovery, and data
security posture management), heavily **licensing-dependent**, and **actively evolving** — so
trial-and-error is slow, inconsistent between admins, and, on high-impact features, genuinely risky.
The result is a **skills gap that is also a compliance gap**: the people who operate your governance
controls have no structured way to build and prove competence.

This package fixes that with a **structured Purview administrator training curriculum** — a sequence
of **hands-on labs** that each build a Purview capability in a **safe sandbox scope and in
simulation/test mode first**, plus **operational runbooks** for the recurring work an administrator
does after go-live. Every lab is named object-for-object, gated with an explicit **pass/fail
validation**, and has a **teardown** so the training environment returns to a known state. It is
self-guided, tested, and repeatable — competence built deliberately instead of learned on a live fire.

> **Vendor boundary.** The **Microsoft Purview portal** (`purview.microsoft.com`), the **Microsoft
> 365 admin center**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft
> Graph** are authored at current, exact detail from Microsoft's public documentation. Purview
> capabilities are heavily **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the
> **E5 Compliance** add-on; some are in preview) and the portal is **evolving** — availability and
> portal paths are **cited or flagged "verify your licensing/tenant,"** never invented. This is
> **administrator skills training**, not a records, privacy, or legal determination: retention
> schedules, records file plans, legal holds, and insider-risk / communication-compliance **case
> outcomes** are **deferred to the organization's compliance, records, privacy, and legal functions**
> — the labs teach the *technical method* and produce evidence, not the governance decision.

## Who this is for
A competent Microsoft 365 administrator (or a team of them) who needs to **own day-to-day Purview
operations** — new to Purview, cross-training from Exchange/security administration, or formalizing
skills they picked up ad hoc. The curriculum assumes M365 admin fundamentals and builds Purview
specifics from the ground up.

## What the curriculum covers
The labs are organized into modules that mirror the Purview solution areas. Each is a **self-contained
lab** with an objective, prerequisites, ordered steps (in a sandbox scope, simulation/test first), a
validation gate, and a teardown.

| Module | Lab focus | Runs in |
|---|---|---|
| 0 — Foundations | Portal orientation, **roles & least-privilege scopes**, PowerShell/Graph toolchain | Read-only |
| 1 — Sensitivity labels | Create a training label + label policy scoped to a training group | Scoped pilot |
| 2 — Data Loss Prevention | Author a DLP policy and run it in **test / simulation** mode (no enforcement) | Simulation |
| 3 — Data lifecycle & records | Configure a retention policy/label against an *illustrative* schedule | Scoped pilot |
| 4 — Auto-labeling | Stand up an auto-labeling policy in **simulation** mode and read the results | Simulation |
| 5 — Insider Risk Management | Walk the policy model with **privacy-by-design** and role separation | Portal, limited scope |
| 6 — Communication Compliance | Walk the policy model with **pseudonymization** and role separation | Portal, limited scope |
| 7 — Audit | Run **Audit (Standard/Premium)** searches and export evidence | Read-only |
| 8 — eDiscovery | Create a case, place/verify a hold on a training custodian, search | Scoped pilot |
| 9 — DSPM & analytics | Read **Data Security Posture Management** and classification analytics | Read-only |
| 10 — Operations | Turn the labs into **runbooks**: alert triage, coverage review, change control | Ongoing |

**Modules 5 and 6 are HR/privacy-sensitive.** They are taught as *policy-model walkthroughs* with
**privacy-by-design, pseudonymization where the feature supports it, and strict role separation** —
never with real employee data, and with all case *outcomes* deferred to HR/legal.

## What "training" delivers here (the model, applied twice)
The house deployment model — **Assess → Design → Configure → Pilot (simulate/test) → Validate →
Expand (enforce)** — is used two ways in this package:

1. **To roll out the training program.** *Assess* the team's current Purview skills and the tenant
   baseline; *design* the curriculum and the sandbox scope; *configure* a training scope group and
   naming convention; *pilot* the labs; *validate* competence with the pass/fail gates; *expand* into
   the operational runbooks and a recurring cadence.
2. **Inside every lab.** Each capability is built the same disciplined way an administrator must build
   it in production — **scoped to a training group and run in simulation/test/disabled mode first**,
   validated against a pass/fail gate, and only then understood as "ready to enforce." The trainee
   *practices the safe rollout pattern itself*, so the habit transfers to production.

## The training naming convention (used verbatim throughout)
Every object a lab creates is prefixed **`TRAIN-`** and scoped to the training group **`TRAIN-Pilot-Users`**,
so training artifacts are unmistakable, auditable, and safe to tear down:

| Lab | Object created | Named |
|---|---|---|
| 1 | Sensitivity label + policy | `TRAIN-Label-Confidential` in `TRAIN-LabelPolicy-Pilot` |
| 2 | DLP policy (test mode) | `TRAIN-DLP-PII-Sim` |
| 3 | Retention policy/label | `TRAIN-Retention-Pilot` / `TRAIN-RetLabel-Illustrative` |
| 4 | Auto-labeling policy (simulation) | `TRAIN-AutoLabel-Sim` |
| 7 | Audit search | `TRAIN-Audit-Search` |
| 8 | eDiscovery case | `TRAIN-eDiscovery-Case` |

## Benefits
- **Competence you can prove.** Every lab ends at a pass/fail validation gate, so "trained" means an
  evidenced capability, not a claim.
- **Safe by construction.** Labs run in a scoped training group and in simulation/test/disabled mode
  — trainees learn the high-impact features (DLP, labels, retention, auto-labeling) without risking
  production.
- **The safe-rollout habit transfers.** Practicing scope-first, simulate-first, validate-before-enforce
  in every lab builds the exact discipline production Purview work demands.
- **Runbooks, not just knowledge.** Module 10 converts the labs into repeatable operational runbooks
  (alert triage, coverage review, audit request handling) the team uses after training.
- **A fraction of consulting cost.** Self-guided, tested curriculum with PowerShell helpers — reusable
  for every new administrator you onboard.

## Limitations (be honest with buyers)
- **This is skills training, not a governance determination.** The labs use *illustrative* label
  taxonomies, retention periods, and policy scopes so trainees can practice the mechanics. **Real**
  retention schedules, records file plans, legal holds, and insider-risk/communication-compliance
  outcomes are **legal/records/privacy/HR determinations** — deferred to those functions.
- **Licensing gates what you can practice.** Advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, eDiscovery Premium, and DSPM require **E5 / E5 Compliance** (some
  preview). Where a feature is not licensed, the lab degrades to a read-only walkthrough — **verify
  your licensing/tenant.**
- **The portal evolves.** Purview paths and cmdlet behavior change; steps reflect current public
  documentation and are flagged **"verify in your tenant"** where volatile. No portal path or cmdlet
  is invented.
- **A sandbox/training tenant is strongly preferred.** Where labs run in a production tenant, they are
  strictly scoped to `TRAIN-Pilot-Users` and simulation/test mode, and torn down afterward.

## The deployment model
> **Assess skills & baseline → Design curriculum & sandbox scope → Configure the training scope →
> Pilot the labs in simulation/test → Validate competence at each pass/fail gate → Expand into
> operational runbooks.** The pattern is **Assess → Design → Configure → Pilot → Validate → Expand**,
> with an explicit gate per lab and a documented teardown for every training object created.
