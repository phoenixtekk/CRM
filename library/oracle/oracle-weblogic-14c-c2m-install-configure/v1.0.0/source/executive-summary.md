# Executive Summary

Oracle Utilities **Customer to Meter (C2M)** runs on **Oracle WebLogic Server** — and a mis-built
WebLogic domain undermines everything above it. Sloppy domain topology, no Node Manager, JVMs sized
by guesswork, or hand-typed database connections produce a middleware layer that looks fine in a
demo and fails under real load. This solution builds that layer correctly: **install and configure
Oracle WebLogic 14c (14.1.1) as the C2M foundation** — the domain, Administration and managed
servers, Node Manager, data sources, and JVM / startup configuration — **pilot-first**, with
explicit gates.

## The problem

The middleware foundation is where C2M problems start but are hardest to see. A domain built without
discipline leaves predictable failures downstream: servers that won't stay up, connection-pool
errors under concurrency, no automated restart when a server crashes, and memory exhaustion when the
JVM is left at template defaults. Because C2M, batch, integrations, and monitoring all sit **on top**
of the domain, a weak foundation multiplies into every layer above it — and re-doing the base after
the fact is expensive and disruptive.

## The solution

A self-guided, tested implementation that builds the WebLogic 14c foundation the way an experienced
middleware administrator would, following **Assess → Configure → Pilot → Validate → Expand** with
pass/fail gates and a documented rollback, always on a **non-production environment first**:

- **Install WebLogic 14c** into a clean `ORACLE_HOME` on a certified stack.
- **Create the `c2m_domain` domain** with a clear, named topology — `AdminServer`, managed
  server(s), cluster, and machine — outside the binaries so patching never disturbs it.
- **Configure the per-domain Node Manager** so servers start, stop, and **auto-restart** under
  control, and start unattended via a boot identity.
- **Create the `C2MDataSource`** connection pool to the C2M database with **Test-On-Reserve** health
  checking, targeted at the managed server(s) — not the Admin Server.
- **Tune JVM / startup** deliberately (heap, metaspace, production mode) for C2M's memory profile.
- **Validate** the whole foundation with evidence — servers `RUNNING`, Node Manager reachable, data
  sources healthy, JVM args in effect — before scaling out.

## What's included

Full documentation — Solution Overview, Requirements, Implementation, Testing, Troubleshooting,
Best Practices, and this summary — plus **five automation scripts** (WLST/Jython, shell, SQL):
read-only **Discovery**, **Validation**, and **Report**; a **Remediation** helper that is **dry-run
by default**; and a **ScopeHelper** that pins per-environment targets. Every step names the same
objects and reuses them; every version-specific detail is **cited or flagged "verify for your
version,"** and My-Oracle-Support-gated content is pointed to, not reproduced.

## Business value

- **A foundation that holds** — a correctly built WebLogic 14c domain that every C2M layer above can
  rely on, proven on a pilot before it carries production load.
- **Risk reduced** — certified stack, backups, and change control; safe by construction (read-only
  discovery/validation, dry-run remediation) with a documented rollback at every gate.
- **Repeatable across environments** — the same scripts and named topology build Dev → Test → Prod
  identically, so the domain that reaches production is the one you validated.
- **A fraction of consulting cost** — the middleware expertise of a WebLogic administrator, packaged
  and self-guided.

## Bottom line

A correctly built **WebLogic 14c foundation for C2M** — domain, servers, Node Manager, and data
sources healthy — **proven on a pilot before you scale.**
