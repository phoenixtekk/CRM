# Best Practices

Durable practices for running Google Workspace day-2 operations. These outlast any single change and
should govern how the operations team works from go-live onward.

## OU tree and policy governance

- **Keep the OU tree shallow and purpose-driven.** Model *policy differences*, not the HR org chart.
  Every OU should exist because a population needs a different setting; if two OUs have identical
  policy, merge them.
- **Prefer inheritance; override deliberately.** Set the safe default at a parent and inherit down.
  Every override is a maintenance liability — document *why* each override exists in the baseline.
- **Treat the settings baseline as code.** `ou-policy-baseline.json` is the source of truth for
  intended configuration. Change it only through change control, keep it in version control, and let
  the drift detector enforce that live == baseline.
- **Use configuration groups only where policy must follow membership,** not OU placement — and
  **verify group-based policy targeting for that service in your tenant** before relying on it.

## Least-privilege administration

- **Super-admin is break-glass, not a job title.** Keep the count minimal, use dedicated break-glass
  accounts with strong 2SV, and never do routine work as super-admin.
- **Scope custom roles to OUs** wherever the privilege supports it, so help desk touches only its
  population.
- **Re-audit roles on a schedule.** Run the admin-role auditor monthly; every new super-admin or
  root-scoped role should be a deliberate, logged decision.
- **Offboard admin rights first.** When an operator leaves, remove role assignments before anything
  else, and confirm with the auditor.

## Monitoring, alerting, and health

- **Monitor the security-relevant few, not everything.** Suspicious logins, admin-privilege changes,
  external-sharing spikes, and OAuth grants catch most real problems; alert fatigue kills the rest.
- **Route alerts to a group, not a person,** so coverage survives PTO and turnover.
- **Run the health check on a cadence and keep the output.** A dated health report is both an
  early-warning signal and audit evidence.
- **Mind log retention.** Know your edition's audit-log retention windows; if compliance needs longer,
  export logs (e.g. to BigQuery) — **verify the current mechanism and windows for your edition.**

## Runbooks and change control

- **Every routine task is a named runbook.** If it is done more than twice, it gets a
  `Runbook – <task> – Production`. Runbooks are the antidote to key-person risk.
- **Dry-run destructive operations by default.** Offboarding, device wipes, and bulk changes should
  print what they *would* do before they do it — the tooling defaults to `--dry-run` for this reason.
- **Change control for anything that touches mail flow, sharing, identity, or security policy.** These
  are high-impact; require approval, a change window, and a documented rollback.
- **Exercise incident runbooks before you need them.** Run a tabletop for account compromise and data
  exposure so the first real incident is not the first rehearsal.

## Tooling and credentials

- **Read-only by default.** Assessment, validation, health, and drift tooling should never need write
  access. Grant the Python tools **only** read-only Directory/Reports/Groups scopes.
- **No secrets in code, ever.** Use OAuth / ADC / a secured service-account credential supplied at
  runtime. Never commit keys; never paste credentials into a runbook.
- **Version the baseline and the reports.** Store the baseline, drift reports, role audits, and health
  reports in an access-controlled, durable evidence store (R6).

## Compliance posture

- **Provide evidence, defer determinations.** The operations practice produces the technical control
  configuration, monitoring, and evidence. Whether that satisfies CMMC/NIST 800-171/ITAR/DFARS is a
  determination for your compliance, legal, and assessor (C3PAO) partners — do not assert
  certification from the technical side.
