# 6. Troubleshooting Guide — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

Use `OC2MPATCH-Discovery.sh` for the current baseline, `OC2MPATCH-Validation.sh` for post-apply and
pre-check state, `OC2MPATCH-Report.sh` for the coverage view, and `OC2MPATCH-Remediation.sh` (dry-run
by default) for safe fixes to common gaps. Always read the specific patch README first — patch-specific
errors are documented there. Specific patch numbers and MOS notes are pointed to, not reproduced.

## A. OPatch apply fails or reports a conflict
| Symptom | Cause | Remediation |
|---|---|---|
| `opatch apply` reports a conflict with an applied patch | The new patch overlaps an already-applied WebLogic patch | Stop; run `opatch lsinventory`; resolve per the patch README (superseding/merge patch from MOS). Do not force — a forced apply leaves an unsupported Oracle Home |
| `opatch` cannot find the Oracle Home / inventory | Central Inventory missing or `ORACLE_HOME` not set | Set the environment to your-oracle-home; confirm the inventory with `opatch lsinventory -detail`; repair the Central Inventory per Oracle docs before retrying |
| Wrong OPatch version | OPatch older than the patch requires | Update OPatch in the Oracle Home to the version the README/release requires (verify for your version), then retry |

## B. OUAF patch install fails
| Symptom | Cause | Remediation |
|---|---|---|
| Install stops at the database component | DB patch prerequisite or connectivity | Confirm SQL connectivity to the C2M schema and the DB patch prerequisite; apply the database component (`ouafDatabasePatch.sh`) before the app-server component |
| Error-checker reports failures at end of install | A component did not apply cleanly | Review the install log; re-apply per the README; a failed error-check is a no-go — do not promote the environment |
| Environment did not shut down for install | Non-WebLogic env, or manual stop needed | OUAF stops WebLogic automatically; for non-WebLogic environments stop manually with `spl.sh -stop` before install |

## C. Managed servers do not reach RUNNING after apply
| Symptom | Cause | Remediation |
|---|---|---|
| Server stuck in ADMIN or FAILED | Config/patch mismatch or startup error | Check the server log; confirm the domain config matches the applied patch; if attributable to the change, roll back (Phase D) and re-validate against baseline |
| Admin server starts, managed servers do not | Node manager / config drift after patch | Verify node manager and the managed-server config via WLST; restart in order (admin, then managed) |

## D. Backup/pre-check gate will not pass
- `OC2MPATCH-Validation.sh --pre-check` reports a missing backup marker. Do **not** apply. Take the
  missing backup (DB restore point/RMAN, Oracle Home, domain, OUAF config), verify it is restorable,
  and re-run the pre-check. A missing or unverified backup is an absolute no-go for the apply.

## E. Stack is not certified for the target release
- `OC2MPATCH-Discovery.sh` shows an OS/JDK/DB/WebLogic version outside the target release's
  certification matrix. Align the stack to a certified combination first — as its own backed-up,
  validated change — before applying the C2M patch/upgrade. Patching into an uncertified stack loses
  supportability.

## F. Version/patch drift between nodes
- `OC2MPATCH-Report.sh` shows different patch/version levels across nodes in one environment. Re-apply
  the missing patch to the lagging node per the README; never leave an environment with mixed levels —
  it is unsupported and produces intermittent, hard-to-diagnose behavior.

## G. A change failed validation — rollback
- For a **patch**: `opatch rollback` (WebLogic) and/or the OUAF back-out per the README, then re-run
  `OC2MPATCH-Validation.sh` to confirm the environment is back at baseline.
- For an **upgrade** (or a patch with no clean back-out): restore from the Phase A backup (DB restore
  point/RMAN, Oracle Home, domain, OUAF config), restart, and re-validate against baseline. Record the
  root cause; do not promote a change that failed a lower-environment gate.

## H. Diagnostics quick reference
```sh
./OC2MPATCH-Discovery.sh                 # read-only baseline: OUAF fixes, opatch lsinventory, versions
./OC2MPATCH-Validation.sh --pre-check    # confirm verified backups before apply (Gate A)
./OC2MPATCH-Validation.sh                # post-apply: inventory, servers RUNNING, DB level (Gate C)
./OC2MPATCH-Report.sh                    # patch/version coverage per node (baseline vs post-apply)
./OC2MPATCH-Remediation.sh               # dry-run by default; add --apply to act on approved fixes
./OC2MPATCH-ScopeHelper.sh               # environment/target list + lower-first progression
```

## I. When to escalate
If backups are verified, the stack is certified, the README prerequisites are met, and the patch still
fails to apply or validate after a clean rollback, capture the `opatch lsinventory` output, the OUAF
install log, and the `OC2MPATCH-Validation.sh` / `OC2MPATCH-Report.sh` output, and open a service
request on My Oracle Support against the patch, quoting the patch README and the failing step.
