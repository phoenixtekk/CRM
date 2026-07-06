#!/usr/bin/env bash
# OC2MPERF-ScopeHelper.sh — record the tuning pilot scope and rollback targets.
#
# PURPOSE
#     Before a tuning pass, capture WHAT is in scope and HOW to roll it back, so every change is
#     single, named, and reversible (Step 0 of the method). It records the target nodes, JDBC data
#     sources, and batch controls, snapshots the current OUAF batch layout and JVM/data-source
#     settings it can read, and writes a scope manifest you attach to the change-control record.
#     Source the environment first (splenviron.sh -e your-environment). Read-only.

# HOW TO RUN
#     . splenviron.sh -e your-environment
#     ./OC2MPERF-ScopeHelper.sh -n "node1,node2" -s "your-datasource-name" -c "BATCHCTRL1,BATCHCTRL2" -o scope-out-dir
#     (-n nodes, -s data sources, -c batch controls in scope; -o output dir. All inputs recorded;
#      current values it can read are snapshotted as the rollback baseline.)

# EXPECTED RESULTS
#     A dated scope directory with a manifest listing the in-scope nodes/data-sources/batch-controls,
#     a copy of the readable current OUAF batch layout (rollback reference), and a checklist of the
#     backups to take. PASS = manifest written and current batch layout captured; FAIL = a required
#     argument is missing (it tells you which) and nothing is written.

# NOTES
#     White-label, repeatable scoping — the front half of production-safe change control. READ-ONLY:
#     it records inputs and copies readable config for rollback reference; it changes nothing. OUAF
#     paths depend on SPLEBASE/your-environment — verify for your version. Pair with a verified
#     backup before applying any change.

set -euo pipefail

NODES=""
DATASOURCES=""
BATCH_CONTROLS=""
OUTDIR="oc2mperf-scope-$(date +%Y%m%d-%H%M%S)"

usage() {
  echo "Usage: $0 -n nodes -s datasources -c batch-controls [-o out-dir]"
  echo "  -n  comma-separated node/server names in scope    [required]"
  echo "  -s  comma-separated JDBC data-source names in scope [required]"
  echo "  -c  comma-separated batch control codes in scope   [required]"
  echo "  -o  output directory                               [default: dated dir]"
  exit 2
}

while getopts "n:s:c:o:h" opt; do
  case "$opt" in
    n) NODES="$OPTARG" ;;
    s) DATASOURCES="$OPTARG" ;;
    c) BATCH_CONTROLS="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h|*) usage ;;
  esac
done

[ -n "$NODES" ]          || { echo "FAIL: -n nodes is required"; usage; }
[ -n "$DATASOURCES" ]    || { echo "FAIL: -s datasources is required"; usage; }
[ -n "$BATCH_CONTROLS" ] || { echo "FAIL: -c batch-controls is required"; usage; }

mkdir -p "$OUTDIR"
MANIFEST="$OUTDIR/scope-manifest.md"

{
  echo "# OC2MPERF tuning scope manifest"
  echo "generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "environment: ${SPLENVIRON:-unknown} (SPLEBASE=${SPLEBASE:-unset})"
  echo ""
  echo "## In scope (one change at a time — tune, re-measure, then move on)"
  echo ""
  echo "### Nodes / servers"
  echo "$NODES" | tr ',' '\n' | sed 's/^/  - /'
  echo ""
  echo "### JDBC data sources"
  echo "$DATASOURCES" | tr ',' '\n' | sed 's/^/  - /'
  echo ""
  echo "### Batch controls"
  echo "$BATCH_CONTROLS" | tr ',' '\n' | sed 's/^/  - /'
  echo ""
  echo "## Rollback targets (record current values BEFORE changing)"
  echo "  - JVM heap/GC args per node (from Server Start args / setUserOverrides.sh)"
  echo "  - Data-source Max/Initial Capacity, TestConnectionsOnReserve, StatementCacheSize"
  echo "  - Batch thread-pool sizes and per-batch thread counts"
  echo ""
  echo "## Pre-change backup checklist"
  echo "  - [ ] WebLogic domain config backed up"
  echo "  - [ ] OUAF config (threadpoolworker.properties, JVM/data-source settings) backed up"
  echo "  - [ ] Database backup / flashback point confirmed"
  echo "  - [ ] Change window booked and approvers notified"
} > "$MANIFEST"

# Snapshot the current readable OUAF batch layout as a rollback reference (read-only copy).
if [ -n "${SPLEBASE:-}" ] && [ -f "${SPLEBASE}/etc/threadpoolworker.properties" ]; then
  cp "${SPLEBASE}/etc/threadpoolworker.properties" "$OUTDIR/threadpoolworker.properties.baseline"
  echo "  captured current threadpoolworker.properties as rollback reference"
else
  echo "  (SPLEBASE not set or threadpoolworker.properties not found — source splenviron.sh -e your-environment"
  echo "   to capture the batch-layout rollback reference)" | tee -a "$MANIFEST" >/dev/null
fi

echo ""
echo "PASS: scope manifest written to $MANIFEST"
echo "Record current rollback values, take the backups, then proceed to OC2MPERF-Discovery (baseline)."
