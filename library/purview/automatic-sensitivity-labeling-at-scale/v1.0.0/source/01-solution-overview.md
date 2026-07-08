# 1. Solution Overview — Automatic Sensitivity Labeling at Scale (Microsoft Purview)

## What this solution is
This solution labels data **automatically, without the user** — it configures Microsoft Purview's two
automatic sensitivity-labeling engines, runs them in **simulation first**, tunes them for precision,
and then enforces them **at scale** across the tenant. It covers:

- **Client-side auto-labeling** — labels applied (or *recommended*) inside the Office apps
  (Word/Excel/PowerPoint/Outlook) as a user creates or edits content, driven by conditions configured
  on the sensitivity **label** and surfaced through a label policy.
- **Service-side auto-labeling** — labels applied by the service to **data at rest** (SharePoint,
  OneDrive) and **data in transit** (Exchange email), configured as an **auto-labeling policy** that is
  **created in simulation** (it scans and reports what *would* be labeled) and only enforced after its
  precision is signed off.

The whole engagement is a repeatable, safe rollout: assess what already exists, configure auto-labeling
in **simulation**, validate the match precision with the data owner, enforce on a **pilot location
subset**, then **expand the location scope to the whole tenant** — using only the Microsoft Purview
portal and Security & Compliance PowerShell (no third-party tooling).

> **Scope boundary.** This solution automates the *application* of sensitivity labels that **already
> exist and are published** in your tenant. Designing the label taxonomy and creating/publishing the
> labels themselves (and any encryption/marking they carry) is a **prerequisite** (see §2.1) — this
> build makes those labels apply themselves accurately and at scale.

## Why this matters
- **Manual labeling never scales or stays consistent.** Users forget, guess, or pick the easiest label. Unlabeled and mislabeled content is a compliance gap and a data-risk exposure — DLP, encryption, and retention all key off the label being present and correct.
- **Auto-labeling is the only way to cover data at rest.** Client-side labeling only touches content a user actively edits; the millions of existing files in SharePoint/OneDrive and mail in Exchange are reached only by **service-side** auto-labeling.
- **Aggressive auto-labeling breaks trust fast.** Mislabeling — and, where labels encrypt, *surprise encryption* — generates a ticket flood. **Simulation-first** is what makes labeling at scale safe: you see exactly what *would* be labeled, measure precision, and tune before a single item is touched.
- **Consistency is the point.** A tuned auto-labeling policy applies the same classification the same way across every workload, every day — something a human workforce cannot do.

## The two engines (and where each applies)
| | **Client-side auto-labeling** | **Service-side auto-labeling** |
|---|---|---|
| Runs in | Office apps on the client (Word/Excel/PowerPoint/Outlook) | The Microsoft 365 service |
| Reaches | Content the user is **actively editing** | **Data at rest** (SharePoint, OneDrive) + **in transit** (Exchange) |
| Behavior | *Recommend* or *automatically apply* a label | Apply a label to matching items in scope |
| Configured on | The **label** (auto-labeling conditions), surfaced via a **label policy** | An **auto-labeling policy** + rule (`New-AutoSensitivityLabelPolicy` / `New-AutoSensitivityLabelRule`) |
| Simulation? | No dedicated simulation — piloted via label policy scope | **Yes — created in simulation** (`TestWithoutNotifications`) and validated before enforce |
| Reaches existing content? | No — new/edited only | **Yes** — sweeps existing content |

Together they cover **new content at creation** (client-side) and **existing + in-transit content**
(service-side). Both are used in this solution.

## Licensing (verify your licensing/tenant)
Automatic sensitivity labeling — **both** client-side automatic labeling in Office apps **and**
service-side auto-labeling for SharePoint/OneDrive/Exchange — is a **premium** capability that
typically requires **Microsoft 365 E5** or the **E5 Compliance** add-on. Manual labeling is available
more broadly, but the automation in this solution is E5-tier. **Verify your licensing/tenant** —
Microsoft's licensing tables are the authority; this solution flags the gate rather than assuming it.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `AutoLabel <Type> – <Label> – <Workload/Stage>` and reused
verbatim across the docs, scripts, and portal. The **label being applied** is an existing published
label — `Confidential \ All Employees` is used as the running example.

| Artifact | Name |
|---|---|
| Service-side auto-label policy — SharePoint/OneDrive (simulation) | `AutoLabel Sim – Confidential – SPO+ODB` |
| Service-side auto-label rule — SharePoint/OneDrive | `AutoLabel Rule – Confidential – SPO+ODB` |
| Service-side auto-label policy — Exchange (simulation) | `AutoLabel Sim – Confidential – Exchange` |
| Service-side auto-label rule — Exchange | `AutoLabel Rule – Confidential – Exchange` |
| Label being auto-applied (existing, published) | `Confidential \ All Employees` |
| Pilot location subset (SPO) | a named subset of sites; broadened to `All` after sign-off |

> Portal artifact names may not accept every punctuation character and the PowerShell examples use an
> ASCII hyphen (`AutoLabel Sim - Confidential - SPO+ODB`) to avoid encoding issues — the *identity* is
> what matters; keep it consistent across your tenant.

## What you can control
- **Which existing label** each auto-labeling policy applies (e.g. `Confidential \ All Employees`).
- **The match conditions** — sensitive information types, keywords, or **trainable classifiers** — on each auto-labeling rule, and the **minimum instance / confidence** thresholds that drive precision.
- **Which workloads and locations** are in scope (all vs a pilot subset of sites/mailboxes) and any **exclusions**.
- **Client-side behavior** — whether a label is *recommended* (user confirms) or *auto-applied* silently, configured on the label.
- **The simulation → enforce transition** — nothing is enforced until the simulation match set is accepted.

## Limitations (be honest with buyers)
- **Licensing gates the whole capability.** Automatic labeling (client- and service-side) requires **E5 / E5 Compliance** — **verify your licensing/tenant**; without it this solution cannot run.
- **Labels must already exist.** This build applies published labels automatically; it does not design or create the taxonomy (see §2.1).
- **Service-side scanning has latency and quotas.** Simulation and enforcement scan large volumes over time; results are **not** instantaneous and item/throughput limits apply — **verify current limits for your tenant.**
- **Auto-labeling only *raises* or sets a label under defined rules.** By default the service won't overwrite a higher-priority label a user set manually — behavior around existing labels is configurable and **tenant/version-sensitive; verify in your tenant.**
- **Where the applied label encrypts, auto-labeling encrypts.** Applying an encrypting label at scale is high-impact — this is precisely why simulation and a pilot location subset come first.
- **The portal is evolving.** Portal paths and some cmdlet parameters change; version-sensitive paths are flagged "verify in your tenant."

## The standard deployment model
> Assess the current auto-labeling posture and confirm the target labels exist → design the match
> conditions → configure client-side and service-side auto-labeling in **simulation** → validate match
> precision with the data owner → enforce on a **pilot location subset** → validate → **expand the scope
> tenant-wide (enforce at scale).**
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
