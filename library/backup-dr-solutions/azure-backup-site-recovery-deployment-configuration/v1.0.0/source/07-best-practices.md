# 7. Best Practices — Azure Backup & Site Recovery — Deployment & Configuration

Keep the platform clean, defensible, and cheap to run.

## Vault hardening

- **Enable soft delete on every vault, always.** It is the free undo button for accidental or
  malicious deletion. Set the retention window per your data-protection policy (14–180 days).
- **Enable immutability, and lock it only after validation.** Locked immutability is
  **irreversible** — prove the whole configuration first (Stage 4), then lock deliberately. Locking
  before validation can trap a mistake you cannot undo.
- **Use multi-user authorization (MUA) for critical vault operations** where available, so a single
  compromised admin cannot weaken protection. *Verify current MUA availability in your tenant.*
- **Separate the backup blast radius.** Keep vaults in a dedicated, tightly-RBAC'd resource group;
  restrict **Backup Contributor** / **Site Recovery Contributor** to the people who operate them.

## Policy design

- **Author policies once, assign many.** Reuse the named policies (`bkpol-vm-daily-30d`, etc.)
  rather than creating per-VM policies — it keeps RPO/RTO consistent and auditable.
- **Match policy to RPO/RTO, not to habit.** For SQL-in-VM, the **log-backup interval** *is* your
  RPO — set it to the agreed target (R1), not a default. Retention (daily/weekly/monthly/yearly)
  should reflect real recovery and compliance needs, not "keep everything forever" (cost) or "keep
  7 days" (too little).
- **Right-size retention for cost.** Long-term retention points accrue storage cost; use tiered
  retention (short daily + longer monthly/yearly) instead of long daily retention.

## Site Recovery & recovery plans

- **Sequence recovery plans by dependency.** Database group first, then app, then web. A plan that
  boots everything at once often fails app health checks.
- **Keep pre/post scripts idempotent and version-controlled.** They run under stress during a real
  failover; they must be safe to re-run.
- **Test failover regularly and always clean up.** A test failover proves the plan; leaving test
  resources behind wastes money and clutters the target region. Automate the cleanup step.
- **Plan and rehearse failback.** Failover is half the story — document and test the return to the
  primary region so DR is not a one-way trip.
- **Watch target-region quota.** Failover fails if the target region lacks vCPU/family quota
  (R2) — recheck quota as the estate grows.

## Operations

- **Alert on failure, not just success.** Route backup-failure, restore-failure, and ASR RPO-breach
  alerts to a monitored destination (`alert-backupdr-health`); a silent backup failure is the
  gap you find during an incident.
- **Keep the runbook current.** Update **Restore/Failover Runbook – Estate – Expand** whenever the
  estate, RPO/RTO, or recovery plans change.
- **Re-baseline coverage as the estate grows.** New VMs, shares, and databases drift out of
  protection unless re-assessed — re-run **`BCKDR-Discovery.ps1`** on a cadence.
- **Never hand-edit production during a test.** All proving happens in `rg-dr-test-sandbox`.

## Deferred decisions (customer-owned)

- **RPO/RTO targets** are a business decision (R1) — this solution meets them, it does not set them.
- **Immutability lock and soft-delete window** are security/ops decisions (R3) — obtain sign-off.
- **Retention beyond operational need** may be driven by legal/records requirements — route those
  to the customer's compliance function, not the backup admin.

## Where to go next (adjacent catalog areas)

- **Backup Validation & Recoverability Assurance** — the essential companion: a scheduled,
  evidence-producing discipline that proves restores across the estate *continuously* (this solution
  proves recoverability once, at deployment).
- **Backup & DR Solutions** category — broader resilience patterns (immutable/offsite copies,
  ransomware recovery runbooks) that build on this deployment.
- **Azure governance / cost management** — policy-as-code to *enforce* that every new VM lands under
  a backup policy, and cost controls for backup/replication storage.
