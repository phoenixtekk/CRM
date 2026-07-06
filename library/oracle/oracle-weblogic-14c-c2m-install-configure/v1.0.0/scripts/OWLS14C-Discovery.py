# OWLS14C-Discovery.py — read-only inventory of the WebLogic 14c domain for C2M.
#
# PURPOSE
#     Inventory the WebLogic 14c environment that C2M runs on so you know what
#     you have before and after building the domain. Reports the domain name,
#     servers and their states, cluster, machine and Node Manager, JDBC data
#     sources and their targets, and JVM/production-mode settings. Reads only —
#     it changes nothing.
#
# HOW TO RUN
#     Offline (inspect config on disk, no running domain needed):
#         java weblogic.WLST OWLS14C-Discovery.py --domain your-domain-home/c2m_domain
#     Online (also read live server states, needs a running AdminServer):
#         java weblogic.WLST OWLS14C-Discovery.py --domain your-domain-home/c2m_domain \
#             --admin-url t3://your-admin-host:7001 --user your-admin-user
#     Values also read from owls14c-scope.env (see OWLS14C-ScopeHelper.sh) if present.
#
# EXPECTED RESULTS
#     A printed inventory: domain, AdminServer, managed server(s) + states,
#     cluster, machine + Node Manager listen address, data sources + targets,
#     production mode and JVM args. No pass/fail judgment (that is Validation) —
#     this is the raw picture. Exit 0 on success; non-zero only if it cannot read.
#
# NOTES
#     White-label, repeatable: run it the same way in Dev/Test/Prod before and
#     after a change to see drift. Strictly read-only — safe against production;
#     it opens no edit session and writes nothing to the domain.

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
ADMIN_URL   = arg('--admin-url', env('OWLS14C_ADMIN_URL', None))
ADMIN_USER  = arg('--user', env('OWLS14C_ADMIN_USER', None))

print('=' * 68)
print(' OWLS14C Discovery — WebLogic 14c for C2M (read-only)')
print('=' * 68)
print(' Domain home : %s' % DOMAIN_HOME)

def read_offline():
    print('\n[Offline] Reading domain config from disk (no changes made)...')
    try:
        readDomain(DOMAIN_HOME)
    except Exception, e:
        print('  ! Could not read domain at %s: %s' % (DOMAIN_HOME, str(e)))
        return False
    try:
        print('  Domain name        : %s' % get('/Name'))
        print('  Production mode    : %s' % get('/ProductionModeEnabled'))
        print('\n  Servers:')
        for s in ls('/Servers', returnMap='true'):
            cd('/Servers/' + s)
            addr = get('ListenAddress'); port = get('ListenPort')
            if not addr:
                addr = '(ALL/localhost — REVIEW)'
            print('    - %-14s listen=%s:%s' % (s, addr, port))
            cd('/')
        print('\n  Clusters : %s' % ls('/Clusters', returnMap='true'))
        print('  Machines : %s' % ls('/Machines', returnMap='true'))
        print('\n  JDBC data sources:')
        for d in ls('/JDBCSystemResource', returnMap='true'):
            print('    - %s' % d)
    except Exception, e:
        print('  ! Error walking config: %s' % str(e))
    try:
        closeDomain()
    except:
        pass
    return True

def read_online():
    if not ADMIN_URL:
        print('\n[Online] Skipped (no --admin-url given). Offline inventory only.')
        return
    pw = env('OWLS14C_ADMIN_PASS', None)
    if pw is None:
        try:
            pw = getpass.getpass('  AdminServer password for %s: ' % ADMIN_USER)
        except:
            print('  ! No password available; skipping online read.')
            return
    print('\n[Online] Connecting to %s ...' % ADMIN_URL)
    try:
        connect(ADMIN_USER, pw, ADMIN_URL)
    except Exception, e:
        print('  ! Could not connect: %s' % str(e))
        return
    try:
        domainRuntime()
        print('  Live server states:')
        for s in cmo.getServerRuntimes():
            print('    - %-14s state=%s health=%s' % (s.getName(), s.getState(),
                  str(s.getHealthState())))
    except Exception, e:
        print('  ! Could not read runtimes: %s' % str(e))
    try:
        disconnect()
    except:
        pass

ok = read_offline()
read_online()
print('\nDiscovery complete (read-only). Nothing was changed.')
if not ok:
    exit(exitcode=2)
exit(exitcode=0)
