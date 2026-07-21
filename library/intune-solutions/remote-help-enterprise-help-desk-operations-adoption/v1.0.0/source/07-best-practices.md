# 7. Best Practices — Remote Help Operations & Adoption

## Role & scope design
- **One role per tier, one capability per tier.** Keep `RHELP Role – Tier 1 View` view-only, reserve
  full control for `RHELP Role – Tier 2 Control`, and elevation for `RHELP Role – Tier 3 Elevation`.
  Never blur capabilities across tiers.
- **Scope is the "who," role is the "what."** Use scope groups (`RHELP-Scope-Standard-Users`,
  `RHELP-Scope-VIP-Users`) to limit who each tier can help; use the role to limit what they can do.
- **Keep scope groups Assigned, not Dynamic.** An agent's reach should widen only by a deliberate,
  auditable change — never automatically.
- **Route VIP/executive support to a dedicated tier.** Handle `RHELP-Scope-VIP-Users` at Tier 3 so
  sensitive users get consistent, senior handling.

## Unattended access
- **Treat unattended as an exception, not a default.** Grant it to **Tier 3 only** and only for
  devices in `RHELP-Scope-Unattended-Devices`.
- **Require a change/ticket for every unattended session** and flag it as unattended in reporting.
- **Review the unattended device scope on a cadence** (for example monthly) and remove devices that
  no longer need it.
- **Verify the capability before you rely on it.** Whether Remote Help offers unattended access, on
  which platforms, and how consent behaves must be confirmed against current Microsoft documentation.

## Workflow & escalation
- **Every session starts from a ticket** — no ad-hoc help. It is the record, the scope, and the KPI
  source.
- **Verify the caller before connecting**, every time.
- **Escalate the ticket, never exceed the role.** When a case is beyond a tier, the ticket moves to
  the tier that is authorized — the agent does not.
- **Log the session on the ticket on completion** (time, attended/unattended, actions, outcome).

## Measurement & adoption
- **Define KPIs up front** and report them on a fixed cadence with `RHELPOPS-Report.ps1`.
- **Combine platform usage with ITSM data** — outcome and adoption KPIs need both.
- **Give end users one request path** and set consent/audit expectations plainly so they trust it.
- **Enable agents on scope, capability, escalation, and logging** — adoption fails when agents are
  unsure what they may do.
- **Iterate the comms where uptake is low** — a downward escalation rate and a rising adoption rate
  mean the model is working.

## Hygiene
- **Document the role/scope model** (which tier, which role, which scope) for audits.
- **Re-validate each wave** with `RHELPOPS-Validate.ps1` and `RHELPOPS-Test-Scope.ps1`.
- **Confirm current portal labels and role/permission names** against Microsoft documentation before
  each major change — they drift.
