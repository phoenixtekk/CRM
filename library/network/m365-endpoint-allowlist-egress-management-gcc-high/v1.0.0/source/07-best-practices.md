# Best Practices — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

Field-proven practices for running a GCC High allow-list well. They reinforce one idea: **derive, don't
hardcode; verify the cloud; keep the blast radius small.**

## Query the right cloud — every time

- **Always use the `USGovGCCHigh` instance.** The default and `Worldwide` instances are the wrong
  cloud. Bake the instance name into scripts and scheduled jobs so no one can accidentally query
  Commercial.
- **Sanity-check the instance in every run.** The scripts confirm the returned `instance` is
  `USGovGCCHigh` before doing anything else. Keep that check.
- **Trust `*.us` / `*.microsoft.us`, be suspicious of `.com`.** In GCC High, a `.com` M365 endpoint in
  your derived data almost always means you queried the wrong instance.

## Never hardcode Microsoft IP ranges

- Microsoft updates GCC High IP/URL data **monthly**, with additions published **30 days in advance**.
  A hand-typed list is a scheduled outage.
- Treat `EGRESSG-M365-GCCHigh-Allow` and `EGRESSG-M365-GCCHigh-URLs` as **machine-maintained** objects
  fed from the Discovery export. Humans review diffs; scripts produce data.
- The only names safe to reference by hand are Microsoft's **documented, stable Gov FQDNs** (portals,
  identity, Intune/Defender service names) — and even those you cross-check against the derived set.

## Respect the SSL-inspection bypass list

- Microsoft **does not support** inspecting `*.manage.microsoft.us`, `has.spserv.microsoft.com`, or
  `*.dm.microsoft.us`. Inspecting them breaks Intune, Defender, and Endpoint Privilege Management.
- Apply `EGRESSG-NoInspect-GCCHigh` **before** enabling inspection anywhere near M365 traffic, not
  after users report breakage.
- When Microsoft publishes a new Gov no-inspect endpoint, add it and **verify for GCC High** against
  current Gov documentation.

## Pilot first, always

- Roll out to `EGRESSG-Pilot` before the fleet (Global Requirement G6). Egress changes affect live
  traffic; a small blast radius is your safety net.
- Keep the pilot representative (a range of OSes, sites, and roles), not just IT machines.
- Validate from a **real endpoint behind the filtered path** — not from the management jump box, which
  usually has open egress and hides problems.

## Keep the 30-day window

- Schedule Discovery frequently enough (weekly is comfortable) that you always catch additions inside
  their 30-day advance window.
- Review diffs promptly. The point of the advance window is to apply changes **before** the endpoints
  go live — not to discover them during an outage.

## Name objects consistently and document them

- Use the `EGRESSG-*` object names throughout so the allow-list is auditable and every step references
  the same objects.
- Keep the Discovery export, the Report output, and the change record together for audit and change
  control (essential in a government compliance context).

## Least privilege and separation

- Discovery, Validation, and Report are **read-only** — run them with reader-level access.
- Reserve device-configuration rights for the person applying the allow-list, and reserve Global
  Administrator for tenant-wide changes only.
- `Set-ScopeTargeting` and `Remediation` default to **`-WhatIf`** — keep it that way; require an
  explicit `-Execute`/`-Execute`-equivalent flag to make changes.

## Watch for parity gaps

- Do not assume a Commercial capability exists or behaves identically in GCC High. Where behavior is
  unconfirmed, treat it as **"verify for GCC High"** and check current Microsoft Gov documentation
  before relying on it.
- ExpressRoute support, feature availability, and some service FQDNs differ between clouds — derive and
  verify rather than carrying over Commercial assumptions.

## Have a rollback ready

- Write and approve the rollback (revert allow-list, disable inspection change, restore prior policy)
  **before** enabling enforcement (Global Requirement G7).
- After any egress-device change, run the regression test in `05-testing.md`. If it fails, roll back
  first, diagnose second.
