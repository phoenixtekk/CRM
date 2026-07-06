# OC2MPATCH-Remediation.sh — safe, dry-run-by-default helper for common post-check gaps.
#
# PURPOSE
#     Address the small, safe gaps a validation run surfaces — a stopped environment that should be
#     running, a managed server not started, missing backup directories before an apply, or an OUAF
#     configuration not yet applied. It DRY-RUNS by default: it prints the exact action it would take
#     and takes none. It NEVER applies a patch or performs an upgrade — patches/upgrades are applied
#     by the runbook with OPatch/OUAF utilities after the README, not by this helper. Set the
#     environment for your-oracle-home and your-env before running.
#
# HOW TO RUN
#     ./OC2MPATCH-Remediation.sh              (dry-run — prints intended actions only)
#     ./OC2MPATCH-Remediation.sh --apply      (act on the approved fixes)
#     Run as the OUAF product account. Only use --apply after the fix is deliberately approved.
#
# EXPECTED RESULTS
#     Dry-run: a numbered list of intended actions, each prefixed [DRY-RUN], with no change made.
#     --apply: each action runs and prints PASS/FAIL. No patch is ever applied by this script.
#
# NOTES
#     Oracle — C2M/WebLogic patching. Dry-run by default; --apply gates real actions. It never
#     applies a patch/upgrade — that stays a deliberate runbook step. The repeatable way.

set -u

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

ORACLE_HOME="${ORACLE_HOME:-your-oracle-home}"
OUAF_ENV="${OUAF_ENV:-your-env}"
BACKUP_DIR="${OC2MPATCH_BACKUP_DIR:-your-backup-dir}"

echo ""
if [ "${APPLY}" -eq 1 ]; then
  echo "=== OC2MPATCH — remediation (APPLY mode) ==="
else
  echo "=== OC2MPATCH — remediation (DRY-RUN — no changes made) ==="
fi

act() {  # act DESCRIPTION COMMAND...
  local desc="$1"; shift
  if [ "${APPLY}" -eq 1 ]; then
    echo "ACTION: ${desc}"
    if "$@"; then echo "  PASS — ${desc}"; else echo "  FAIL — ${desc}"; fi
  else
    echo "[DRY-RUN] would: ${desc}"
    echo "          cmd : $*"
  fi
}

# 1. Ensure the backup directory exists before an apply (safe; creates a dir only).
act "create backup directory ${BACKUP_DIR} if absent" mkdir -p "${BACKUP_DIR}"

# 2. Start the OUAF environment if it should be running (post-validation health).
act "start the OUAF environment (${OUAF_ENV}) via spl.sh -start" spl.sh -start

# 3. Re-apply OUAF configuration (initialSetup) — only when the README/step calls for it.
#    This applies configuration, not a patch. Left as an explicit, approved action.
act "apply OUAF configuration via initialSetup.sh (only if the runbook step requires it)" \
    initialSetup.sh

echo ""
echo "-- NOT handled here (deliberate) --"
echo "   * Applying a WebLogic patch (opatch apply)  -> runbook Phase B, per patch README"
echo "   * Applying a C2M/OUAF fix (installSF*/ouafDatabasePatch) -> runbook Phase B, per README"
echo "   * Performing a version upgrade (e.g. 25.4)   -> runbook Phase B, per upgrade guide"
echo "   * opatch rollback / restore-from-backup      -> runbook Phase D, a deliberate decision"

echo ""
[ "${APPLY}" -eq 1 ] && echo "=== Remediation (APPLY) complete ===" \
                     || echo "=== Dry-run complete — re-run with --apply to act on approved fixes ==="
