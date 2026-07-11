# 6. Troubleshooting — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

Common failures when running the suite assessment, in **symptom → cause → fix** form. All fixes stay read-only.

## `Connect-MgGraph` fails or needs admin consent
**Symptom:** The connect command errors, or a consent screen requires an administrator.
**Cause:** The read scopes (`SecurityEvents.Read.All`, `RoleManagement.Read.Directory`, `Directory.Read.All`) are not consented, or your account lacks them.
**Fix:** Have an administrator grant admin consent for the read-only scopes once. Confirm **Security Reader** / **Global Reader** (R3). *Verify current scope names.*

## A pillar shows "not onboarded" that you believe is live
**Symptom:** Discovery marks e.g. the identity pillar dark, but you think sensors are deployed.
**Cause 1:** The signal the script reads (licensing/onboarding indicator) is not visible to the read role.
**Cause 2:** The pillar is genuinely partially onboarded (some sensors, not all) — a real finding.
**Fix:** Cross-check in the Defender portal **Settings** for that pillar. If the portal shows it onboarded and the script does not, re-check scopes. Partial onboarding is a legitimate coverage finding.

## RBAC audit lists nothing / only a few roles
**Symptom:** `SOAXDR-RBACAudit.ps1` returns an empty or tiny set.
**Cause 1:** `RoleManagement.Read.Directory` / `Directory.Read.All` not consented.
**Cause 2:** The tenant genuinely has few privileged assignments (good).
**Fix:** Verify the scopes (R4). Cross-check in Entra → **Roles and administrators**. If the portal shows assignments the script does not, the scope is missing.

## Unified RBAC "not activated" but you use Defender roles
**Symptom:** Validation flags unified RBAC as not activated although people can act in the portal.
**Cause:** The tenant is on **legacy per-product permissions** or broad Entra roles rather than the Defender XDR Unified RBAC model.
**Fix:** Confirm under **Settings → Permissions & roles** whether Unified RBAC is activated. Legacy per-product permissions are a legitimate finding ("activate unified RBAC for least-privilege cross-pillar access"). *Verify current RBAC model availability.*

## Secure Score reads low or "not available"
**Symptom:** The Secure Score domain shows no score or a surprisingly low one.
**Cause:** A pillar was recently onboarded and the score is still populating, or improvement actions genuinely aren't worked.
**Fix:** Allow a warm-up window and re-run (Global Requirements G5). A genuinely low score with a stale backlog is a legitimate finding.

## Incident-correlation evidence is empty
**Symptom:** The incident-correlation domain shows no multi-pillar incidents.
**Cause 1:** Only one pillar is feeding signal, so there is nothing to correlate (a coverage problem upstream).
**Cause 2:** The tenant is quiet (few incidents in the sample window).
**Fix:** If pillars are dark, the correlation gap is downstream of the coverage gap — fix coverage first. If pillars are onboarded and the queue is simply quiet, note it and re-sample over a longer window.

## Az cloud-pillar section errors
**Symptom:** The cloud-pillar part of discovery throws.
**Cause:** `Az` not installed, or no Azure subscription in context.
**Fix:** `Install-Module Az -Scope CurrentUser`; `Connect-AzAccount`. If Azure is not in use, mark the cloud pillar **N/A** in the scope rather than a gap (R5).

## Findings contradict the live portal
**Symptom:** A finding disagrees with what the portal shows now.
**Cause:** Posture is a **point-in-time snapshot**; the baseline predates your view, or a change was made after the run.
**Fix:** Re-run discovery to refresh the baseline, then re-score. Trust the dated baseline over memory (Global Requirements G5).
