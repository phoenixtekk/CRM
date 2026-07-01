# Executive Summary — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

Replacing a legacy web-filtering platform is one of the riskiest changes a network team makes.
Leave the old agent and the new agent both running and they fight over the same outbound traffic;
cut over too fast and you open a gap in protection or break access for users. This package gives
you a controlled, repeatable migration from Forcepoint Neo to Netskope: translate the existing
web-filtering policy, manage agent coexistence so the two clients do not collide, steer traffic in
stages, validate parity, then decommission the legacy platform once Netskope is proven.

This is a complete, deploy-it-the-repeatable-way package, written for an administrator with no prior
migration experience. Netskope and Forcepoint console internals are deferred to each vendor's
official documentation; the work here is authored at the architectural and procedural level and
driven from endpoint agent state and exported policy.

## What you get
- A plain-language Solution Overview of the migration model, policy translation, agent coexistence and steering conflicts, and the staged cutover and decommission.
- A Requirements Guide with Description, Why, Verify, and Implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: inventory and translate legacy policy, stand up Netskope policy, steer traffic in stages, validate parity, decommission Forcepoint, then expand.
- Five PowerShell scripts for legacy-agent and policy discovery, post-migration parity validation, a migration coverage and conflict report, safe remediation (remove the legacy agent), and a migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
A staged migration with named, reusable artifacts — a translated policy set, migration rings, and
device groups — moving each ring from `Forcepoint-steered` to `Netskope-steered` only after parity
passes, with the legacy agent removed per ring and the platform decommissioned only after a final
pilot/parity gate. A documented rollback restores the prior steering at every stage.

## The standard deployment model
`Assess -> Configure -> Pilot -> Validate -> Expand.`

## Outcome
Web filtering moved off Forcepoint Neo to Netskope with no gap in protection — policy translated,
agents coexisting then cut over in stages, parity validated, and the legacy platform decommissioned
— proven on a pilot before you scale.
