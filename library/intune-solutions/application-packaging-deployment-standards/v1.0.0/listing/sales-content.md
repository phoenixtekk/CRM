# Sales Content — Application Packaging & Deployment Standards (Win32, MSIX & Store)

## The transformation

Stop your Intune app catalog from decaying. Set the org-wide standard once, then let five audit
scripts keep it clean forever. This is the specification layer **above** per-app packaging: it governs
how *every* application in your tenant is named, formatted, detected, documented, reviewed, released,
and audited — not how any single app is wrapped.

## The problem

An app catalog decays predictably. The first ten apps are fine because one person built them all. By
app forty there are three naming styles, detection rules only one person understands, apps assigned to
groups nobody can explain, several apps with no owner, and a `Test - do not use` app that has been
pushed to every device for months. Nobody did anything wrong — there was no **standard**. The cost is
real: failed installs nobody can triage, licence spend on software still deployed to leavers, audit
findings because there is no record of what was approved, and a "don't touch that app" culture.

## Run it yourself — simpler, cheaper, and proven

- **Simpler** — exact, ordered steps with full navigation paths; every tenant object is named once
  and reused verbatim across the templates, the gates, and the audit scripts.
- **Cheaper** — one fixed price instead of an open meter; comparable governance consulting runs well
  into the thousands per day. Adopt once, reuse on every package forever.
- **Tested** — a pilot-first model (Assess → Configure → Pilot → Validate → Expand) with explicit
  pass/fail gates; no package reaches broad release without a signed sign-off record.

## What's inside

- **Solution Overview** — the standards layer, its four control points (intake, build, release,
  operate), the three delivery formats governed (Win32, MSIX, Microsoft Store) plus the legacy LOB/MSI
  type being retired, and what the standard produces.
- **Requirements Guide** — a named standard owner, two reviewers, the Graph SDK and scopes,
  packager-vs-approver RBAC, a retained-evidence document store, a real pilot population, the
  Government-cloud Microsoft Store position, an agreed category taxonomy, and a baseline audit — each
  with verify / implement-if-missing.
- **Implementation Guide** — the tenant objects, then the format decision tree and matrix, the
  naming/version/metadata standard, the detection-rule acceptability rules and **ten banned
  patterns**, the command/return-code/reboot standards, a reusable **Package Intake & Specification
  template**, a **five-gate acceptance checklist**, a **peer-review and sign-off** process with
  retained evidence, ring and assignment-hygiene rules, and an enforcement and audit cadence with an
  exceptions register.
- **5 PowerShell scripts** (Microsoft Graph) — a package-standard compliance auditor, a detection-rule
  quality checker, an assignment-hygiene reporter, a metadata-completeness scorer, and a
  preview-by-default metadata remediation tool (changes nothing without an explicit apply).
- **Testing & Troubleshooting Guides** with explicit pass/fail gates.

## Scoped to avoid overlap

This is the **standards layer**. The hands-on mechanics of packaging a single app — the Content Prep
Tool, install/uninstall commands, authoring one detection rule, supersedence — are a separate,
complementary discipline. This product governs the org-wide standard; it does not duplicate per-app
packaging.

## The bottom line

An app catalog that a new starter can pick up in days, an auditor can answer questions about in
minutes, and a growing team can extend without it becoming a liability — because the standard, the
templates, the quality gates, and the audit scripts are all in place from the first package onward.

## Pricing

| Tier | Price | SKU |
|---|---|---|
| Commercial | $2,495.00 | `PTK-APPSTD-COMM-001` |
| Non-Profit (−40%) | $1,497.00 | `PTK-APPSTD-NPO-001` |
| Government (−15%) | $2,120.75 | `PTK-APPSTD-GOV-001` |

Delivered as a Word document and PDF, plus all five PowerShell scripts in a single ZIP — yours to keep
and reuse across unlimited packages.
