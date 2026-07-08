# Requirements — Trainable Classifiers in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, Security & Compliance PowerShell / Graph
toolchain, in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change
control) are in `global-requirements-purview.md` — reference them; they are **not** repeated here.
The items below are the ones **specific to trainable classifiers**: the **seed/test content**, the
**target control** (label/DLP/retention), and the **accuracy acceptance** decision.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. Licensing for trainable classifiers and the controls they feed

**Description:** The licensing that includes **trainable classifiers** and the downstream control you
will wire them into — **auto-labeling**, **advanced DLP**, and/or **retention** — typically
**Microsoft 365 E5**, the **E5 Compliance**, or the **E5 Information Protection & Governance** add-on,
assigned to the in-scope users/scope.
**Why:** Trainable classifiers and auto-labeling/advanced DLP are premium, plan-gated capabilities;
without the right licence they are unavailable, and content-level enforcement is licensed per user.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** confirms the SKU/add-on. In the
Purview portal, **Data classification → Classifiers → Trainable classifiers** is present, and the
target control (auto-labeling / DLP / retention) is available. Cross-check against the *Microsoft
Purview service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire and assign the required SKU/add-on before building classifiers or
wiring controls.

## R2. Least-privilege roles for classifiers + the target control

**Description:** The least-privilege roles, mapped to **named** people:
- The rights to **create/manage trainable classifiers** (typically a data-classification / information-
  protection role — **verify the exact role in your tenant**).
- **Compliance Administrator / Compliance Data Administrator / Information Protection** roles to author
  the **auto-labeling / DLP / retention** policy the classifier feeds.
- **Global Administrator** only where genuinely required.
**Why:** Purview uses fine-grained role groups; classifier management and policy authoring are distinct
duties and should not be over-granted.
**Verify:** Purview portal → **Roles & scopes / Permissions** confirms the memberships.
`CLSTRAIN-Discovery.ps1` reports the policy/label signals it can read.
**Implement if missing:** Assign the least-privilege role for each duty under change control.

## R3. Seed content — a SharePoint site of positive example documents (for custom classifiers)

**Description:** For each **custom** classifier, a **SharePoint site (or location)** containing a set
of **positive example documents** that represent the category (e.g. contracts), meeting Microsoft's
**minimum/recommended sample counts** — **verify the current minimums for your tenant** (they are
non-trivial; too few samples yields a weak model).
**Why:** A trainable classifier learns **by example**; the quality and quantity of the seed set
directly determines accuracy. Built-in classifiers need no seed content.
**Verify:** Confirm the seed site exists and holds enough representative, correctly-categorized
documents. `CLSTRAIN-ScopeHealth.ps1` prompts you to confirm the seed site and reports what it can
read.
**Implement if missing:** Assemble a representative seed set on a dedicated SharePoint site **before**
creating the custom classifier. (Avoid mixing categories — seed = positive examples of *one*
category.)

## R4. Test content — a separate, pre-categorized set to measure accuracy

**Description:** A **separate** set of items (not the seed set) that you have **pre-categorized** as
**match / non-match**, used in the classifier's **Test** stage to measure prediction accuracy before
publishing.
**Why:** Publishing a classifier that has not been tested for accuracy risks mislabeling/mis-acting on
content at scale. The test stage is where you decide whether accuracy is acceptable (R7).
**Verify:** Confirm a distinct test set exists with a known ground truth (which items *should* match).
**Implement if missing:** Assemble a labeled test set (mix of true matches and true non-matches)
before the Test stage.

## R5. The target control decided: auto-labeling and/or DLP and/or retention

**Description:** A decision on **what acts on the classifier** — an **auto-labeling** policy (apply a
sensitivity label), a **DLP** policy (protect/restrict), and/or a **retention** policy (retain/dispose)
— and, for auto-labeling, **which sensitivity label** the matched content should receive.
**Why:** A published classifier does nothing until it is **wired into a control**; the target control
and (for labeling) the specific label are the point of the whole exercise.
**Verify:** Purview → **Information Protection → Labels** confirms the target label exists and is
published; the target control (auto-labeling/DLP/retention) is available. `CLSTRAIN-Discovery.ps1`
inventories labels and the candidate policies.
**Implement if missing:** Confirm/publish the target label and decide the target control **before**
wiring. (A label taxonomy rollout may be a separate project; classifiers can start by feeding an
audit-only DLP or a simulation auto-label policy.)

## R6. Built-in classifier catalog reviewed (use ready-made where possible)

**Description:** A review of the **built-in (pre-trained) classifiers** available in your tenant (e.g.
Resumes, Source Code, and others — **verify the current catalog**) to decide which categories are
already covered without any training, versus which need a **custom** classifier.
**Why:** Built-in classifiers work immediately with no seed/test effort; building custom classifiers
for content Microsoft already covers is wasted effort.
**Verify:** Purview → **Data classification → Classifiers → Trainable classifiers** shows the built-in
classifiers. **Verify the catalog against your tenant** — it evolves.
**Implement if missing:** Map each needed category to a built-in classifier where one exists; reserve
custom classifiers for organization-specific content.

## R7. An accuracy-acceptance decision — agreed with the data owners

**Description:** A documented decision, agreed with the **data owners / compliance**, of **what
accuracy is acceptable** for the classifier's intended use (a classifier feeding an audit-only report
can tolerate more error than one auto-applying an encrypting label), and who signs off the Test-stage
results before publishing.
**Why:** "Is this classifier good enough?" is a **business/risk determination**, not a technical
default — the tolerance depends on what the classifier will drive.
**Verify:** Confirm the accuracy threshold and the named approver **in writing** before publishing and
before moving the wired control from simulation to enforce.
**Implement if missing:** Capture the acceptance criteria with the data owners; until then, keep the
wired control in **simulation / audit only.** (See `global-requirements-purview.md` §5.)

## R8. A named pilot scope and change control (simulation/test first)

**Description:** A **named pilot scope** (users/sites, e.g. `SG-Classifier-Pilot`) for the wired
control, and agreement to run the auto-labeling/DLP policy in **simulation/test mode first**, under a
**change-control** process, before any enforcing, broad rollout.
**Why:** Auto-labeling (which can encrypt) and DLP block actions are high-impact; simulation on a
small scope proves the classifier + control behave as measured **without** changing content, and lets
you tune before enforcing.
**Verify:** Confirm the pilot scope exists, that **simulation/test mode** is used, and a change
window/approval path. `CLSTRAIN-ScopeHealth.ps1` (`-WhatIf`) previews pilot-scope targeting.
**Implement if missing:** Define the pilot scope, deploy the wired control in simulation, and agree
change control before enabling enforcement.
