# OC2MMIG-Validation.py — read-only WLST parity validation of a promotion target.
#
# PURPOSE
#     Confirm a C2M/OUAF promotion actually landed on a target environment, from the WebLogic side:
#     that the Inbound Web Service (IWS) modules for the release are deployed and in the active
#     state on the C2M managed server, and that the domain is reachable. Pair it with the SQL
#     import/build checks from OC2MMIG-Report to get the full parity picture. Read-only — it reads
#     deployment state through WLST, it never deploys, redeploys, starts, or stops anything.
#
# HOW TO RUN
#     source the product environment, then run under the OUAF WLST wrapper, e.g.
#       wlst.sh OC2MMIG-Validation.py your-target-env
#     Connection comes from the environment (ENVIRON.INI / wlst connect), or export:
#       OC2MMIG_ADMIN_URL   e.g. t3://your-admin-host:7001
#       OC2MMIG_WLS_USER    WebLogic admin user (read-only monitor role is sufficient)
#     The password is read from OC2MMIG_WLS_PASS if set, otherwise WLST prompts (never hard-coded).
#
# EXPECTED RESULTS
#     A PASS/GAP line per in-scope IWS module (STATE = active vs not-deployed/stale) and a domain
#     reachability line. All PASS means the IWS side of parity is met; any GAP names the module to
#     (re)deploy with iwsdeploy on the target. Non-zero exit if any GAP is found.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live domain. WLST/Jython, not PowerShell.
#     The online IWS deployment portal is dev-only; QA/Prod use command-line iwsdeploy. Verify MBean
#     paths/service names for your WebLogic 14c / C2M version.

import os
import sys

env_name  = sys.argv[1] if len(sys.argv) > 1 else 'your-target-env'
admin_url = os.environ.get('OC2MMIG_ADMIN_URL', 't3://your-admin-host:7001')
wls_user  = os.environ.get('OC2MMIG_WLS_USER',  'weblogic')
wls_pass  = os.environ.get('OC2MMIG_WLS_PASS')   # None -> WLST connect() will prompt

# In-scope IWS application/module names for this release. Override via OC2MMIG_IWS
# (comma-separated) to match the Migration Request scope; defaults are placeholders to replace.
iws_scope = os.environ.get('OC2MMIG_IWS', 'your-iws-app-1,your-iws-app-2').split(',')

print('')
print('=== OC2MMIG Validation (read-only) — target: %s ===' % env_name)

gaps = 0
try:
    if wls_pass:
        connect(wls_user, wls_pass, admin_url)
    else:
        connect(userConfigFile=None, url=admin_url)   # prompts for credentials if not supplied
    print('[domain] reachable at %s : PASS' % admin_url)
except Exception, e:   # noqa: E722 (Jython 2.x syntax)
    print('[domain] NOT reachable at %s : GAP (%s)' % (admin_url, str(e)))
    print('=== end OC2MMIG Validation (%s) — could not connect ===' % env_name)
    sys.exit(2)

try:
    domainRuntime()
    for app in iws_scope:
        app = app.strip()
        if app == '':
            continue
        state = None
        try:
            # Read-only: walk AppRuntimeStateRuntime for the module's current state.
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
    print('IWS parity: PASS for all in-scope modules on %s.' % env_name)
else:
    print('IWS parity: %d GAP(s) on %s — (re)deploy the named modules, then re-run.' % (gaps, env_name))
print('=== end OC2MMIG Validation (%s) ===' % env_name)
sys.exit(0 if gaps == 0 else 1)
