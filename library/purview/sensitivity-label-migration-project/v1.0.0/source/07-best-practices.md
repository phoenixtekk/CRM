# 7. Best Practices — Sensitivity Label Migration Project

Field-tested practices for migrating a legacy/third-party classification estate onto Microsoft Purview
sensitivity labels **without mislabeling content or surprising users**. These complement the
Implementation and Testing guides.

## Mapping design
- **One target label per legacy value.** Keep the matrix unambiguous — each legacy value resolves to
  exactly one Purview label. Collapsing several legacy values to one label is fine; a value with two
  possible targets is a decision to make **before** configuring, not a coin flip at enforcement.
- **Map to an existing, published label — never invent a target.** The destination taxonomy is a
  separate build. If a legacy value has no clean home, that is a finding for the label owner (extend the
  taxonomy, or scope the value out), not a new label improvised inside the migration.
- **Name every unmapped value as an owner decision.** Silent gaps are how legacy content stays
  ungoverned. The matrix must show *why* a value is unmapped and *who* owns the decision.
- **Record the protection intent explicitly.** Whether the mapped label encrypts — and whether that
  reproduces protection the legacy tool applied — is a records/security determination. Capture it in the
  matrix; don't let encryption "come along for free" unexamined.

## Detection (the real risk)
- **Prove detectability per value before you trust it.** What the source tool wrote — extractable
  content, indexable metadata, an email header, or an opaque blob — determines whether Purview can match
  it. Confirm on a sample per value; verify the exact property/header names for your specific source
  tool, never assume.
- **Prefer specific detections over broad ones.** A tight regex/keyword that matches the exact legacy
  marking string beats a loose one that also catches unrelated content. False positives here mean
  **mislabeled** content.
- **Escalate the undetectable, don't fudge it.** If Purview can't reliably see a marking, re-stamp it at
  the source tool into a detectable form, plan manual re-labeling for that subset, or scope it out with
  sign-off — never enforce a detection you know is unreliable.

## Simulation & precision
- **Always simulate the reclassification first.** Never create a reclassification auto-labeling policy in
  Enable mode. Simulation (`TestWithoutNotifications`) scans and reports **without labeling** — it is the
  single most important safety control in this migration.
- **Measure precision with the data owner, then enforce.** Sample simulation matches for false positives
  and estimate false negatives against the legacy inventory. Enforcing a noisy detection reclassifies
  content wrongly — and if the label encrypts, that's surprise encryption at scale.
- **Watch scan latency and limits.** Service-side scanning processes large volumes over time and is
  subject to throughput/item limits — **verify current limits for your tenant** and set expectations;
  "no matches yet" is often "still scanning," not "nothing to find."

## Enforcement & protection
- **Enforce encrypting mappings last and smallest.** Applying an encrypting label to existing content is
  the highest-blast-radius action in the project. Pilot it on a tiny, disposable-safe set first, prove
  the unauthorized-open test, and only then widen.
- **Expand location-by-location.** Widen each reclassification policy's scope in waves, re-simulating
  where a new location introduces new content patterns. A tenant-wide flip skips the cheap place to catch
  a mapping error.
- **Keep a return-to-simulation rollback per policy.** Flipping a policy back to simulation stops further
  labeling immediately; document how already-applied labels are removed for each mapping before you
  enforce.

## Reconciliation & decommission
- **Decide the residual-marking end state up front.** Content that carries both the old legacy footer and
  the new Purview label confuses users. Agree — leave, co-exist, or clean up — before enforcement, per
  mapping.
- **Decommission the source tool on a schedule, not all at once.** Retire the legacy classifier for a
  population only after it is fully reclassified and validated; keep the source export as migration
  evidence.
- **Reclassify to one scheme, then govern from it.** The migration's payoff is that Purview controls —
  DLP, retention, Copilot protection — now key off labels the platform understands. Point those controls
  at the migrated labels once coverage is proven.

## Program & change management
- **Pilot locations, always.** Reclassify a small set of sites/mailboxes before the estate; the pilot
  surfaces detection, marking, and encryption issues cheaply.
- **Communicate before broad reclassification.** Tell users which markings are changing to which labels
  and what they'll see (new marking/encryption), and where to get help — the ticket flood comes from
  surprise.
- **Keep least-privilege roles.** Information Protection Admin (plus SIT management) is enough; don't
  grant Global Admin for migration work.
- **Re-baseline periodically.** Re-run `IPMIG-Discovery.ps1` / `IPMIG-Report.ps1` to catch new legacy
  values appearing (a source tool still in use) and to track coverage over the migration's life.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` /
  `Connect-MgGraph`; never embed secrets. Store exports securely — a legacy classification inventory can
  itself be sensitive.
- **Read-only or `-WhatIf` by default.** Every provided script defaults to no-change; writes require an
  explicit `-Commit`, and enforcement requires an explicit `-EnforceFromSimulation`. Keep it that way.
- **Verify licensing/tenant before relying on auto-labeling.** Service-side auto-labeling is E5-gated and
  the portal evolves — flag, don't assume.
