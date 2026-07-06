# OSOAC2M-Report.py — read-only health/coverage report for the C2M SOA-integration surface.
#
# PURPOSE
#     Produce a single human-readable coverage report across scope: which IWS application(s)
#     are active and their health, each integration JMS destination with its current /
#     pending / consumer counts (so staged-but-undispatched or backed-up outbound flows are
#     visible), and a coverage line. Intended as the pilot sign-off artifact and change-record
#     evidence. Reads runtime metrics; makes no changes. Point it at your-domain via the
#     environment variables below. Pair with OSOAC2M-Discovery.sql for the C2M-metadata side.
#
# HOW TO RUN
#     Set OSOAC2M_ADMIN_URL / OSOAC2M_ADMIN_USER / OSOAC2M_ADMIN_PASS, then:
#         java weblogic.WLST OSOAC2M-Report.py > osoac2m-integration-report.txt
#
# EXPECTED RESULTS
#     A sectioned report (IWS / INTEGRATION JMS METRICS) with per-object counts and an overall
#     coverage line. Exit 0 on a clean read; nonzero only if it cannot connect.
#
# NOTES
#     White-label, repeatable. Read-only: uses domainRuntime() metric MBeans only, never edits
#     — safe on production. A rising pending count with zero consumers signals an outbound flow
#     that is staged but not being dispatched — investigate the sender / OSB proxy.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL  = env('OSOAC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER = env('OSOAC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS = env('OSOAC2M_ADMIN_PASS', '')
EXP_IWS    = env('OSOAC2M_EXPECT_IWS', 'spl-web-services')

def hr(title):
    print('')
    print('==== ' + title + ' ' + ('=' * max(4, 60 - len(title))))

def safe(fn, default='(n/a)'):
    try:
        return fn()
    except:
        return default

try:
    connect(ADMIN_USER, ADMIN_PASS, ADMIN_URL)
except Exception, e:
    print('ERROR: could not connect to ' + ADMIN_URL + ' : ' + str(e))
    exit(exitcode=2)

print('C2M SOA INTEGRATION HEALTH / COVERAGE REPORT (read-only)')
print('Domain: ' + safe(lambda: cmo.getName()))

iws_active = 0
dest_count = 0
backlog = 0

# ---- Inbound Web Services ---------------------------------------------------
hr('INBOUND WEB SERVICES (IWS)')
try:
    domainRuntime()
    for s in cmo.getServerRuntimes():
        for ar in safe(lambda: s.getApplicationRuntimes(), []):
            if ar.getName().lower().find(EXP_IWS.lower()) >= 0:
                iws_active += 1
                print('  [' + s.getName() + '] ' + ar.getName()
                      + '  health=' + str(safe(lambda: ar.getHealthState(), '(n/a)')))
    if iws_active == 0:
        print('  (no active IWS application found matching "' + EXP_IWS + '")')
except Exception, e:
    print('  (application runtime unavailable: ' + str(e) + ')')

# ---- Integration JMS metrics -----------------------------------------------
hr('INTEGRATION JMS DESTINATION METRICS')
try:
    domainRuntime()
    for s in cmo.getServerRuntimes():
        jr = safe(lambda: s.getJMSRuntime(), None)
        if jr is None:
            continue
        for js in safe(lambda: jr.getJMSServers(), []):
            for d in safe(lambda: js.getDestinations(), []):
                dest_count += 1
                cur = safe(lambda: d.getMessagesCurrentCount(), '?')
                pen = safe(lambda: d.getMessagesPendingCount(), '?')
                con = safe(lambda: d.getConsumersCurrentCount(), '?')
                try:
                    if int(pen) > 0 and int(con) == 0:
                        backlog += 1
                except:
                    pass
                print('  [' + s.getName() + '] ' + d.getName()
                      + '  current=' + str(cur) + ' pending=' + str(pen)
                      + ' consumers=' + str(con))
    if dest_count == 0:
        print('  (no integration JMS destinations reporting runtime metrics)')
except Exception, e:
    print('  (JMS runtime metrics unavailable: ' + str(e) + ')')

# ---- Coverage summary ------------------------------------------------------
hr('COVERAGE SUMMARY')
print('  IWS applications active               : ' + str(iws_active))
print('  Integration JMS destinations reporting: ' + str(dest_count))
print('  Destinations with backlog & 0 consumer: ' + str(backlog))
overall = 'HEALTHY' if (iws_active > 0 and backlog == 0) else 'REVIEW'
print('  Overall integration status            : ' + overall)
print('')
print('NOTE: for the C2M-metadata side (external systems, outbound message types + processing')
print('      method, senders, inbound web services) run OSOAC2M-Discovery.sql and reconcile.')

try:
    serverConfig()
except:
    pass
try:
    disconnect()
except:
    pass
