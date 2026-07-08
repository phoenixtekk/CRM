# 6. Troubleshooting Guide — Automatic Sensitivity Labeling at Scale (Microsoft Purview)

Field issues and how to resolve them, in roughly the order you are likely to hit them. Every check here
is safe: read-only (`IPAUTO-Discovery.ps1`, `IPAUTO-Validate.ps1`, `IPAUTO-Report.ps1`,
`IPAUTO-ScopeHealth.ps1`), a `-WhatIf`/preview (`IPAUTO-Configure.ps1` without `-Commit`), or a controlled
change on the pilot scope. Nothing here labels content by surprise. When a portal path, mode value, or
cmdlet parameter differs from this guide, **verify it in your tenant** — automatic labeling is
E5/E5 Compliance and the portal is evolving.

## The target label isn't found by the scripts
**Symptom:** `IPAUTO-Discovery.ps1` or `IPAUTO-Configure.ps1` reports the target label
(`Confidential \ All Employees`) as NOT found, and refuses to build a policy.
**Cause:** Auto-labeling can only apply an **existing, published** label (§2.1). The label may not exist,
may be unpublished, or you may be passing the display name where the internal `Name`/GUID is expected.
**Fix:** Run `IPAUTO-Discovery.ps1 -TargetLabel "Confidential \ All Employees"` and read the labels list;
confirm with `Get-Label` and `Get-LabelPolicy` that the label exists and is published. If it is missing,
complete the labels prerequisite first (a separate labels-implementation effort) — do not proceed. Pass
the exact name the inventory shows.

## `Get-AutoSensitivityLabelPolicy` / `New-AutoSensitivityLabelPolicy` is not available
**Symptom:** A script prints "Get-AutoSensitivityLabelPolicy not available — check licensing/role", or the
cmdlet errors.
**Cause:** Either you are not connected to Security & Compliance PowerShell, or the account/tenant lacks
the plan/role for **automatic** labeling (E5 / E5 Compliance; **Information Protection Admin** role —
§2.2/§2.3).
**Fix:** `Connect-IPPSSession` with a modern-auth admin; confirm the account is in the Information
Protection role group and the tenant is licensed for auto-labeling. Then re-run
`IPAUTO-ScopeHealth.ps1 -PolicyName "<name>"` — its readiness flags confirm the cmdlets resolve. Microsoft's
licensing tables are the authority — **verify your licensing/tenant.**

## A service-side policy is already `Enable` before sign-off
**Symptom:** `IPAUTO-Validate.ps1 -PolicyName "<name>" -ExpectMode Simulation` returns **FAIL** on the
"Mode is SIMULATION" check — the policy is enforcing when it should still be simulating.
**Cause:** The policy was enforced (or created) outside the simulation-first flow, so it is labeling
content before the match set was accepted (§2.7).
**Fix:** Return it to simulation immediately:
`IPAUTO-Configure.ps1 -ServiceSide -PolicyName "<name>" -BackToSimulation -Commit` (runs
`Set-AutoSensitivityLabelPolicy -Mode TestWithoutNotifications`). Note this **stops new labeling but does
not un-label** already-labeled content. Then investigate who enforced it and re-run `IPAUTO-Validate.ps1`.

## Simulation has produced no match set yet
**Symptom:** `IPAUTO-Validate.ps1` flags "Simulation scan/match signal present" as not yet satisfied, or
`IPAUTO-Report.ps1` shows a blank/zero match count.
**Cause:** Service-side scanning is **not instant** and is subject to item/throughput limits; the scan may
still be running, or the in-scope locations may contain no matching content.
**Fix:** Allow scan time and re-run `IPAUTO-Report.ps1 -PolicyName "<name>"`. Confirm the in-scope
locations actually hold content that matches the rule (SIT + `-MinCount`). A zero count often means "still
scanning", not "nothing matches" — **verify current scan limits/latency for your tenant** before
concluding the policy is broken.

## Simulation precision is poor — too many false positives (or misses)
**Symptom:** In the `IPAUTO-Report.ps1` match set, the data owner sees content that should **not** get the
label (false positives) or obvious sensitive content missed (false negatives).
**Cause:** The rule conditions are too broad, too narrow, or built on a thin/noisy sensitive-information
type — precision is entirely a function of the conditions (§2.5).
**Fix:** Tune the rule and re-simulate:
`IPAUTO-Configure.ps1 -ServiceSide -PolicyName "<name>" -RuleName "<rule>" -UpdateRule -Sit "<better SIT>" -MinCount <higher N> -Commit`
(raise `-MinCount`, use a higher-confidence or more specific SIT, add keywords, or a trainable classifier).
Let simulation re-run, then re-review with `IPAUTO-Report.ps1` and `IPAUTO-Validate.ps1`. **This is the
gate before any enforcement (Testing Test 5).** Which content is truly sensitive remains the data owner's
determination.

