# 1. Solution Overview — Mandatory vs Recommended Labeling Policy Design

## What this solution is
Once a sensitivity-label taxonomy exists, the **label policy** decides *how hard* the tenant asks
users to classify: whether a label is **required** (mandatory), **suggested** (recommended, via a
prompt), or **pre-set** (a default label), and whether removing or lowering a label demands a
**justification**. This solution is the **policy-design** build for exactly those behaviours — it does
not create the label taxonomy or encryption (that is a separate solution); it decides and configures
**where to require a label versus where to merely suggest one**, sets sensible **defaults**, turns on
**downgrade justification**, and configures **recommended-label prompts** — all piloted on a small
ring first, validated, then expanded, using only the Microsoft Purview portal and Security &
Compliance PowerShell.

Over-mandating labels tanks adoption (users click the first label to get past the prompt, or file a
ticket); under-mandating leaves content unclassified, so DLP, encryption, and retention have nothing
to key off. This solution is the disciplined middle: **mandatory where the risk justifies friction,
recommended where a nudge is enough, defaults so nothing is unlabelled by accident.**

## Why this matters
- **Labels are only useful if they get applied.** A perfect taxonomy that nobody applies protects nothing. The *policy* — not the label — determines application rates.
- **Mandatory labeling forces a decision** at save/send time. Powerful, but blunt: applied too broadly it trains users to pick any label to dismiss the prompt, which corrupts your classification data.
- **A default label guarantees a floor.** Every new document/email starts at a known classification (e.g. `General`) instead of "no label", so content is never silently unclassified.
- **Downgrade justification creates evidence.** When a user removes a label or lowers `Confidential` → `Public`, requiring a typed justification both deters careless downgrades and produces an **audit trail** for investigations.
- **Recommended labeling nudges without blocking.** A *recommend* prompt ("This looks like it contains financial data — apply **Confidential**?") raises correct-label rates without the backlash of hard enforcement.

## The four policy levers (what this solution configures)
| Lever | What it does | Where it is set | Blunt or soft? |
|---|---|---|---|
| **Mandatory labeling** | User must apply *a* label before they can save a document or send an email | Label **policy** setting ("require users to apply a label"), per-app override via advanced settings | Blunt (hard stop) |
| **Default label** | A label is pre-selected on new documents/email (and optionally sites/groups, Power BI) | Label **policy** setting ("apply a default label"), per-app default via advanced settings | Soft (floor) |
| **Downgrade justification** | User must type a justification to remove a label or lower its classification | Label **policy** setting ("require justification…") | Soft (evidence + friction) |
| **Recommended labeling** | A label is *suggested* with a prompt/policy-tip when content matches conditions — user accepts or dismisses | The **label's** auto-labeling for Office apps, set to **Recommend** (not Automatic) | Soft (nudge) |

> **Mandatory vs Recommended is the core decision.** Mandatory forces *some* label but not the
> *right* one; Recommended suggests the *right* label but the user can decline. The design skill is
> deciding, per population and per content type, which lever (or combination) fits — see the decision
> matrix below.

## Labeling decision matrix (the design starting point — confirm with your governance owners)
> A **technical starting point**; the final decisions (which populations are mandated, the default
> label, downgrade rules) are an information-governance determination — confirm with the accountable
> owner. Names here are reused verbatim across the docs and scripts.

| Population / content | Mandatory? | Default label | Downgrade justification? | Recommended prompts? |
|---|---|---|---|---|
| **Pilot ring** (`grp-labeling-pilot@contoso.com`) | Yes (validate friction here first) | `General` | Yes | Yes — on `Confidential \ All Employees` |
| **General workforce** (after pilot) | Yes (documents + email) | `General` | Yes | Yes |
| **Front-line / high-volume senders** | Consider **recommend-only** to protect throughput | `General` | Yes | Yes |
| **Outlook (email)** | Often **relaxed** vs documents (`DisableMandatoryInOutlook`) to avoid send-blocking | `General` (Outlook default) | Yes | Yes |
| **External-share-heavy sites** | Default label + recommend | `General` | Yes | Yes |

## Naming convention (used in every doc and script)
Every artifact this solution creates or configures is named and reused verbatim across the docs,
scripts, and portal:

| Artifact | Name |
|---|---|
| Label policy (pilot) | `LabelPolicy – Pilot – Ring1` |
| Label policy (broad) | `LabelPolicy – Broad – AllUsers` |
| Pilot ring group | `grp-labeling-pilot@contoso.com` |
| Default label (documents & email) | `General` |
| Recommended-prompt label | `Confidential \ All Employees` |
| Recommended-prompt message | *"This content looks sensitive — apply Confidential to protect it."* |

## What you can control
- **Which populations are mandated** to apply a label, and on which apps (documents vs Outlook can differ).
- **The default label** for documents and email (and, where licensed, sites/groups, Power BI, meetings).
- **Whether downgrade/removal requires a justification**, and the justification prompt.
- **Which labels recommend themselves** (with a policy-tip message) when content matches conditions — a nudge, not a block.
- **Rollout order** — pilot ring → broad — and rollback (unpublish/relax a setting) per policy.

## Limitations (be honest with buyers)
- **These are label *policy* settings, not a simulation feature.** Unlike service-side auto-labeling, mandatory/default/downgrade settings have **no "simulation" mode** — the safe rollout mechanism is a **pilot policy scoped to a pilot ring** (validate friction there), then broad. This solution enforces pilot-first for exactly that reason.
- **Recommend vs Automatic is a per-label setting.** Recommended labeling is configured on the **label's** auto-labeling for Office apps (set to *Recommend*), which is **client-side** and **licensing-dependent** for some conditions (advanced classifiers) — **verify your licensing/tenant**.
- **Advanced-setting keys and portal paths evolve.** Per-app overrides (e.g. `Mandatory`, `DisableMandatoryInOutlook`, `OutlookDefaultLabel`) are documented advanced settings, but Microsoft's portal and some keys change — each is flagged "verify in your tenant"; none is invented.
- **The taxonomy itself is out of scope.** This solution assumes labels already exist (or references the taxonomy/labels solution); it designs the *policy behaviour* over them.
- **Determinations are deferred.** What *should* be mandated, the enterprise default classification, and records/legal implications are **governance determinations** — this solution provides the configuration method and evidence.

## The standard deployment model
> Assess the current label-policy posture → design the mandatory-vs-recommended matrix (defaults,
> downgrade rules, prompts) → configure on a **pilot policy scoped to a pilot ring** (`-WhatIf` →
> commit) → validate friction and effective settings → **expand** the settings to the broad policy →
> validate → operate.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
