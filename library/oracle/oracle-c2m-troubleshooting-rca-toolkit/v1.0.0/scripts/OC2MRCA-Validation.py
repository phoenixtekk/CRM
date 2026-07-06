# OC2MRCA-Validation.py — read-only WLST per-layer isolation checks (servers, threads, JDBC, JMS, certs).
#
# PURPOSE
#     Read the live WebLogic 14c / C2M state for each fault-domain layer and print a PASS or
#     FAIL per check, implementing the C2M RCA - Layer Isolation Checklist:
#       Up            server states / health (RUNNING vs ADMIN/FAILED)
#       Resourced     execute-thread pool health, stuck and hogging thread counts
#       Authenticated JDBC data-source / connection-pool state (connect, capacity, failures)
#       Resourced     JMS destination consumer and pending-message counts (backlog)
#       Authenticated SSL identity/trust certificate expiry
#     Read-only — it only reads runtime MBeans and lists keystore expiry; it changes nothing.
#     Run it during triage to isolate the failing layer, and after a fix to validate the
#     restore (Diagnostic Playbook; Testing Guide Tests 2 and 7).
#
# HOW TO RUN
#     java weblogic.WLST OC2MRCA-Validation.py
#     Set the admin URL and read-capable credentials via environment variables first:
#         export ADMIN_URL=t3://your-admin-host:7001
#         export WLS_USER=your-readonly-admin
#         export WLS_PASS=your-password
#     (Prompted interactively if not set. Keystore expiry uses keytool separately — see NOTES.)
#
# EXPECTED RESULTS
#     One PASS/FAIL line per layer check with the reading, then an overall verdict. On a
#     healthy environment every layer reads PASS. Any FAIL names the failing layer to
#     descend into (see the Diagnostic Playbook) and, if a restore is needed, points to
#     OC2MRCA-Remediation.sh (dry-run by default).
#
# NOTES
#     White-label, repeatable validation — the same per-layer checks every incident and
#     environment. Read-only against live systems (runtime MBean reads only). MBean paths,
#     health-state names, and status values follow the WebLogic 14c / OUAF model — verify for
#     your version; they are cited, not invented. Certificate expiry is best listed with
#     keytool -list on the identity/trust stores from the domain SSL config (kept separate so
#     this script needs no keystore passwords); this script reports the SSL listener presence
#     and reminds you to check expiry.

import os
import sys

rc = {"fail": 0}

def result(ok, label, detail=""):
    tag = "PASS" if ok else "FAIL"
    if not ok:
        rc["fail"] += 1
    print("  %s: %s %s" % (tag, label, ("- " + detail) if detail else ""))

ADMIN_URL = os.environ.get("ADMIN_URL", "t3://your-admin-host:7001")
WLS_USER  = os.environ.get("WLS_USER", "")
WLS_PASS  = os.environ.get("WLS_PASS", "")

print("== OC2MRCA Validation (C2M RCA - Layer Isolation Checklist) ==")
print("Admin URL: %s  (verify for your version)" % ADMIN_URL)

# --- Connect (read-only session) ---
try:
    if WLS_USER and WLS_PASS:
        connect(WLS_USER, WLS_PASS, ADMIN_URL)
    else:
        # WLST will prompt for any missing credentials
        connect(url=ADMIN_URL)
except Exception, e:  # noqa: WLST runs on Jython 2.x
    print("  FAIL: could not connect to the Admin Server (%s)" % str(e))
    print("        This is itself a middleware/network-layer finding — confirm the Admin Server is RUNNING and the port is reachable.")
    sys.exit(1)

