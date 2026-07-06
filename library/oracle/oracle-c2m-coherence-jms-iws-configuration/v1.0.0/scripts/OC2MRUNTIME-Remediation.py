# OC2MRUNTIME-Remediation.py — create/repair missing C2M runtime objects (DRY-RUN by default).
#
# PURPOSE
#     Bring the JMS/Coherence configuration up to the expected named objects: create the
#     Coherence cluster if absent, the JMS server, the JMS module, the connection factory,
#     the queue and topic, and the subdeployment, using the solution reference names. By
#     default it only PRINTS the plan; it changes nothing until you pass the explicit apply
#     flag. IWS deployment itself is done with the OUAF iwsdeploy utility (shell), not here.
#
# HOW TO RUN
#     Dry-run (default, safe):
#         java weblogic.WLST OC2MRUNTIME-Remediation.py
#     Apply for real (inside a change window, after review):
#         OC2M_APPLY=true java weblogic.WLST OC2MRUNTIME-Remediation.py
#     Names/targets come from environment variables (see below); source ScopeHelper first.
#
# EXPECTED RESULTS
#     Dry-run prints "[PLAN] would create ..." lines and makes no changes (exit 0). Apply
#     mode prints "[APPLY] created ..." inside a single edit session and activates once;
#     objects that already exist are reported "[SKIP] exists" and left untouched.
#
# NOTES
#     White-label, repeatable. DRY-RUN is the default — it only edits when OC2M_APPLY=true,
#     and even then only creates missing objects (idempotent), never deletes. A server
#     restart is still required for Coherence/JMS changes to take effect.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL   = env('OC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER  = env('OC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS  = env('OC2M_ADMIN_PASS', '')
APPLY       = env('OC2M_APPLY', 'false').lower() in ('true', '1', 'yes')

CLUSTER     = env('OC2M_EXPECT_CLUSTER', 'c2m-coherence-cluster')
COH_PORT    = int(env('OC2M_COHERENCE_PORT', '7574'))     # verify for your version
JMSSVR      = env('OC2M_EXPECT_JMSSERVER', 'C2MJMSServer')
MODULE      = env('OC2M_EXPECT_JMSMODULE', 'C2MJMSModule')
CF_NAME     = env('OC2M_CF_NAME', 'C2MConnectionFactory')
CF_JNDI     = env('OC2M_EXPECT_CF_JNDI', 'jms/C2MConnectionFactory')
Q_NAME      = env('OC2M_QUEUE_NAME', 'C2MRealTimeQueue')
Q_JNDI      = env('OC2M_EXPECT_QUEUE_JNDI', 'jms/C2MRealTimeQueue')
T_NAME      = env('OC2M_TOPIC_NAME', 'C2MEventTopic')
T_JNDI      = env('OC2M_TOPIC_JNDI', 'jms/C2MEventTopic')
SUBDEP      = env('OC2M_SUBDEPLOYMENT', 'C2MJMSSubDeployment')
# target managed server or cluster for JMS objects
TARGET      = env('OC2M_JMS_TARGET', 'your-managed-server')

MODE = 'APPLY' if APPLY else 'PLAN'

def act(msg):
    print('[' + MODE + '] ' + msg)

def skip(msg):
    print('[SKIP] ' + msg)

def names_of(coll):
    try:
        return [x.getName() for x in coll]
    except:
        return []

try:
    connect(ADMIN_USER, ADMIN_PASS, ADMIN_URL)
except Exception, e:
    print('ERROR: could not connect to ' + ADMIN_URL + ' : ' + str(e))
    exit(exitcode=2)

print('C2M RUNTIME REMEDIATION  mode=' + MODE + '  (DRY-RUN unless OC2M_APPLY=true)')
print('Reference names: cluster=' + CLUSTER + ' jmsServer=' + JMSSVR + ' module=' + MODULE
      + ' target=' + TARGET)

edit()
if APPLY:
    startEdit()

