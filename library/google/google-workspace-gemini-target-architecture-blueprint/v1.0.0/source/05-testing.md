# Testing — Architecture-Conformance Validation Gates

You do not "test" an architecture by running it; you test whether the **designs and the built estate
conform** to the blueprint's principles, patterns, ADRs, and NFRs. This section defines the
**conformance gates** — explicit pass/fail checks — that a domain, a wave, or the whole program must
clear. `GWARCH-Validation.ps1` automates the source-side, machine-checkable subset; the rest are
review gates the ARB signs.

**Every gate is pass/fail with a documented remediation path.** A domain does not advance from Pilot
to Expand until its gates pass or the ARB records an exception ADR.

## Gate 0 — Foundation conformance (blocks everything)

| Check | Pass criterion |
| --- | --- |
| Single identity source of truth named | ADR GWARCH-ADR-ID-01 exists and is Accepted |
| GWARCH-Scope OU/group taxonomy defined | Named taxonomy exists incl. pilot scope |
| ARB + ADR log stood up | Charter and log present; cadence set |
| Governance stakeholders engaged | RACI + policy inputs collected |

*Fail → stop. No domain proceeds on an undefined foundation (GWARCH-P1/P2).*

## Gate 1 — Identity conformance

- **No shadow provisioning:** every population traces to the one provisioning pipeline (GWARCH-ID-1).
  *Check:* discovery shows no workstream-owned identity source. **Pass/fail.**
- **SSO ≠ provisioning coupling:** federation and lifecycle are separable (GWARCH-ID-2).
- **Break-glass admin independent of IdP:** an admin path survives an IdP outage. **Must pass.**
- **Deprovisioning path exists and orphan detection is defined** (GWARCH-ID-3).

## Gate 2 — Collaboration conformance

- **Coexistence is bounded:** every mail/calendar bridge has a sunset condition recorded
  (GWARCH-COL-2 / GWARCH-P5). **Pass/fail.**
- **Collaboration policy binds to scope,** not individuals (GWARCH-COL-3).
- **MX/routing change has a documented rollback.** **Must pass** before any mail-flow change.

## Gate 3 — Drive / content conformance

- **Team content lands in shared drives** with an ownership/lifecycle owner (GWARCH-DRV-1).
- **Content is classified and each class has a disposition** (GWARCH-DRV-2).
- **Permissions are remodeled, not raw-copied** (GWARCH-DRV-3 / no legacy over-sharing).
- **Retention-bearing content routed to the governance plane,** not migrated as active.

## Gate 4 — Governance & retention conformance

- **Retention schedule expressed in Vault by scope** and matches the stakeholders' schedule
  (GWARCH-ADR-GOV-01).
- **Hold continuity:** no gap between Purview holds and Vault governance; each matter has a sunset
  owner/date (GWARCH-GOV-2). **Must pass — a hold gap is a legal defect.**
- **DLP binds to scope + classification, closed-by-default externally** (GWARCH-GOV-3 / GWARCH-P4).

## Gate 5 — AI enablement conformance (gated by Gate 4)

- **AI enabled only where governance exists:** no OU/group has Gemini/agent access to a data class
  whose DLP/sharing/retention controls are not yet in place (GWARCH-P6 / Pattern AI-C). **Must pass.**
- **Every production agent is governed:** owner, data/actions scope, and review recorded
  (GWARCH-AI-2). No ungoverned agents. **Pass/fail on the agent inventory.**
- **Preview-capability risk register maintained:** each Gemini capability marked GA vs preview with a
  contingency (**verify in tenant** items are tracked, not assumed GA).
- **AI enablement is scoped, not tenant-wide,** and auditable (GWARCH-AI-1/AI-3).

## Gate 6 — Cross-domain NFR conformance

- **Scale stated at 150k users** per domain (limits, sync windows, admin blast radius).
- **Every domain names an operational owner + runbook** (supportability).
- **Least standing access + break-glass** verified across domains (security).
- **Compliance continuity** end-to-end (retention/holds/regulatory).

## Gate 7 — ADR completeness & authority

- **Every domain has its required ADRs recorded** with status; supersessions are linked.
- **No un-reconciled design conflicts:** any workstream deviation from a principle/pattern is either
  removed or carried as an explicit exception ADR (GWARCH-P1). **Pass/fail.**
- **The ADR log is the single source** the ARB governs against and is current.

## How to run the machine-checkable subset

`GWARCH-Validation.ps1` performs read-only source-side checks that feed Gates 0–2 (e.g. detecting
multiple potential identity sources, unscoped targeting, missing break-glass indicators) and emits a
pass/fail summary. `GWARCH-Report.ps1` rolls the results plus the design-review gates into a
**coverage/gap** view the ARB uses to decide Pilot→Expand. The review gates (patterns, ADRs, NFR
sign-off) are human ARB decisions the scripts surface but do not replace.

**Exit criterion for "architecture approved":** Gates 0–7 pass (or carry ARB-approved exceptions), the
Target-Architecture document is compiled, and the ADR log is current. Only then does the architecture
Expand to all waves.
