# Executive Summary

**Outcome.** External collaboration in Microsoft Teams stays **enabled** — partners, vendors, and
clients can chat, meet, and share — while being **scoped, reviewed, and on policy**. External access is
limited to approved domains, guests are recertified and expire rather than accumulate, shared channels
connect only to deliberately chosen partner tenants, and sensitivity classification drives external
posture. The result is open-but-governed collaboration with an audit trail.

**Problem.** Teams offers three *different* external-collaboration surfaces — external access
(federation), guest access (Entra B2B collaboration), and shared channels (Entra B2B direct connect) —
each with its own controls. Ungoverned, they leak data to any domain and pile up stale guest accounts
that never expire. Locking one down does not govern the others, so most tenants are partially exposed
without realizing it.

**Approach.** The solution governs all three surfaces plus lifecycle and sensitivity, following a
disciplined, pilot-first model — **Assess → Design → Configure → Pilot → Validate → Expand**:

- **Assess** current posture read-only (federation, guest, shared-channel, cross-tenant settings, and a
  stale-guest count).
- **Design** the target with security/compliance/governance: allowed/blocked domains, shared-channel
  partners, guest review cadence and expiration, and the governing sensitivity label.
- **Configure** each surface with named, reusable policies; **pilot** on a scoped group; **validate**
  against explicit pass/fail gates; then **expand** with a documented, deterministic rollback.

**Why it is low-risk.** Every change is **dry-run by default** (`-WhatIf`) and applied only with an
explicit `-Commit` inside a change window. A full baseline is captured before any change, so rollback
reapplies known-good values rather than "turning external access off". Changes reach a **pilot** group
before the tenant, and pass/fail gates must clear before expansion. Automation uses **modern-auth**,
least-privilege roles, and **no stored credentials**. Plan- and cloud-dependent behavior (Entra ID
Governance/P2 for reviews, container-label licensing, Commercial vs Government cloud URLs) is
**flagged to verify in your tenant**, never assumed. Domain, classification, and retention
**determinations remain with your compliance and governance functions** — the solution provides the
technical method and evidence, delivered as documentation plus five safe-by-default PowerShell tools.