# ---- Coherence cluster -----------------------------------------------------
existing_coh = names_of(cmo.getCoherenceClusterSystemResources())
if CLUSTER in existing_coh:
    skip('Coherence cluster exists: ' + CLUSTER)
else:
    act('create Coherence cluster ' + CLUSTER + ' (listen port ' + str(COH_PORT)
        + ', unicast preferred; verify for your version)')
    if APPLY:
        cmo.createCoherenceClusterSystemResource(CLUSTER)

# ---- JMS server ------------------------------------------------------------
existing_jms = names_of(cmo.getJMSServers())
if JMSSVR in existing_jms:
    skip('JMS server exists: ' + JMSSVR)
else:
    act('create JMS server ' + JMSSVR + ' (assign a persistent store; target ' + TARGET + ')')
    if APPLY:
        cmo.createJMSServer(JMSSVR)
        # NOTE: assign a persistent store and target in your environment step; left to the
        # admin so the correct file/JDBC store is chosen. See Implementation Guide Phase 2.

# ---- JMS module ------------------------------------------------------------
existing_mod = names_of(cmo.getJMSSystemResources())
mod = None
if MODULE in existing_mod:
    skip('JMS module exists: ' + MODULE)
    if APPLY:
        mod = cmo.lookupJMSSystemResource(MODULE)
else:
    act('create JMS module ' + MODULE + ' (target ' + TARGET + ')')
    if APPLY:
        mod = cmo.createJMSSystemResource(MODULE)

# ---- Destinations, CF, subdeployment (only meaningful in APPLY with a module) ----
if APPLY and mod is not None:
    res = mod.getJMSResource()

    if SUBDEP not in names_of(res.getSubDeployments()):
        act('create subdeployment ' + SUBDEP)
        mod.createSubDeployment(SUBDEP)
    else:
        skip('subdeployment exists: ' + SUBDEP)

    cf_jndis = []
    for cf in res.getConnectionFactories():
        cf_jndis.append(cf.getJNDIName())
    if CF_JNDI not in cf_jndis:
        act('create connection factory ' + CF_NAME + ' JNDI=' + CF_JNDI)
        cf = res.createConnectionFactory(CF_NAME)
        cf.setJNDIName(CF_JNDI)
        cf.setSubDeploymentName(SUBDEP)
    else:
        skip('connection factory JNDI exists: ' + CF_JNDI)

    q_jndis = []
    for q in res.getQueues():
        q_jndis.append(q.getJNDIName())
    if Q_JNDI not in q_jndis:
        act('create queue ' + Q_NAME + ' JNDI=' + Q_JNDI)
        q = res.createQueue(Q_NAME)
        q.setJNDIName(Q_JNDI)
        q.setSubDeploymentName(SUBDEP)
    else:
        skip('queue JNDI exists: ' + Q_JNDI)

    t_jndis = []
    for t in res.getTopics():
        t_jndis.append(t.getJNDIName())
    if T_JNDI not in t_jndis:
        act('create topic ' + T_NAME + ' JNDI=' + T_JNDI)
        t = res.createTopic(T_NAME)
        t.setJNDIName(T_JNDI)
        t.setSubDeploymentName(SUBDEP)
    else:
        skip('topic JNDI exists: ' + T_JNDI)
else:
    act('would create subdeployment ' + SUBDEP + ', connection factory ' + CF_NAME
        + ' (' + CF_JNDI + '), queue ' + Q_NAME + ' (' + Q_JNDI + '), topic ' + T_NAME
        + ' (' + T_JNDI + ')  [dry-run: assign store/targets per Implementation Guide]')

# ---- Commit ----------------------------------------------------------------
if APPLY:
    save()
    activate()
    print('[APPLY] changes activated. Restart affected servers for Coherence/JMS to take effect.')
else:
    print('[PLAN] no changes made. Re-run with OC2M_APPLY=true inside a change window to apply.')
    try:
        stopEdit('y')
    except:
        pass

print('REMINDER: deploy IWS separately with the OUAF iwsdeploy utility (see ScopeHelper / Implementation Guide).')
try:
    disconnect()
except:
    pass
