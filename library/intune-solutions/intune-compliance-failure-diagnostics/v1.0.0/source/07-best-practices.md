# Best Practices

These practices keep compliance both **enforced** and **diagnosable** — so failures are
rare, explained fast, and never "fixed" by weakening protection for everyone.

## 1. Diagnose to the setting, always

Never act on "non-compliant" alone. The first move is always to read the **per-setting
state and the exact reason string**. The device is only as compliant as its worst setting;
if you do not know which setting failed, you cannot fix the right thing — and you risk
disabling a whole policy to chase one setting.

## 2. Use grace deliberately, not as a hiding place

- Set a **grace period** (Actions for noncompliance) that matches how long a legitimate fix
  realistically takes (for example `1–3 days` for BitLocker to finish encrypting), so a
  transient/in-progress state does not instantly block a user.
- **Never extend grace to mask a real, persistent failure.** Grace buys time to fix the
  cause; it is not a remediation. A setting failing quietly inside grace is a ticking clock —
  fix it before it expires (this is the classic "worked yesterday, blocked today" story).
- Keep grace **consistent** within a policy so the evaluation timing is predictable.

## 3. Enforce in stages: Assess → Configure → Pilot → Validate → Expand

- Roll out new or tightened compliance settings to a **pilot group first**, watch the
  per-setting status, then expand. A setting that fails 500 devices at once is almost always
  a rollout that skipped piloting.
- Stage grace changes and Custom compliance script/JSON updates the same way.

## 4. Never disable or loosen policy fleet-wide to unblock one device

This is the cardinal rule. Fix the **cause** (the device, the rule, or the targeting), not
the policy. To unblock a single device fast without stripping protection:
- Fix the real setting on the device and force a sync; or
- Move the device to a correctly-scoped pilot/target group; or
- Apply a *temporary, pilot-scoped* exception — never a global disable.

## 5. Understand the three clocks

Keep **device evaluation**, **report freshness**, and **CA token/sign-in** separate in your
head. Most "I fixed it but it's still blocked" reports are one clock that has not ticked:
force a sync, wait for the report, then have the user re-sign-in so CA re-reads the state.

## 6. Keep built-in and Custom compliance rules distinct

- Prefer **built-in settings** where they exist — they evaluate reliably and report clear
  reasons.
- For **Custom compliance**, treat the **script + JSON** as code: validate the script
  returns valid JSON, use correct operators/data types, and author a helpful
  **RemediationString** so the per-setting reason tells the help desk what to do. An
  **Error** state means the rule could not evaluate — that is a script/agent bug, not a
  compliance verdict.

## 7. Map the Conditional Access blast radius before you act

Know which enabled CA policies **Require device to be marked as compliant**, and who they
target, *before* a device goes non-compliant. Then an incident is "this device is blocked
from these resources for these users," not a surprise. Review CA scope and compliance
policies together, periodically.

## 8. Keep the toolkit read-only by default

Run Discovery, Validation, and Report freely — they only read. Keep Remediation and
Set-ScopeTargeting on their **-WhatIf** default; review the planned change, then commit
explicitly. This makes diagnosis safe to run any time, including during an active incident.

## 9. Document the resolution

For each incident record: the **failing setting + reason**, whether it was **timing / grace
/ real failure / custom-rule / CA**, the **fix applied**, and the **blast radius**. Patterns
across incidents tell you which setting to harden at the source (Best Practice 3) so the
same failure stops recurring.