# ===================================================================
# Layer: UP — server states / health
# ===================================================================
print("")
print("-- UP: server states / health --")
try:
    domainRuntime()
    servers = cmo.getServerRuntimes()
    if not servers:
        result(False, "no ServerRuntime MBeans found")
    for s in servers:
        name  = s.getName()
        state = s.getState()          # RUNNING / ADMIN / FAILED / SHUTDOWN
        try:
            health = s.getHealthState().getState()
        except:
            health = "?"
        ok = (state == "RUNNING")
        result(ok, "server %s" % name, "state=%s health=%s" % (state, health))

    # ---------------------------------------------------------------
    # Layer: RESOURCED — execute-thread pool (stuck / hogging / health)
    # ---------------------------------------------------------------
    print("")
    print("-- RESOURCED: execute-thread pool (stuck/hogging) --")
    for s in servers:
        try:
            tp = s.getThreadPoolRuntime()
            stuck   = tp.getStuckThreadCount()
            hogging = tp.getHoggingThreadCount()
            hstate  = tp.getHealthState().getState()
            ok = (stuck == 0 and hstate == "ok")
            result(ok, "threadpool on %s" % s.getName(),
                   "stuck=%d hogging=%d health=%s" % (stuck, hogging, hstate))
        except Exception, e:
            result(False, "threadpool on %s" % s.getName(), "unreadable (%s)" % str(e))

    # ---------------------------------------------------------------
    # Layer: AUTHENTICATED — JDBC data source / connection pool
    # ---------------------------------------------------------------
    print("")
    print("-- AUTHENTICATED: JDBC data-source / connection-pool state --")
    for s in servers:
        try:
            jdbcs = s.getJDBCServiceRuntime().getJDBCDataSourceRuntimeMBeans()
            if not jdbcs:
                print("    (no JDBC data sources on %s)" % s.getName())
            for ds in jdbcs:
                dstate  = ds.getState()                  # Running / Suspended / etc.
                active  = ds.getActiveConnectionsCurrentCount()
                waiting = ds.getWaitingForConnectionCurrentCount()
                failed  = ds.getFailedReserveRequestCount()
                ok = (dstate == "Running" and waiting == 0)
                result(ok, "data source %s" % ds.getName(),
                       "state=%s active=%d waiting=%d failedReserves=%d" % (dstate, active, waiting, failed))
        except Exception, e:
            result(False, "JDBC runtime on %s" % s.getName(), "unreadable (%s)" % str(e))

    # ---------------------------------------------------------------
    # Layer: RESOURCED — JMS destinations (consumers / backlog)
    # ---------------------------------------------------------------
    print("")
    print("-- RESOURCED: JMS destinations (consumers / pending backlog) --")
    for s in servers:
        try:
            jms = s.getJMSRuntime()
            if jms is None:
                continue
            for srv in jms.getJMSServers():
                for dest in srv.getDestinations():
                    cur     = dest.getMessagesCurrentCount()
                    pend    = dest.getMessagesPendingCount()
                    cons    = dest.getConsumersCurrentCount()
                    # Backlog with zero consumers is the classic "queue backs up" cause.
                    ok = not (cur > 0 and cons == 0)
                    result(ok, "JMS dest %s" % dest.getName(),
                           "current=%d pending=%d consumers=%d" % (cur, pend, cons))
        except Exception, e:
            # Not every server hosts JMS; only report if the runtime existed but failed.
            result(False, "JMS runtime on %s" % s.getName(), "unreadable (%s)" % str(e))

    # ---------------------------------------------------------------
    # Layer: AUTHENTICATED — SSL listeners present (check cert expiry with keytool)
    # ---------------------------------------------------------------
    print("")
    print("-- AUTHENTICATED: SSL / certificate reminder --")
    try:
        serverConfig()
        ssl_on = 0
        for cs in cmo.getServers():
            ssl = cs.getSSL()
            if ssl is not None and ssl.isEnabled():
                ssl_on += 1
                print("    SSL enabled on server: %s (list cert expiry with keytool)" % cs.getName())
        if ssl_on == 0:
            print("    (no SSL listeners enabled in domain config)")
        print("    ACTION: keytool -list -v -keystore your-identity-or-trust-store  -> confirm no cert is near/past expiry")
        print("            An expired cert presents as can't-log-in or a failed outbound IWS call (Requirement 2.6).")
    except Exception, e:
        print("    NOTE: could not read SSL config (%s)" % str(e))

except Exception, e:
    print("  FAIL: error reading runtime MBeans (%s)" % str(e))
    rc["fail"] += 1

# --- Overall verdict ---
print("")
if rc["fail"] == 0:
    print("OVERALL: PASS — every layer reads healthy.")
else:
    print("OVERALL: FAIL — %d check(s) failed. Descend into the failing layer (Diagnostic Playbook);" % rc["fail"])
    print("         preview any restore with OC2MRCA-Remediation.sh (dry-run by default).")

try:
    disconnect()
except:
    pass
