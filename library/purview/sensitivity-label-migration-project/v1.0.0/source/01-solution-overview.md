# 1. Solution Overview — Sensitivity Label Migration Project (Microsoft Purview)

## What this solution is
Many organizations classified their content **before** Microsoft Purview — with an on-premises or
third-party classification tool that stamped a marking on every document and email, or with an older
Microsoft labeling client. Those legacy markings are **not** Microsoft Purview sensitivity labels: they
don't drive Purview encryption, DLP, retention, or Copilot data protection, and they leave the estate
in two classification schemes at once. Left unaddressed, that is both a **compliance gap** (governance
keyed off labels that Purview doesn't understand) and a **data-risk exposure** (content the new
controls can't see). This solution **maps** every legacy/third-party classification to a target
Microsoft Purview **sensitivity label** and **reclassifies** the content onto those labels — with the
reclassification **piloted in simulation first**, validated for precision, and only then enforced.

- **Inventory both sides:** the **legacy classification values** the source tool wrote (exported from
  that tool), and the **target Purview estate** — existing sensitivity labels, label policies,
  auto-labeling policies, and sensitive information types.
- Build a **mapping matrix**: every distinct legacy classification value → exactly one target Purview
  sensitivity label, with unmapped values flagged as explicit owner decisions.
- Build the **detection** for each legacy value — a **sensitive information type (SIT)** or content/
  metadata condition Purview can match on — and an **auto-labeling policy** that applies the mapped
  target label wherever that detection fires.
- **Pilot the reclassification in simulation** (the auto-labeling policy scans and reports **without
  labeling anything**), measure precision against the mapping, then **enforce from simulation** to
  reclassify.
- Validate coverage and precision against pass/fail gates, then **expand** location-by-location.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling on
the target side.

> **This is a migration onto an existing target taxonomy — not a taxonomy build.** It assumes the
> **destination** Microsoft Purview sensitivity labels already exist (or are being built by the separate
> labels-implementation solution). Designing the label taxonomy, authoring DLP, and standing up
> retention are separate Purview solutions; where this guide reaches their edge it points to them
> rather than duplicating them.

## Why this matters
- **Two classification schemes is a governance gap.** While content carries a legacy marking that
  Purview can't read, none of Purview's controls — encryption, DLP, retention, Copilot protection —
  apply to it. The point of the migration is to collapse to **one** scheme that the platform actually
  enforces.
- **Legacy markings don't convert themselves.** There is **no supported cmdlet that turns a
  third-party classification value into a Purview label.** Each legacy value must be *detected* and
  *reclassified* onto its mapped label. This solution treats the **mapping matrix** and its **detection
  precision** as the deliverables, not an afterthought.
- **Reclassification is high-impact.** Applying a Purview label — especially an **encrypting** one — to
  a large body of existing content changes how every one of those files is protected. Doing it in
  **simulation first**, measuring false positives, and enforcing only after sign-off is the difference
  between a clean migration and a tenant-wide incident (surprise encryption, broken co-authoring).
- **Detectability is the real risk, and simulation is how you retire it.** Whether Purview can reliably
  match a given legacy marking depends entirely on **what the source tool wrote and where** (document
  content, document metadata, or an email header) — this is verified empirically in simulation, not
  assumed.

## How it works
1. **Assess.** Read-only: inventory the **legacy classification values** (from the source tool's own
   export) and the **target Purview estate** (labels, label policies, auto-labeling policies, custom
   SITs). No changes.
2. **Design.** Build the **mapping matrix** — every legacy value → one target sensitivity label — and,
   for each value, decide the **detection method** (a custom SIT matching the marking text/metadata, a
   keyword, or a trainable classifier). Flag any legacy value with no clean target as an explicit owner
   decision.
3. **Configure (detection + simulation).** Create/confirm the detection SITs, then create the
   **auto-labeling policies in simulation** (`TestWithoutNotifications`) that apply each mapped target
   label wherever its detection fires — scoped to the pilot locations. Preview every write with
   `-WhatIf` first.
4. **Pilot (measure precision).** Let simulation scan the in-scope locations and produce a match
   report. **Nothing is labeled yet.** Review the matches against the mapping with the data owner.
5. **Validate.** Confirm mapping **coverage** (every in-scope legacy value is detected and mapped) and
   **precision** (the simulated reclassification hits the right content) against explicit pass/fail
   gates.
6. **Expand (enforce = reclassify).** Only after precision sign-off, **enforce from simulation** so the
   target labels are actually applied, then broaden location-by-location and reconcile the residual
   legacy markings.

## The migration mapping (what the matrix covers)
| Mapping dimension | Legacy / third-party source | Purview target |
|---|---|---|
| Classification value | A marking string / metadata written by the source tool (e.g. a `Classification` document property, an email `x-header`, a footer marking) | Exactly one Microsoft Purview **sensitivity label** |
| Detection | How Purview *recognizes* the legacy value | A **custom SIT** (regex/keyword), content marking keyword, or trainable classifier |
| Protection | Any encryption/rights the legacy tool applied out-of-band | The target label's Purview encryption/rights (parity is a **records/security decision**, not automatic) |
| Reclassification | The legacy marking left in place | The mapped Purview label **applied by auto-labeling** (enforced from simulation) |
| Residual marking | The old visual/metadata marking still on the file | Reconciliation decision — leave, overwrite, or clean up (owner call) |

> **What the source tool wrote, and whether Purview can detect it, must be verified per tool.** Some
> tools write an extractable **content marking** (matchable by a keyword SIT); some write **document
> metadata / custom properties**; some write **email x-headers**. Detectability is **flagged and proven
> in simulation**, never assumed — this is the single most important honesty in the project.

## What you can control
- The **mapping matrix** — which legacy value maps to which target label, and which values are out of
  scope or need an owner decision.
- The **detection method** per legacy value (custom SIT text/regex, keyword, or trainable classifier).
- The **pilot locations** (which SharePoint sites / OneDrive accounts / mailboxes are reclassified
  first) and the change window per wave.
- Whether a mapped target label **encrypts** — and therefore the blast radius of enforcement.
- The **residual-marking reconciliation** decision once content carries the new Purview label.

## Limitations (be honest with buyers)
- **Auto-labeling is licensing-gated.** Service-side auto-labeling for SharePoint/OneDrive/Exchange —
  the engine that does the reclassification — requires **Microsoft 365 E5** or the **E5 Compliance**
  add-on. Manual labels and publishing work at E3, but the automated reclassification does not —
  **verify your licensing/tenant.**
- **Detectability is not guaranteed.** If the source tool wrote its marking somewhere Purview can't
  index (an opaque metadata blob, a proprietary property, an image-only footer), a content/metadata SIT
  may not match it. This solution **surfaces** that in simulation; it cannot make an undetectable
  marking detectable.
- **No auto-convert exists.** There is no supported cmdlet that converts a legacy label into a Purview
  label. Reclassification is detection-driven, which is why precision must be measured before enforcing.
- **Protection parity is a decision, not a copy.** Whether the mapped Purview label should reproduce
  encryption the legacy tool applied is a **records/security determination** — the method is here; the
  determination is deferred.
- **This is not a taxonomy, DLP, or retention build.** The target labels are assumed to exist; those
  builds are separate Purview solutions.

## Naming convention (used in every doc and script)
Artifacts this solution creates or captures follow `<Purpose> – Purview – <Stage>` and are reused
verbatim across the docs, scripts, and portal.

| Artifact | Name |
|---|---|
| Legacy classification values inventory (from source tool) | `Legacy Classification Inventory – Migration – Assess` |
| Legacy → Purview label mapping matrix | `Label Mapping Matrix – Design` |
| Detection SIT for a legacy value | `SIT – Legacy <Value> – Detect` |
| Reclassification auto-labeling policy (simulation) | `Reclassify Sim – <Label> – Locations` |
| Migration coverage & precision report | `Migration Coverage – Report` |
| Migration scope & mapping-health map | `Migration Scope – Map` |
| Reclassification pilot ring | `Label Migration Pilot Ring – Stage1` |

## The standard deployment model
> Assess both sides → design the mapping matrix + detection → configure detection and auto-labeling **in
> simulation** → pilot to measure precision → validate coverage + precision against pass/fail gates →
> **enforce from simulation to reclassify** and expand location-by-location. Pattern: **Assess → Design
> → Configure → Pilot (simulate) → Validate → Expand (enforce).**
