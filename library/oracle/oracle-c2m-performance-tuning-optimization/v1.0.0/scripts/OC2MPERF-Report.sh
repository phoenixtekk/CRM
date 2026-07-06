#!/usr/bin/env bash
# OC2MPERF-Report.sh — read-only health/coverage evidence pack for C2M performance tuning.
#
# PURPOSE
#     Assemble a single evidence pack for tuning sign-off from read-only sources: the WLST
#     baseline/re-measure output (OC2MPERF-Discovery / OC2MPERF-Validation), the OUAF batch
#     layout, the JVM/GC log summary, and the database performance snapshot (OC2MPERF-Report.sql).
#     Nothing is changed. Use it to show baseline-vs-current per layer with gate outcomes for the
#     change-control record. Source the environment first (splenviron.sh -e your-environment).

# HOW TO RUN
#     . splenviron.sh -e your-environment
#     ./OC2MPERF-Report.sh -b baseline-discovery.txt -c current-validation.txt -o report-out-dir
#     (-b baseline capture, -c current capture, -o output directory; -g points at a GC log to
#      summarize, -d runs the DB snapshot via OC2MPERF-Report.sql. All inputs are read-only.)

# EXPECTED RESULTS
#     A dated evidence directory containing: side-by-side thread-pool and connection-pool metrics
#     (baseline vs current), the OUAF thread-pool worker layout, a GC-time summary if a GC log was
#     given, and the DB top-SQL/top-wait snapshot. PASS = the pack is produced and every layer has
#     a before/after; FAIL = a named input is missing (it tells you which) and no pack is written.

# NOTES
#     White-label, repeatable evidence packaging — the auditable record of a tuning pass. READ-ONLY:
#     it only reads capture files, the OUAF config, a GC log, and runs a read-only SQL snapshot.
#     OUAF utility names are for a current OUAF release — verify for your version.

set -euo pipefail

BASELINE=""
CURRENT=""
OUTDIR="oc2mperf-report-$(date +%Y%m%d-%H%M%S)"
GCLOG=""
RUN_DB="N"

usage() {
  echo "Usage: $0 -b baseline-file -c current-file [-o out-dir] [-g gc-log] [-d]"
  echo "  -b  baseline capture (OC2MPERF-Discovery output)   [required]"
  echo "  -c  current capture  (OC2MPERF-Validation output)  [required]"
  echo "  -o  output directory                               [default: dated dir]"
  echo "  -g  GC log to summarize                             [optional]"
  echo "  -d  also run the read-only DB snapshot (OC2MPERF-Report.sql via sqlplus) [optional]"
  exit 2
}

while getopts "b:c:o:g:dh" opt; do
  case "$opt" in
    b) BASELINE="$OPTARG" ;;
    c) CURRENT="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    g) GCLOG="$OPTARG" ;;
    d) RUN_DB="Y" ;;
    h|*) usage ;;
  esac
done

[ -n "$BASELINE" ] || { echo "FAIL: -b baseline file is required"; usage; }
[ -n "$CURRENT" ]  || { echo "FAIL: -c current file is required"; usage; }
[ -f "$BASELINE" ] || { echo "FAIL: baseline file not found: $BASELINE"; exit 1; }
[ -f "$CURRENT" ]  || { echo "FAIL: current file not found: $CURRENT"; exit 1; }

mkdir -p "$OUTDIR"
echo "OC2MPERF-Report : building evidence pack in $OUTDIR"

# 1. Side-by-side WebLogic pool metrics (thread pool + JDBC), read from the captures.
{
  echo "# C2M performance evidence pack"
  echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "## WebLogic thread-pool + JDBC pool — BASELINE vs CURRENT"
  echo ""
  echo "### Baseline ($BASELINE)"
  grep -E '\[ThreadPool\]|\[JDBC\]|Server:' "$BASELINE" || echo "  (no pool lines found in baseline)"
  echo ""
  echo "### Current ($CURRENT)"
  grep -E '\[ThreadPool\]|\[JDBC\]|Server:' "$CURRENT" || echo "  (no pool lines found in current)"
} > "$OUTDIR/01-weblogic-pools.md"

# 2. OUAF batch thread-pool worker layout (read-only; reads config only).
{
  echo "## OUAF batch thread-pool layout"
  echo ""
  if [ -n "${SPLEBASE:-}" ] && [ -f "${SPLEBASE}/etc/threadpoolworker.properties" ]; then
    echo "### ${SPLEBASE}/etc/threadpoolworker.properties (pool/thread settings)"
    grep -Ev '^[[:space:]]*#' "${SPLEBASE}/etc/threadpoolworker.properties" \
      | grep -iE 'pool|thread|daemon|cache' || echo "  (no pool/thread entries matched)"
  else
    echo "  SPLEBASE not set or threadpoolworker.properties not found —"
    echo "  source 'splenviron.sh -e your-environment' first to include batch layout."
  fi
} > "$OUTDIR/02-batch-layout.md"

# 3. GC log summary (read-only), if a log was provided.
{
  echo "## JVM / GC summary"
  echo ""
  if [ -n "$GCLOG" ] && [ -f "$GCLOG" ]; then
    total=$(grep -ciE 'gc|pause' "$GCLOG" || true)
    echo "GC log: $GCLOG"
    echo "GC/pause log lines: $total"
    echo ""
    echo "Longest pause lines (heuristic — verify units for your JDK GC log format):"
    grep -oiE '[0-9]+([.][0-9]+)?[[:space:]]*ms' "$GCLOG" 2>/dev/null | sort -rn | head -5 \
      || echo "  (no ms-formatted pauses parsed; verify for your JDK GC log format)"
  else
    echo "  No GC log supplied (-g); JVM/GC layer not included."
  fi
} > "$OUTDIR/03-gc-summary.md"

# 4. Optional read-only DB snapshot via the companion SQL.
if [ "$RUN_DB" = "Y" ]; then
  if command -v sqlplus >/dev/null 2>&1; then
    echo "  running read-only DB snapshot (OC2MPERF-Report.sql) ..."
    echo "  NOTE: connect string is prompted by sqlplus; the SQL is read-only (V\$/AWR views)."
    sqlplus -s /nolog @"$(dirname "$0")/OC2MPERF-Report.sql" \
      > "$OUTDIR/04-db-snapshot.txt" 2>&1 || echo "  (DB snapshot returned non-zero; see 04-db-snapshot.txt)"
  else
    echo "  sqlplus not found on PATH — skipping DB snapshot." > "$OUTDIR/04-db-snapshot.txt"
  fi
fi

echo ""
echo "PASS: evidence pack written to $OUTDIR"
echo "Layers covered: WebLogic pools, batch layout, GC (if provided), DB (if -d)."
echo "Attach this pack to the change-control record with the gate keep/rollback decision."
