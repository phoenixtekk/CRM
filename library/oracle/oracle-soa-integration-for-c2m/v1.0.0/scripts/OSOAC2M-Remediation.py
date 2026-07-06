# OSOAC2M-Remediation.py — create/repair the WebLogic-side C2M integration objects (DRY-RUN by default).
#
# PURPOSE
#     Bring the WebLogic integration JMS configuration up to the expected named objects that
#     back the C2M outbound JMS sender: create the integration JMS server, the JMS module, the
#     connection factory, the outbound queue, and the subdeployment, using the solution
#     reference names. By default it only PRINTS the plan; it changes nothing until you pass the
#     explicit apply flag. IWS deployment (iwsdeploy), the C2M metadata (external systems,
#     outbound message types, senders, inbound services), and SOA/OSB composites are done per
#     the Implementation Guide, not written here.
#
# HOW TO RUN
#     Dry-run (default, safe):
#         java weblogic.WLST OSOAC2M-Remediation.py
#     Apply for real (inside a change window, after review):
#         OSOAC2M_APPLY=true java weblogic.WLST OSOAC2M-Remediation.py
#     Names/targets come from environment variables (see below); source ScopeHelper first.
#
# EXPECTED RESULTS
#     Dry-run prints "[PLAN] would create ..." lines and makes no changes (exit 0). Apply mode
#     prints "[APPLY] created ..." inside a single edit session and activates once; objects that
#     already exist are reported "[SKIP] exists" and left untouched.
#
# NOTES
#     White-label, repeatable. DRY-RUN is the default — it only edits when OSOAC2M_APPLY=true,
#     and even then only creates missing objects (idempotent), never deletes. Assign the JMS
#     persistent store/target in your environment step; a restart is still required for JMS
#     changes to take effect. C2M metadata + SOA/OSB deployment are done separately.

import os

def env(name, default=''):
    v = os.environ.get(name)
    return v if v not in (None, '') else default

ADMIN_URL   = env('OSOAC2M_ADMIN_URL',  't3://your-admin-host:7001')
ADMIN_USER  = env('OSOAC2M_ADMIN_USER', 'your-weblogic-admin')
ADMIN_PASS  = env('OSOAC2M_ADMIN_PASS', '')
APPLY       = env('OSOAC2M_APPLY', 'false').lower() in ('true', '1', 'yes')

JMSSVR      = env('OSOAC2M_EXPECT_JMSSERVER', 'C2MIntegrationJMSServer')
MODULE      = env('OSOAC2M_EXPECT_JMSMODULE', 'C2MIntegrationJMSModule')
CF_NAME     = env('OSOAC2M_CF_NAME', 'C2MConnectionFactory')
CF_JNDI     = env('OSOAC2M_EXPECT_CF_JNDI', 'jms/C2MConnectionFactory')
Q_NAME      = env('OSOAC2M_QUEUE_NAME', 'C2MOutboundQueue')
Q_JNDI      = env('OSOAC2M_EXPECT_QUEUE_JNDI', 'jms/C2MOutboundQueue')
SUBDEP      = env('OSOAC2M_SUBDEPLOYMENT', 'C2MIntegrationSubDeployment')
# target managed server or cluster for the integration JMS objects
TARGET      = env('OSOAC2M_JMS_TARGET', 'your-managed-server')

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

print('C2M SOA INTEGRATION REMEDIATION  mode=' + MODE + '  (DRY-RUN unless OSOAC2M_APPLY=true)')
print('Reference names: jmsServer=' + JMSSVR + ' module=' + MODULE + ' target=' + TARGET)

edit()
if APPLY:
    startEdit()

# ---- Integration JMS server ------------------------------------------------
existing_jms = names_of(cmo.getJMSServers())
if JMSSVR in existing_jms:
    skip('JMS server exists: ' + JMSSVR)
else:
    act('create integration JMS server ' + JMSSVR + ' (assign a persistent store; target ' + TARGET + ')')
    if APPLY:
        cmo.createJMSServer(JMSSVR)
        # NOTE: assign a persistent store and target in your environment step; left to the
        # admin so the correct file/JDBC store is chosen. See Implementation Guide Phase 3.

# ---- Integration JMS module ------------------------------------------------
existing_mod = names_of(cmo.getJMSSystemResources())
mod = None
if MODULE in existing_mod:
    skip('JMS module exists: ' + MODULE)
    if APPLY:
        mod = cmo.lookupJMSSystemResource(MODULE)
else:
    act('create integration JMS module ' + MODULE + ' (target ' + TARGET + ')')
    if APPLY:
        mod = cmo.createJMSSystemResource(MODULE)

# ---- Subdeployment, connection factory, outbound queue ---------------------
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
        act('create outbound queue ' + Q_NAME + ' JNDI=' + Q_JNDI)
        q = res.createQueue(Q_NAME)
        q.setJNDIName(Q_JNDI)
        q.setSubDeploymentName(SUBDEP)
    else:
        skip('outbound queue JNDI exists: ' + Q_JNDI)
else:
    act('would create subdeployment ' + SUBDEP + ', connection factory ' + CF_NAME
        + ' (' + CF_JNDI + '), outbound queue ' + Q_NAME + ' (' + Q_JNDI
        + ')  [dry-run: assign store/targets per Implementation Guide]')

# ---- Commit ----------------------------------------------------------------
if APPLY:
    save()
    activate()
    print('[APPLY] changes activated. Restart affected servers for JMS to take effect.')
else:
    print('[PLAN] no changes made. Re-run with OSOAC2M_APPLY=true inside a change window to apply.')
    try:
        stopEdit('y')
    except:
        pass

print('REMINDER: deploy IWS with the OUAF iwsdeploy utility, configure C2M external system /')
print('          outbound message type / sender in C2M, and deploy SOA/OSB composites per the')
print('          Implementation Guide — those are not written by this script.')
try:
    disconnect()
except:
    pass
