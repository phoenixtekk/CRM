# 7. Best Practices

Durable practices for keeping Google Groups governed as the estate grows. These outlast the initial
rollout — treat them as the steady-state operating standard.

## Model & typing
- **Type every group; type drives everything.** Never create a group without deciding its type
  (Distribution / Security / Collaboration / Dynamic / External). The type sets the default settings,
  the review cadence, and whether external members are even allowed. An untyped group is an ungoverned
  group.
- **The name is the contract.** Enforce `<Type> – <Scope> – <Purpose>` and the email prefix at
  **creation** (via the intake), not after the fact. A machine-readable name lets the validator gate the
  whole estate cheaply — the naming standard is what makes governance auditable rather than aspirational.
- **Security label anything that grants access.** If a group is ever added to a Shared Drive, calendar,
  IAM binding, target audience, or SSO app, make it a **Cloud Identity security group**. The immutable
  label stops it being silently repurposed and is a prerequisite for IAM use.

## Ownership & membership
- **Never a single owner; prefer an owner *group*.** Require **≥2 owners**, and make the `OWNER` a group
  (`sec-groups-owners@…`) rather than named individuals so ownership survives departures. Orphaned
  groups are the most common and most dangerous defect — the hygiene sweep must catch them continuously.
- **Membership by group, not by person.** Nest groups instead of maintaining long individual-member
  lists. Access then lives in one auditable place and follows the directory source of truth.
- **Prefer dynamic membership where an attribute fits.** For department/location/cost-centre-shaped
  groups, a dynamic group eliminates the "forgot to remove them" error class — but only after confirming
  the source attribute is trustworthy (Requirement 2.4). A dynamic group over bad attributes is worse
  than a static one.

## Exposure & trust boundary
- **Restrictive by default, opened deliberately.** Keep the org-wide baseline closed (creation
  restricted, external members off, inbound external posting restricted) and open exposure only
  per-group on explicitly `ext-` groups with allow-listed partner domains.
- **Treat "external members" and "public settings" as findings, not features.** Any external member on a
  non-`ext-` group, any world-readable archive, or any open posting outside policy is a defect the
  checker flags and an owner must justify or fix.
- **Access groups don't accept mail.** Security/access groups should post `NONE_CAN_POST` — if an access
  principal is also an open mailing list, that is over-permissioning waiting to be abused.

## Lifecycle & hygiene
- **Route all creation through the intake.** Uncontrolled self-service group creation is the source of
  sprawl; restrict creation and make the request → approve path the only way in, enforcing type/naming/
  owner/external at the door.
- **Review on a cadence proportional to risk.** Security and external groups reviewed quarterly;
  distribution and dynamic groups annually. Owner attestation on the generated review report is the
  evidence.
- **Retire in stages, never in one destructive step.** Suspend (stop posting / remove from access) →
  hold for a rollback window → delete. Deleting a group that still routes mail or grants access breaks
  both silently.
- **Sweep continuously, not just at rollout.** Schedule the hygiene assessment so orphaned/stale/
  external-exposed/over-permissioned groups surface between reviews, not only during them.

## Automation & change safety
- **Read-only first, dry-run always.** Run assessments and validators freely; run any write helper in
  dry-run and inspect the diff before `--apply`, and only `--apply` inside a change window.
- **No secrets in code, least-privilege scopes.** Auth via ADC or a delegated service account; grant the
  read-only scopes broadly and the write scopes only to the identity that runs `--apply`. Never commit a
  key file.
- **Gate expansion on the pilot.** Do not roll a change past the pilot scope until the naming/type
  validator and external/policy checker both PASS and the review report is attested — one scope at a
  time, never a big-bang across the estate.
