# 1. Solution Overview — Data Classification Framework & Strategy (Microsoft Purview)

## What this solution is
A **data classification framework** is the single, organization-wide scheme that says *how many
sensitivity tiers exist, what each one means, and which technical controls enforce it*. This solution
delivers that framework end to end in Microsoft Purview: a small, defensible set of **sensitivity
tiers**, a written **classification standard** (tier definitions + handling rules), and — the core
artifact — a **crosswalk** that maps each tier to its **sensitivity label**, its **DLP posture**, and
its **retention treatment**, so all three control families key off *one* scheme instead of drifting
apart. The framework is configured as a **reference implementation** (the tier labels, a tier-aligned
DLP baseline in **test/simulation** mode, and tier-aligned retention labels), piloted, validated for
coherence, then expanded — using only the Microsoft Purview portal and Security & Compliance
PowerShell (no third-party tooling).

This is the **framework and strategy** layer — the tier model, the standard, and the tier→controls
crosswalk that everything else aligns to. It is deliberately distinct from the deep *build* solutions:
the exhaustive label taxonomy/auto-labeling build, the full DLP policy development, and the records
retention schedule are each their own engagement. Here you establish the **scheme** and a coherent
minimum reference implementation of it; those solutions go deep on each control family.

## Why this matters
- **Inconsistent classification undermines every control.** If a "Confidential" label, a DLP rule, and a retention policy each define "sensitive" differently, protection has gaps and users get contradictory signals. One framework removes the ambiguity.
- **The crosswalk is the contract.** When every tier has exactly one label, one DLP posture, and one retention treatment, you can *prove* coverage — and spot the tier that has a label but no DLP, or retention but no label.
- **A framework scales; ad-hoc labels don't.** New DLP policies, new workloads, and Copilot/data-governance initiatives all plug into the tier model instead of inventing their own definitions.
- **High-impact controls are piloted first.** DLP blocking, encryption, and retention deletion are disruptive if rolled out carelessly — the framework's reference implementation is created in **test/simulation** and piloted before any enforcement.

## The classification tier model (starting point — confirm with your governance owners)
> The four-tier model below is a **technical starting point**. The final number of tiers, their
> names, definitions, and handling rules are a **governance / compliance / records determination**
> (see §2 and the deferral note). The names here are reused verbatim across every doc and script.

| Tier | Name | Example definition (confirm with governance) | Example handling rule |
|---|---|---|---|
| **Tier 0** | `Public` | Approved for public release; no harm if disclosed. | May be shared externally. |
| **Tier 1** | `Internal` | Default for all business content; not for public release. | Share inside the org; external sharing by exception. |
| **Tier 2** | `Confidential` | Sensitive business data, PII, or contract-restricted data. | Encrypt; restrict external sharing. |
| **Tier 3** | `Restricted` | Highly regulated / high-impact if disclosed (e.g. regulated PII, secrets). | Encrypt + mark; named-recipient only; strong DLP. |

## The crosswalk (the core deliverable — one row per tier)
Each tier maps to exactly one artifact in each control family. Names are reused verbatim everywhere.

| Tier | Sensitivity label | DLP posture (piloted in **test** first) | Retention treatment (records/legal determination) |
|---|---|---|---|
| **Tier 0 · Public** | `Public` (marking only) | Monitor only — no block | `CLS Retain – Public` |
| **Tier 1 · Internal** | `Internal` (footer marking) | Policy tips, no block | `CLS Retain – Internal` |
| **Tier 2 · Confidential** | `Confidential` (encrypt) | Block/restrict external — **test mode first** | `CLS Retain – Confidential` |
| **Tier 3 · Restricted** | `Restricted` (encrypt + watermark) | Block external + require justification — **test mode first** | `CLS Retain – Restricted` |

> The DLP conditions (which sensitive information types trigger each tier) and the retention
> **periods/actions** are placeholders here — the sensitive-info-type selection is confirmed with data
> owners, and the retention periods are a **records/legal determination** (see §2).

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `CLS <Type> – <Scope> – <Stage>` (or the tier name for
labels/retention) and reused verbatim across the docs, scripts, and portal:

| Artifact | Name |
|---|---|
| Sensitivity labels (the tiers) | `Public`, `Internal`, `Confidential`, `Restricted` |
| Sensitivity label policy (pilot) | `CLS Policy – Pilot – Ring1` |
| Sensitivity label policy (broad) | `CLS Policy – Broad – AllUsers` |
| DLP baseline policy (test mode) | `CLS DLP – Tier2-3 – Test` |
| Retention labels (per tier) | `CLS Retain – Public` / `– Internal` / `– Confidential` / `– Restricted` |
| Retention label policy (pilot) | `CLS Retain Publish – Pilot – Ring1` |

## What you can control
- The tier model — how many tiers, their names, definitions, and handling rules (with governance sign-off).
- The crosswalk — which label, DLP posture, and retention treatment each tier maps to.
- The classification standard document — the written scheme users and admins follow.
- The reference implementation — the tier labels, the tier-aligned DLP baseline (in test mode), and tier-aligned retention labels.
- The pilot scope and the order of enforcement (labels first, DLP and retention piloted before enforcing).

## Limitations (be honest with buyers)
- **This is the framework, not the exhaustive build.** Deep auto-labeling, full DLP policy development, and the records retention schedule are separate solutions — this one establishes the scheme and a coherent reference implementation of it.
- **Licensing gates capability.** Encrypting labels are broadly available; advanced DLP, activity/content explorer reporting, and some retention features require **E5 / E5 Compliance** — **verify your licensing/tenant**; the solution flags each gate.
- **Records, retention periods, and regulatory applicability are determinations, not technical defaults** — owned by records/compliance/privacy/legal (see the §2 deferral note). This solution provides the configuration method and evidence.
- **DLP and encryption are high-impact.** A blocking DLP rule or an encrypting label applied carelessly disrupts users — always pilot in **test/simulation** first.
- **The portal is evolving.** Portal paths and some cmdlet parameters change; where a path is version-sensitive it is flagged "verify in your tenant."

## The standard deployment model
> Assess the current classification posture → design the tier model + crosswalk (the standard) →
> configure the reference implementation (tier labels; DLP baseline in **test**; retention labels) →
> pilot to a small ring → validate the tiers map coherently → expand and enforce tenant-wide.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
