# 1. Solution Overview — Application Packaging & Deployment Standards (Win32, MSIX & Store)

## What this solution is

This is the **organisation-wide specification** that governs how every application in your tenant is
packaged, named, detected, documented, reviewed, released, and audited. It is the layer **above** the
mechanics of packaging any single app.

It does **not** teach you how to run `IntuneWinAppUtil.exe`, how to type an `msiexec` command, or how
to click through the Win32 app wizard for one application — that is per-app packaging work. This
solution answers the questions that only appear when **many people package many apps over many
years**:

- What must an app be **named**, and why does an inconsistent catalog become unmanageable?
- Which **format** — Win32, MSIX, Microsoft Store (new), or LOB/MSI — is correct for a given app, and
  who decides?
- What makes a detection rule **acceptable and auditable**, and which patterns are **banned outright**?
- What must be true before a package is allowed to be **released** to real users?
- Who **reviews and signs off** a package, and what evidence is retained?
- How do assignments stay clean as the catalog grows from 10 apps to 300?
- How is the standard **enforced and audited** so it does not decay into a document nobody follows?

## The problem it solves

An app catalog decays predictably. The first ten apps are fine because one person built them all. By
app forty there are three naming styles, two people who "know" the detection rules, apps assigned to
groups nobody can explain, four apps with no owner, and a `Test - do not use` app that has been
assigned to All Devices for eight months. Nobody did anything wrong; there was simply no **standard**.

The cost is real and measurable: failed installs nobody can triage, licence spend on apps still
deployed to leavers, audit findings because there is no record of what was approved, and a
"do not touch that app" culture where the safest action is to create a duplicate.

A packaging standard is cheap to adopt and expensive to retrofit. This solution gives you the
standard, the templates that operationalise it, the quality gates that enforce it, and the scripts
that audit it.

## The four control points

Everything in this specification hangs off four control points. Each is a place where a decision is
made and where a rule can be enforced.

| Control point | The question | Enforced by |
|---|---|---|
| **1. Intake** | Should we package this app at all, and in which format? | The Package Intake & Specification Template + the format decision matrix |
| **2. Build** | Does the package meet the naming, metadata, detection, command, and return-code standards? | The packaging specification + the acceptance checklist |
| **3. Release** | Has a second person reviewed it, and is the evidence retained? | The peer review & sign-off process |
| **4. Operate** | Are assignments still clean, and does the catalog still comply? | The ring/assignment standard + the quarterly audit scripts |

## The three app formats you will govern

The specification covers three delivery formats plus one legacy format being retired. The
**format decision matrix** in the Implementation Guide (Step 3) is the authoritative decision tree;
this is the orientation.

- **Win32** (`.intunewin`, installed by the Intune Management Extension) — the default. Wraps any
  MSI, EXE, or script. Full control over install/uninstall commands, detection, requirements,
  dependencies, supersedence, and return codes. Chosen unless another format is clearly better.
- **MSIX** (and `.msixbundle` / `.appx`) — a modern, containerised Windows package format installed
  by the OS rather than by a custom command line. No install command to get wrong, clean uninstall,
  and per-user by design. Only usable when the vendor ships an MSIX or when your packaging team
  converts one — and conversion is a project, not a step.
- **Microsoft Store (new)** — Intune's integration with the Microsoft Store, covering both UWP and,
  since the "new" Store, packaged Win32 apps. Zero packaging effort and automatic vendor updates,
  which is exactly why it should be preferred where it is available and where automatic updating is
  acceptable to the business. **Availability differs in US Government clouds — see Requirement 2.9.**
- **Line-of-business (LOB) / MSI** — the legacy `.msi` app type. It exists, it still works, and the
  standard's position is that it is **not used for new packages**. It is listed in the matrix only so
  that reviewers know to reject it and so that migration of existing LOB apps is a tracked item.

## What the standard actually produces

When this specification is adopted, the following exist in your tenant and your document store, and
they are the deliverables a reviewer or auditor will ask for:

1. A **naming convention** applied to every app, every assignment group, and every scope tag —
   `<Vendor> <Product> – <Format> – v<Version>` for apps and `APP – <Purpose> – <Stage>` for groups.
2. A completed **Package Intake & Specification form** per application, retained for its lifetime.
3. A **detection rule** per app that satisfies the acceptability rules and matches no banned pattern.
4. A signed **Package Acceptance Checklist** per release, with the reviewer's name and date.
5. A **ring assignment** — Ring 0 packaging lab, Ring 1 pilot, Ring 2 broad — with an explicit,
   named exclusion group.
6. A **quarterly compliance report** produced by the audit scripts, with the exceptions register.

## Benefits

- **Anyone can pick up anyone else's package.** Consistent names, consistent metadata, and a
  completed spec form mean the person who packaged an app is not a single point of failure.
- **Detection stops being the top failure cause.** A rule that must pass documented acceptability
  tests is a rule that reports the truth.
- **Bad packages cannot reach production.** The acceptance checklist and peer sign-off are gates, not
  suggestions, and Ring 1 is a real ring with real users.
- **The catalog stays clean at scale.** Assignment hygiene rules plus a scripted quarterly audit stop
  orphan apps, duplicate assignments, and conflicting Required/Uninstall targeting accumulating.
- **Audit answers itself.** "Who approved this, when, against what test evidence?" has a filed answer
  for every app.
- **New starters are productive in days.** The standard plus the intake template is the onboarding
  material.

## Limitations (be honest)

- **A standard is a social artefact.** Scripts can detect violations; only management support makes
  people fix them. The enforcement section (Implementation Step 10) is not optional garnish.
- **Retrofitting an existing catalog takes effort.** The remediation script normalises metadata, but
  renaming apps and rebuilding non-compliant detection rules is manual work. Plan it as a project and
  use the exceptions register for what you will not fix.
- **Microsoft Graph reflects what Intune stores, not what a human meant.** The audit scripts detect
  structural violations (missing publisher, banned detection pattern, orphan assignment); they cannot
  judge whether a description is *good*.
- **Format availability changes.** The Microsoft Store (new) app type in particular has different
  availability across Commercial and US Government clouds — the matrix tells you to verify before
  committing, and Requirement 2.9 covers the government position.
- **This standard governs deployment, not licensing.** Entitlement, licence counting, and app
  contract management are adjacent disciplines and out of scope.

## The standard deployment model

> **Intake the app against the spec form → decide the format from the matrix → build to the packaging
> specification → pass the acceptance checklist → peer review and sign-off → release to Ring 1 pilot →
> validate → expand to Ring 2 broad → audit quarterly.** This is the repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.** No package skips the checklist, and no package
> reaches Ring 2 without a signed sign-off record.
