# 7. Best Practices

Durable practices for keeping the Drive & Shared Drives estate governed as it grows.

## Architecture & taxonomy
- **Business content belongs in Shared Drives, not My Drive.** Make organization-ownership the default
  for anything a team relies on; reserve My Drive for personal, transient work. This single rule
  eliminates the orphaned-ownership problem at the source.
- **Express hierarchy as Drives + naming, not deep folders.** Shared Drives are flat by design. Keep
  the top-level domain set small and governed; encode structure in the
  `Shared Drive – <Domain> – <Team> – <Purpose>` name, and reuse that exact name in groups, reports,
  and scripts.
- **One Manager (owner) group per Drive.** Every Shared Drive has a named `grp-<function>-drive-owners@…`
  as **Manager** — never a lone individual. Ownership is a role a group holds, so it survives departures.

## Membership & least privilege
- **Add groups, never users.** Members of a Shared Drive should be Google Groups synced from the
  directory source of truth; manage people by changing group membership, so access is auditable in one
  place. The provisioner and the config helper both refuse individual-user membership.
- **Default to the lowest useful role.** Most groups are **Contributor** or **Viewer**; **Content
  manager** where a team genuinely curates structure; **Manager** only for the owner group. Grant up,
  never down.
- **Review membership on a cadence.** Run `Access Review – <Drive> – <Quarter>` from the governance
  report; remove groups that no longer need access.

## Sharing & the trust boundary
- **Restrictive by default, opened deliberately.** Set OU sharing to internal-only or allow-listed,
  curtail "Anyone with the link," and require outside-domain warnings. Open external sharing only via a
  named **target audience** / **trust rule** for a specific partner — recorded in the catalog's
  allow-list.
- **Prefer target audiences over public links.** A governed audience as the default share suggestion
  quietly steers users away from public links without blocking legitimate collaboration.
- **Let classification drive DLP, not the other way around.** Author `DLP – <Detector> – <Action>`
  rules from the approved data-classification scheme; start rules in **audit**, move to **warn**, then
  **block** once false-positives are tuned — never ship a blocking rule cold into production.

## Governance & lifecycle
- **Provision through the standard, not ad hoc.** Restrict Shared Drive creation to the service owner /
  automation, and create every Drive through the catalog + provisioner so naming and roles stay
  consistent.
- **Sweep for orphaned owners and stale Drives regularly.** Schedule `Orphaned-Owner Sweep – <Scope> –
  <Date>` and act on empty/stale-Drive flags from the governance report before they accumulate.
- **Keep the three surfaces coherent.** The catalog (design), the tenant (live config), and the
  reports (evidence) must agree; re-run the validator after every change so drift is caught early.

## Safety & operations
- **Pilot every production sharing change, and keep the rollback baseline.** Record the pre-change OU
  sharing settings before touching them; sharing tightening can break active work, so gate it and be
  ready to revert.
- **Run the tools read-only first.** Every write tool defaults to dry-run/`--apply`-gated; review the
  planned actions before applying, and keep the before-state lines for rollback.
- **No secrets in code or repo.** The tools authenticate via OAuth/ADC or a delegated service account
  resolved at runtime; never commit keys, exported credentials, or tokens.
