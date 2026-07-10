# Executive Summary — Azure Backup & Site Recovery — Deployment & Configuration

## The problem

Hoping your VMs are backed up is not a disaster-recovery strategy. Many Azure estates run
with no Recovery Services vault at all, with backup enabled on some VMs but not others, with
policies that were set once and never revisited, and with **no** cross-region replication for
the workloads that would actually take the business down if a region or a resource group were
lost. When an accidental deletion, a ransomware event, or a regional outage happens, the team
discovers — during the incident — that the data was never protected, that a "backup" was really
just a mutable snapshot an attacker could delete, or that there is no tested way to bring the
application back up somewhere else.

Two failure modes are especially common:

- **Backup exists but is not immutable or soft-delete-protected.** A backup an administrator (or
  an attacker with administrator rights) can silently delete is not a ransomware control. Soft
  delete and immutability turn a backup vault into a last line of defense that survives credential
  compromise.
- **There is backup but no *recovery*.** Restoring a single file is not the same as failing an
  application tier over to another region in sequence, with the database up before the app servers,
  DNS repointed, and post-failover scripts run. Without **Azure Site Recovery** replication and a
  tested **recovery plan**, "DR" is an aspiration, not a capability.

## The solution

This solution **deploys and configures** Azure Backup and Azure Site Recovery end to end:

- **Recovery Services and Backup vaults** hardened with **soft delete** and **immutability**.
- **Backup policies** for **Azure VMs, Azure Files, SQL Server running in Azure VMs, and Azure
  Blob storage**, assigned to the in-scope estate.
- **Azure Site Recovery** replication — **Azure-to-Azure** (region to region) and
  **on-premises-to-Azure** — with a replication policy meeting the target RPO.
- **Recovery plans** with tiered sequencing, pre/post scripts, and a **non-disruptive test
  failover**, plus **alerting** and a written **restore/failover runbook**.

It follows a consistent deployment model — **Assess → Configure → Pilot → Validate → Expand** —
so that protection is proven on a pilot before it is rolled out across the estate, and every
object created is named to a convention and reused verbatim in the scripts and runbook.

> **Scope boundary.** This solution *deploys and configures* Azure Backup and ASR. The ongoing
> discipline of *scheduling and evidencing test restores* across the estate is a separate program —
> see **Backup Validation & Recoverability Assurance** in this catalog. This solution proves the
> deployment works once (via test failover and a first restore); that program keeps proving it.

## What you get

- A hardened vault design with **soft delete + immutability** for Recovery Services and Backup
  vaults.
- **Backup policies** for VMs, Files, SQL-in-VM, and blobs, applied pilot-first then estate-wide.
- **ASR replication** (Azure-to-Azure and on-prem-to-Azure) with a policy meeting the agreed RPO.
- **Recovery plans** with sequencing, scripts, and a proven **test failover**.
- **Alerting** on backup/replication health and a **restore/failover runbook**.
- **Five automation artifacts** — a read-only discovery script, a Bicep template that provisions
  the hardened vaults and policies, a gated protection-enablement script, a read-only validation
  script (with an optional non-disruptive test failover), and a read-only reporting script.

## Business outcomes

- **Provable protection** — workloads are backed up under policy, in immutable, soft-delete
  vaults, with defined RPO/RTO rather than assumed coverage.
- **Real recoverability** — replication plus a tested recovery plan means an application tier can
  actually be brought up in another region, in order, on demand.
- **Ransomware resilience** — immutability and soft delete keep recovery points intact even if an
  administrator account is compromised.
- **Operational readiness** — alerting and a written runbook mean the team executes a rehearsed
  procedure during an incident, not an improvised one.

> **Your decision, not ours.** RPO/RTO targets are a business decision the customer owns — this
> solution implements the technical controls to *meet* the targets you set, and flags where a
> desired RPO/RTO is or is not achievable with the chosen configuration.

## Effort

A typical engagement is a **1–3 week** deployment: assessment and vault design in week 1, pilot
configuration and a first test failover in week 2, and estate-wide expansion plus alerting and
runbook handover in week 3. Delivered as a **Complete Solution Package** (PDF + Word + scripts).
