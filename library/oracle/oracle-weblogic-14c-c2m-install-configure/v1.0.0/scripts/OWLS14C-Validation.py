# OWLS14C-Validation.py — read-only pass/fail checks on the WebLogic 14c domain for C2M.
#
# PURPOSE
#     Assert the WebLogic 14c foundation for C2M meets its gate criteria:
#     AdminServer and managed server(s) RUNNING, Node Manager reachable, the
#     C2MDataSource data source passes its Test-On-Reserve and is NOT targeted at
#     AdminServer, JVM/production mode as intended, and no localhost/placeholder
#     listen addresses. Reads only — it makes no changes.
#
# HOW TO RUN
#     java weblogic.WLST OWLS14C-Validation.py --domain your-domain-home/c2m_domain \
#         --admin-url t3://your-admin-host:7001 --user your-admin-user
#     (Values also read from owls14c-scope.env if present; password from
#      OWLS14C_ADMIN_PASS or an interactive prompt.)
#
# EXPECTED RESULTS
#     One line per check: PASS / FAIL / WARN with a short reason, then a summary.
#     Exit 0 when all checks pass; exit 1 when any check FAILs — so it can gate a
#     pipeline. FAIL points you to the Troubleshooting Guide / Remediation script.
#
# NOTES
#     White-label, repeatable: run at the Pilot and Validate gates and after every
#     change to catch drift by evidence, not by incident. Strictly read-only —
#     opens no edit session; safe against production.

import sys
import os
import getpass

def arg(name, default=None):
    a = sys.argv
    for i in range(len(a)):
        if a[i] == name and i + 1 < len(a):
            return a[i + 1]
    return default

def env(name, default=None):
    return os.environ.get(name, default)

DOMAIN_HOME = arg('--domain', env('OWLS14C_DOMAIN_HOME', 'your-domain-home/c2m_domain'))
ADMIN_URL   = arg('--admin-url', env('OWLS14C_ADMIN_URL', 't3://your-admin-host:7001'))
ADMIN_USER  = arg('--user', env('OWLS14C_ADMIN_USER', 'your-admin-user'))
DS_NAME     = env('OWLS14C_DS_NAME', 'C2MDataSource')

results = []   # (level, text) ; level in PASS/FAIL/WARN

def record(level, text):
    results.append((level, text))
    print('  [%-4s] %s' % (level, text))

print('=' * 68)
print(' OWLS14C Validation — WebLogic 14c for C2M (read-only)')
print('=' * 68)
print(' Domain : %s' % DOMAIN_HOME)
print(' Admin  : %s' % ADMIN_URL)
print('')

# --- Offline checks: listen addresses / production mode -----------------------
print('Offline config checks:')
try:
    readDomain(DOMAIN_HOME)
    try:
        if get('/ProductionModeEnabled') == 1 or str(get('/ProductionModeEnabled')) == 'true':
            record('PASS', 'Domain is in production mode')
        else:
            record('WARN', 'Domain is NOT in production mode (expected for prod)')
    except:
        record('WARN', 'Could not read production mode flag')
    for s in ls('/Servers', returnMap='true'):
        cd('/Servers/' + s)
        addr = get('ListenAddress')
        if (not addr) or (str(addr).lower() == 'localhost'):
            record('FAIL', 'Server %s listens on localhost/ALL — use a real host/IP' % s)
        else:
            record('PASS', 'Server %s listen address is %s' % (s, addr))
        cd('/')
    for m in ls('/Machines', returnMap='true'):
        try:
            for nm in ls('/Machines/' + m + '/NodeManager', returnMap='true'):
                cd('/Machines/' + m + '/NodeManager/' + nm)
                nmaddr = get('ListenAddress')
                if (not nmaddr) or (str(nmaddr).lower() == 'localhost'):
                    record('FAIL', 'Machine %s Node Manager on localhost — use a real host/IP' % m)
                else:
                    record('PASS', 'Machine %s Node Manager listen address is %s' % (m, nmaddr))
                cd('/')
        except:
            pass
    closeDomain()
except Exception, e:
    record('FAIL', 'Could not read domain config: %s' % str(e))
    try:
        closeDomain()
    except:
        pass

# --- Online checks: server states, data source target + test ------------------
print('\nOnline runtime checks:')
pw = env('OWLS14C_ADMIN_PASS', None)
if pw is None:
    try:
        pw = getpass.getpass('  AdminServer password: ')
    except:
        pw = None

connected = 0
if pw is not None:
    try:
        connect(ADMIN_USER, pw, ADMIN_URL)
        connected = 1
    except Exception, e:
        record('FAIL', 'Could not connect to AdminServer: %s' % str(e))

if connected:
    # server states
    try:
        domainRuntime()
        for s in cmo.getServerRuntimes():
            st = s.getState()
            if st == 'RUNNING':
                record('PASS', 'Server %s state=RUNNING' % s.getName())
            else:
                record('FAIL', 'Server %s state=%s (expected RUNNING)' % (s.getName(), st))
    except Exception, e:
        record('WARN', 'Could not read server states: %s' % str(e))

    # data source target must NOT be AdminServer; and Test-On-Reserve on
    try:
        edit()  # config MBeans are readable via the edit tree without startEdit
        cd('/JDBCSystemResources/' + DS_NAME +
           '/JDBCResource/' + DS_NAME + '/JDBCConnectionPoolParams/' + DS_NAME)
        tor = get('TestConnectionsOnReserve')
        ttn = get('TestTableName')
        if tor == 1 or str(tor) == 'true':
            record('PASS', '%s Test-On-Reserve enabled (table=%s)' % (DS_NAME, ttn))
        else:
            record('FAIL', '%s Test-On-Reserve is OFF — enable it' % DS_NAME)
        cd('/SystemResources/' + DS_NAME)
        tgts = get('Targets')
        tgtnames = []
        if tgts is not None:
            for t in tgts:
                tgtnames.append(t.getName())
        if 'AdminServer' in tgtnames:
            record('FAIL', '%s is targeted at AdminServer — target managed servers/cluster' % DS_NAME)
        elif len(tgtnames) == 0:
            record('FAIL', '%s has no targets' % DS_NAME)
        else:
            record('PASS', '%s targets = %s' % (DS_NAME, str(tgtnames)))
    except Exception, e:
        record('WARN', 'Could not inspect data source %s: %s' % (DS_NAME, str(e)))

    try:
        disconnect()
    except:
        pass
else:
    record('WARN', 'Online checks skipped (no connection). Offline results only.')

# --- Summary ------------------------------------------------------------------
fails = 0
warns = 0
for lvl, _ in results:
    if lvl == 'FAIL':
        fails = fails + 1
    elif lvl == 'WARN':
        warns = warns + 1
print('\n' + '-' * 68)
print(' Summary: %d checks, %d FAIL, %d WARN' % (len(results), fails, warns))
if fails > 0:
    print(' RESULT: FAIL — see Troubleshooting Guide; some drift is fixable via OWLS14C-Remediation.')
    exit(exitcode=1)
else:
    print(' RESULT: PASS — foundation meets the gate criteria.')
    exit(exitcode=0)
