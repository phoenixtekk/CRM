# Executive Summary — Troubleshooting Microsoft Entra Connect Cloud Sync (Users Skipped / JoinNotFound)

Entra ID Solutions · Cloud Sync Diagnostics

You set up **Microsoft Entra Connect cloud sync** to synchronize on-premises Active Directory users
into Microsoft Entra ID. It looks configured, the agent looks healthy — but **no accounts are being
created**. When you run **provision on demand** you see **Import ✓ / In scope ✓ / Match ✓**, and then
**Evaluate action → "User was skipped", SkipReason: JoinNotFound**. Nothing is wrong with the network;
one specific condition is stopping the create — and cloud sync's own logs will tell you which, if you
know where to read them.

This is a **diagnostics toolkit**, not a deployment guide. It gives an administrator a structured way
to find *why* cloud sync is skipping users — a **read-only** workflow and five PowerShell tools that
snapshot the agent, read the authoritative per-object reason from the provisioning logs, and classify
the object — so the fix is named in minutes instead of guessed at over days.

## What you get
- A plain-language **Solution Overview**: how cloud sync differs from the older Entra Connect *Sync*,
  what **JoinNotFound** actually means (the evaluate step found no target to join and no new object to
  create), and the specific conditions that cause it — an already-existing target from a prior sync
  method, an out-of-scope OU, a disabled configuration, a quarantined job, a deletion threshold, a
  missing service principal, or an unhealthy agent.
- A **Requirements Guide** with verify / implement-if-missing for every read-access prerequisite.
- A **Diagnostic Workflow** — the ordered **Collect → Analyze → Remediate → Verify** process with a
  symptom → tool map and explicit gates.
- **Five read-only PowerShell tools**: an agent-host collector, an agent-health check, a provisioning-
  log reader (the authoritative skip reason by `ObjectGuid`/UPN), a synchronization-job/quarantine/SP
  check, and an Active Directory object test (critical-object, in-scope, UPN, duplicate).
- **Testing and Troubleshooting** guides — the decisive test is that, after the fix, provision on
  demand creates the user and the provisioning log shows **action = Create**.

## What this delivers
A named root cause for "cloud sync isn't provisioning users," reached with tools that change nothing on
the agent, the tenant, the configuration, or the object — and a clear, owner-plane remediation for each
condition.

## The diagnostic model
Collect → Analyze → Remediate → Verify — an adaptation of the category's Assess → Configure → Pilot →
Validate → Expand model to a read-only troubleshooting shape.

## Outcome
The reason users are skipped — JoinNotFound and the condition behind it — isolated fast, so provision
on demand creates the user, the provisioning log shows **action = Create**, and the account appears in
Entra ID.
