# Best Practices

Durable practices for retiring a Microsoft 365 tenant cleanly and auditably after a move to Google.

## Sequence and gates

- **Never tear down before completeness passes.** The single most common way to lose data is to start
  disposition or closure while a subset of users still depend on Microsoft 365. Gate 1 is a hard stop.
- **One direction, gated.** Completeness → disposition → licensing → identity → DNS → closure. Each
  gate produces evidence; a later phase never starts until the prior gate is green.
- **Closure is last and irreversible.** Everything reversible (disable before delete, re-assign a
  license, restore a zone) happens before the tenant enters Microsoft's deletion window. Treat the
  grace period as your final safety margin, not a rollback plan.

## Safe-by-default automation

- **Read-only or `--dry-run` until `--apply`.** All five tools default to no-change mode. Review the
  plan, get sign-off, then apply — pilot scope first.
- **Least privilege for verification.** The tooling app (`Decommission Read – Source-Tenant – v1`)
  holds **read** scopes only. Write actions use just-in-time admin roles (R6), removed after the
  change window.
- **No secrets in code or repo.** Tenant/client IDs and the client secret come from the environment
  (R3). The tools refuse to run if the variables are absent — never hardcode, never print, never
  commit credentials or exported service-account/app keys.

## Data & legal discipline

- **Legal/records owns the determination; you own the method and the evidence.** Inventory and export
  are technical; HOLD/RETAIN/DISPOSE is a legal decision. Get disposition sign-off in writing before
  any deletion.
- **Disable before delete.** For ambiguous identities and apps, disable and soak through the rollback
  window before removal — a reversible step that catches "actually, that was still in use".
- **Preserve first, dispose second.** Export everything under hold/retention to the governed evidence
  store *before* any DISPOSE action; record item, size, and hash so the export is verifiable.

## Identity & app hygiene

- **Enumerate standing secrets.** Migrations leave app registrations with long-lived secrets/certs and
  orphaned service principals — prime attack surface. Inventory them explicitly and remove what the
  Google move made obsolete.
- **Kill the tooling app last.** The read app is the final object removed, after it has produced the
  closure evidence.

## DNS & integration

- **Snapshot every zone before you touch it.** A pre-change export of the zone is your rollback for
  mail-flow records. Never edit MX/SPF/DKIM/DMARC blind.
- **One zone at a time, under change control.** Mail-flow records are high-impact; change one domain,
  validate externally (`dig`, a test message), then move on.
- **Re-point survivors to Google explicitly.** Confirm the Google target records (MX, SPF include,
  DKIM selector) in the Google Admin console before removing the Microsoft equivalents.

## Evidence & auditability

- **Every gate leaves a file.** JSON/CSV inventories per phase, plus the final HTML closure report,
  archived in `Decommission Evidence – Source-Tenant – v1` with retention at least as long as the
  longest applicable obligation.
- **Name artifacts consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention and reuse the
  exact names across steps, scripts, and evidence — an auditor should be able to follow one thread.

## Vendor-accuracy discipline

- **Flag version/preview-dependent mechanics.** Microsoft's tenant-deletion prerequisites, Purview
  eDiscovery export navigation, and domain-removal rules change; where this matters, verify in your
  tenant rather than trusting a remembered path. Google-side re-point targets are confirmed in the
  Google Admin console at the time of change.
