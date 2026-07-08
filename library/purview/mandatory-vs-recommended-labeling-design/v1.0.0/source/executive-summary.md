# Executive Summary — Mandatory vs Recommended Labeling Policy Design (Microsoft Purview)

## The problem
A sensitivity-label taxonomy only protects content that actually gets labelled — and it is the label
**policy**, not the label, that decides application rates. Organisations get this wrong in both
directions. Mandate labels everywhere and users click the first (lowest) label just to dismiss the
prompt, corrupting the classification data and flooding the help desk; mandate nothing and content
stays unlabelled, so DLP, encryption, and retention have nothing to key off. Left unaddressed, this is
a compliance gap and a data-risk exposure.

## The solution
A complete, self-guided design and configuration of the **label-policy behaviour** that balances the
two: **mandatory labeling** where the risk justifies friction, **recommended (prompt) labeling** where
a nudge is enough, a sensible **default label** so nothing is silently unclassified, and **downgrade
justification** for an audit trail. It decides *where to require a label versus suggest one* — a
mandatory-vs-recommended matrix — and configures each lever, piloted on a ring and validated before it
touches everyone. It uses only the Microsoft Purview portal and Security & Compliance PowerShell — no
third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot → Validate →
Expand.** Assess the current label-policy posture; design a signed-off mandatory-vs-recommended matrix
(defaults, downgrade rules, prompts); configure the settings on a **pilot policy scoped to a pilot
ring**; validate the *friction* (ticket volume, send-blocking, mislabel rate) as well as the effective
settings; then expand the accepted settings to the broad policy. Because label-policy settings have
**no simulation mode**, the pilot ring is the safety mechanism — every write is previewed with
`-WhatIf` first. Five PowerShell tools — read-only or `-WhatIf` by default — automate discovery,
configuration, effective-settings validation, posture reporting, and a policy-conflict health check.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five Security & Compliance PowerShell tools: posture assessment, a configuration/remediation helper (mandatory/default/downgrade/recommend), effective-settings validation, posture-matrix reporting, and a policy-conflict health helper.
- A named, gated, reversible rollout with explicit pass/fail criteria at every step.

## Business outcome
High classification rates **without a user revolt** — labels required where they matter, suggested
where a nudge suffices, defaulted so nothing escapes unlabelled, and downgrades evidenced. The policy
design is configured, piloted, validated, and defensible — at a fraction of the cost of a bespoke
consulting engagement.

## Important boundaries
Which populations *should* be mandated, the enterprise default classification, and the downgrade rules
are **determinations owned by your compliance, security, and records functions** — this solution
provides the technical configuration method and evidence, not the determination. The label taxonomy,
encryption, and retention are assumed to exist (separate solutions). Recommended (client-side) labeling
with advanced conditions is **licensing-dependent** (E5 / E5 Compliance) and the Purview portal is
evolving — availability, portal paths, and advanced-setting keys are flagged "verify your
licensing/tenant," never assumed.
