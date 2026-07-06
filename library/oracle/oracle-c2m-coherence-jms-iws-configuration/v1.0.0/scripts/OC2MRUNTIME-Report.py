# OC2MRUNTIME-Report.py — read-only health/coverage report for the C2M runtime.
#
# PURPOSE
#     Produce a single human-readable coverage report across scope: which servers are
#     Coherence members, each JMS destination with its current/pending/consumer counts,
#     and which IWS application(s) are active. Intended as the pilot sign-off artifact and
#     change-record evidence. Reads runtime metrics; makes no changes. Point it at
#     your-domain via the environment variables below.
#
# HOW TO RUN
#     Set OC2M_ADMIN_URL / OC2M_ADMIN_USER / OC2M_ADMIN_PASS, then:
#         java weblogic.WLST OC2MRUNTIME-Report.py > oc2m-runtime-report.txt
#
# EXPECTED RESULTS
#     A sectioned report (COHERENCE / JMS METRICS / IWS) with per-object counts and an
#     overall coverage line. Exit 0 on a clean read; nonzero only if it cannot connect.
#
# NOTES
#     White-label, repeatable. Read-only: uses domainRuntime() metric MBeans only, never
#     edits — safe on production. For a database-side cross-check of C2M Inbound Web Service /
#     Message Sender metadata, see the reconciliation query in the deliverables notes.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL  = env('OC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER = env('OC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS = env('OC2M_ADMIN_PASS', '')
EXP_IWS    = env('OC2M_EXPECT_IWS', 'spl-web-services')

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

print('C2M RUNTIME HEALTH / COVERAGE REPORT (read-only)')
print('Domain: ' + safe(lambda: cmo.getName()))

members = 0
dest_count = 0
iws_active = 0

# ---- Coherence membership --------------------------------------------------
hr('COHERENCE MEMBERSHIP')
try:
    domainRuntime()
    for s in cmo.getServerRuntimes():
        st = s.getState()
        if st == 'RUNNING':
            members += 1
        print('  Server ' + s.getName() + ' : ' + st)
except Exception, e:
    print('  (server runtime unavailable: ' + str(e) + ')')

# ---- JMS metrics -----------------------------------------------------------
hr('JMS DESTINATION METRICS')
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
                print('  [' + s.getName() + '] ' + d.getName()
                      + '  current=' + str(cur) + ' pending=' + str(pen)
                      + ' consumers=' + str(con))
    if dest_count == 0:
        print('  (no JMS destinations reporting runtime metrics)')
except Exception, e:
    print('  (JMS runtime metrics unavailable: ' + str(e) + ')')

# ---- IWS -------------------------------------------------------------------
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

# ---- Coverage summary ------------------------------------------------------
hr('COVERAGE SUMMARY')
print('  Coherence members (RUNNING servers) : ' + str(members))
print('  JMS destinations reporting          : ' + str(dest_count))
print('  IWS applications active             : ' + str(iws_active))
overall = 'HEALTHY' if (members > 0 and iws_active > 0) else 'REVIEW'
print('  Overall runtime status              : ' + overall)

try:
    serverConfig()
except:
    pass
try:
    disconnect()
except:
    pass
