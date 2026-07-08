# 7. Best Practices — Insider Risk Readiness Assessment (Microsoft Purview)

Field-tested practices for getting IRM **ready** responsibly — privacy first, roles strictly separated,
signal prepared, scope minimal — so that when the organization does deploy, the capability is defensible to
employees, privacy officers, works councils, and auditors. These complement the Implementation and Testing
guides. The governing principle: **prepare the capability; defer every outcome to HR, privacy, and legal.**

## Privacy-by-design is the deployment — do it first
- **Turn anonymization ON before anyone sees signal.** Analysts should triage **pseudonymized** identities by
  default; de-anonymization is an **Investigator** action inside an authorized case, not a triage default.
  Configure it before granting any access.
- **Collect the minimum.** Enable only the **indicators** the intended template needs — not the full catalog.
  Data minimization is a privacy control, and fewer indicators mean fewer false signals and a smaller
  footprint to defend.
- **Consult before you monitor.** Where employment/privacy law or a works council requires **consultation or
  notice** before monitoring, that happens *first* — it is a legal prerequisite, not a formality. This
  assessment prepares the technical capability; the lawfulness of monitoring is legal's determination.

## Separate the roles — ruthlessly
- **Four different people:** **Admins** (configure), **Analysts** (triage on pseudonymized data),
  **Investigators** (case content, forensic evidence, de-anonymization), **Auditors** (audit the others).
  Collapsing them is the classic governance failure.
- **Almost no one holds the super-group.** The all-powerful **Insider Risk Management** role group should be
  break-glass only.
- **HR and Legal are reviewers, not Investigators.** They receive escalations and make the employment/legal
  call; giving them the de-anonymizing Investigator role by default breaks separation and privacy. Keep IRM
  operations separate from the functions that act on its outputs.
- **Audit the auditors.** The Auditor role exists so IRM activity itself is reviewable — use it.

## Start in the least-exposing mode — Analytics before policy
- **Run Insider Risk Analytics first.** It returns **aggregated, anonymized** insight into potential risk
  **without a policy and without naming anyone** — the lowest-exposure way to confirm IRM has signal worth
  acting on. Only after reviewing analytics do you scope a named-user policy.
- **First policy is disabled or minimal, and narrowly scoped** to a **priority-user group** you control —
  never tenant-wide from an assessment. Prove the wiring, then let HR/privacy/legal own expansion.
- **Prefer aggregated evidence** for stakeholder conversations. The readiness scorecard is **counts and gate
  status**, not names — most decisions can be made without exposing an identity.

## Get the connectors right (signal without over-collection)
- **Match connectors to the template.** *Data theft by departing users* needs the **HR connector** (or the
  Entra account-deletion signal); security-violation indicators need **Defender for Endpoint** integration. A
  policy with no connected signal is inert — and a connector with no policy behind it is needless collection.
- **Confirm audit logging is on** — it is the correlation substrate; IRM has little to work with without it.
- **Health-check imports.** An HR connector that silently stopped importing degrades the departing-user signal
  without warning — check last-import status on a cadence.

## Be honest about what is scriptable
- **IRM is largely portal-configured.** Use the delivered scripts for what they reliably report — **role
  groups & separation, audit-log state, licensing signal, the backing scope group** — and use the **Purview
  portal** for analytics, connector health, pseudonymization, and policy/priority configuration. **Do not
  trust an invented cmdlet** for a portal-only step.
- **Verify licensing/tenant** before relying on any IRM capability or template — plans and portal paths
  evolve and some features are in preview; don't assume a template or the analytics scan exists in your
  tenant.

## Keep the scaffold non-operational until the decision is made
- **Nothing runs against an individual during readiness.** The policy stays disabled/minimal, the scope group
  holds test accounts, reporting is pseudonymized. Readiness is proving the capability, not using it.
- **Rollback is trivial because nothing is operating.** Delete/disable the readiness policy, empty the scope
  group, revert indicators — there is no operational state to unwind. Preserve this property until HR/privacy/
  legal decide to deploy.

## Operations & governance (for when it goes live — hand these to the owners)
- Give IRM **alerts an owner and an SLA**, and keep **evidence access least-privilege** — case content can
  contain highly sensitive personal data.
- Keep a **change log** of every privacy-setting, role, connector, and scope change, with the privacy/legal
  sign-off attached.
- **Review role membership and connector health on a cadence** — separation and signal drift over time.
- Re-run **Analytics** periodically as an aggregated health check before expanding scope.

## Stay inside the boundary
- IRM **surfaces signals for human review** — it does not decide anything about a person. **Whether monitoring
  is lawful, whether to open a case, what a score means, and any disciplinary/legal action are HR/privacy/
  legal determinations.** You deliver the technical readiness and the evidence; they own the decision and the
  operation.
