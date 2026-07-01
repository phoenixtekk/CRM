# 6. Troubleshooting Guide — Endpoint Security Baselines

Use **`ESB-Validation.ps1`** / **`ESB-Discovery.ps1`** for device posture and
**`ESB-ConflictCheck.ps1`** for overlaps, **`ESB-Remediation.ps1`** to force a sync.

## A. Settings in conflict (most common)
| Symptom | Cause | Remediation |
|---|---|---|
| Per-setting status shows **Conflict** | Two policies set the same setting differently | Run `ESB-ConflictCheck.ps1`; pick one authoritative policy for that setting; remove/scope the other |
| Baseline fights a dedicated solution | BitLocker/Firewall/ASR managed both by baseline and its own solution | Decide one owner per area; exclude that area from the baseline or from the dedicated policy |
| Legacy GPO overrides baseline | On-prem GPO sets the same control | Disable/scope the GPO away from Intune-managed devices |

## B. Baseline not applying
| Symptom | Cause | Remediation |
|---|---|---|
| Profile "Error"/"Pending" | Device not synced / not enrolled | Run `ESB-Remediation.ps1` (forces sync); confirm device in `Baseline-Pilot` |
| Some settings "Not applicable" | OS build doesn't support the setting | Patch/upgrade Windows; expected for down-level builds |

## C. App or usability breakage
- A hardened setting blocks a required app → identify it via per-setting status / event logs, then **adjust that single setting** in the baseline profile (don't abandon the whole baseline).
- Pilot exists precisely to catch this before fleet rollout.

## D. Version update problems
- Unexpected changes after updating a baseline version → review the **change summary** first; test the new version on the pilot before production.
- A setting reverted → a newer version may have changed a default; re-apply your customization.

## E. Diagnostics quick reference
```powershell
# sample of hardened values the baseline sets:
Get-MpPreference | Select-Object PUAProtection, EnableNetworkProtection
(Get-NetFirewallProfile).Enabled
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name LimitBlankPasswordUse -EA SilentlyContinue
```
Intune → **Endpoint security → Security baselines → (profile) → Per-setting status** is the
authoritative view of what applied and what conflicted.

## F. When to escalate
If a setting shows **Error** (not Conflict) on a healthy, synced, supported device and persists
after remediation, capture the per-setting detail and open a Microsoft support case.
