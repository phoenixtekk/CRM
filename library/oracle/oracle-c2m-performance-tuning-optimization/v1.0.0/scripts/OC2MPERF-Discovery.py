# OC2MPERF-Discovery.py — read-only baseline of the C2M / WebLogic 14c performance stack.
#
# PURPOSE
#     Collect a repeatable performance baseline via WLST/JMX WITHOUT changing anything.
#     Reads JVM/GC settings, the WebLogic self-tuning thread pool runtime, and every JDBC
#     data-source connection-pool runtime for each managed server in the domain. This is
#     Step 1 (Measure & baseline) of the measure-first method; the numbers it prints are the
#     gate that later changes are validated against. Fill the placeholders (admin-url,
#     admin-user) for your-domain before running.

# HOW TO RUN
#     java weblogic.WLST OC2MPERF-Discovery.py
#     (prompts for the admin password; connects read-only to the Admin Server, then loops the
#      managed servers. Pair with the DB baseline in OC2MPERF-Discovery.sql.)

# EXPECTED RESULTS
#     A per-server report of ExecuteThreadTotalCount, HoggingThreadCount, StuckThreadCount,
#     PendingUserRequestCount and Throughput, plus per-data-source ActiveConnectionsCurrentCount,
#     ActiveConnectionsHighCount, WaitingForConnectionCurrentCount, ConnectionDelayTime and
#     CurrCapacity. PASS = it connected and printed metrics for every running server; FAIL =
#     it reports which server/MBean it could not read (fix access, then re-run).

# NOTES
#     White-label, repeatable baseline capture. READ-ONLY: it only navigates and reads runtime
#     MBeans, never edits config. MBean paths and attributes are for WebLogic 14c (14.1.1) —
#     verify for your version. Run the same script again after a change as OC2MPERF-Validation.

from java.lang import Exception as JException

# --- connection settings (edit for your-domain; no angle brackets) ---
ADMIN_URL  = 't3://your-weblogic-admin-host:7001'
ADMIN_USER = 'weblogic'
# Password is prompted so it is never stored in the script.

def read_attr(mbean, name):
    try:
        return mbean.getAttribute(name)
    except:
        return 'n/a'

def report_server(serverName):
    print('')
    print('=== Server: ' + serverName + ' ===')
    try:
        domainRuntime()
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  could not reach ServerRuntime for ' + serverName + ' (server down or no access)')
        return

    # JVM / GC layer
    try:
        cd('JVMRuntime/' + serverName)
        heapFree = read_attr(cmo, 'HeapFreeCurrent')
        heapMax  = read_attr(cmo, 'HeapSizeMax')
        heapCur  = read_attr(cmo, 'HeapSizeCurrent')
        print('  [JVM] HeapSizeCurrent=%s HeapSizeMax=%s HeapFreeCurrent=%s' % (heapCur, heapMax, heapFree))
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  [JVM] JVMRuntime not readable')

    # WebLogic self-tuning thread pool layer
    try:
        cd('ThreadPoolRuntime/ThreadPoolRuntime')
        print('  [ThreadPool] ExecuteThreadTotalCount=%s HoggingThreadCount=%s StuckThreadCount=%s' % (
            read_attr(cmo, 'ExecuteThreadTotalCount'),
            read_attr(cmo, 'HoggingThreadCount'),
            read_attr(cmo, 'StuckThreadCount')))
        print('  [ThreadPool] PendingUserRequestCount=%s Throughput=%s' % (
            read_attr(cmo, 'PendingUserRequestCount'),
            read_attr(cmo, 'Throughput')))
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  [ThreadPool] ThreadPoolRuntime not readable')

    # JDBC connection-pool layer (per data source)
    try:
        cd('JDBCServiceRuntime/' + serverName)
        dsList = cmo.getJDBCDataSourceRuntimeMBeans()
        if dsList is None or len(dsList) == 0:
            print('  [JDBC] no data sources deployed on this server')
        for ds in dsList:
            print('  [JDBC] %s active=%s activeHigh=%s waiting=%s waitHigh=%s delayMs=%s currCapacity=%s' % (
                ds.getName(),
                read_attr(ds, 'ActiveConnectionsCurrentCount'),
                read_attr(ds, 'ActiveConnectionsHighCount'),
                read_attr(ds, 'WaitingForConnectionCurrentCount'),
                read_attr(ds, 'WaitingForConnectionHighCount'),
                read_attr(ds, 'ConnectionDelayTime'),
                read_attr(ds, 'CurrCapacity')))
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  [JDBC] JDBCServiceRuntime not readable')

def main():
    print('OC2MPERF-Discovery : read-only C2M/WebLogic performance baseline')
    print('Connecting to ' + ADMIN_URL + ' as ' + ADMIN_USER + ' ...')
    try:
        connect(ADMIN_USER, url=ADMIN_URL)
    except JException, e:
        print('FAIL: could not connect: ' + str(e))
        return

    try:
        domainRuntime()
        servers = cmo.getServerLifeCycleRuntimes()
        names = []
        for s in servers:
            names.append(s.getName())
        print('Managed/Admin servers found: ' + str(names))
        for n in names:
            report_server(n)
    finally:
        try:
            disconnect()
        except:
            pass
    print('')
    print('Baseline capture complete. Record these numbers as the tuning baseline.')

main()
