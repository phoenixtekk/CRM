# 7. Best Practices — Data Classification Framework & Strategy

Field-tested practices for building a classification framework that the whole organization can align
to **without a user revolt**. These complement the Implementation and Testing guides.

## Tier model design
- **Keep the tiers few.** Three to four tiers is the practical ceiling — `Public / Internal / Confidential / Restricted` covers most organizations. More tiers and users guess or ignore; the tier *count* is a usability decision, not a technical one.
- **Define each tier in plain language, with a handling rule.** "Confidential — sensitive business data or PII; encrypt and don't share externally" beats an abstract label. The tier definition is the user's only guidance at the moment of classifying.
- **One scheme, one source of truth.** The whole point of a framework is that labels, DLP, and retention all mean the same thing by tier. Resist per-team or per-workload tier variants — they reintroduce the inconsistency the framework exists to remove.
- **Design the tier model once, with governance owners.** Renaming or re-tiering after publish is disruptive (existing content keeps the old label). Get the tier model and standard signed off before creating any artifact.

## The crosswalk (the core discipline)
- **Every tier maps to exactly one label, one DLP posture, and one retention treatment.** The crosswalk table is the contract; a complete row per tier is what makes coverage provable.
- **Hunt for orphans.** A label with no retention, a DLP rule with no matching tier, a retention label no tier points to — each is a gap or a source of confusion. `CLSFRAME-Validation.ps1` exists to catch them; run it whenever the config changes.
- **Keep the live crosswalk equal to the standard.** When someone adds a policy outside the framework, the standard and the tenant drift. Re-export the live crosswalk (`CLSFRAME-Crosswalk.ps1`) on a cadence and reconcile.

## Protection & DLP
- **Encrypt only the tiers that need it.** `Public`/`Internal` should mark (footer) but not encrypt — visible classification with zero friction. Reserve encryption for `Confidential`/`Restricted`, and always pilot first.
- **Define encryption rights by group, not by person.** Point `EncryptionRightsDefinitions` at mail-enabled security groups so membership changes don't require editing the label.
- **Always build the DLP baseline in *test* mode first.** `TestWithNotifications`/`TestWithoutNotifications` reports and tips without blocking. Enforcing a noisy DLP policy is the fastest way to lose user trust — measure precision, then enforce.
- **Align DLP conditions to the tier definitions.** The Tier 2/3 DLP rule should trigger on the *same* sensitive info types that make content Tier 2/3 in the standard — otherwise DLP and the labels disagree.

## Retention (defer the determination)
- **Retention periods and records declarations are records/legal's call.** Configure exactly what the accountable owner signs off; never invent a schedule or declare a record without their determination. This framework provides the tier→retention mapping method, not the periods.
- **Pilot delete actions on disposable content only.** Any tier retention label that deletes must be proven on throwaway test items with a controlled trigger before it goes near real records.
- **The deep retention schedule is a separate engagement.** Here you establish the tier-aligned retention *labels*; the full records file plan and schedule are their own solution.

## Program & change management
- **Pilot ring, always.** Publish tier labels to `CLS Policy – Pilot – Ring1` before `CLS Policy – Broad – AllUsers`; the pilot surfaces marking, encryption, and DLP-tip issues cheaply.
- **Document a rollback per policy.** Unpublish (`Remove-LabelPolicy` / `Remove-RetentionCompliancePolicy`) or `Set-DlpCompliancePolicy -Mode Disable` removes exposure without deleting artifacts; know the exact command before you publish.
- **Communicate the scheme before rollout.** Tell users what the tiers mean, how to pick one, and where to get help — the ticket flood comes from surprise, not from tiers. The classification standard document is the communication asset.
- **Keep least-privilege roles.** Information Protection Admin, DLP Compliance Management, and Records Management cover the framework; don't grant Global Admin for day-to-day work.
- **Re-baseline periodically.** Run `CLSFRAME-Discovery.ps1` and `CLSFRAME-Validation.ps1` on a cadence to catch label sprawl, orphaned policies, and framework drift.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` / `Connect-MgGraph`; never embed secrets. Store any exports securely.
- **Read-only or `-WhatIf` by default.** Every provided script defaults to no-change; writes require an explicit `-Commit`, and the DLP baseline is created in **test** mode. Keep it that way.
- **Verify licensing/tenant before relying on advanced features.** Advanced DLP conditions, activity/content explorer coverage reporting, and auto-labeling are plan-gated and the portal evolves — flag, don't assume.
