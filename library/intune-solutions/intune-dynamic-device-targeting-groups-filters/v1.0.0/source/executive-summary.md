# Executive Summary — Dynamic Device Targeting in Intune (Dynamic Groups & Filters)

White-label · Intune Solutions

As a fleet grows, assigning policies and apps to hand-built static groups stops scaling: new
devices miss policy, membership drifts, and admins burn hours maintaining lists. The modern answer
is dynamic targeting — dynamic security groups whose membership rules auto-include the right
devices, and assignment filters that scope a single assignment to exactly the devices that match
(OS, ownership, model, enrollment profile).

This is a complete, deploy-it-today package for building a repeatable dynamic device targeting model
in Intune, written for an administrator with no prior experience in membership-rule or filter-rule
syntax.

## What you get
- A plain-language Solution Overview of dynamic security groups vs. assignment filters, when to use
  each, precedence and evaluation, and a scalable targeting taxonomy.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including
  Entra dynamic-group licensing and a device attribute/naming convention.
- An Implementation Guide of precise, click-by-click steps in the required order — define the
  taxonomy, build dynamic groups, create filters, apply filters to assignments, validate, expand.
- Five PowerShell scripts for dynamic-group/filter discovery, membership and effective-targeting
  validation, targeting-coverage and drift reporting, safe remediation of mis-scoped assignments,
  and a dynamic-group/filter builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A scalable targeting model — a named taxonomy of dynamic security groups (membership rules that
auto-include devices by attribute) and assignment filters (include/exclude by OS, ownership, model,
or enrollment profile at assignment time) — so policies and apps reach exactly the right devices
automatically and stay correct as the fleet changes, validated on a pilot before broad use.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Policies and apps that reach exactly the right devices automatically — dynamic groups and assignment
filters replacing hand-maintained static lists, staying correct as the fleet changes — deployable by
a single administrator and validated before broad rollout.
