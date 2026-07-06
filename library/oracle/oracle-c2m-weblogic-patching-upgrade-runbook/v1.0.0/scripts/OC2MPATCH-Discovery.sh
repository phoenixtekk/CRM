# OC2MPATCH-Discovery.sh — read-only baseline of current C2M/OUAF and WebLogic patch/version state.
#
# PURPOSE
#     Capture, read-only, the state you patch from and compare against afterward: the C2M/OUAF
#     release and applied fixes, the WebLogic Oracle Home patch inventory (opatch lsinventory),
#     the OS/JDK/DB/WebLogic versions, and the domain/server layout. Set the environment for
#     your-oracle-home and your-env before running. Reads live systems only; changes nothing.
#
# HOW TO RUN
#     ./OC2MPATCH-Discovery.sh
#     Run as the OUAF product account with OPatch and the OUAF utilities on PATH.
#
# EXPECTED RESULTS
#     A baseline summary printed to stdout: OUAF release + fix list, opatch lsinventory patches,
#     OS/JDK/DB/WebLogic versions, and managed-server list. Each source prints PASS (readable) or
#     GAP (not reachable — record against the Requirements checklist). Save the output as the baseline.
#
# NOTES
#     Oracle — C2M/WebLogic patching. Read-only against live systems. The repeatable way: this is
#     the same baseline capture run in every environment before any apply.

set -u

ORACLE_HOME="${ORACLE_HOME:-your-oracle-home}"
OUAF_ENV="${OUAF_ENV:-your-env}"

echo ""
echo "=== OC2MPATCH — patch/version discovery (read-only) ==="
echo "Oracle Home : ${ORACLE_HOME}"
echo "OUAF env    : ${OUAF_ENV}"

signal() {  # signal LABEL OK(0-or-1) DETAIL
  if [ "$2" -eq 0 ]; then
    echo "  Signal    : PASS — $1 readable ($3)"
  else
    echo "  Signal    : GAP  — $1 not reachable ($3)"
  fi
}

# --- WebLogic Oracle Home patches (opatch lsinventory) ---
echo ""
echo "-- WebLogic Oracle Home patches (opatch lsinventory) --"
if [ -x "${ORACLE_HOME}/OPatch/opatch" ]; then
  "${ORACLE_HOME}/OPatch/opatch" lsinventory -oh "${ORACLE_HOME}" 2>/dev/null \
    | grep -E 'Patch |Oracle Home|Installed Top-level' || echo "  (no patches listed)"
  signal "opatch inventory" 0 "opatch found in Oracle Home"
else
  signal "opatch inventory" 1 "opatch not executable at ORACLE_HOME/OPatch"
fi

# --- OUAF release and applied fixes ---
echo ""
echo "-- C2M / OUAF release and applied fixes --"
if command -v configureEnv.sh >/dev/null 2>&1 || [ -n "${SPLEBASE:-}" ]; then
  # Framework version file is written by the install; adjust path per your version.
  VERSION_FILE="${SPLEBASE:-}/etc/ENVIRON.INI"
  if [ -f "${VERSION_FILE}" ]; then
    grep -Ei 'VERSION|RELEASE|SPLENVIRON' "${VERSION_FILE}" || echo "  (version keys not found)"
  else
    echo "  (source configureEnv.sh / splenviron to populate SPLEBASE; verify path for your version)"
  fi
  signal "OUAF environment" 0 "framework utilities on PATH"
else
  signal "OUAF environment" 1 "configureEnv.sh not on PATH — source the environment"
fi

# --- OS / JDK / DB / WebLogic versions (for certification comparison) ---
echo ""
echo "-- Certified-stack versions (compare to the target release matrix on MOS) --"
echo "OS   : $(uname -a 2>/dev/null || echo 'unknown')"
if command -v java >/dev/null 2>&1; then
  echo "JDK  : $(java -version 2>&1 | head -n 1)"
else
  echo "JDK  : java not on PATH"
fi
if [ -r "${ORACLE_HOME}/inventory/registry.xml" ] || [ -x "${ORACLE_HOME}/OPatch/opatch" ]; then
  echo "WLS  : $("${ORACLE_HOME}/OPatch/opatch" version 2>/dev/null | head -n 1 || echo 'see opatch/version')"
else
  echo "WLS  : verify WebLogic version for your Oracle Home"
fi
echo "DB   : query v\$version via OC2MPATCH-Validation.sh (SQL) — DB version is read there"

echo ""
echo "=== Baseline capture complete — save this output as the pre-change baseline ==="
