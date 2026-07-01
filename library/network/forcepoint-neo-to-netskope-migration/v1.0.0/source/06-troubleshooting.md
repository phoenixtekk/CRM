# 6. Troubleshooting Guide — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

Use `NSMIG-Validation.ps1` / `NSMIG-Discovery.ps1` for device agent state, `NSMIG-Report.ps1` for
fleet coverage and conflicts, and `NSMIG-Remediation.ps1` for safe legacy-agent removal. Netskope and
Forcepoint console specifics are deferred to each vendor's documentation.

## A. Both agents fighting traffic (dual enforcement)
| Symptom | Cause | Remediation |
|---|---|---|
| Broken HTTPS, certificate errors, looping/dropped connections | Forcepoint and Netskope both enforcing the same traffic | Run `NSMIG-Validation.ps1`; ensure the device is in only one of `Coexistence Group - Netskope - Passive` or `Steering Group - Netskope - Enforce`; set Netskope back to passive until the swap is intended |
| Random which site is filtered by which agent | Overlapping group membership | Remove the overlap; a device must be passive or enforce, never both |

## B. Cutover didn't take effect
| Symptom | Cause | Remediation |
|---|---|---|
| Ring moved to enforce but Forcepoint still steering | Steering not switched in the consoles, or policy not assigned | Confirm `Translated Web Filtering Policy - Org - Netskope` is assigned to the enforce group and Forcepoint steering is stopped for those devices (vendor consoles); re-sync Intune; re-run `NSMIG-Validation.ps1` |
| Netskope not steering after enforce | Client/cert not deployed or device not synced | Confirm the Netskope client and certificate profiles are assigned and installed; sync the device |

## C. Parity failures (over- or under-blocking)
| Symptom | Cause | Remediation |
|---|---|---|
| Sites that worked now blocked | Translated policy too strict or a mis-mapped category | Compare against the policy export; adjust the Netskope category/allow rule; re-test that case |
| Previously blocked categories now allowed | Missing/mis-mapped rule in the translation | Add the equivalent Netskope rule; re-run the blocked-category parity tests |
| SSL inspection breaks an app | Inspection scope or exception not carried over | Recreate the legacy exception / inspection scope in Netskope; re-test |

## D. Legacy agent won't remove
- Run `NSMIG-Remediation.ps1` first with default `-WhatIf` to confirm what it would do, then with `-Confirm`. If removal fails, the Forcepoint Neo agent may have tamper protection or require an uninstall password — obtain it from the Forcepoint console/admin (deferred to Forcepoint docs) before retrying.
- Do not remove the legacy agent until the ring has passed the parity gate; premature removal opens a protection gap.

## E. Discovery / report shows unexpected devices
- A device still appears in `Legacy Estate - Forcepoint Neo - Inventory` after removal: re-run `NSMIG-Discovery.ps1` to refresh state, then update the group; the decommission gate requires this group to be empty.
- New devices appear with the legacy agent: add them to the appropriate migration ring and run the standard sequence; do not decommission the platform while any device still reports the agent.

## F. Rollback (any ring, before legacy removal)
- Return the ring to `Coexistence Group - Netskope - Passive`, revert steering to Forcepoint, and leave the Forcepoint Neo agent installed. This restores the pre-cutover state with no protection gap. Re-run `NSMIG-Validation.ps1` to confirm Forcepoint is steering again.

## G. When to escalate
If coexistence is correct (one enforcing agent), the translated policy matches the export, and parity
tests still fail or the cutover will not swap, capture `NSMIG-Validation.ps1` and `NSMIG-Report.ps1`
output and open a support case with the relevant vendor (Netskope for steering/policy, Forcepoint for
agent removal/steering teardown).
