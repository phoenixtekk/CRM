# Executive Summary

**Outcome.** The organization can move enterprise-scale **files and mail** from **Microsoft 365**
(SharePoint Online, OneDrive, Exchange Online) into **Google Workspace** (Drive, Shared Drives,
Gmail) using **Google Workspace Migrate**, Google's own large-scale migration platform — deployed,
mapped, throttled, waved, and validated so large volumes move **reliably** and with **preserved
ownership and sharing**.

**Approach.** This is a **tool deployment-and-execution playbook**. It stands up the self-hosted
node platform (management/database node plus scalable worker nodes), wires the **Microsoft 365 and
Google connections**, builds **mappings and the identity bridge**, and runs data in **throttled
waves** using the house model **Assess → Design → Configure → Pilot → Validate → Expand**. A small
named **pilot wave** is migrated end to end — pre-stage bulk pass, delta pass, then gated cutover —
and validated for item-count, permission, and mail parity **before** any production wave runs. Five
**Python tools** (Google Workspace Admin SDK and Microsoft Graph) handle the scriptable edges: node
sizing from a real source baseline, mapping/connection artifact generation, wave batching with a
throttling plan, live migration health/throttling monitoring, and post-migration validation
reporting. Every tool is **safe-by-default** (read-only or dry-run until explicitly applied) with **no
credentials in code**; the tool's deep console internals are **deferred to Google's own
documentation** and version-specific behavior is flagged **"verify for your version."**

**Why it is low-risk.** Nothing scales until a pilot passes explicit **pass/fail gates**. The bulk of
the data moves while users keep working on the source; only **cutover** is high-impact, and it runs
inside a change window with a **tested, reversible rollback** (routing reverts, source data is
preserved). Throttling is planned conservatively and calibrated from measured pilot throughput, so
migrations run steadily under source/target API limits rather than tripping them. The result is a
predictable, auditable, enterprise-scale migration on Google's native tool — for a fraction of the
cost of an open-ended consulting engagement.
