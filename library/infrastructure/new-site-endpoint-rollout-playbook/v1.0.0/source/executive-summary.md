# Executive Summary — New-Site Endpoint Rollout Playbook (Microsoft Intune)

Opening a new office, clinic, branch, or acquired site usually means reinventing the endpoint
rollout from scratch — scrambling on go-live day and discovering missing apps, no printers, or
no network access while staff are already trying to work. This package replaces that scramble with
a repeatable program: a sequenced playbook that provisions the site's devices, applies your
existing baseline, deploys the site's apps and printers, validates connectivity and identity, and
runs a concrete go-live checklist — so every new location opens the same proven way.

This is a complete, deploy-it-today playbook for rolling out endpoints at a new site with Microsoft
Intune, written for an administrator with no prior site-rollout experience. It reuses the Intune
standards you already have rather than building anything new.

## What you get
- A plain-language Solution Overview of the new-site rollout model and its dependency order.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune steps in the required order.
- Five PowerShell scripts for site-readiness discovery, per-device go-live validation, a site
  rollout status report, safe remediation of failed deployments, and a site device-group builder.
- A concrete go-live checklist, plus Testing and Troubleshooting guides for confident rollout.

## What this delivers
A sequenced rollout — network/identity readiness, then provisioning, then your baseline, then the
site's apps and printers, then validation, then go-live — driven by a per-site device group and a
consistent object-naming convention. The first site runs as the pilot; once it passes the go-live
gate, you repeat the same program at every subsequent location.

## The deployment model
Assess → Configure → Pilot → Validate → Expand. The first site is the pilot.

## Outcome
Every new site opening with endpoints that work on day one — provisioned, baselined, app- and
printer-ready, and validated against a go-live checklist — proven on a pilot site before you repeat
it everywhere.
