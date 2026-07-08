# 6. Troubleshooting — Microsoft Purview Automation Framework

The failure modes that make automated Purview ops **fail closed, drift, or over-reach** — plus the
toolchain, config-validation, deploy, and enforcement issues you'll hit running policy management through
Graph + PowerShell. Each: **symptom → likely cause → fix.** The framework is **safe by default** — every
write runs in `-WhatIf` until `-Commit`, and nothing **enforces** without a separate, explicit
`-Enforce -Commit` — so most "it did the wrong thing" reports are a config error caught in the dry-run,
not a live incident.

## `OPSAUTO-Health.ps1` shows a red item
- **Cause:** a missing module, a failed `Connect-IPPSSession`/`Connect-MgGraph`, a missing role for a
  policy type, or a missing license.
- **Fix:** resolve the specific red item **before** proceeding — `Install-Module ExchangeOnlineManagement`
  / `Install-Module Microsoft.Graph` (Requirement 2.3), complete modern-auth, assign the least-privilege
  role for the policy types you manage (Requirement 2.2), confirm E5/E5-Compliance where the config needs
  it (Requirement 2.1). Do not run the deploy path until health is green for the types your config targets.

## `-ValidateConfigOnly` fails or flags entries
- **Cause:** the desired-state config (`Automation Config – Purview Ops – Baseline`) is malformed, missing
  a required field (name/type/scope/mode), or contains an entry that needs **E5**.
- **Fix:** this check makes **no tenant calls** — fix the JSON: every policy needs `name`, `type`
  (`dlp`/`label`/`labelPolicy`/`retention`), `scope` (`Pilot`/`Full`), and its target mode. E5-flagged
  entries stay out until licensed. Re-run `-ValidateConfigOnly` until clean before any `-WhatIf`.

## `-WhatIf` prints changes I didn't expect
- **Cause:** the config's names, locations, or modes don't match intent — e.g. a location is tenant-wide
  when you meant the pilot subset, or a DLP mode is `Enable` when it should be test/simulation.
- **Fix:** `-WhatIf` is the gate — **review every planned `New-/Set-*` line.** Confirm names match the
  config, locations are the **pilot** scope (not tenant-wide), DLP is targeted at **test/simulation mode**,
  labels **unpublished**, retention **unenforced/pilot-scoped**. Only then re-run with `-Commit`.

## A policy deployed but in the wrong mode / already enforcing
- **Cause:** the safe-first deploy and the enforce step were conflated, or a portal edit changed the mode.
- **Fix:** the design separates them deliberately — `-Commit` (safe-first) creates DLP in **test/simulation
  mode**, labels **unpublished**, retention **pilot-scoped**; only `-Enforce -Commit` turns on real
  user/data impact. `OPSAUTO-Validate.ps1` reports the **MODE-MISMATCH**; move it back to safe-first, then
  enforce deliberately. **Rollback:** re-run without `-Enforce` (`-Commit`) to return to test mode / unpublish.

## `OPSAUTO-Validate.ps1` reports drift
- **Cause:** a policy was edited in the portal, disabled, un-published, removed from a label policy, or a
  managed-name object exists in the tenant but not in the config (`EXTRA`).
- **Fix:** read the drift categories — **MISSING** (in config, not deployed → re-run deploy),
  **MODE-MISMATCH** (wrong mode → correct via deploy or update the config's expectation), **EXTRA**
  (investigate with the owner; it may be an out-of-band change). The config is the source of truth; changes
  flow through the gated deploy path, not the portal. **Verify expected DLP mode values for your tenant.**

## `OPSAUTO-Report.ps1` scorecard shows present < expected, or unexpected enforced count
- **Cause A — not deployed yet.** Expected-but-missing policies show as `MISSING` in the inventory.
  **Fix:** run the safe-first deploy for the scope, then re-report.
- **Cause B — enforced count higher than intended.** A DLP policy is in `Enable` mode when the pilot should
  still be test/simulation. **Fix:** confirm this was a deliberate `-Enforce -Commit`; if not, return it to
  test mode. The scorecard's "in expected mode" vs "enforced in tenant" is the safe-first check.
- **Cause C — EXTRA managed-style names.** An `Automation *`-named object exists that the config doesn't
  track. **Fix:** reconcile with the owner — bring it into config or remove it via the gated path.

## `-Enforce -Commit` caused user/data impact you didn't want
- **Cause:** enforcement was widened before the pilot was reconciled and reviewed.
- **Fix:** enforce is the **one** step that turns on real impact and it is pilot-scoped by design. **Rollback:**
  re-run without `-Enforce` (`-Commit`) to return DLP to test mode / unpublish labels / unpublish retention;
  or `-Remove -Commit` to delete the managed objects (it touches only config-managed objects, never
  pre-existing unmanaged policies). Reconcile and review the simulation results before re-enforcing.

## `-Remove -Commit` didn't delete a policy I expected
- **Cause:** the framework only removes **config-managed** objects; a pre-existing unmanaged policy is left
  untouched by design (it never created it).
- **Fix:** this is intentional — the framework will not delete objects it didn't create. Remove genuinely
  unmanaged policies deliberately in the portal under change control.

## Scheduled read-only chain didn't run / drift caught late
- **Cause:** the cadence (`Discovery → Validate → Report`) wasn't scheduled, or the account's token expired.
- **Fix:** schedule the read-only chain (daily/weekly) so a portal edit, disable, un-publish, or removal is
  caught early; confirm the account can complete modern-auth/MFA unattended (or run it interactively on
  cadence). Drift found late is a monitoring gap, not a tool fault.

## `Connect-IPPSSession` / `Connect-MgGraph` fails mid-run
- **Cause:** module not installed, MFA/modern-auth not completed, or a throttled/expired session.
- **Fix:** install the modules, complete the interactive sign-in (Requirement 2.3), and re-run. Scripts are
  read-only or `-WhatIf` by default, so a failed connect is safe to retry. **No credentials in code.**

## When to escalate beyond this solution
- **What a policy should *contain*** — info types, retention durations, label taxonomy, insider-risk
  conditions → **compliance, records, privacy, and legal**. The framework records and deploys those
  decisions; it does not make them.
- **Whether to enforce tenant-wide** → the policy owners + change control, after a reconciled, reviewed
  pilot.
- **A cmdlet or DLP mode value that has genuinely changed** → verify against current Microsoft
  documentation; DLP modes and policy cmdlets evolve and are licensing-dependent.