## Client-side auto-labeling isn't recommending in Office
**Symptom:** A pilot user editing matching content is not prompted with the label; `IPAUTO-Configure.ps1
-ClientSide` appeared to run.
**Cause:** The label's client-side auto-labeling condition wasn't set, the user's label policy doesn't
publish that label, Office needs to refresh its policy, or the Office build is too old for the feature.
**Fix:** Confirm the condition in the portal (**Information Protection → Labels → the label →
Auto-labeling for files and emails** — **verify this path in your tenant**). Confirm the label is published
to that user (`Get-LabelPolicy`). Have the user restart Office to refresh policy, and confirm a supported
Office build. Note that `IPAUTO-Configure.ps1 -ClientSide` deliberately previews/`-WhatIf`s the `Set-Label`
change because the **exact auto-labeling parameter surface is version-sensitive** — supply your tenant's
confirmed parameters to actually apply it, then re-test.

## Enforced labels don't match what simulation predicted
**Symptom:** After enforcing on the pilot subset, spot-checks show labels applied to items simulation did
not flag (or vice-versa).
**Cause:** The rule or scope changed between the accepted simulation and enforcement, or scan drift/latency
means the two snapshots differ.
**Fix:** Roll back first — `IPAUTO-Configure.ps1 -ServiceSide -PolicyName "<name>" -BackToSimulation
-Commit` — then compare the current rule against the accepted design, re-simulate, and re-validate with
`IPAUTO-Report.ps1` before re-enforcing. Do not expand scope until pilot enforcement equals the accepted
simulation (Testing Test 7).

## The policy is enforcing on the wrong locations
**Symptom:** `IPAUTO-ScopeHealth.ps1 -PolicyName "<name>"` shows `ALL — tenant-wide` when you intended a
pilot subset, or the wrong sites/mailboxes are targeted.
**Cause:** The location/scope parameters were set to `All` (or the wrong subset), or an adaptive scope
resolves more broadly than expected. Location parameter names are **tenant/version-sensitive**.
**Fix:** Re-scope with `IPAUTO-Configure.ps1 -ServiceSide -PolicyName "<name>" -Enforce -Locations "<pilot
site urls>" -WhatIf`, review the previewed `Set-AutoSensitivityLabelPolicy` change, then `-Commit`. Re-run
`IPAUTO-ScopeHealth.ps1` and confirm the locations resolve to the intended subset. **Verify the current
location/adaptive-scope parameter names in your tenant** — `IPAUTO-ScopeHealth.ps1` flags any scope
property it cannot resolve rather than asserting one exists.

## Auto-labeling overwrote (or failed to upgrade) an existing manual label
**Symptom:** Content a user had manually labeled shows a different label after enforcement, or obviously
sensitive already-labeled content wasn't upgraded.
**Cause:** The policy's behavior toward existing/manually-set labels (§2.8) is not set as intended — this
behavior is configurable and **tenant/version-sensitive**.
**Fix:** Confirm the intended behavior with the data owner, set it on the policy (**verify the current
setting/parameter in your tenant**), and re-validate it against the **simulation** match set before
re-enforcing — inspect items that already carry a label in `IPAUTO-Report.ps1` output (Testing Test 6).
Whether a deliberate manual classification may be changed is a compliance/data-owner decision, not a
technical default.

## Rollback ran but content is still labeled
**Symptom:** You ran `-BackToSimulation -Commit` but previously labeled items still carry the label.
**Cause:** This is expected — returning a policy to simulation **stops new labeling; it does not un-label**
content already labeled while enforced.
**Fix:** Confirm the policy is back in simulation with `IPAUTO-Validate.ps1 -PolicyName "<name>"
-ExpectMode Simulation`. If specific items must be re-labeled or cleared, that is a separate, deliberate
action on those items (and, where the label encrypts, an access decision) — treat it as change-controlled,
not a side effect of rollback.

## Coverage is flat or zero after tenant-wide expansion
**Symptom:** After expanding to `All`, `IPAUTO-Report.ps1` shows label counts not climbing.
**Cause:** The policy may not actually be in `Enable`, the locations may not have expanded, matching
content may be sparse, or the scan is still catching up.
**Fix:** Run `IPAUTO-Validate.ps1 -PolicyName "<name>" -ExpectMode Enforce` (confirms `Enable`) and
`IPAUTO-ScopeHealth.ps1` (confirms locations resolve to `All`). Confirm matching content exists and allow
scan time; **re-check scan limits for your tenant.** Report on a cadence rather than judging from a single
snapshot.

---
### When to stop and escalate
- **Auto-labeling cmdlets/paths aren't available** (`New-AutoSensitivityLabelPolicy` missing, portal
  auto-labeling node absent) → this is a **licensing/tenant** action (E5 / E5 Compliance, Information
  Protection role). Record it and do not force a path that isn't there — **verify your licensing/tenant.**
- A question of **which content is sensitive, which label it should carry, or whether a manual label may
  be changed** is being asked of you → escalate to the **data owner / compliance / records / privacy**
  function. This solution provides the technical method to apply labels accurately and the evidence that
  it does — never the classification determination (§2 deferral).
- **A mode value, location parameter, or Set-Label auto-labeling parameter in this guide doesn't match
  your environment** → the Purview auto-labeling surface is evolving; confirm the current
  cmdlet/parameter against Microsoft's documentation and your tenant rather than assuming the step is
  wrong. The scripts never invent parameters — they preview the change and apply only what you confirm.
