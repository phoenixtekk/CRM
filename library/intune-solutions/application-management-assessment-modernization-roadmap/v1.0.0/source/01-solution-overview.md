# 1. Solution Overview — Application Management Current-State Assessment & Modernization Roadmap

## What this solution is

Almost every organization running Microsoft Intune has an application estate that grew rather than was
designed. Apps arrived one at a time, packaged by whoever was available, assigned to whichever group
was handy, and never retired. The result is familiar: nobody can say how many apps are actually
deployed, install failures are tolerated as background noise, three versions of the same product are
live at once, and every conversation about "modernizing app management" stalls because there is no
agreed picture of where things actually stand.

**This solution is a structured, repeatable assessment that produces that picture — and then turns it
into a sequenced modernization roadmap.** It is the front-door engagement: run it first, and the
findings tell you which deeper workstreams to fund, in what order, and why.

It delivers four things:

1. A **capability maturity model** — nine dimensions of application management, scored 1–5, with
   **observable evidence** defined for every level so scoring is objective rather than opinion.
2. A **discovery method** — an interview guide (who to ask, what to ask), an artifact request list, and
   a **read-only technical data collection** from Intune and Microsoft Graph that evidences the scores.
3. A **gap analysis** — every gap becomes a written finding with business impact, a risk rating, and a
   remediation direction with a sized effort.
4. A **roadmap** — findings sequenced into three waves (Quick Wins → Foundational → Strategic) plotted
   on effort vs impact, with dependencies mapped and a 30/60/90-day plus 12-month view, delivered in an
   executive readout.

## What this solution is NOT

This is an **assessment and sequencing** product. It tells you what is broken, how badly, and in what
order to fix it. It does **not** contain the implementation detail for the fixes themselves — those are
separate, deeper engagements. Specifically, this package does not teach:

- How to build an application governance operating model (intake, roles, decision forum, change tiers).
- How to write packaging and deployment standards (detection rules, requirement rules, PSADT wrappers,
  supersedence chains).
- How to run an application retirement and decommissioning program.
- How to remediate Win32 app uninstall and removal failures.
- How to build application estate monitoring, reporting, and supportability tooling.

Where a finding points at one of those, this solution states the **remediation direction and the effort
size** — and stops there. That boundary is deliberate: an assessment that drifts into implementation
detail stops being an assessment and becomes an unread 300-page document.

## The maturity model — `APPASMT – Maturity Model (9 Dimensions x 5 Levels)`

This is the core named artifact. It is reused verbatim in the Requirements Guide, the Implementation
Guide, the Testing Guide, the Troubleshooting Guide, and every script.

### The nine dimensions

| # | Dimension | What it measures |
|---|---|---|
| **D1** | Governance & Ownership | Whether every app has a named accountable owner, an intake path, and an approval record |
| **D2** | Packaging Standards | Whether apps are packaged to a written standard — naming, detection, requirements, install behaviour |
| **D3** | Deployment & Rings | Whether deployments follow defined rings with gates, or go straight to All Devices |
| **D4** | Patching & Version Currency | Whether app versions are kept current on a defined cadence, and how much drift exists |
| **D5** | Security & Application Control | Whether app execution is controlled (WDAC/AppLocker), signed, and security-reviewed before deployment |
| **D6** | Lifecycle & Retirement | Whether apps are reviewed, superseded, and actually removed when no longer needed |
| **D7** | Monitoring & Reporting | Whether install success, failure, and estate composition are measured and reported to someone |
| **D8** | Support Model | Whether app tickets have a defined route, runbooks, and escalation to a named owner or vendor |
| **D9** | Tooling & Migration Debt | Whether the estate is genuinely Intune-native, or still carries SCCM/co-management/manual remnants |

### The five levels

| Level | Name | General meaning |
|---|---|---|
| **L1** | Initial | Ad hoc. Undocumented, person-dependent, no repeatable process. |
| **L2** | Repeatable | A process exists in practice but is unwritten and inconsistently applied. |
| **L3** | Defined | Written, published, and followed for new work. Legacy backlog not yet remediated. |
| **L4** | Managed | Measured. Metrics exist, are reviewed on a cadence, and drive corrective action. |
| **L5** | Optimized | Automated and continuously improved. Exceptions are rare, visible, and closed. |

The generic level names above are deliberately not the scoring criteria. **Each dimension has its own
evidence table** — the exact observable artifact or data signal required to claim each level — in
Implementation Step 5. That is what makes the score defensible: an assessor cannot award L3 on D2
without producing the written packaging standard document.

