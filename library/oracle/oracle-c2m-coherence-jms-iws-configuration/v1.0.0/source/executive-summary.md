# Executive Summary — C2M Coherence, JMS & Inbound Web Services Configuration

## The problem

Oracle Utilities **Customer to Meter (C2M)** only clusters, messages, and integrates when three
runtime layers are configured correctly on **Oracle WebLogic Server**: the **Coherence cluster**, the
**JMS queues/topics and connection factories**, and the **Inbound Web Services (IWS)** that expose C2M
to external systems. When any one is misconfigured, the symptoms are business-visible — the cluster
won't form, messages back up or vanish, inbound integration calls fail — and the causes are easy to
misdiagnose because the three layers depend on one another.

## What this solution does

It configures the **entire C2M runtime layer as one coherent unit**, pilot-first:

- **Coherence** — a single named cluster the managed servers reliably join (unicast WKA, correct
  listen port), verified on a cold restart.
- **JMS** — a JMS server with a persistent store, a module with named queues/topics and a connection
  factory, targeted explicitly via a subdeployment, with JNDI names reconciled to C2M's message
  senders so messages actually flow.
- **IWS** — the `spl-web-services` application deployed with the repeatable OUAF `iwsdeploy` utility
  and only the required inbound services enabled, secured, and responding.

Delivered as **self-guided documentation plus five automation scripts** (WLST/Jython, shell, SQL —
the authentic C2M/WebLogic toolchain) for discovery, validation, reporting, safe remediation, and
scoping.

## How it's delivered

The proven **Assess → Configure → Pilot → Validate → Expand** model: all changes are made on a
**non-production environment first**, behind explicit pass/fail gates, with a documented rollback,
before promoting the **same named objects and same scripts** to Test and Production.

## The business outcome

The C2M runtime wired correctly — **Coherence clustering, JMS messaging, and IWS integration all
healthy** — proven on a pilot before you scale, with saved evidence for change control. Self-guided
and tested, at a fraction of the cost of a bespoke consulting engagement.

## Who it's for

C2M/OUAF administrators, WebLogic middleware engineers, and integration teams standing up or repairing
the C2M runtime on WebLogic 14c (reference stack C2M 25.4 / minimum v2.9; version-specific details are
cited or flagged "verify for your version", and My-Oracle-Support-gated notes are pointed to, not
reproduced).
