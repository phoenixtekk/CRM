# 1. Solution Overview — Sensitivity Label Taxonomy Design (Microsoft Purview)

## What this solution is
A **sensitivity label taxonomy** is the ordered set of labels users choose from to classify content in
Microsoft Purview — the tier names, the parent/sublabel structure, the naming convention, and the
**protection and marking each label applies**. This solution is a repeatable way to **design** that
taxonomy well: decide how many tiers you need, structure parents and sublabels, agree a stable naming
convention, and produce a **protection/marking mapping** (which labels encrypt, which mark, and with
what rights) — then configure the designed taxonomy in the tenant, **publish it to a pilot ring**,
and validate that it behaves as designed. All configuration uses only the Microsoft Purview portal and
Security & Compliance PowerShell (no third-party tooling), and every high-impact change is piloted in a
small ring before broad rollout.

This is the **design** build — the taxonomy, sublabels, naming, and protection/marking *mapping* done
deliberately so users actually adopt it. It is distinct from:
- the **full labels implementation** (which also builds service-side auto-labeling and retention labels
  with adaptive scopes),
- **mandatory vs recommended labeling design** (the default-label / prompt-for-justification decision),
- and **container labeling** for Teams/Groups/Sites — each a separate solution. A well-designed
  taxonomy is the foundation those build on.

## Why this matters
- **A bad taxonomy breaks adoption.** Too many labels and users guess or ignore them; too few and the
  labels don't reflect real sensitivity. The taxonomy *is* the user-facing guidance — getting the
  structure and names right is what makes classification stick.
- **Renaming and reordering after publish is disruptive.** Existing content keeps the label it was
  stamped with, and a display-name change confuses users. The taxonomy is expensive to change later —
  so it is worth designing once, deliberately, up front.
- **Protection travels with the label.** When a sensitivity label encrypts, that protection stays
  enforced when the file leaves the tenant. Deciding *which* tiers encrypt (and with what rights) is a
  design decision with real blast radius — encrypt the wrong tier and you break co-authoring and
  downstream automation.
- **A stable naming convention prevents sprawl.** Consistent, immutable internal names and predictable
  display names keep the taxonomy legible as it grows and make every downstream control (DLP,
  auto-labeling, retention) easier to target.

## The label object model (what you are designing)
| Property | What it is | Design guidance |
|---|---|---|
| **DisplayName** | What users see in Office (a sublabel shows as `Parent \ Child`) | Plain business language; short; the tooltip carries the detail |
| **Name** (internal) | Immutable identifier used by cmdlets/policies | Stable slug; **never reused or renamed**; the naming convention lives here |
| **Tooltip** | The only in-context help a user gets | One plain-language sentence: what it means + a handling instruction |
| **Priority / order** | Position in the ordered list (least → most sensitive) | The order *is* the guidance; set it deliberately |
| **ParentId** | Links a sublabel to its parent tier | Parents group only; **parents must not apply protection** and are not selectable |
| **Protection** | Encryption + rights (usage rights per group) | The high-impact decision — map it explicitly (below) |
| **Content marking** | Header / footer / watermark text | Visible classification; cheap, low-friction, use broadly |

## The naming convention (the core design deliverable)
Every label this solution creates follows one convention, reused verbatim across the docs, scripts, and
portal. This is what keeps the taxonomy legible and prevents sprawl.

- **Display name (what users see):**
  - **Top tier:** the plain sensitivity word — `Public`, `Internal`, `Confidential`, `Highly Confidential`.
  - **Sublabel:** the **audience / handling** it targets — shown as `Confidential \ All Employees`,
    `Highly Confidential \ Specified People`. The sublabel display name is the *audience*, not a repeat
    of the tier.
- **Internal name (immutable identifier):** a stable slug `SL-<Tier>[-<Audience>]` —
  e.g. `SL-Public`, `SL-Confidential`, `SL-Conf-AllEmp`, `SL-HighlyConf-Specified`. The internal name is
  **never renamed or reused**; display names can be adjusted, internal names cannot.
- **Order (priority):** ascending by sensitivity — `Public (0) → Internal (1) → Confidential (2) →
  Highly Confidential (3)`, sublabels ordered within their parent.

## Sample taxonomy (a technical starting point — confirm with your governance owners)
> This is a **technical starting point**, not a determination. The final tier count, names, protection
> settings, and rights model are a **compliance/records/security decision** (see §2 deferral). The names
> below are reused verbatim across the docs and scripts.