## How the assessment runs

The engagement is eight ordered phases (Implementation Guide, Steps 1–8):

1. **Charter** — agree scope, dimensions, target levels, stakeholders, and the readout date.
2. **Access** — obtain least-privilege **read-only** tenant access and verify it.
3. **Artifacts** — request and collect the documentary evidence (`APPASMT – Artifact Request List`).
4. **Interviews** — run the structured interviews (`APPASMT – Discovery Interview Guide`).
5. **Technical collection** — run the five read-only scripts to build the `APPASMT – Evidence Pack`.
6. **Score** — apply the evidence tables to produce the `APPASMT – Scoring Sheet`.
7. **Findings** — convert gaps into the `APPASMT – Findings Register` with impact and risk ratings.
8. **Roadmap & readout** — sequence findings into the `APPASMT – Roadmap One-Pager` and present the
   `APPASMT – Executive Readout`.

## Everything is read-only

**This assessment must not change the tenant.** All five scripts use read-only Microsoft Graph scopes,
and the recommended Intune role is **Read Only Operator**. Nothing is created, modified, assigned, or
deleted. This matters commercially as much as technically: an assessment that changes production is
an assessment nobody will let you run again, and a customer who has to schedule a change window will
delay the engagement by weeks.

## Named artifacts produced

These names are used verbatim throughout the documentation and the scripts:

| Artifact | What it is |
|---|---|
| `APPASMT – Assessment Charter` | Scope, dimensions in play, target levels, stakeholders, dates, out-of-scope statement |
| `APPASMT – Maturity Model (9 Dimensions x 5 Levels)` | The scoring rubric with per-dimension evidence tables |
| `APPASMT – Artifact Request List` | The documents and exports requested from the customer |
| `APPASMT – Discovery Interview Guide` | Structured questions per stakeholder role |
| `APPASMT – Evidence Pack` | The folder of script outputs (CSV/JSON) that evidences every score |
| `APPASMT – Scoring Sheet` | The 9-dimension score table: current level, target level, gap, evidence citation |
| `APPASMT – Findings Register` | One row per finding: dimension, description, evidence, business impact, risk rating, remediation direction, effort |
| `APPASMT – Roadmap One-Pager` | The three waves plotted on effort vs impact, with dependencies |
| `APPASMT – Wave Plan` | Wave 1 Quick Wins (0–30 days) · Wave 2 Foundational (30–90 days) · Wave 3 Strategic (90 days–12 months) |
| `APPASMT – Executive Readout` | The presentation deck and its mandatory executive summary |

## Benefits

- **A number, not a debate.** Nine dimensions, each scored 1–5 against observable evidence. Two
  assessors running this model on the same tenant reach the same scores.
- **Evidence, not survey answers.** Interviews describe intent; the scripts show reality. Where they
  disagree, the data wins, and that disagreement is itself a finding.
- **A defensible investment case.** Every finding carries a business impact and a risk rating, so the
  budget conversation is about consequences rather than preferences.
- **A sequenced plan, not a wish list.** Quick wins fund credibility; foundational work unblocks the
  strategic work. The roadmap makes the dependencies explicit.
- **Repeatable.** Re-run the same model in six or twelve months and the movement in the scores is the
  proof the investment worked.

## Limitations — be honest with the buyer

- **The assessment measures configuration and process, not user satisfaction.** A D3 score of L4 means
  rings are defined and measured; it does not prove users are happy with the change cadence.
- **Scores are as good as the access granted.** A dimension the assessor cannot read scores as
  "Insufficient Evidence," not as L1. Guessing a low score to fill a gap is the single most common way
  an assessment loses credibility.
- **Findings that depend on non-Intune systems are bounded.** Procurement systems, ITSM tooling, and
  software asset management platforms are described from interview and artifact evidence only; this
  solution does not integrate with them.
- **Remediation is out of scope.** The roadmap sizes the work; it does not do it. Where a finding needs
  deep implementation detail, that is a separate engagement.
- **Effort estimates are ranges, not quotes.** Effort is sized in T-shirt bands (S/M/L/XL) with a day
  range per band. Converting a band into a fixed price requires the customer's own rates and
  constraints.

## The standard deployment model

> **Assess → Design → Configure → Pilot → Validate → Expand.**

This solution owns the **Assess** stage in full, and produces the **Design** input (the roadmap) that
every downstream workstream consumes. Configure, Pilot, Validate, and Expand belong to the workstreams
the roadmap sequences.
