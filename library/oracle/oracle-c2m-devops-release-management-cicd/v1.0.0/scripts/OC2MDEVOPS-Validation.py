# OC2MDEVOPS-Validation.py — read-only WLST parity/health validation of a release-pipeline target.
#
# PURPOSE
#     Confirm a C2M release landed cleanly on a target from the WebLogic side after the deploy stage:
#     that the domain is reachable, the C2M managed and admin servers are in the running state, and
#     the in-scope Inbound Web Service (IWS) modules are deployed and active (not stale). Pair it with
#     OC2MDEVOPS-Report.sql (config-object + build-level compare) for the full validate-stage gate.
#     Read-only — it reads deployment and server state through WLST, it never deploys, redeploys,
#     starts, stops, or changes anything.
#
# HOW TO RUN
#     source the product environment, then run under the OUAF WLST wrapper, e.g.
#       wlst.sh OC2MDEVOPS-Validation.py your-target-env
#     Connection comes from the environment (ENVIRON.INI / wlst connect), or export:
#       OC2MDEVOPS_ADMIN_URL   e.g. t3://your-admin-host:7001
#       OC2MDEVOPS_WLS_USER    WebLogic admin user (read-only monitor role is sufficient)
#       OC2MDEVOPS_IWS         comma-separated in-scope IWS app/module names for this release
#     The password is read from OC2MDEVOPS_WLS_PASS if set, otherwise WLST prompts (never hard-coded).
#
# EXPECTED RESULTS
#     A domain-reachability line, a PASS/GAP line per server (running vs not), and a PASS/GAP line per
#     in-scope IWS module (active vs not-deployed/stale). All PASS means the WebLogic side of parity
#     and health is met; any GAP names the server to start or the module to (re)deploy with iwsdeploy.
#     Non-zero exit if any GAP is found.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live domain. WLST/Jython, not PowerShell.
#     The online IWS deployment portal is dev-only; QA/Prod use command-line iwsdeploy. Verify MBean
#     paths / server / service names for your WebLogic 14c / C2M version (C2M 25.4 / min v2.9).

import os
import sys

env_name  = sys.argv[1] if len(sys.argv) > 1 else 'your-target-env'
admin_url = os.environ.get('OC2MDEVOPS_ADMIN_URL', 't3://your-admin-host:7001')
wls_user  = os.environ.get('OC2MDEVOPS_WLS_USER',  'weblogic')
wls_pass  = os.environ.get('OC2MDEVOPS_WLS_PASS')   # None -> WLST connect() will prompt

# In-scope IWS application/module names for this release. Override via OC2MDEVOPS_IWS
# (comma-separated) to match the release scope; defaults are placeholders to replace.
iws_scope = os.environ.get('OC2MDEVOPS_IWS', 'your-iws-app-1,your-iws-app-2').split(',')

print('')
print('=== OC2MDEVOPS Validation (read-only) — target: %s ===' % env_name)

gaps = 0
try:
    if wls_pass:
        connect(wls_user, wls_pass, admin_url)
    else:
        connect(userConfigFile=None, url=admin_url)   # prompts for credentials if not supplied
    print('[domain] reachable at %s : PASS' % admin_url)
except Exception, e:   # noqa: E722 (Jython 2.x syntax)
    print('[domain] NOT reachable at %s : GAP (%s)' % (admin_url, str(e)))
    print('=== end OC2MDEVOPS Validation (%s) — could not connect ===' % env_name)
    sys.exit(2)

try:
    domainRuntime()

    # --- Server running state (read-only) ------------------------------------------------------
    try:
        servers = cmo.getServerRuntimes()
        if servers is None or len(servers) == 0:
            print('[server] no server runtimes read — verify domain / monitor role')
        for srt in servers:
            sname = srt.getName()
            sstate = srt.getState()
            if str(sstate).upper() == 'RUNNING':
                print('[server] %-24s : PASS (running)' % sname)
            else:
                gaps += 1
                print('[server] %-24s : GAP  (state=%s) — start this server' % (sname, str(sstate)))
    except Exception, se:   # noqa
        print('[server] could not read server runtimes : GAP (%s)' % str(se))
        gaps += 1

    # --- In-scope IWS module state (read-only) -------------------------------------------------
    for app in iws_scope:
        app = app.strip()
        if app == '':
            continue
        state = None
        try:
            ars = cmo.lookupAppRuntimeStateRuntime()
            state = ars.getCurrentState(app, env_name)
        except Exception:
            state = None
        if state is not None and str(state).upper() == 'STATE_ACTIVE':
            print('[iws] %-28s : PASS (active)' % app)
        else:
            gaps += 1
            print('[iws] %-28s : GAP  (state=%s) — deploy with iwsdeploy on this target'
                  % (app, str(state)))
finally:
    try:
        disconnect()
    except Exception:
        pass

print('')
if gaps == 0:
    print('WebLogic parity/health: PASS on %s. Also run OC2MDEVOPS-Report.sql for config/build compare.' % env_name)
else:
    print('WebLogic parity/health: %d GAP(s) on %s — fix the named server/module, then re-run.' % (gaps, env_name))
print('=== end OC2MDEVOPS Validation (%s) ===' % env_name)
sys.exit(0 if gaps == 0 else 1)
