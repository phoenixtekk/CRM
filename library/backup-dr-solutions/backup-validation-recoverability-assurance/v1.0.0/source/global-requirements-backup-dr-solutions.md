# Global Requirements — Backup & DR Solutions

These requirements apply across **every** solution in the **Backup & DR Solutions** category. They are intentionally generic: any individual solution layers its specific prerequisites on top of these. **Do not assume any prerequisite is already in place** — for each, confirm **Description / Why / Verify / Implement if missing** before proceeding.

---

## GR1 — A tenant/subscription with backup tooling and administrative access

**Description:** A cloud tenant and/or subscription (for example a Microsoft 365 tenant and/or an Azure subscription) with backup tooling provisioned, plus administrative access sufficient to view, configure, and restore protected data.

**Why:** Backup and DR work — coverage assessment, restore testing, remediation — is impossible without administrative reach into the platform that holds the data and the tooling that protects it.

**Verify:** Sign in to the relevant admin console/portal and confirm an account with the required administrative or backup-operator role, and that backup tooling is present and licensed.

**Implement if missing:** Provision the tenant/subscription, license and configure the backup tooling, and obtain an appropriately scoped administrative/operator role before continuing.

---

## GR2 — A non-production restore target

**Description:** An isolated, non-production destination for performing test restores — a sandbox location, alternate path, or restore-test resource group/network — kept separate from live data and systems.

**Why:** Recovery testing must prove restorability **without** risking production. Restoring into production can overwrite live data or cause resource collisions and outages.

**Verify:** Confirm a documented, isolated restore target exists for each in-scope workload type and that it cannot affect production data or networks.

**Implement if missing:** Provision a dedicated non-production restore target (sandbox location / alternate path / restore-test resource group with an isolated network) and document it.

---

## GR3 — Documented RPO/RTO objectives

**Description:** Written, agreed **Recovery Point Objective** and **Recovery Time Objective** targets per workload class.

**Why:** Backup and recovery outcomes can only be judged PASS/FAIL against defined objectives. Without them, "recoverable" and "timely" are subjective and unauditable.

**Verify:** Locate an approved document stating RPO and RTO per workload class.

**Implement if missing:** Propose objectives per workload class, agree them with the stakeholder/client, and record them in the solution's baseline.

---

## GR4 — Secure evidence storage

**Description:** A controlled, retained store for recovery-test evidence and reporting outputs, with access control and a defined retention period.

**Why:** Audits, insurers, and clients require durable proof of tested recovery. Evidence that is ad hoc, mutable, or short-lived is not defensible.

**Verify:** Confirm a designated store exists with access control and retention, holding prior evidence/reports.

**Implement if missing:** Designate a secure, access-controlled store with a documented retention period and restrict write access to program operators.

---

## GR5 — Change control

**Description:** A change-management process under which backup/restore/DR activities (test restores, on-demand backups, configuration changes) are authorized and logged.

**Why:** These activities consume resources, create artifacts, and touch protected data; they must be authorized and traceable, especially in shared or regulated environments.

**Verify:** Confirm a change record or standing change covers the recurring backup/DR activities.

**Implement if missing:** Establish a standing/recurring change authorizing the activity and require a change reference on each execution.

---

## GR6 — Network connectivity and a tooling host

**Description:** A management host with the required administrative modules/CLIs installed (for example Az PowerShell and the Microsoft Graph PowerShell SDK) and network access to the relevant portals, APIs, and backup consoles.

**Why:** Discovery, validation, reporting, and remediation tooling — and the restores themselves — require reliable connectivity and the right client tools.

**Verify:** From the host, confirm the required modules/CLIs are installed and the relevant endpoints are reachable.

**Implement if missing:** Install the required tooling and ensure outbound connectivity to the platform and backup console from the host.
