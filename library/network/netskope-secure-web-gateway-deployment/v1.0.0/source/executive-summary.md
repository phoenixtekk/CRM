# Executive Summary — Netskope Secure Web Gateway (SWG) Deployment & Web Filtering

Web traffic is where most threats and most data loss start, yet many organizations still rely on
patchy filtering that remote users bypass the moment they leave the office. The result is
inconsistent policy, threats that slip in over HTTPS, and no control once a laptop is off the
corporate network.

The `Netskope Secure Web Gateway (SWG)` solves this by putting every user's web traffic behind one
cloud-delivered chokepoint: URL categorization, a web-filtering policy, threat and content controls,
and consistent enforcement whether the user is on or off the corporate network. This package stands
that gateway up the repeatable way — pilot-first and rollback-ready, because inline proxy affects
live traffic.

This is a complete, deploy-it-today package written for a competent network/security engineer with
no prior Netskope experience. The Microsoft side (identity, client and certificate delivery, and
steering scope) is given as exact navigation; the Netskope console internals are given as the correct
architectural and procedural steps with the precise control named, and deferred to Netskope's
official documentation for the exact current screen.

## What you get
- A plain-language `Solution Overview` of how a cloud SWG works: traffic steering, URL
  categorization, web-filtering policy, threat/content controls, and on/off-network enforcement.
- A `Requirements Guide` with verify / implement-if-missing for every prerequisite.
- An `Implementation Guide` of precise, ordered steps across Netskope, Entra ID, and Intune.
- Five `PowerShell scripts` for readiness discovery, client/steering validation, a web-traffic and
  policy-coverage report, safe remediation of mis-steered devices, and a steering-scope group builder.
- `Testing` and `Troubleshooting` guides with explicit pass/fail gates.

## What this delivers
A cloud secure web gateway with a named, reusable set of artifacts — a steering scope, a URL
categorization profile, a web-filtering policy, and threat/content controls — proven on a pilot group
before it is expanded fleet-wide, with a documented rollback at every stage.

## The deployment model
`Assess → Configure → Pilot → Validate → Expand`, with a pilot gate before any fleet rollout.

## Outcome
Every user's web traffic behind one cloud secure web gateway — categorized, filtered, and
consistently enforced wherever they work — proven on a pilot before you scale.
