# OC2MLOG-Remediation.sh — preview safe log rotation/cleanup to hold log filesystems within policy (DRY-RUN by default).
#
# PURPOSE
#     When a log location is filling or retaining more than policy, bring it back within
#     policy by rotating/compressing old logs and removing files past the retention age —
#     for the OUAF logs (your-splebase/logs/system), the batch logs (your-sploutput), and
#     the WebLogic server/domain logs. DRY-RUN by default: it prints exactly which files it
#     WOULD compress/remove and the WebLogic rotation setting to check, and changes nothing.
#     It applies only when explicitly asked, and only intended for a change window.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MLOG-Remediation.sh                         # DRY-RUN: prints intended actions only
#         ./OC2MLOG-Remediation.sh --apply                 # applies (change window only)
#     Tune:  RETAIN_DAYS=30 COMPRESS_DAYS=3 ./OC2MLOG-Remediation.sh
#
# EXPECTED RESULTS
#     DRY-RUN lists the files older than RETAIN_DAYS it would remove and older than
#     COMPRESS_DAYS it would gzip, per log location, plus the WebLogic LogFileMBean rotation
#     settings to verify — and exits changing nothing. With --apply it compresses and removes
#     those files (never an active/current log) and prints what it did. It never deletes the
#     newest log and never truncates a file in use.
#
# NOTES
#     White-label, repeatable remediation — DRY-RUN by default so it is safe to run anywhere.
#     It never rotates WebLogic itself (that is a LogFileMBean/console setting under change
#     control) — it prints the setting to check. Only ever removes files past retention, never
#     the current log. Verify paths/retention for your version and policy before --apply.

set -u

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

RETAIN_DAYS="${RETAIN_DAYS:-30}"     # remove logs older than this many days
COMPRESS_DAYS="${COMPRESS_DAYS:-3}"  # gzip logs older than this many days (but younger than RETAIN_DAYS)

echo "== OC2MLOG Remediation =="
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
echo "Policy: retain ${RETAIN_DAYS} days, compress after ${COMPRESS_DAYS} days."
[ "$APPLY" -eq 0 ] && echo "Mode: DRY-RUN (no changes) — re-run with --apply in a change window to act." \
                   || echo "Mode: APPLY (change window) — will compress/remove per policy."

# remediate_dir <label> <dir> <glob>
remediate_dir() {
  label="$1"; dir="$2"; glob="$3"
  echo
  echo "-- ${label} --"
  echo "   dir: ${dir}"
  [ -d "$dir" ] || { echo "   (not present — skipped)"; return; }

  # newest file is the current log — never touch it
  newest="$(ls -1t ${dir}/${glob} 2>/dev/null | head -1)"
  echo "   current log (never touched): ${newest:-<none>}"

  # candidates to remove (older than RETAIN_DAYS), excluding the newest
  echo "   would REMOVE (older than ${RETAIN_DAYS}d):"
  found_rm=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ "$f" = "$newest" ] && continue
    found_rm=1
    echo "     - $f"
    [ "$APPLY" -eq 1 ] && rm -f "$f" && echo "       removed."
  done <<EOF
$(find "$dir" -maxdepth 1 -name "$glob" -type f -mtime "+${RETAIN_DAYS}" 2>/dev/null)
EOF
  [ "$found_rm" -eq 0 ] && echo "     (none)"

  # candidates to compress (older than COMPRESS_DAYS, not already .gz, not newest)
  echo "   would COMPRESS (older than ${COMPRESS_DAYS}d, not yet gzipped):"
  found_gz=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ "$f" = "$newest" ] && continue
    case "$f" in *.gz) continue ;; esac
    found_gz=1
    echo "     - $f"
    [ "$APPLY" -eq 1 ] && gzip -f "$f" && echo "       compressed -> ${f}.gz"
  done <<EOF
$(find "$dir" -maxdepth 1 -name "$glob" -type f -mtime "+${COMPRESS_DAYS}" -mtime "-${RETAIN_DAYS}" 2>/dev/null)
EOF
  [ "$found_gz" -eq 0 ] && echo "     (none)"
}

# OUAF application logs
remediate_dir "OUAF application logs" "${SPLEBASE}/logs/system" "spl*.log"
# Batch logs
[ -n "${SPLOUTPUT:-}" ] && remediate_dir "Batch logs" "${SPLOUTPUT}" "threadpoolworker.*.log"
# WebLogic server logs
if [ -n "${DOMAIN_HOME:-}" ] && [ -d "${DOMAIN_HOME}/servers" ]; then
  for srv in "${DOMAIN_HOME}"/servers/*/; do
    [ -d "${srv}logs" ] || continue
    remediate_dir "WebLogic server: $(basename "$srv")" "${srv}logs" "*.log*"
  done
fi

echo
echo "-- WebLogic rotation config (verify, do not auto-change) --"
echo "   Check LogFileMBean per server: FileMinSize (rotate-at size) and FileCount (files kept)."
echo "   Set via WebLogic console or WLST under change control — this script does not change it."

echo
if [ "$APPLY" -eq 0 ]; then
  echo "DRY-RUN complete: nothing changed. Re-run with --apply in a change window to act."
else
  echo "APPLY complete: files compressed/removed per policy. Re-run OC2MLOG-Discovery.sh to confirm headroom."
fi