| Order | Display name | Internal `Name` | Parent | Selectable? |
|---|---|---|---|---|
| 0 | `Public` | `SL-Public` | — | yes |
| 1 | `Internal` | `SL-Internal` | — | yes |
| 2 | `Confidential` | `SL-Confidential` | — (grouping only) | **no** |
| 2.1 | `Confidential \ All Employees` | `SL-Conf-AllEmp` | `SL-Confidential` | yes |
| 2.2 | `Confidential \ Trusted People` | `SL-Conf-Trusted` | `SL-Confidential` | yes |
| 3 | `Highly Confidential` | `SL-HighlyConf` | — (grouping only) | **no** |
| 3.1 | `Highly Confidential \ All Employees` | `SL-HighlyConf-AllEmp` | `SL-HighlyConf` | yes |
| 3.2 | `Highly Confidential \ Specified People` | `SL-HighlyConf-Specified` | `SL-HighlyConf` | yes |

## The protection / marking mapping (the second core deliverable)
For **each** selectable label, the design records exactly what it applies. This mapping is the artifact
that turns a list of names into an enforceable design.

| Label | Encryption | Rights (by group) | Content marking |
|---|---|---|---|
| `Public` | none | — | Footer: `Public` |
| `Internal` | none | — | Footer: `Internal — do not distribute externally` |
| `Confidential \ All Employees` | Encrypt | all internal users → **Co-Author** | Footer: `Confidential` |
| `Confidential \ Trusted People` | Encrypt | named group → **Reviewer** (Do-Not-Forward-style) | Footer: `Confidential` |
| `Highly Confidential \ All Employees` | Encrypt | all internal users → **Co-Author** | Footer: `Highly Confidential` + watermark `HIGHLY CONFIDENTIAL` |
| `Highly Confidential \ Specified People` | Encrypt | named recipients → **Viewer** (no export/print) | Footer: `Highly Confidential` + watermark |

**Design rules baked into the mapping:**
- **Parents never protect** — `Confidential` and `Highly Confidential` group only; they are not
  selectable and carry no encryption/marking.
- **Lower tiers mark, don't encrypt** — `Public`/`Internal` get visible footers with **zero friction**.
- **Rights point at groups, not people** — every encrypting label's rights target a **mail-enabled
  security group**, so membership changes never require editing the label.
- **Reserve encryption for what needs it** — encryption travels with the file and is the strongest
  control, but it breaks some co-authoring/automation paths; only the tiers that genuinely need it
  encrypt, and each is piloted first.

## Artifact names used in every doc and script
| Artifact | Name |
|---|---|
| Sensitivity label policy (pilot) | `SL Policy - Pilot - Ring1` |
| Sensitivity label policy (broad) | `SL Policy - Broad - AllUsers` |
| Pilot ring group (placeholder) | `grp-purview-pilot@contoso.com` |
| Rights group — all employees (placeholder) | `grp-all-employees@contoso.com` |
| Rights group — trusted people (placeholder) | `grp-trusted-people@contoso.com` |
| Rights group — specified people (placeholder) | `grp-specified-people@contoso.com` |

## What you can control
- The **number of tiers** and whether each has sublabels — kept short enough that users don't guess.
- The **display names, internal names, order, and tooltips** — the whole user-facing structure.
- The **protection/marking mapping** — which labels encrypt, the exact rights per group, and the
  header/footer/watermark on each.
- **Who the label policy targets** — pilot ring first (`SL Policy - Pilot - Ring1`), then broad.
- Whether the taxonomy is published as a starting design or extended over time — with the naming
  convention keeping it legible.

## Limitations (be honest with buyers)
- **This is design + configuration, not the full label program.** Service-side auto-labeling, retention
  labels, adaptive scopes, DLP, and container labeling are **separate solutions** — this one delivers a
  sound taxonomy and its protection mapping, published to a pilot.
- **Licensing gates some protection features.** Manual sensitivity labeling, content marking, and
  encryption are available broadly (Microsoft 365 E3 tier); some advanced label behaviors are E5-tier —
  **verify your licensing/tenant**; the solution flags each gate rather than assuming.
- **Protection settings are determinations, not defaults.** The final tier count, rights model, and
  which tiers encrypt are decisions owned by security/compliance/records (see §2 deferral). This
  solution provides the design method, the mapping template, and the configuration — not the sign-off.
- **The taxonomy is expensive to change after publish.** Existing content keeps its stamped label;
  renaming/reordering is disruptive. That is exactly why the design is done deliberately up front.
- **The portal is evolving.** Portal paths and some cmdlet parameters change; where a path is
  version-sensitive it is flagged "verify in your tenant."

## The standard deployment model
> Assess the current label posture → **design** the taxonomy (tiers, sublabels, naming, protection/
> marking mapping) with governance owners → configure the labels (`-WhatIf` → `-Commit`) → **publish to
> a pilot ring** → validate structure + protection → **expand** to broad publish.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
