# OSOAC2M-Validation.py — read-only pass/fail checks for the C2M SOA-integration surface.
#
# PURPOSE
#     Validate the WebLogic-side integration surface against the expected named objects and
#     print a PASS/FAIL line per check: the spl-web-services (IWS) application deployed and
#     active, and the integration JMS server / module / connection factory / queue that back
#     the outbound JMS sender present with the expected JNDI names. Expected names default to
#     the solution reference names and can be overridden by environment variables. C2M-side
#     metadata (external systems, outbound message types, senders, inbound services) is
#     validated with the SQL companion; this script covers the deployed endpoints/JMS.
#
# HOW TO RUN
#     Set OSOAC2M_ADMIN_URL / OSOAC2M_ADMIN_USER / OSOAC2M_ADMIN_PASS (and optional
#     OSOAC2M_EXPECT_* / OSOAC2M_SCOPE_SERVERS from ScopeHelper), then:
#         java weblogic.WLST OSOAC2M-Validation.py
#
# EXPECTED RESULTS
#     One [PASS]/[FAIL] line per check and a summary count. Process exit code is 0 when every
#     check passes, 1 when any check fails (so it gates a pipeline/change step).
#
# NOTES
#     White-label, repeatable. Read-only: reads the config/runtime MBeans only, no edits —
#     safe on production. Reuse the same expected names in every environment via ScopeHelper.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL   = env('OSOAC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER  = env('OSOAC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS  = env('OSOAC2M_ADMIN_PASS', '')

EXP_IWS     = env('OSOAC2M_EXPECT_IWS', 'spl-web-services')
EXP_JMSSVR  = env('OSOAC2M_EXPECT_JMSSERVER', 'C2MIntegrationJMSServer')
EXP_MODULE  = env('OSOAC2M_EXPECT_JMSMODULE', 'C2MIntegrationJMSModule')
EXP_CF_JNDI = env('OSOAC2M_EXPECT_CF_JNDI', 'jms/C2MConnectionFactory')
EXP_Q_JNDI  = env('OSOAC2M_EXPECT_QUEUE_JNDI', 'jms/C2MOutboundQueue')
# comma-separated list of servers expected to host the integration surface / be RUNNING
SCOPE_SRV   = [s.strip() for s in env('OSOAC2M_SCOPE_SERVERS', '').split(',') if s.strip()]

PASS = 0
FAIL = 0

def check(ok, label, detail=''):
    global PASS, FAIL
    if ok:
        PASS += 1
        print('[PASS] ' + label + ('  ' + detail if detail else ''))
    else:
        FAIL += 1
        print('[FAIL] ' + label + ('  ' + detail if detail else ''))

def safe(fn, default=None):
    try:
        return fn()
    except:
        return default

try:
    connect(ADMIN_USER, ADMIN_PASS, ADMIN_URL)
except Exception, e:
    print('[FAIL] connect  could not reach ' + ADMIN_URL + ' : ' + str(e))
    exit(exitcode=1)

print('C2M SOA INTEGRATION VALIDATION')
print('Expected iws=' + EXP_IWS + ' jmsServer=' + EXP_JMSSVR + ' module=' + EXP_MODULE)

# ---- Scope servers RUNNING -------------------------------------------------
try:
    domainRuntime()
    running = {}
    for s in cmo.getServerRuntimes():
        running[s.getName()] = s.getState()
    if SCOPE_SRV:
        for srv in SCOPE_SRV:
            st = running.get(srv, 'NOT-FOUND')
            check(st == 'RUNNING', 'Integration server RUNNING: ' + srv, 'state=' + st)
    else:
        allrun = len(running) > 0 and all([v == 'RUNNING' for v in running.values()])
        check(allrun, 'All managed servers RUNNING', 'states=' + str(running))
except Exception, e:
    check(False, 'Server states readable', str(e))
finally:
    try:
        edit()
    except:
        pass

# ---- IWS deployed (config) + active (runtime) ------------------------------
iws_ok = False
try:
    for ad in cmo.getAppDeployments():
        if ad.getName().lower().find(EXP_IWS.lower()) >= 0:
            iws_ok = True
except Exception, e:
    print('  (deployment read error: ' + str(e) + ')')
check(iws_ok, 'IWS application deployed (config)', EXP_IWS)

iws_active = False
try:
    domainRuntime()
    for s in cmo.getServerRuntimes():
        for ar in safe(lambda: s.getApplicationRuntimes(), []):
            if ar.getName().lower().find(EXP_IWS.lower()) >= 0:
                iws_active = True
except Exception, e:
    print('  (app runtime read error: ' + str(e) + ')')
finally:
    try:
        edit()
    except:
        pass
check(iws_active, 'IWS application active (runtime)', EXP_IWS)

# ---- Integration JMS server present ----------------------------------------
jms_names = safe(lambda: [j.getName() for j in cmo.getJMSServers()], [])
check(EXP_JMSSVR in (jms_names or []), 'Integration JMS server present', 'found=' + str(jms_names))

# ---- CF + queue JNDI present in the expected module ------------------------
cf_ok = False
q_ok = False
try:
    for m in cmo.getJMSSystemResources():
        if m.getName() != EXP_MODULE:
            continue
        res = m.getJMSResource()
        for cf in safe(lambda: res.getConnectionFactories(), []):
            if safe(lambda: cf.getJNDIName()) == EXP_CF_JNDI:
                cf_ok = True
        for q in safe(lambda: res.getQueues(), []):
            if safe(lambda: q.getJNDIName()) == EXP_Q_JNDI:
                q_ok = True
        for udq in safe(lambda: res.getUniformDistributedQueues(), []):
            if safe(lambda: udq.getJNDIName()) == EXP_Q_JNDI:
                q_ok = True
except Exception, e:
    print('  (JMS module read error: ' + str(e) + ')')
check(cf_ok, 'Outbound connection factory JNDI present', EXP_CF_JNDI)
check(q_ok,  'Outbound queue JNDI present', EXP_Q_JNDI)

# ---- Summary ---------------------------------------------------------------
print('')
print('NOTE: validate C2M external systems / outbound message types / senders / inbound')
print('      web services with the SQL companion OSOAC2M-Discovery.sql for the full surface.')
print('SUMMARY: ' + str(PASS) + ' passed, ' + str(FAIL) + ' failed')
try:
    disconnect()
except:
    pass
if FAIL > 0:
    exit(exitcode=1)
else:
    exit(exitcode=0)
