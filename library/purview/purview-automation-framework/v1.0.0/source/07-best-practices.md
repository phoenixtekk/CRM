# 7. Best Practices — Automating Microsoft Purview Operations Safely

Operating principles for running Purview policy operations as repeatable, reversible, evidenced code.
Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce)** model.

## Treat policy as reviewable code
- Keep the **desired-state config** (`Automation Config – Purview Ops – Baseline`) in version control and change it through a review flow: edit → `-ValidateConfigOnly` → `-WhatIf` → `-Commit` (safe-first) → validate → `-Enforce -Commit`. The config, not the portal, is the source of truth.
- One config, many environments — the same config deployed to pilot and production means production is not a hand-rebuilt approximation of what you tested.

## Deploy safe-first, enforce deliberately
- **Never let deploy and enforce be the same action.** The framework deploys DLP in **test/simulation mode**, labels **unpublished**, retention **unenforced/pilot-scoped** by default; enforcing is a separate, explicit `-Enforce -Commit`. Keep it that way — it is the single biggest guard against a high-impact mistake.
- Always **`-WhatIf` first** and read the plan. The plan is your last cheap chance to catch a tenant-wide scope, a wrong mode, or an unintended enforce.
- **Review DLP simulation/test results** with the policy owners before enforcing — a rule that looks right in config can match far more (or less) than intended. **Verify the simulation behavior in your tenant**; mode values and the simulation experience evolve.

## Pilot small, expand under control
- Prove the whole flow on `Automation Pilot – Ops Scope – Stage1` — a few locations/users/policies — before touching full scope. Pilot-first is not optional for DLP/label/retention changes; they hit real users and data on enforce.
- Expand only after the pilot validates drift-free, the scorecard is green, and the pilot enforce gate is clean. Re-run the safe-first + validate cycle at full scope; don't jump straight to enforce.

## Make drift visible
- Schedule the **read-only chain** (Discovery → Validate → Report) so a portal edit, a disabled policy, an unpublished label policy, or a removed rule surfaces as reported drift rather than an audit-day surprise.
- Investigate **extra** objects (policies in the tenant the config doesn't know about) with their owners — either bring them under config management or retire them; unmanaged policies are how drift accumulates.

## Manage only what you own — and know the boundary
- The framework touches **only config-managed objects**; it does not delete or alter unmanaged pre-existing policies. Keep that discipline so automation can never surprise you by removing something it didn't create.
- **Records-management file plans, insider-risk, and communication-compliance are out of automated scope** — they encode legal/HR/records determinations. Inventory and report on them if you must, but manage them under their own governance.

## Least-privilege and separation
- Run the **read-only tools** (Health, Discovery, Validate, Report) under a **view-only** role; run **Deploy** under the write role for that policy type; reserve Global Administrator for exceptions. The read/write split limits blast radius and makes the scheduled cadence safe.
- Access to policy configuration is sensitive — review role membership periodically and keep the deploy path auditable (every change is a committed config edit + a `-WhatIf`/`-Commit` transcript).

## Keep decisions where they belong
- The framework **carries** compliance/records/legal decisions and **proves** they landed; it does not make them. *Which* info types, *which* retention duration, *which* labels — and legal adequacy — stay with **compliance, records, privacy, and legal**. Record the owner per policy in the config.
- Verify the config against **current Microsoft documentation** periodically — Purview cmdlet parameters, DLP mode values, and capability availability change; a config that deployed cleanly last quarter may need updating.

## No secrets, ever
- The tools use **interactive modern-auth / MFA** sign-in; **no client secrets or credentials in code or config**. If you later automate unattended runs, use a certificate-based app identity with least-privilege scopes and store the certificate outside the repo — never a secret in the config file.
