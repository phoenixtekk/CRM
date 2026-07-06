# Solution Overview — Target Architecture Blueprint

## What this blueprint is (and is not)

This is an **architecture-authority** product for a large-scale (150,000-user) transformation from
Microsoft 365 to **Google Workspace + Gemini Enterprise**. It defines the **end-state target
architecture** and the **architectural principles, reference patterns, decision records (ADRs), and
non-functional requirements (NFRs)** that every migration workstream is measured against. It is the
document the chief architect owns so the transformation stays scalable, supportable, and under
enterprise control.

It is **not** a click-by-click configuration runbook. Individual workstreams (mail cutover, Drive
migration, SSO federation, DLP, Vault) each have their own build procedures; this blueprint governs
**how those builds must be designed** so they compose into one coherent, defensible end state instead
of fragmenting across partners and waves.

> **Authority statement.** When a workstream design conflicts with a principle or ADR in this
> blueprint, the blueprint wins unless the Architecture Review Board (ARB) records a superseding
> decision. That is what "owning the architecture" means in practice.

## The end-state architecture at a glance

The target estate is organized into five **architecture domains**, each with an owning principle set,
reference patterns, and ADRs (detailed in `03-implementation.md`):

| Domain | End-state anchor | Source-side coexistence |
| --- | --- | --- |
| **Collaboration** (email, calendar, Chat, Meet, Docs) | Google Workspace as the single collaboration plane | M365 mailboxes decommissioned wave-by-wave; dual-delivery only during coexistence |
| **Content / Drive replacement** | Google Drive + shared drives as the SharePoint/OneDrive successor | SharePoint/OneDrive read-only then retired per content class |
| **Identity integration** | One authoritative identity source federated to Google via SSO + automated provisioning | Entra ID / on-prem AD retained as source of truth or transitional IdP |
| **Data governance & retention** | Google Vault + Workspace DLP + AI control center as the governance plane | Microsoft Purview retained for legacy holds until legal sunset |
| **AI enablement** | Gemini Enterprise + agentic workflows governed by the AI control center | N/A (net-new capability) |

These five domains sit on a **shared foundation**: the identity source of truth, the organizational
unit (OU) and group model, DNS/mail-flow control, and change control. Every domain design must trace
back to that foundation — this is the **GWARCH-Foundation** principle set (see below).

## How the workstreams fit together

The transformation runs many parallel workstreams (mail, calendar, Drive, Chat, identity, governance,
AI, endpoint/Chrome). Left uncoordinated they drift. The blueprint binds them with three integration
contracts:

1. **Identity contract.** Every domain consumes users and groups from **one** provisioning pipeline
   (see the *Identity integration* domain). No workstream provisions its own shadow identities. This
   is the **GWARCH-ID-1** principle: *one authoritative identity source, one provisioning path.*
2. **OU/group targeting contract.** Every policy (DLP, sharing, Gemini access, retention) is applied
   to the **same** named OU/group taxonomy — the **GWARCH-Scope** model — so scope is consistent and
   auditable across domains. `GWARCH-Set-ScopeTargeting.ps1` operationalizes this on the source side.
3. **Governance contract.** Every domain exposes its policy surface to the governance plane (Vault,
   DLP, AI control center) rather than governing itself in isolation. This is **GWARCH-GOV-1**:
   *governance is a shared plane, not a per-app setting.*

## Enterprise architecture principles (the constraints on every design)

These principles constrain all five domains. Each is named so downstream designs and ADRs can cite it.

- **GWARCH-P1 — One end-state, owned centrally.** There is a single approved target architecture;
  partner/wave designs conform to it or raise an ARB exception. No workstream defines its own end
  state.
- **GWARCH-P2 — Identity is the spine.** Collaboration, content, governance, and AI all resolve
  access through one authoritative identity and one provisioning pipeline (GWARCH-ID-1). Identity
  decisions are made first and constrain everything else.
- **GWARCH-P3 — Govern by scope, not by exception.** Policy is applied to the named OU/group
  taxonomy (GWARCH-Scope), never to ad-hoc individuals. New capabilities inherit governance by
  landing in the right scope.
- **GWARCH-P4 — Least standing access; sharing is a decision, not a default.** External sharing,
  broad admin roles, and AI data access are closed by default and opened per scope with justification.
- **GWARCH-P5 — Coexistence is bounded and temporary.** Every M365↔Google coexistence bridge (mail
  routing, directory, holds) has a defined sunset condition. Nothing "temporary" becomes permanent
  without an ARB decision.
- **GWARCH-P6 — Data governance precedes AI enablement.** Gemini/agent access to Workspace data is
  only enabled where DLP, sharing, and retention controls for that data class are already in place
  (GWARCH-GOV-1). AI does not outrun governance.
- **GWARCH-P7 — Avoid one-way lock-in where reversible costs little.** Prefer open, exportable data
  formats and portable identity patterns so a future change of tooling touches integration layers,
  not the whole estate.
- **GWARCH-P8 — Non-functional requirements are first-class.** Availability, scale (150k users),
  supportability, security, and compliance NFRs are stated per domain and validated at conformance
  gates, not assumed.
- **GWARCH-P9 — Assess → Configure → Pilot → Validate → Expand.** Every domain change follows this
  model with explicit pass/fail gates and a documented rollback for production-affecting changes.

## Deployment / decision model

The blueprint itself is delivered and kept authoritative through the same lifecycle the workstreams
use:

**Assess** current-state (source M365/Entra discovery via `GWARCH-Discovery.ps1`) →
**Configure** the target architecture (principles, domain patterns, ADRs, NFRs) →
**Pilot** the architecture against one wave/OU and validate conformance
(`GWARCH-Validation.ps1`) → **Validate** coverage and close gaps (`GWARCH-Report.ps1`,
`GWARCH-Remediation.ps1`) → **Expand** the approved architecture to all waves under ARB control.

## Who uses this

Chief/enterprise architect and the ARB (own and enforce it); workstream leads (design to it);
security, legal/eDiscovery, and data-governance stakeholders (validate their controls are expressed
in it); program leadership (measure wave readiness against it). Audience is **senior**: the document
assumes fluency in identity, collaboration, and governance concepts and is decision-oriented, not
tutorial.

## What you get

The `source/` docs (overview, requirements, the architecture-definition method, conformance testing,
troubleshooting, best practices, deliverables, executive summary), five source-side PowerShell scripts
(discovery, validation, coverage/gap report, remediation guidance, scope targeting), and a
**Target-Architecture document template outline** (`08-deliverables-summary.md`) you populate to
produce the authoritative artifact your program governs against.
