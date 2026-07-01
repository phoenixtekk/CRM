# 2. Requirements Guide — New-Site Endpoint Rollout Playbook

Verify **every** requirement before you start a site rollout. Each entry: Description · Why ·
Verify · Implement-if-missing. Category-wide prerequisites are in
`global-requirements-infrastructure.md`. This playbook reuses your existing Intune standards — most
requirements below are about confirming those standards exist, not building new ones.

## 2.1 Intune licensing
Description: Microsoft Intune (Plan 1 or via Microsoft 365 E3/E5 or Business Premium).
Why: Intune delivers the device group targeting, baseline, app, and printer assignments the rollout
depends on.
Verify: Microsoft 365 admin center → **Billing → Licenses**; confirm an Intune-bearing plan.
Implement: Assign Microsoft 365 E3/E5 or Business Premium (Intune included), or standalone Intune
Plan 1.

## 2.2 Enrollment method for the new site
Description: A way to enroll the site's devices into Intune — Windows Autopilot, automatic
enrollment, or bulk enrollment.
Why: Provisioning (the second stage) cannot happen until devices can enroll.
Verify: Intune → **Devices → Enrollment → Windows**; confirm an enrollment method is configured
(Autopilot profile or automatic enrollment).
Implement: Configure **Automatic Enrollment** (Intune → Devices → Enrollment → Automatic
Enrollment, set MDM user scope), and/or import the site's devices as Autopilot devices.

## 2.3 Site network / identity readiness
Description: The site can reach Microsoft cloud endpoints and devices can sign in and enroll from
the site's network.
Why: This is the first dependency — provisioning, baseline, apps, and printing all fail if the site
cannot reach Microsoft Entra and Intune.
Verify: From a device on the site network, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; run `NEWSITE-Discovery.ps1` for an automated check.
Implement: Have the network team allow Microsoft's published Microsoft 365 / Intune URL and IP
ranges through the site proxy/firewall, and confirm the internet circuit and Wi-Fi are live.

## 2.4 Existing device baseline
Description: Your standard compliance policy, security baseline, and configuration profiles that the
rest of the fleet uses.
Why: The site inherits the fleet's baseline rather than getting a new one; this is what makes the
rollout repeatable.
Verify: Intune → **Devices → Compliance** and **Endpoint security → Security baselines**; confirm
your standard policies exist.
Implement: If no baseline exists, create your standard compliance policy and security baseline once
(this becomes the reusable baseline for all sites). The exact baseline is your organization's
standard and is out of scope for this playbook.

## 2.5 Site app set
Description: The list of applications the site's staff need, available as Intune apps.
Why: Apps are deployed to the site group during the apps/printers stage; they must already be
packaged in Intune.
Verify: Intune → **Apps → Windows**; confirm the site's required apps are present (Microsoft Store,
Win32, or line-of-business apps).
Implement: Add any missing apps (Intune → Apps → Windows → Add); reuse apps already in your catalog
where possible.

## 2.6 Site printer set and a printer deployment method
Description: The site's local printers and your existing way of deploying them — Universal Print or a
print-server / connector method.
Why: Printers are assigned to the site group during the apps/printers stage.
Verify: For Universal Print, Intune → **Devices → Configuration**; confirm a Universal Print printer
profile or your printer-deployment configuration exists. For a print server, confirm the connector
is in place.
Implement: Register the site's printers in your chosen print method and prepare a printer assignment
targetable to a device group. The playbook assigns to the site group; it does not change your print
architecture.

## 2.7 Site device group (created by this playbook)
Description: A Microsoft Entra device group scoped to the new site, named per the convention.
Why: It scopes every assignment to the site so one rollout never disturbs another.
Verify: Entra → **Groups**; confirm the site group exists (e.g. `New Site – Site A – Pilot`).
Implement: Create it manually (Entra → Groups → New group → Security) or run
`NEWSITE-Set-SiteGroupTargeting.ps1` to build it.

## 2.8 Go-live window and pilot designation
Description: A scheduled go-live date for the site, and a decision on which site is the pilot.
Why: The first site runs as the pilot and must pass the go-live gate before you scale; the window
sets the validation deadline.
Verify: Confirm with the business the site's open date and that the first site is treated as the
pilot.
Implement: Designate the first site as the pilot; schedule its go-live with enough lead time to run
validation and remediation before staff arrive.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Enrollment method configured for the site (Autopilot / automatic enrollment)
- [ ] Site network/identity reachable — `NEWSITE-Discovery.ps1`
- [ ] Existing baseline (compliance + security baseline) present
- [ ] Site app set available in Intune
- [ ] Site printer set + printer deployment method ready
- [ ] Site device group created (per naming convention)
- [ ] Go-live window scheduled; first site designated as pilot
