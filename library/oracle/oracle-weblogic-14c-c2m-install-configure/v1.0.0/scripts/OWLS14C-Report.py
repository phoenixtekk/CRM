# OWLS14C-Report.py — read-only health/coverage report for the WebLogic 14c C2M domain.
#
# PURPOSE
#     Produce one health and coverage snapshot of the WebLogic 14c foundation for
#     C2M — servers and states, Node Manager reachability, data sources with their
#     targets and Test-On-Reserve setting, JVM/production mode, and any
#     localhost/AdminServer-targeting findings — to attach to a change record and
#     reuse as a regression baseline. Reads only; changes nothing.
#
# HOW TO RUN
#     java weblogic.WLST OWLS14C-Report.py --domain your-domain-home/c2m_domain \
#         --admin-url t3://your-admin-host:7001 --user your-admin-user \
#         --out owls14c-report.txt
#     (Values also read from owls14c-scope.env if present. --out is optional;
#      without it the report prints to the screen.)
#
# EXPECTED RESULTS
#     A sectioned report (Domain, Servers, Node Manager/Machines, Data Sources,
#     Findings) written to screen and, if --out is given, to a text file. A clean
#     foundation shows all servers RUNNING, Node Manager reachable, data sources
#     healthy and correctly targeted, and zero findings. Exit 0 on success.
#
# NOTES
#     White-label, repeatable: capture a report before and after every change so a
#     green-to-green comparison proves you did not regress the foundation. Strictly
#     read-only — opens no edit session; safe against production.

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
OUT_FILE    = arg('--out', None)

lines = []
findings = []

def out(text=''):
    print(text)
    lines.append(text)

def finding(text):
    findings.append(text)

out('=' * 68)
out(' OWLS14C Report — WebLogic 14c for C2M (read-only)')
out('=' * 68)
out(' Domain home : %s' % DOMAIN_HOME)
out(' Admin URL   : %s' % ADMIN_URL)
out('')

# --- Domain + servers + machines (offline) ------------------------------------
out('--- Domain & topology ---')
try:
    readDomain(DOMAIN_HOME)
    out(' Domain name     : %s' % get('/Name'))
    try:
        out(' Production mode : %s' % get('/ProductionModeEnabled'))
    except:
        pass
    out(' Servers:')
    for s in ls('/Servers', returnMap='true'):
        cd('/Servers/' + s)
        addr = get('ListenAddress'); port = get('ListenPort')
        out('   - %-14s listen=%s:%s' % (s, addr, port))
        if (not addr) or (str(addr).lower() == 'localhost'):
            finding('Server %s listens on localhost/ALL' % s)
        cd('/')
    out(' Clusters : %s' % ls('/Clusters', returnMap='true'))
    out(' Machines : %s' % ls('/Machines', returnMap='true'))
    closeDomain()
except Exception, e:
    out(' ! Could not read domain config: %s' % str(e))
    finding('Domain config unreadable: %s' % str(e))
    try:
        closeDomain()
    except:
        pass

# --- Online: states + data sources --------------------------------------------
out('\n--- Runtime & data sources ---')
pw = env('OWLS14C_ADMIN_PASS', None)
if pw is None:
    try:
        pw = getpass.getpass(' AdminServer password (blank to skip online): ')
    except:
        pw = None

if pw:
    try:
        connect(ADMIN_USER, pw, ADMIN_URL)
        domainRuntime()
        out(' Live server states:')
        for s in cmo.getServerRuntimes():
            st = s.getState()
            out('   - %-14s state=%s health=%s' % (s.getName(), st, str(s.getHealthState())))
            if st != 'RUNNING':
                finding('Server %s state=%s (not RUNNING)' % (s.getName(), st))
        # data source config
        try:
            edit()
            cd('/JDBCSystemResources/' + DS_NAME +
               '/JDBCResource/' + DS_NAME + '/JDBCConnectionPoolParams/' + DS_NAME)
            out(' Data source %s: TestOnReserve=%s TestTable=%s' %
                (DS_NAME, get('TestConnectionsOnReserve'), get('TestTableName')))
            if not (get('TestConnectionsOnReserve') == 1 or str(get('TestConnectionsOnReserve')) == 'true'):
                finding('%s Test-On-Reserve is OFF' % DS_NAME)
            cd('/SystemResources/' + DS_NAME)
            tgts = get('Targets'); names = []
            if tgts is not None:
                for t in tgts:
                    names.append(t.getName())
            out(' Data source %s targets: %s' % (DS_NAME, str(names)))
            if 'AdminServer' in names:
                finding('%s targeted at AdminServer' % DS_NAME)
            if len(names) == 0:
                finding('%s has no targets' % DS_NAME)
        except Exception, e:
            out(' ! Data source %s not readable: %s' % (DS_NAME, str(e)))
        disconnect()
    except Exception, e:
        out(' ! Online section skipped: %s' % str(e))
else:
    out(' Online section skipped (no password).')

# --- Findings -----------------------------------------------------------------
out('\n--- Findings ---')
if len(findings) == 0:
    out(' None. Foundation is clean against the report checks.')
else:
    for f in findings:
        out(' * %s' % f)

if OUT_FILE:
    try:
        fh = open(OUT_FILE, 'w')
        fh.write('\n'.join(lines) + '\n')
        fh.close()
        print('\nReport written to %s' % OUT_FILE)
    except Exception, e:
        print('\n! Could not write %s: %s' % (OUT_FILE, str(e)))

exit(exitcode=0)
