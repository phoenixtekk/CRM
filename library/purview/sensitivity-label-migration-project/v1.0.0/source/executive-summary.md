# Executive Summary — Sensitivity Label Migration Project (Microsoft Purview)

## The problem
Most organizations classified their content **before** Microsoft Purview — with an on-premises or
third-party classification tool, or an older Microsoft labeling client. Those legacy markings are not
Purview sensitivity labels: they don't drive Purview encryption, DLP, retention, or Copilot data
protection, and they leave the estate running **two classification schemes at once**. That is a
compliance gap (governance keyed off labels the platform can't read) and a data-risk exposure (content
the new controls can't see) — and legacy labels **do not convert themselves**; there is no supported
button that turns a third-party marking into a Purview label.

## The solution
A complete, self-guided project that **maps** every legacy/third-party classification value to a target
Microsoft Purview **sensitivity label** and **reclassifies** the content onto those labels. It builds a
detection for each legacy value, an auto-labeling policy that applies the mapped label wherever that
detection fires, and — critically — runs the whole reclassification **in simulation first**, measuring
precision before a single file is touched. It uses only the Microsoft Purview portal and Security &
Compliance PowerShell — no third-party tooling on the target side.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce).** Inventory both sides — the legacy values (from the source tool's export)
and the target Purview estate; build a **mapping matrix** (each legacy value → one existing label) and
choose a **detection** per value; configure the reclassification auto-labeling **in simulation**; let it
scan and **measure precision** with the data owner; validate coverage; then **enforce from simulation**
to reclassify, expanding location-by-location. Five PowerShell tools — read-only or `-WhatIf` by
default — automate the two-sided inventory, the simulation-first configuration, the coverage/precision
reporting, and the health checks.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five Security & Compliance PowerShell tools: two-sided inventory, reclassification config/remediation helper (simulation-first), simulation & health helper, coverage & precision report, and a mapping-health check.
- A named, gated, reversible migration with explicit pass/fail criteria — and a precision sign-off gate before any content is reclassified.

## Business outcome
**One classification scheme the platform actually governs.** Legacy markings are mapped and content is
reclassified onto Microsoft Purview labels — proven in simulation before enforcement, so nothing is
mislabeled and no one is surprised by new encryption. Purview's controls (DLP, retention, Copilot
protection) can then key off labels the platform understands — at a fraction of the cost of a bespoke
consulting engagement.

## Important boundaries
Whether a mapped label should **encrypt** or reproduce the legacy tool's protection, and whether a
value is a "record," are **determinations owned by your records, security, compliance, and legal
functions** — this solution provides the mapping method, detection, and evidence, not the
determination. The reclassification engine (service-side auto-labeling) is **licensing-dependent**
(E5 / E5 Compliance), the destination labels are assumed to already exist, and whether a given legacy
marking is even **detectable** depends on the source tool — all flagged "verify your licensing/tenant"
and proven in simulation, never assumed.
