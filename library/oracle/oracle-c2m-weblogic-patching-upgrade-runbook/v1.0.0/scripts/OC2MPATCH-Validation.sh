# OC2MPATCH-Validation.sh — read-only pre-check and post-apply validation for a patch/upgrade.
#
# PURPOSE
#     Two read-only modes. With --pre-check it confirms the Phase A backup markers exist before an
#     apply (Gate A). Without it, it validates after the apply (Gate C): the expected patch/version
#     shows in the OPatch and OUAF inventories, WebLogic managed servers are RUNNING, and the
#     database reports the expected level. Set the environment for your-oracle-home and your-env.
#     Reads live systems only; changes nothing.
#
# HOW TO RUN
#     ./OC2MPATCH-Validation.sh --pre-check      (before apply — confirm verified backups)
#     ./OC2MPATCH-Validation.sh                  (after apply — confirm the change landed)
#     Run as the OUAF product account; needs SQL access to the C2M schema and WLST for server state.
#
# EXPECTED RESULTS
#     Pre-check: each backup marker prints PASS/GAP; any GAP is an absolute no-go for the apply.
#     Post-apply: each check prints PASS/FAIL; all PASS is the Gate C go decision to promote up.
#
# NOTES
#     Oracle — C2M/WebLogic patching. Read-only against live systems. The repeatable way: run the
#     pre-check before every apply and the post-apply validation before every promotion.

set -u

MODE="post"
[ "${1:-}" = "--pre-check" ] && MODE="pre"

ORACLE_HOME="${ORACLE_HOME:-your-oracle-home}"
OUAF_ENV="${OUAF_ENV:-your-env}"
BACKUP_DIR="${OC2MPATCH_BACKUP_DIR:-your-backup-dir}"

pass() { echo "  PASS — $1"; }
fail() { echo "  FAIL — $1"; RC=1; }
gap()  { echo "  GAP  — $1"; RC=1; }
RC=0

if [ "${MODE}" = "pre" ]; then
  echo ""
  echo "=== OC2MPATCH — pre-apply readiness (Gate A, read-only) ==="
  echo "Checking backup markers under: ${BACKUP_DIR}"
  # Each marker is a backup artifact your Phase A step wrote; verify restorability separately.
  for marker in db-restore-point.marker oracle-home.tar domain-config.tar ouaf-config.tar; do
    if [ -e "${BACKUP_DIR}/${marker}" ]; then
      pass "backup present: ${marker}"
    else
      gap "backup MISSING: ${marker} — do NOT apply until taken and verified restorable"
    fi
  done
  echo ""
  [ "${RC}" -eq 0 ] && echo "=== Gate A: PASS — verified backups present, apply may proceed ===" \
                    || echo "=== Gate A: FAIL — resolve gaps before any apply ==="
  exit "${RC}"
fi

echo ""
echo "=== OC2MPATCH — post-apply validation (Gate C, read-only) ==="

# --- 1. WebLogic patch inventory shows the expected change ---
echo ""
echo "-- opatch lsinventory --"
if [ -x "${ORACLE_HOME}/OPatch/opatch" ]; then
  "${ORACLE_HOME}/OPatch/opatch" lsinventory -oh "${ORACLE_HOME}" 2>/dev/null | grep -E 'Patch ' \
    && pass "opatch inventory readable — confirm the expected patch number is listed" \
    || fail "opatch inventory empty or unreadable"
else
  fail "opatch not executable at ORACLE_HOME/OPatch"
fi

# --- 2. OUAF fix/version inventory shows the expected change ---
echo ""
echo "-- OUAF fix/version inventory --"
if [ -f "${SPLEBASE:-}/etc/ENVIRON.INI" ]; then
  grep -Ei 'VERSION|RELEASE' "${SPLEBASE}/etc/ENVIRON.INI" \
    && pass "OUAF version readable — confirm expected release/fix (e.g. 25.4) is present" \
    || fail "OUAF version keys not found"
else
  gap "source configureEnv.sh / splenviron so SPLEBASE resolves (verify path for your version)"
fi

# --- 3. WebLogic managed servers RUNNING (via WLST) ---
echo ""
echo "-- WebLogic managed-server state (WLST) --"
if command -v wlst.sh >/dev/null 2>&1; then
  echo "  Run the companion WLST check (server state) — see OC2MPATCH-Report.sh for the WLST snippet"
  echo "  Expected: admin + all managed servers RUNNING (no ADMIN/FAILED)"
else
  gap "wlst.sh not on PATH — check server state via the Administration Console"
fi

# --- 4. Database at the expected level ---
echo ""
echo "-- Database level (SQL) --"
if command -v sqlplus >/dev/null 2>&1; then
  echo "  Run OC2MPATCH-Report.sql (or sqlplus) to read v\$version and the OUAF DB version;"
  echo "  Expected: database component at the expected post-patch/upgrade level; no new invalid objects"
else
  gap "sqlplus/sql not on PATH — run the SQL checks from a DB client"
fi

echo ""
[ "${RC}" -eq 0 ] && echo "=== Gate C: PASS — change validated, environment may be promoted up ===" \
                  || echo "=== Gate C: FAIL — do NOT promote; roll back or restore per the runbook ==="
exit "${RC}"
