# Deliverables Summary

Everything included in **Intune Compliance-Failure Diagnostics & Remediation**, and how the
pieces fit together.

## Documents

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** (`01`) | How compliance evaluation works end-to-end (policy → per-setting state → grace → device state → Conditional Access gate), the three clocks of evaluation timing, where every result surfaces, and the five-question diagnostic model. |
| **Requirements Guide** (`02`) | Each prerequisite — Intune roles, Entra/CA read roles, Graph read scopes, PowerShell + SDK, affected-device access, pilot group — with **Description / Why / Verify / Implement if missing**. |
| **Global Requirements** | Category-level prerequisites shared by all Intune solutions (tenant, subscription, enrollment, Windows baseline, network). |
| **Diagnostic Playbook** (`03`) | The symptom-driven decision tree: which setting failed, timing vs real failure, grace expiry, built-in vs Custom rule, and the Conditional Access blast radius — with exact clicks and script checks per branch. |
| **Testing & Validation** (`05`) | The three pass/fail gates — setting passes, device compliant, CA allows — plus regression checks that no policy was loosened fleet-wide. |
| **Troubleshooting** (`06`) | Fixes for problems running the toolkit itself: Graph consent, empty results, Error states, CA timing, grace masking, WhatIf previews. |
| **Best Practices** (`07`) | Grace discipline, staged enforcement, never-disable-fleet-wide, the three clocks, built-in vs Custom rules, mapping CA blast radius, read-only-by-default tooling. |

## PowerShell scripts

All scripts use the **Microsoft Graph PowerShell SDK**. Discovery, Validation, and Report are
**read-only**. Remediation and Set-ScopeTargeting default to **-WhatIf** (preview only) and
change nothing until you re-run with `-WhatIf:$false`.

| Script | Read/Write | Purpose |
|--------|-----------|---------|
| `INTCOMPDX-Discovery.ps1` | Read-only | Enumerate compliance policies, their settings, grace (Actions for noncompliance), assignments, and device compliance state. |
| `INTCOMPDX-Validation.ps1` | Read-only | For a device (or set), return the **per-setting** failure with the raw reason string, and flag built-in vs Custom vs Error states. |
| `INTCOMPDX-Report.ps1` | Read-only | Fleet compliance summary ranked by failing setting, **plus** the Conditional Access impact (which compliance-requiring CA policies exist and how many affected devices they touch). |
| `INTCOMPDX-Remediation.ps1` | Write (**-WhatIf** default) | Apply safe, common fixes (sync, re-target, staged grace) with a previewed plan before committing. |
| `INTCOMPDX-Set-ScopeTargeting.ps1` | Write (**-WhatIf** default) | Build/adjust pilot/target group assignments for staged remediation, showing the assignment change before applying. |

## How to use them together

1. **Discovery** — map the policies, settings, grace, and where a device stands.
2. **Validation** — read the exact per-setting failure and reason on the affected device.
3. Work the **Diagnostic Playbook** to classify the cause (timing / grace / real / custom /
   CA).
4. **Report** — measure the Conditional Access blast radius and fleet pattern.
5. **Remediation** / **Set-ScopeTargeting** (preview, then commit) — fix the cause safely,
   staged to a pilot group; never disable policy fleet-wide.
6. **Testing** — confirm all three gates pass and no policy was loosened.

## Outcome

Every non-compliant device explained to the **exact failing setting**, with its **evaluation
timing and grace status** and its **Conditional Access impact**, and a **safe remediation** —
using a repeatable method and scripts you keep and reuse.
