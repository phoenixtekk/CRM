# OC2MRUNTIME-Validation.py — read-only pass/fail checks for the C2M runtime.
#
# PURPOSE
#     Validate the three runtime layers against the expected named objects and print a
#     PASS/FAIL line per check: Coherence cluster present and all in-scope servers are
#     members; JMS server running with the expected destinations / connection factory;
#     the spl-web-services (IWS) application deployed and active. Expected names default
#     to the solution reference names and can be overridden by environment variables.
#
# HOW TO RUN
#     Set OC2M_ADMIN_URL / OC2M_ADMIN_USER / OC2M_ADMIN_PASS (and optional OC2M_EXPECT_* /
#     OC2M_SCOPE_SERVERS from ScopeHelper), then:
#         java weblogic.WLST OC2MRUNTIME-Validation.py
#
# EXPECTED RESULTS
#     One [PASS]/[FAIL] line per check and a summary count. Process exit code is 0 when
#     every check passes, 1 when any check fails (so it gates a pipeline/change step).
#
# NOTES
#     White-label, repeatable. Read-only: reads the config/runtime MBeans only, no edits —
#     safe on production. Reuse the same expected names in every environment via ScopeHelper.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL   = env('OC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER  = env('OC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS  = env('OC2M_ADMIN_PASS', '')

EXP_CLUSTER = env('OC2M_EXPECT_CLUSTER', 'c2m-coherence-cluster')
EXP_JMSSVR  = env('OC2M_EXPECT_JMSSERVER', 'C2MJMSServer')
EXP_MODULE  = env('OC2M_EXPECT_JMSMODULE', 'C2MJMSModule')
EXP_CF_JNDI = env('OC2M_EXPECT_CF_JNDI', 'jms/C2MConnectionFactory')
EXP_Q_JNDI  = env('OC2M_EXPECT_QUEUE_JNDI', 'jms/C2MRealTimeQueue')
EXP_IWS     = env('OC2M_EXPECT_IWS', 'spl-web-services')
# comma-separated list of servers expected to be Coherence members / RUNNING
SCOPE_SRV   = [s.strip() for s in env('OC2M_SCOPE_SERVERS', '').split(',') if s.strip()]

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

print('C2M RUNTIME VALIDATION')
print('Expected cluster=' + EXP_CLUSTER + ' jmsServer=' + EXP_JMSSVR + ' module=' + EXP_MODULE)

# ---- Coherence -------------------------------------------------------------
try:
    edit()
except:
    pass
names = safe(lambda: [c.getName() for c in cmo.getCoherenceClusterSystemResources()], [])
check(EXP_CLUSTER in (names or []), 'Coherence cluster present', 'found=' + str(names))

# Membership: in-scope servers should be RUNNING (proxy for joined membership)
try:
    domainRuntime()
    running = {}
    for s in cmo.getServerRuntimes():
        running[s.getName()] = s.getState()
    if SCOPE_SRV:
        for srv in SCOPE_SRV:
            st = running.get(srv, 'NOT-FOUND')
            check(st == 'RUNNING', 'Coherence member/server RUNNING: ' + srv, 'state=' + st)
    else:
        allrun = len(running) > 0 and all([v == 'RUNNING' for v in running.values()])
        check(allrun, 'All managed servers RUNNING', 'states=' + str(running))
except Exception, e:
    check(False, 'Coherence membership readable', str(e))
finally:
    try:
        edit()
    except:
        pass

# ---- JMS -------------------------------------------------------------------
jms_names = safe(lambda: [j.getName() for j in cmo.getJMSServers()], [])
check(EXP_JMSSVR in (jms_names or []), 'JMS server present', 'found=' + str(jms_names))

# JMS server RUNNING (runtime)
try:
    domainRuntime()
    jms_run = {}
    for s in cmo.getServerRuntimes():
        for jr in safe(lambda: s.getJMSRuntime().getJMSServers(), []):
            jms_run[jr.getName()] = 'RUNNING'
    check(EXP_JMSSVR in jms_run, 'JMS server RUNNING', 'running=' + str(list(jms_run.keys())))
except Exception, e:
    check(False, 'JMS server runtime readable', str(e))
finally:
    try:
        edit()
    except:
        pass

# Destination + CF JNDI present in the expected module
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
check(cf_ok, 'Connection factory JNDI present', EXP_CF_JNDI)
check(q_ok,  'Queue JNDI present', EXP_Q_JNDI)

# ---- IWS -------------------------------------------------------------------
iws_ok = False
iws_active = False
try:
    for ad in cmo.getAppDeployments():
        if ad.getName().lower().find(EXP_IWS.lower()) >= 0:
            iws_ok = True
except Exception, e:
    print('  (deployment read error: ' + str(e) + ')')
check(iws_ok, 'IWS application deployed (config)', EXP_IWS)

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
        serverConfig()
    except:
        pass
check(iws_active, 'IWS application active (runtime)', EXP_IWS)

# ---- Summary ---------------------------------------------------------------
print('')
print('SUMMARY: ' + str(PASS) + ' passed, ' + str(FAIL) + ' failed')
try:
    disconnect()
except:
    pass
if FAIL > 0:
    exit(exitcode=1)
else:
    exit(exitcode=0)
