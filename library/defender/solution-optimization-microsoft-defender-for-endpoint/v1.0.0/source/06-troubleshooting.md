# 6. Troubleshooting Guide — Solution Optimization: Microsoft Defender for Endpoint

Common field issues, in **symptom → cause → fix** form. Run `SOPMDE-Discovery.ps1` and `SOPMDE-Validate.ps1` first — most causes surface there.

## No baseline / report empty
**Symptom:** `SOPMDE-Report.ps1` returns no metrics, or there is no "before" to compare against.
**Cause:** The baseline was never saved, or the account lacks read access to devices/alerts/hunting.
**Fix:** Run `SOPMDE-Report.ps1 -SaveBaseline` **before** making changes (Implementation Step 1); confirm the account has at least **Security Reader** and the Graph scopes (`SecurityEvents.Read.All`, `Machine.Read.All`, `ThreatHunting.Read.All`). Re-run.

## ASR rule not blocking
**Symptom:** After Implementation Step 2 the rule still shows **Audit** / **Not configured** on pilot devices.
**Cause:** The policy is unassigned or assigned to the wrong group, a **conflicting** policy in another surface (GPO/CM/second Intune policy) wins, or the device hasn't synced.
**Fix:** Confirm `ASR Hardening – Pilot Ring – Pilot` is assigned to `MDE Optimize – Pilot Ring – Pilot`; resolve split-brain policy by authoring in the single authoritative surface (Requirements 2.5); force an Intune sync and allow propagation. Re-run `SOPMDE-Validate.ps1`.

## ASR blocking a legitimate app
**Symptom:** A business application stops working after a rule moved to Block.
**Cause:** The rule blocks a behaviour the app legitimately uses; the app wasn't represented in the audit data before blocking.
**Fix:** Add a scoped ASR **file/folder exclusion** on `ASR Hardening – Pilot Ring – Pilot` for that app (documented), or **revert that rule to Audit** (rollback) and re-soak. Confirm with `SOPMDE-Hunt.ps1 -Mode ASRAudit -BlockedOnly`. *Whether the app is business-critical is the app owner's call.*

## Noise not dropping
**Symptom:** After creating suppressions, `SOPMDE-Report.ps1` shows no reduction in alert/false-positive volume.
**Cause:** The suppression is scoped too narrowly (or too broadly and matching nothing), targets the wrong detection title, or the noisiest source wasn't the one tuned.
**Fix:** Re-identify the top repeating benign detections (`SOPMDE-Hunt.ps1 -Mode Noise`), align the suppression scope (process/path/device group) to them, and confirm the indicator/exclusion applies. Allow time for the next reporting window. Re-run the report.

## Over-broad suppression
**Symptom:** A suppression hides more than intended, creating a blind spot.
**Cause:** The rule was scoped to a whole detection type or all devices instead of the specific benign case.
**Fix:** Tighten the scope to the exact process/path/device group, add a **justification and review date**, and name it `FP Suppression – <detection> – Prod`. Review suppressions on a cadence. *Whether the residual risk is acceptable is the security team's decision.*

## Device not onboarding / sensor unhealthy
**Symptom:** A device stays **not onboarded** or **sensor health = Inactive/Misconfigured**.
**Cause:** The management channel (Intune/CM/GPO/script) isn't reaching it, the onboarding blob/script didn't run, or outbound access to Defender service endpoints is blocked.
**Fix:** Confirm the device is managed and the onboarding policy targets it; verify network access to the documented Defender endpoints (per `global-requirements-defender.md` G5); re-run onboarding. Truly unmanaged devices must be brought under management first. Re-check with `SOPMDE-Hunt.ps1 -Mode Coverage`.

## Hardening not applying
**Symptom:** Tamper protection, EDR block mode, or web content filtering shows off/unapplied on the pilot ring.
**Cause:** The `Endpoint Hardening – Pilot Ring – Pilot` policy is unassigned, a conflicting policy wins, the plan doesn't include the feature, or the device hasn't synced.
**Fix:** Confirm assignment to `MDE Optimize – Pilot Ring – Pilot`; resolve conflicting policy in the authoritative surface; *verify the feature is available in your plan (P1 vs P2, web content filtering)*; force a sync. Re-run `SOPMDE-Validate.ps1`.

## Tags/groups not resolving
**Symptom:** A device tag is missing, or a device group used for scoping is empty.
**Cause:** The tag wasn't applied (manual tag not set, dynamic-rule syntax wrong), or the group's membership rule doesn't match the tag/attribute.
**Fix:** Re-apply the tag (**Assets → Devices → Manage tags**) or fix the dynamic rule; confirm the device group's rule matches; allow membership to recompute. Re-run `SOPMDE-Validate.ps1`.

## Script cannot authenticate or run the hunting query
**Symptom:** `SOPMDE-*.ps1` fails on connect, or `SOPMDE-Hunt.ps1` errors on the advanced-hunting call.
**Cause:** `Microsoft.Graph.Authentication` is missing, the account isn't signed in, or it lacks the required scopes/consent (`ThreatHunting.Read.All`, `SecurityEvents.Read.All`, `Machine.Read.All`).
**Fix:** Let the script install the module (it checks on run); `Connect-MgGraph` with the listed scopes and consent them; confirm at least Security Reader. Re-run the script.
