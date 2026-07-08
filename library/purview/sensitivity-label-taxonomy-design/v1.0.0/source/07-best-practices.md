# 7. Best Practices — Sensitivity Label Taxonomy Design

Field-tested practices for designing a label taxonomy users will **actually use** — and for building it
so it doesn't have to be rebuilt. These complement the Implementation and Testing guides.

## Taxonomy structure
- **Keep it short.** Three to five top-level tiers is the practical ceiling — more and users guess or
  ignore them. Use **sublabels** (parent + children) to add nuance without lengthening the top list.
- **Order by sensitivity, least → most.** Users pick from the ordered list; the order *is* the guidance.
  Set Priority deliberately and never leave ordering to chance.
- **Parents group only — never protect, never select.** A parent (`Confidential`, `Highly
  Confidential`) exists to group its sublabels. Give it no encryption/marking and keep it
  non-selectable; the user always picks a specific sublabel with a defined handling.
- **Design once, with governance owners.** Renaming or reordering after publish is disruptive (existing
  content keeps the old label, users get confused). Get the taxonomy and protection mapping **signed off
  before** creating any label (§2.7).

## Naming convention
- **Separate display names from internal names.** Display names are for users and can be tuned; internal
  `Name` values are immutable identifiers cmdlets and policies bind to — **never rename or reuse** an
  internal name. Follow one convention (`SL-<Tier>[-<Audience>]`) so the set stays legible as it grows.
- **Name sublabels by audience/handling, not by repeating the tier.** `Confidential \ Trusted People`
  tells the user *who* it's for; `Confidential \ Confidential-2` tells them nothing.
- **Write plain-language tooltips.** The tooltip is the only in-context help a user gets. "Confidential —
  share only with named colleagues; do not send outside the company" beats a policy code.
- **Retire, don't rename.** If a name is wrong, create the correct label and retire the wrong one — a
  rename ripples through everything already stamped or bound to that name.

## Protection / marking mapping
- **Map protection explicitly, per label.** A taxonomy isn't done until every selectable label has a
  recorded decision: encrypt (yes/no), rights group + usage-rights level, and header/footer/watermark.
  The mapping is what turns a list of names into an enforceable design.
- **Encrypt deliberately.** Encryption travels with the file and is the strongest control — but it also
  breaks co-authoring in some paths, third-party tools, and downstream automation. Encrypt only the
  tiers that truly need it, and always pilot first.
- **Prefer marking for the lower tiers.** `Public`/`Internal` should mark (footer) but not encrypt — you
  get visible classification with zero friction and no support load.
- **Define rights by group, not by person.** Point `EncryptionRightsDefinitions` at mail-enabled
  security groups so membership changes don't require editing the label.
- **Test the "unauthorized open" every time.** The only proof encryption works is that someone *outside*
  the rights is denied. Make that Test 4 non-negotiable before broad publish.

## Piloting & rollout
- **Pilot ring, always.** Publish to `SL Policy - Pilot - Ring1` before `SL Policy - Broad - AllUsers`.
  The pilot surfaces marking, co-authoring, and encryption issues cheaply, on a small group.
- **Document a rollback per policy.** `Remove-LabelPolicy "<name>"` unpublishes without deleting the
  labels — know the exact command before you publish. Removing a **policy** never deletes the underlying
  **labels**, so rollback is low-risk and reversible.
- **Communicate before broad rollout.** Tell users what the labels mean, what changes (marking/
  encryption they'll see), and where to get help — surprise, not labels, generates tickets.
- **Publish selectable labels only.** Exclude parents from the policy's applicable set so users can't
  pick a bare grouping label.

## Keeping the taxonomy healthy over time
- **Re-baseline periodically.** Run `IPTAX-Discovery.ps1` on a cadence to catch label sprawl, orphaned
  policies, ad-hoc labels that break the naming convention, and drift from the design sheet.
- **Report conformance.** `IPTAX-Reporting.ps1` exports the taxonomy + protection mapping and flags any
  label that doesn't conform to the naming convention — use it as the living record of the design.
- **Change under control.** Any addition to the taxonomy goes through the same design → sign-off →
  `-WhatIf` → pilot → validate flow; don't hand-edit labels in the portal outside change control.
- **Keep least-privilege roles.** **Information Protection Admin** is enough for taxonomy work; don't
  grant Global Admin for day-to-day label operations.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` /
  `Connect-MgGraph`; never embed secrets. Store any exports securely.
- **Read-only or `-WhatIf` by default.** Every provided script defaults to no-change; writes require an
  explicit `-Commit`. Keep it that way.
- **Placeholders are placeholders.** The sample tier names, rights groups (`contoso.com`), and tooltips
  are starting points — replace every one with your signed-off values before committing.
- **Verify licensing/tenant.** Sensitivity labeling and label-based encryption are broadly licensed, but
  the portal evolves and some behaviors are plan-gated — flag, don't assume.
