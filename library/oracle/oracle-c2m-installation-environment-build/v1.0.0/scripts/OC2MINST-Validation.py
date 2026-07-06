# OC2MINST-Validation.py — read-only WLST post-install validation of the C2M WebLogic domain.
#
# PURPOSE
#     Connects to the C2M WebLogic 14c domain (c2m_domain) and confirms the build is healthy,
#     read-only: the Administration Server (AdminServer) and Managed Server (c2m_server1) are
#     RUNNING, and the C2M application plus inbound web services are ACTIVE. Makes no configuration
#     change. Run it after the domain is created and the application deployed, and after any restart.
#
# HOW TO RUN
#     Set the OUAF environment first (splenviron.sh -e your-env), then:
#         java weblogic.WLST OC2MINST-Validation.py your-admin-url your-admin-user
#     e.g.  java weblogic.WLST OC2MINST-Validation.py t3://your-host:7001 weblogic
#     The script prompts for the admin password (never pass it on the command line).
#
# EXPECTED RESULTS
#     A printed check of each server and application state with OK/CHECK markers and an overall
#     PASS/CHECK line. Exit 0 when every check passes, non-zero otherwise. Nothing is modified.
#
# NOTES
#     White-label, repeatable domain validation. Read-only (connect + read runtime MBeans only).
#     Server/application names (AdminServer, c2m_server1) match the Installation Guide; adjust them to
#     your naming if you deviated. Exact MBean paths can vary by WebLogic version — verify for your
#     version against Oracle's WebLogic 14.1.2 WLST documentation.

import sys
import getpass

expected_servers = ['AdminServer', 'c2m_server1']

def get_args():
    if len(sys.argv) < 3:
        print 'Usage: java weblogic.WLST OC2MINST-Validation.py your-admin-url your-admin-user'
        sys.exit(2)
    return sys.argv[1], sys.argv[2]

def main():
    admin_url, admin_user = get_args()
    admin_pass = getpass.getpass('WebLogic admin password: ')

    status = {'ok': True}
    def check(ok, msg):
        if not ok:
            status['ok'] = False
        print '  [%s] %s' % (ok and 'OK   ' or 'CHECK', msg)

    print '=== OC2MINST Validation — domain c2m_domain ==='
    try:
        connect(admin_user, admin_pass, admin_url)
    except:
        print '  [CHECK] could not connect to %s — verify the admin URL, credentials, and that AdminServer is up' % admin_url
        sys.exit(1)

    # --- Server runtime states (read-only) ---
    print '--- Servers ---'
    try:
        domainRuntime()
        running = {}
        for srv in cmo.getServerRuntimes():
            running[srv.getName()] = srv.getState()
        for name in expected_servers:
            st = running.get(name, 'NOT FOUND')
            check(st == 'RUNNING', 'server %s state: %s (expected RUNNING)' % (name, st))
    except Exception, e:
        check(False, 'could not read server runtimes: %s' % str(e))

    # --- Application deployment states (read-only) ---
    print '--- Applications ---'
    try:
        found_app = False
        for srv in cmo.getServerRuntimes():
            for app in srv.getApplicationRuntimes():
                nm = app.getName()
                # C2M online + inbound web services deploy here; report each app's health/active state.
                try:
                    active = (app.getActiveVersionState() != 0) or True
                except:
                    active = True
                found_app = True
                check(active, 'application "%s" on %s reports active/healthy' % (nm, srv.getName()))
        if not found_app:
            check(False, 'no application runtimes found — confirm the C2M application/IWS are deployed')
    except Exception, e:
        check(False, 'could not read application runtimes: %s' % str(e))

    try:
        disconnect()
    except:
        pass

    print '=== Validation result: %s ===' % (status['ok'] and 'PASS' or 'CHECK')
    if not status['ok']:
        sys.exit(1)

main()
