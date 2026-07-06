# Requirements & Inputs

Confirm every input below before running the assessment. Each entry follows the same shape:
**Description / Why / How to verify / How to implement if missing.** These are in addition to the
category-level prerequisites in `global-requirements-infrastructure.md`.

---

## R1. Active Directory read access (domain-wide)

**Description:** An account that can read directory objects across the domain — users, groups,
computers, the RID Manager object, and organizational units. Read-only is sufficient for the
discovery, validation, report, and token-exposure scripts.

**Why:** The assessment is a read-only diagnostic. It queries the RID pool, enumerates project
groups, and inspects group memberships and token contributors. None of that requires write access
(the only script that *can* change objects — the lifecycle cleanup — defaults to preview and is run
separately with elevated rights).

**How to verify:** From a workstation with RSAT installed, run
`Get-ADDomain` and `Get-ADGroup -Filter * -ResultSetSize 5`. Both must return data without an
access error.

**How to implement if missing:** Use any standard domain user for reads; most attributes needed
(group counts, `whenCreated`, `tokenGroups`, `rIDAvailablePool`) are readable by *Authenticated
Users*. If your directory is hardened, request a read-only account or membership in a
directory-readers role.

---

## R2. RSAT ActiveDirectory PowerShell module

**Description:** The Remote Server Administration Tools **ActiveDirectory** module, providing
`Get-ADDomain`, `Get-ADGroup`, `Get-ADUser`, `Get-ADObject`, etc.

**Why:** Every script in this package uses these cmdlets. Without the module the scripts cannot run.

**How to verify:** `Get-Module -ListAvailable ActiveDirectory` returns the module.

**How to implement if missing:** On Windows 10/11:
`Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"`.
On Windows Server: `Install-WindowsFeature RSAT-AD-PowerShell`.

---

## R3. RID Master reachability and health

**Description:** The domain controller holding the **RID Master** FSMO role must be online and
healthy, and reachable from where you run the discovery script.

**Why:** The RID pool ceiling and next-issuable RID are read from the **RID Manager$** object,
and RID Master health is a gating finding — a sick RID Master blocks *all* new principal creation
domain-wide, which is a more urgent problem than pool capacity.

**How to verify:** `netdom query fsmo` (or `Get-ADDomain | Select RIDMaster`) identifies the
holder; `dcdiag /test:RidManager /v` and `repadmin /showrepl the-ridmaster-dc` confirm health.

**How to implement if missing:** If the current holder is unhealthy, transfer or (if it is
permanently offline) seize the RID Master role to a healthy DC before proceeding. Resolve any
replication errors on that DC first.

---

## R4. The provisioning rate and groups-per-object count

**Description:** Two numbers that define the workload under review: **groups created per project**
(or per object) and **projects created per week** (or per whatever period). Also gather the **total
blended organizational RID burn per year** if you want the whole-domain projection.

**Why:** These drive the entire lifetime projection. Annual app burn =
`groups-per-project x projects-per-week x 52`. Without them you can measure the pool but cannot
project its lifetime.

**How to verify:** Read the provisioning tool's design (how many groups it creates per project) and
its expected throughput (projects/week) from the project's own runbook or product owner. For the
blended figure, sample historical creation: compare `rIDAvailablePool` consumed value across two
dates (e.g. 12 months apart) and divide by the elapsed time.

**How to implement if missing:** If throughput is unknown, use a **worst-case** upper bound
(peak projects/week) for the projection and label it as such. If historical burn is unknown, run
the discovery script now, record the consumed count and date, and re-run in a known interval to
derive the real annual rate.

---

## R5. Dedicated OU and naming standard for provisioned groups

**Description:** A single OU subtree that contains **only** the provisioned project groups, and a
deterministic naming convention that embeds the project identifier. This package uses these names
verbatim throughout — adapt the domain component to your own:

- **OU:** `OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn`
- **Group name pattern:** `PRJ-projectId-ROLE (ROLE = READ, WRITE, or PRIV)` — e.g. `PRJ-1042-READ`.

**Why:** A dedicated OU makes every project group targetable for counting, reporting, and cleanup;
the naming standard makes the project ID machine-parseable so orphan detection and growth reporting
are deterministic. Without both, the report and validation scripts cannot reliably distinguish
project groups from the rest of the directory.

**How to verify:** `Get-ADOrganizationalUnit -Identity "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn"`
succeeds, and spot-checked group names match the PRJ-projectId-ROLE pattern.

**How to implement if missing:** Create the OU
(`New-ADOrganizationalUnit -Name ProjectGroups -Path "OU=Provisioned,DC=your-domain-dn"`) and
configure the provisioning tool to create groups there with the naming pattern above. If groups
already exist elsewhere under inconsistent names, plan a one-time rename/move before relying on the
reports.

---

## R6. Ownership metadata on provisioned groups

**Description:** Each provisioned group carries owner and project-lifecycle metadata — at minimum a
project ID and creation date, ideally an owner reference. Store these in `managedBy`, `info`, or a
chosen extension attribute, consistently.

**Why:** Ownership metadata is what makes orphan detection, recertification, and cleanup
**automatable** rather than manual. A group you cannot attribute to an active project is exactly the
sprawl this assessment is trying to prevent.

**How to verify:** Sample groups with
`Get-ADGroup PRJ-1042-READ -Properties managedBy,info,whenCreated` and confirm the fields are
populated.

**How to implement if missing:** Have the provisioning tool stamp `managedBy`/`info` at creation
time. Backfill existing groups from the provisioning system's records where possible.

---

## R7. Token-size and RID monitoring tooling

**Description:** A monitoring platform (or scheduled script output) able to trend two signals:
**RID-pool consumption** against the pool ceiling, and **Kerberos token size / group-SID count**
for high-membership principals.

**Why:** The assessment's approval is *conditional on monitoring*. RID trend is the early-warning
for the (unlikely) capacity case; token-size trend is the early-warning for the (likely) bloat case
on portfolio-spanning users and service accounts.

**How to verify:** Confirm a scheduled job or monitoring check exists that runs the discovery and
token-exposure scripts on a cadence (e.g. weekly) and alerts on thresholds.

**How to implement if missing:** Schedule `RIDCAP-Discovery.ps1` and `RIDCAP-TokenExposure.ps1`
and route their output to your monitoring platform, alerting at **80% of the RID pool** and when a
principal's group-SID count approaches the token limits (see `07-best-practices.md`).
