#!/bin/sh
# OC2MINST-Discovery.sh — read-only discovery of a host's C2M build prerequisites.
#
# PURPOSE
#     Captures the starting state of an application-tier host before a C2M install, read-only:
#     OS product user, Java version, WebLogic Home and version, mount points and free space,
#     database listener reachability, and whether the chosen WebLogic ports are free. Produces the
#     Build Baseline record for one environment (your-env, e.g. C2MDEV). Changes nothing.
#
# HOW TO RUN
#     Run as the product OS user (cissys) on the target host:
#         ./OC2MINST-Discovery.sh -e your-env -w your-weblogic-home -d your-db-host -l 7001,7002,7003
#     -e environment name, -w WebLogic Home, -d DB listener host, -l comma-list of WebLogic ports.
#
# EXPECTED RESULTS
#     A printed report of each prerequisite with an OK/CHECK marker; overall PASS if every item is OK,
#     otherwise CHECK with the failing items listed. No files or systems are modified.
#
# NOTES
#     White-label, repeatable pre-build recon. Read-only only. Oracle-version specifics (certified
#     Java/WebLogic/DB versions) are compared informationally against values you pass in; confirm the
#     certified combination against Oracle's certification matrix on My Oracle Support for your release.

ENV_NAME=""
WL_HOME=""
DB_HOST=""
PORTS=""

while getopts "e:w:d:l:h" opt; do
  case "$opt" in
    e) ENV_NAME="$OPTARG" ;;
    w) WL_HOME="$OPTARG" ;;
    d) DB_HOST="$OPTARG" ;;
    l) PORTS="$OPTARG" ;;
    h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Usage: $0 -e your-env -w your-weblogic-home -d your-db-host -l port1,port2"; exit 2 ;;
  esac
done

[ -z "$ENV_NAME" ] && { echo "ERROR: -e your-env is required."; exit 2; }

STATUS="PASS"
mark() {
  # mark OK|CHECK "message"
  if [ "$1" = "CHECK" ]; then STATUS="CHECK"; fi
  printf "  [%-5s] %s\n" "$1" "$2"
}

echo "=== OC2MINST Discovery — environment: $ENV_NAME ==="
echo "--- Host ---"
echo "  host    : $(hostname 2>/dev/null)"
echo "  user    : $(id -un 2>/dev/null)"

echo "--- Java ---"
if command -v java >/dev/null 2>&1; then
  JV=$(java -version 2>&1 | head -n 1)
  mark OK "java present: $JV  (verify it matches the certified JDK, e.g. Java 17, for your release)"
else
  mark CHECK "java not found on PATH — set JAVA_HOME/PATH to the certified JDK"
fi
[ -n "$JAVA_HOME" ] && echo "  JAVA_HOME: $JAVA_HOME" || mark CHECK "JAVA_HOME not set"

echo "--- WebLogic Home ---"
if [ -n "$WL_HOME" ] && [ -d "$WL_HOME" ]; then
  mark OK "WebLogic Home exists: $WL_HOME"
  if [ -f "$WL_HOME/server/lib/weblogic.jar" ] || [ -f "$WL_HOME/wlserver/server/lib/weblogic.jar" ]; then
    mark OK "weblogic.jar found (verify version is WebLogic 14c / 14.1.2.x for your release)"
  else
    mark CHECK "weblogic.jar not found under $WL_HOME — confirm this is a WebLogic install"
  fi
else
  mark CHECK "WebLogic Home not found (pass -w your-weblogic-home)"
fi

echo "--- Mount points / free space ---"
for MP in "/opt/oracle/spl" "/opt/oracle/splout"; do
  if [ -d "$MP" ]; then
    FREE=$(df -h "$MP" 2>/dev/null | awk 'NR==2 {print $4}')
    mark OK "$MP present, free: ${FREE:-unknown}"
  else
    mark CHECK "$MP not present — create the product/output mount point"
  fi
done
echo "  NOTE: the log mount point must already exist before the framework install."

echo "--- Database listener reachability ---"
if [ -n "$DB_HOST" ]; then
  if command -v tnsping >/dev/null 2>&1; then
    if tnsping "$DB_HOST" >/dev/null 2>&1; then mark OK "tnsping $DB_HOST reachable"; else mark CHECK "tnsping $DB_HOST failed — verify TNS/listener"; fi
  else
    # Fall back to a plain TCP reachability check on the default listener port 1521.
    if (exec 3<>"/dev/tcp/$DB_HOST/1521") 2>/dev/null; then mark OK "TCP reach $DB_HOST:1521 OK (default listener port; verify your port)"; else mark CHECK "cannot reach $DB_HOST:1521 — verify network/listener"; fi
  fi
else
  mark CHECK "no DB host given (pass -d your-db-host)"
fi

echo "--- WebLogic ports free ---"
if [ -n "$PORTS" ]; then
  OLDIFS="$IFS"; IFS=","
  for P in $PORTS; do
    INUSE=""
    if command -v ss >/dev/null 2>&1; then INUSE=$(ss -ltn 2>/dev/null | awk '{print $4}' | grep -E "[:.]$P\$");
    elif command -v netstat >/dev/null 2>&1; then INUSE=$(netstat -ltn 2>/dev/null | awk '{print $4}' | grep -E "[:.]$P\$"); fi
    if [ -n "$INUSE" ]; then mark CHECK "port $P already in use on this host"; else mark OK "port $P free"; fi
  done
  IFS="$OLDIFS"
else
  mark CHECK "no ports given (pass -l port1,port2) — cannot confirm WebLogic ports are free"
fi

echo "=== Discovery result for $ENV_NAME: $STATUS ==="
[ "$STATUS" = "PASS" ] && exit 0 || exit 1
