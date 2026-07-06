# Executive Summary — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

Standing up Oracle Utilities Customer to Meter (C2M) is where utility programs stall. C2M is not a
single install — it is a build with three tiers that all have to line up: a **certified platform stack**
(OS, Java, WebLogic, database), the **OUAF product installed on a WebLogic 14c domain**, and a **loaded
C2M database schema**. Do it by hand once and it works; do it again for the next environment and it
drifts — different ports, a hand-edited config, a missed rollup — and now Development, Test, and
Production behave differently and every defect is impossible to reproduce.

This solution is the end-to-end, repeatable way to install C2M and build it **consistently across
Dev/Test/Prod**. It gives an experienced Oracle/WebLogic administrator the correct ordered procedure —
certify the stack, install the OUAF framework, install the C2M product, load the schema with `OraDBI`,
create the WebLogic `c2m_domain`, configure and validate — and a set of **named objects reused verbatim
in every environment** so the three builds differ only by their host, port, and database inputs. It
follows the standard model **Assess → Configure → Pilot → Validate → Expand**: build and prove
non-production first, then build Production under change control with backups and a documented rollback.

The build is **verifiable, not hopeful.** Five automation scripts — WLST/Jython against the WebLogic
domain, shell against the OUAF file system, and SQL against the schema — do read-only discovery and
validation, produce a build/coverage report per environment, and offer safe, dry-run-by-default
remediation. Every stage has an explicit pass/fail gate: certified stack present, ENVIRON.INI correct,
schema owned by `CISADM`, `AdminServer` and `c2m_server1` RUNNING, the C2M application ACTIVE, and the
whole environment surviving a clean stop and start.

Where a detail is Oracle's — the exact installer prompts, the certification matrix, patch and rollup
numbers, gated My Oracle Support notes — this solution points to Oracle's official C2M Installation
Guide, C2M Database Administrator's Guide, OUAF Server Administration Guide, and WebLogic 14.1.2
documentation rather than reproducing gated content, and flags every version-specific value (C2M 25.4 /
minimum 2.9.x, WebLogic 14c, Java 17, Oracle Database 19c) as "verify for your version." Nothing here is
invented.

The result: **Oracle C2M installed and configured consistently in every environment — certified,
healthy, and reproducible — proven on a pilot before you scale** — delivered as a self-guided guide plus
automation, at a fraction of the cost of a bespoke installation engagement.
