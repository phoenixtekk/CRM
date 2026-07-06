# 2. Requirements Guide — Gemini Connector Strategy & Agent Development Framework

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`. Objects are
named `<Purpose> – <Scope> – <Stage>` and reused verbatim across steps, scripts, and tests.

> **Preview note.** Gemini Enterprise (formerly Agentspace) and the Agent Platform (formerly Vertex AI
> Agent Builder) are rolling out. Where a requirement names a specific role, API, or console area it is
> **cited**; confirm each in your tenant and the
> [release notes](https://docs.cloud.google.com/gemini/enterprise/docs/release-notes) — **verify in your
> tenant** before relying on it.

## 2.1 Gemini Enterprise provisioned on a Google Cloud project
**Description:** Gemini Enterprise enabled on a Google Cloud **project** with the required edition/
licensing and the **Discovery Engine API** enabled.
**Why:** Connectors (data stores) and agents live under this project; every approval, boundary, and
framework control is scoped to it.
**Verify:** `console.cloud.google.com` → confirm Gemini Enterprise is enabled and the Discovery Engine
API is on; run `GEMCONN-Discovery.ps1 -ProjectId 'your-project-id'`.
**Implement-if-missing:** Provision Gemini Enterprise and licenses through Google or a reseller; enable
the Discovery Engine API on the project. (Edition specifics — Standard/Plus, data residency — are
**verify-in-tenant**.)

## 2.2 Gemini Enterprise administrative rights
**Description:** An operating account with the Gemini Enterprise admin role
(`roles/discoveryengine.agentspaceAdmin`) or equivalent, plus at least
`roles/discoveryengine.viewer` for the read-only scripts
([IAM roles](https://docs.cloud.google.com/gemini/enterprise/docs/access-control)).
**Why:** Approving/configuring connectors and governing agents requires admin rights; the discovery/
validation/report scripts require read access.
**Verify:** Project **IAM & Admin** shows the `discoveryengine.*` bindings; `GEMCONN-Set-ScopeTargeting.ps1`
lists them.
**Implement-if-missing:** Grant the least-privilege `discoveryengine.*` role at the narrowest scope; role
names/availability are **verify-in-tenant**.

## 2.3 An identity provider and identity mapping
**Description:** A configured **identity provider** and, for external identities, **identity mapping /
Workforce Identity Federation**, so Gemini can resolve *who* is asking and honor source ACLs
([Configure identity provider](https://cloud.google.com/agentspace/docs/configure-identity-provider)).
**Why:** Data-access boundaries depend on Gemini resolving the authenticated principal and matching it
to each source's ACLs — "respect source permissions" only works with identity resolved.
**Verify:** Confirm the identity provider is configured and external identities map correctly.
**Implement-if-missing:** Configure the identity provider and identity mapping before connecting any
sensitive source.

## 2.4 A data-governance baseline and data-classification scheme
**Description:** An existing data-governance baseline (source ACLs, DLP, retention) and a **classification
scheme** (e.g. public / internal / confidential / restricted) to tag each connector against.
**Why:** Connector approval criteria are meaningless without a classification to approve *against*; the
boundary respects source ACLs, so those ACLs must be correct.
**Verify:** A written classification scheme exists and the source systems' ACLs are trusted.
**Implement-if-missing:** Establish the classification scheme and remediate source over-sharing before
connecting a source to Gemini.

## 2.5 A data-access boundary decision (VPC Service Controls / IAM / residency)
**Description:** A decision on the **boundary** around Gemini: whether a **VPC Service Controls**
perimeter applies, which **IAM** roles bound access, **VPC firewall** egress limits, and any **data-
residency** requirement ([security overview](https://docs.cloud.google.com/gemini/enterprise/docs/security-overview)).
**Why:** The boundary is what stops a connected source or agent from reaching further than approved.
**Verify:** `GEMCONN-Validation.ps1` reports whether a perimeter and org policies are present.
**Implement-if-missing:** Define/confirm a VPC Service Controls perimeter covering the project, set IAM
to least privilege, and record the residency requirement. (Perimeter/residency specifics are
**verify-in-tenant**.)

## 2.6 The agent-development framework tooling (Agent Platform)
**Description:** Access to the agent build/run/govern tooling in scope — **Agent Designer** and/or
**ADK + Agent Engine**, and the governance components (**Agent Registry, Agent Identity, Agent Gateway,
Agent Security Dashboard, Agent Sandbox**) where available
([Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)).
**Why:** The framework's design/review/deploy/monitor stages assume the registry, identity, gateway, and
observability exist; which are enabled shapes how much of the framework is enforced by the platform vs
by process.
**Verify:** Confirm in the console which Agent Platform components are available on the project.
**Implement-if-missing:** Enable the available components; for any not yet GA, enforce the equivalent
control by process and flag it **verify-in-tenant**.

## 2.7 Change control, pilot scope, and rollback
**Description:** An approved change window, a named **pilot project/scope** (one connector + one agent),
and a documented rollback before connecting a production source or exposing an agent
(per `global-requirements-google.md` §5).
**Why:** Connecting a source or publishing an agent can over-expose data; the pilot limits blast radius
and the rollback is the safety net.
**Verify:** An approved change record, the pilot scope, and a written back-out exist.
**Implement-if-missing:** Capture the current state (`GEMCONN-Report.ps1 -SaveBaseline`), define the
pilot, and write the rollback (disable the connector / unpublish the agent).

---
## Checklist
- [ ] Gemini Enterprise on a project + Discovery Engine API — `GEMCONN-Discovery.ps1`
- [ ] Gemini Enterprise admin role (+ viewer for scripts) — `GEMCONN-Set-ScopeTargeting.ps1`
- [ ] Identity provider + identity mapping configured
- [ ] Data-governance baseline + classification scheme
- [ ] Data-access boundary decision (VPC Service Controls / IAM / residency) — `GEMCONN-Validation.ps1`
- [ ] Agent Platform tooling available (Designer / ADK / registry / gateway)
- [ ] Change window, pilot scope, and rollback documented
