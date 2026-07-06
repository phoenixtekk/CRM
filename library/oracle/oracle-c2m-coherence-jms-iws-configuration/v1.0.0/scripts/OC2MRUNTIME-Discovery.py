# OC2MRUNTIME-Discovery.py — read-only snapshot of the C2M runtime (Coherence, JMS, IWS).
#
# PURPOSE
#     Connect to a running WebLogic domain and snapshot the current C2M runtime
#     configuration: Coherence cluster(s) and members, JMS servers / modules /
#     destinations / connection factories, and the spl-web-services (IWS) deployment.
#     Read-only baseline evidence before any change. Set admin-url, admin-user, and
#     admin-password for your-domain via the environment variables below.
#
# HOW TO RUN
#     Set OC2M_ADMIN_URL, OC2M_ADMIN_USER, OC2M_ADMIN_PASS (or source ScopeHelper output), then:
#         java weblogic.WLST OC2MRUNTIME-Discovery.py
#     Optionally: java weblogic.WLST OC2MRUNTIME-Discovery.py > oc2m-discovery.out
#
# EXPECTED RESULTS
#     Prints a sectioned snapshot (COHERENCE / JMS / IWS) to stdout. Exit 0 on a clean
#     read; nonzero only if it cannot connect. It never edits — safe to run any time.
#
# NOTES
#     White-label, repeatable. Read-only: no edit()/startEdit() — it only reads the MBean
#     tree, so it is safe against production. Reuse the same object names across environments.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL  = env('OC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER = env('OC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS = env('OC2M_ADMIN_PASS', '')

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

print('C2M RUNTIME DISCOVERY (read-only)')
print('Domain: ' + safe(lambda: cmo.getName()))

# ---- Coherence -------------------------------------------------------------
hr('COHERENCE CLUSTERS')
try:
    cds = cmo.getCoherenceClusterSystemResources()
    if not cds:
        print('  (no Coherence cluster system resources defined)')
    for c in cds:
        print('  Cluster: ' + c.getName())
        tgts = safe(lambda: [t.getName() for t in c.getTargets()], [])
        print('    Targets: ' + str(tgts))
except Exception, e:
    print('  (unable to read Coherence resources: ' + str(e) + ')')

# Live membership via the domain runtime, where available
try:
    domainRuntime()
    cd('/')
    servers = cmo.getServerRuntimes()
    print('  Managed-server runtime states:')
    for s in servers:
        print('    ' + s.getName() + ' : ' + s.getState())
except Exception, e:
    print('  (server runtime membership unavailable: ' + str(e) + ')')
finally:
    try:
        serverConfig()
    except:
        pass

# ---- JMS -------------------------------------------------------------------
hr('JMS SERVERS')
try:
    edit()  # navigate config tree read-only; no startEdit()/save()
except:
    pass
try:
    for js in cmo.getJMSServers():
        print('  JMSServer: ' + js.getName())
        store = safe(lambda: js.getPersistentStore().getName() if js.getPersistentStore() else '(none)')
        print('    PersistentStore: ' + str(store))
except Exception, e:
    print('  (unable to read JMS servers: ' + str(e) + ')')

hr('JMS MODULES / DESTINATIONS / CONNECTION FACTORIES')
try:
    for m in cmo.getJMSSystemResources():
        print('  JMSModule: ' + m.getName())
        res = m.getJMSResource()
        for q in safe(lambda: res.getQueues(), []):
            print('    Queue: ' + q.getName() + '  JNDI=' + safe(lambda: q.getJNDIName()))
        for t in safe(lambda: res.getTopics(), []):
            print('    Topic: ' + t.getName() + '  JNDI=' + safe(lambda: t.getJNDIName()))
        for udq in safe(lambda: res.getUniformDistributedQueues(), []):
            print('    UDQueue: ' + udq.getName() + '  JNDI=' + safe(lambda: udq.getJNDIName()))
        for cf in safe(lambda: res.getConnectionFactories(), []):
            print('    ConnFactory: ' + cf.getName() + '  JNDI=' + safe(lambda: cf.getJNDIName()))
        for sd in safe(lambda: res.getSubDeployments(), []):
            print('    SubDeployment: ' + sd.getName())
except Exception, e:
    print('  (unable to read JMS modules: ' + str(e) + ')')

# ---- IWS -------------------------------------------------------------------
hr('INBOUND WEB SERVICES (IWS) DEPLOYMENT')
try:
    found = 0
    for ad in cmo.getAppDeployments():
        nm = ad.getName()
        if nm.lower().find('spl-web-services') >= 0 or nm.lower().find('iws') >= 0:
            found = 1
            tgts = safe(lambda: [t.getName() for t in ad.getTargets()], [])
            print('  AppDeployment: ' + nm + '  Targets=' + str(tgts))
    if not found:
        print('  (no spl-web-services / IWS application deployment found)')
except Exception, e:
    print('  (unable to read deployments: ' + str(e) + ')')

hr('END OF DISCOVERY')
try:
    disconnect()
except:
    pass
