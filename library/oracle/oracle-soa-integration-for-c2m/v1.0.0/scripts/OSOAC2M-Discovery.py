# OSOAC2M-Discovery.py — read-only snapshot of the C2M SOA/web-service integration surface.
#
# PURPOSE
#     Connect to a running WebLogic domain and snapshot the C2M integration surface:
#     the spl-web-services (IWS) application deployment and its targets, and any
#     integration-relevant JMS servers / modules / destinations / connection factories
#     that back outbound message senders. Read-only baseline evidence before any change.
#     Set admin-url, admin-user, and admin-password for your-domain via the environment
#     variables below. For the C2M-side metadata (external systems, outbound message
#     types, message senders, inbound web services) use the SQL companion OSOAC2M-Discovery.sql.
#
# HOW TO RUN
#     Set OSOAC2M_ADMIN_URL, OSOAC2M_ADMIN_USER, OSOAC2M_ADMIN_PASS (or source ScopeHelper output), then:
#         java weblogic.WLST OSOAC2M-Discovery.py
#     Optionally: java weblogic.WLST OSOAC2M-Discovery.py > osoac2m-discovery.out
#
# EXPECTED RESULTS
#     Prints a sectioned snapshot (IWS DEPLOYMENT / INTEGRATION JMS) to stdout. Exit 0 on a
#     clean read; nonzero only if it cannot connect. It never edits — safe to run any time.
#
# NOTES
#     White-label, repeatable. Read-only: no edit()/startEdit() writes — it only reads the
#     MBean tree, so it is safe against production. Reuse the same object names across
#     environments (see ScopeHelper). C2M metadata is read separately via the SQL companion.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL  = env('OSOAC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER = env('OSOAC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS = env('OSOAC2M_ADMIN_PASS', '')
EXP_IWS    = env('OSOAC2M_EXPECT_IWS', 'spl-web-services')

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

print('C2M SOA INTEGRATION DISCOVERY (read-only)')
print('Domain: ' + safe(lambda: cmo.getName()))

# ---- Inbound Web Services (IWS) deployment ---------------------------------
hr('IWS APPLICATION DEPLOYMENT (spl-web-services)')
try:
    found = 0
    for ad in cmo.getAppDeployments():
        nm = ad.getName()
        if nm.lower().find(EXP_IWS.lower()) >= 0 or nm.lower().find('iws') >= 0:
            found = 1
            tgts = safe(lambda: [t.getName() for t in ad.getTargets()], [])
            print('  AppDeployment: ' + nm + '  Targets=' + str(tgts))
    if not found:
        print('  (no spl-web-services / IWS application deployment found)')
except Exception, e:
    print('  (unable to read deployments: ' + str(e) + ')')

# Live app state, where available
try:
    domainRuntime()
    for s in cmo.getServerRuntimes():
        for ar in safe(lambda: s.getApplicationRuntimes(), []):
            if ar.getName().lower().find(EXP_IWS.lower()) >= 0:
                print('  Active on ' + s.getName() + ': ' + ar.getName()
                      + '  health=' + str(safe(lambda: ar.getHealthState(), '(n/a)')))
except Exception, e:
    print('  (application runtime unavailable: ' + str(e) + ')')
finally:
    try:
        serverConfig()
    except:
        pass

# ---- Integration JMS (outbound message senders backing) --------------------
hr('INTEGRATION JMS SERVERS')
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

hr('INTEGRATION JMS MODULES / DESTINATIONS / CONNECTION FACTORIES')
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

hr('END OF DISCOVERY')
print('NOTE: read C2M external systems / outbound message types / senders / inbound web')
print('      services with the SQL companion OSOAC2M-Discovery.sql for the full surface.')
try:
    disconnect()
except:
    pass
