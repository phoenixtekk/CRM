# 1. Solution Overview — New-Site Endpoint Rollout Playbook

## What this playbook is
The New-Site Endpoint Rollout Playbook is a repeatable program for standing up Windows endpoints at
a new location — a new office, clinic, branch, or acquired site — using Microsoft Intune. Instead of
reinventing the rollout each time, you follow one sequenced process: confirm the site's network and
identity readiness, provision its devices, apply your existing device baseline, deploy the site's
apps and printers, validate that everything works, and run a go-live checklist before staff arrive.

It deliberately reuses the Intune standards you already have — your compliance policy, your security
baseline, your Autopilot/enrollment configuration, your printer deployment method — and adds only
the per-site coordination layer: a site device group, site-scoped assignments, validation, and the
go-live gate. The repeatable way to open a site is to make the rollout a program, not a one-off.

## The dependency order (why the sequence matters)
Each stage depends on the one before it; doing them out of order is the usual cause of a chaotic
go-live. The order is:

1. Network / identity readiness — the site can reach Microsoft cloud endpoints and devices can sign
   in and enroll. Nothing downstream works without this, so it is verified first.
2. Provisioning — devices are enrolled into Intune and placed in the site's device group.
3. Baseline — your standard compliance policy, security baseline, and configuration apply to the
   site's devices so they match the rest of the fleet.
4. Apps and printers — the site's required applications and its local printers deploy to the site
   group.
5. Validation — connectivity, identity sign-in, baseline state, app installs, and printing are
   confirmed per device.
6. Go-live checklist — a final gate; only when every item passes does the site open.

After the first site passes the gate, you expand: repeat the identical program for the next site by
cloning the site group and assignments and changing only the site name.

## How it works
- A per-site Microsoft Entra device group scopes every assignment to that site only, so one site's
  rollout never disturbs another.
- Existing baseline and configuration profiles are assigned to the new site group — you reuse them,
  you do not author new ones.
- The site's app set and printer set are deployed to the site group as required (auto-installed)
  assignments.
- Validation scripts confirm each device meets the go-live criteria; the go-live checklist is the
  final human gate.
- A status report shows, per site, how many devices are provisioned, baselined, app-ready, and
  validated — so you know at a glance whether the site is ready to open.

## What you control
- The per-site device group and the consistent naming of every object created for the site.
- Which existing baseline / configuration profiles are assigned to the site.
- The site's app set and printer set.
- The go-live criteria and the order in which sites are opened (pilot first, then expand).

## Object naming convention (use verbatim)
Every object you create for a site is named `<Purpose> – <Site> – <Stage>` so the tenant stays
readable as you add sites. Reuse these names exactly:

- Site device group (pilot site): `New Site – Site A – Pilot`
- Site device group (a later site): `New Site – Site B – Production`
- App deployment assignment: `App Deployment – Site A – Pilot`
- Printer deployment assignment: `Printer Deployment – Site A – Pilot`
- Baseline assignment: `Baseline Assignment – Site A – Pilot`

For the first site, the Stage is `Pilot`; for every site after the pilot validates, the Stage is
`Production`.

## Benefits
- Predictable go-live — endpoints work on day one because nothing is improvised.
- Repeatable — every site opens the same proven way; the second site is faster than the first.
- Low risk — the first site runs as a pilot and must pass a go-live gate before you scale.
- Reuses your standards — no new baseline to maintain; the site inherits the fleet's configuration.
- Visible — a per-site status report shows exactly how far each rollout has progressed.

## Limitations (be honest with buyers)
- This is a coordination playbook, not a replacement for your baseline — it assumes you already have
  a compliance policy, security baseline, and enrollment method in place (the Requirements Guide
  shows how to confirm or create them).
- It manages Windows endpoints through Intune; non-Windows platforms and on-premises-only servers
  are out of scope.
- Physical site readiness (cabling, internet circuit, Wi-Fi) must be delivered by the site/network
  team; the playbook verifies cloud reachability but does not install network hardware.
- Printer deployment uses your existing method (Universal Print or a print-server connector); the
  playbook assigns printers to the site group but does not change your print architecture.

## The deployment model
> Confirm network/identity → build the site device group → provision devices → apply baseline →
> deploy site apps and printers → validate → run the go-live checklist → expand to the next site.
> Model: Assess → Configure → Pilot → Validate → Expand — the first site is the pilot.
