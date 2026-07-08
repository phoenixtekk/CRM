# 7. Best Practices — Sensitivity & Retention Labels

Field-tested practices for building a label program that protects and governs content **without a user
revolt**. These complement the Implementation and Testing guides.

## Taxonomy design
- **Keep it short.** Five to seven top-level sensitivity labels is the practical ceiling — more and users guess or ignore. Use sublabels (parent + children) to add nuance without lengthening the top list.
- **Order by sensitivity, least → most.** Users pick from the ordered list; the order *is* the guidance. Parents used only for grouping should not themselves apply protection.
- **Write plain-language tooltips.** The tooltip is the only in-context help a user gets. "Confidential — share only with named colleagues; do not send outside the company" beats a policy code.
- **Design the taxonomy once, with governance owners.** Renaming or reordering labels after publish is disruptive (existing content keeps the old label). Get the taxonomy signed off before creating labels.

## Protection (encryption & marking)
- **Encrypt deliberately.** Encryption travels with the file and is the strongest control — but it also breaks co-authoring in some paths, third-party tools, and downstream automation. Encrypt only the labels that truly need it, and always pilot first.
- **Define rights by group, not by person.** Point `EncryptionRightsDefinitions` at mail-enabled security groups so membership changes don't require editing the label.
- **Prefer marking for the lower tiers.** `Public`/`General` should mark (footer) but not encrypt — you get visible classification with zero friction.
- **Test the "unauthorized open" every time.** The only proof encryption works is that someone *outside* the rights is denied. Make that Test 3 non-negotiable.

## Auto-labeling
- **Always simulate service-side first.** Never create a service-side auto-labeling policy in Enable mode. Simulation (`TestWithoutNotifications`) scans and reports without touching content — it is the single most important safety control in this solution.
- **Measure precision, then enforce.** Review the simulation match set with the data owner and tune rule conditions (sensitive info types, instance counts, keywords, trainable classifiers) until false positives are acceptable. Enforcing a noisy policy is how you lose user trust.
- **Layer client-side and service-side.** Client-side catches content at creation in Office apps; service-side sweeps data at rest and in transit. Together they cover new and existing content.
- **Watch latency and limits.** Simulation and enforcement scan large volumes over time and are subject to throughput/item limits — **verify current limits for your tenant** and set expectations accordingly.

## Retention & adaptive scopes
- **Retention periods are records/legal's call.** Configure exactly what the accountable owner signs off; never invent a schedule or declare a record without their determination.
- **Prefer adaptive scopes over static scopes** for anything that changes — department, region, site property. Adaptive scopes re-evaluate membership automatically, so coverage doesn't drift as people and sites change.
- **Confirm the query attribute is populated** before trusting an adaptive scope (§2.7). A scope on `Department` silently misses everyone whose `Department` is blank.
- **Pilot delete actions on disposable content only.** Any retention label that deletes must be proven on throwaway test items with a controlled trigger before it goes near real records (Test 10).
- **Keep pilot → adaptive order.** Publish retention labels to a small pilot ring first, validate application and disposition, *then* bind labels to broad adaptive scopes.

## Program & change management
- **Pilot ring, always.** Publish sensitivity labels to `SL Policy – Pilot – Ring1` before `SL Policy – Broad – AllUsers`. The pilot surfaces co-authoring, marking, and encryption issues cheaply.
- **Document a rollback per policy.** Unpublish (`Remove-LabelPolicy` / `Remove-RetentionCompliancePolicy`) removes exposure without deleting labels; know the exact command before you publish.
- **Communicate before broad rollout.** Tell users what the labels mean, what changes (marking/encryption they'll see), and where to get help — the ticket flood comes from surprise, not from labels.
- **Keep least-privilege roles.** Information Protection Admin and Records Management are enough for label work; don't grant Global Admin for day-to-day label operations.
- **Re-baseline periodically.** Run `PURVLABEL-Discovery.ps1` on a cadence to catch label sprawl, orphaned policies, and auto-labeling drift.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` / `Connect-MgGraph`; never embed secrets. Store any exports securely.
- **Read-only or `-WhatIf` by default.** Every provided script defaults to no-change; writes require an explicit `-Commit`. Keep it that way.
- **Verify licensing/tenant before relying on advanced features.** Service-side auto-labeling and adaptive scopes are plan-gated and the portal evolves — flag, don't assume.
