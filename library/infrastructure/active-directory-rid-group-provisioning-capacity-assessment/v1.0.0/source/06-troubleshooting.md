# Troubleshooting

Common problems encountered while running the assessment, and how to resolve them. Symptoms are
grouped by the risk area they belong to.

---

## RID Master unhealthy or unreachable

**Symptoms:** `RIDCAP-Discovery.ps1` cannot read `rIDAvailablePool`; new principal creation fails
domain-wide with *"the directory service was unable to allocate a relative identifier"*; DCs cannot
obtain new RID blocks.

**Why it matters:** the RID Master is the single issuer of RID blocks. If it is down or its own pool
is exhausted/invalidated, **no** DC can create users, computers, or groups — a more urgent outage than
any capacity projection.

**Diagnose:**
- Identify the holder: `Get-ADDomain | Select RIDMaster` or `netdom query fsmo`.
- Health: `dcdiag /test:RidManager /v` on the holder; check the **Directory Service** event log for
  RID-allocation events; `repadmin /showrepl the-ridmaster-dc` for replication errors.

**Resolve:**
- If the holder is merely unhealthy, fix its replication first, then re-test.
- If it is permanently offline, **transfer** the role to a healthy DC
  (`Move-ADDirectoryServerOperationMasterRole -Identity the-healthy-dc -OperationMasterRole RIDMaster`),
  or **seize** it only if the old holder will never return.
- If the pool ceiling is genuinely near the 30-bit maximum (an 80%+ Discovery reading), plan the
  **extended RID pool** (raises the ceiling to 2^31) as the supported, one-way safety valve — after
  confirming the burn source.

---

## Token-size authentication failures

**Symptoms:** specific users or service accounts fail Kerberos authentication while others succeed;
errors such as *KDC_ERR_MORE_DATA*, HTTP 400 "bad request / header too large" on Kerberos-backed web
apps, or logon failures for portfolio-spanning accounts. `RIDCAP-TokenExposure.ps1` flags the account
WARN/CRITICAL.

**Why it matters:** every group SID rides in the Kerberos PAC. Past MaxTokenSize (default 48,000
bytes) and the ~1,015 group-SID hard ceiling, authentication fails outright. This is the token-bloat
risk the assessment predicts for identities attached to many projects.

**Diagnose:**
- Run `RIDCAP-TokenExposure.ps1 -Identity the-account` to get the effective group-SID count.
- Compare against the WARN (900) / CRITICAL (~1,015) thresholds.

**Resolve:**
- **Scope the identity down** — remove it from projects it no longer needs (service accounts are the
  worst offenders; give each automation only the projects it truly touches).
- **Consolidate groups** for that use case per methodology Step 4 (role reuse / nesting) — but only to
  fix a *measured* problem.
- **Avoid deep nesting** that inflates the effective SID set.
- As a stopgap only, MaxTokenSize can be raised, but this treats the symptom, not the sprawl — reduce
  membership as the real fix.

---

## Orphaned-group detection issues

**Symptoms:** `RIDCAP-Report.ps1` reports zero orphans when you expect many, flags active groups as
orphans, or cannot parse project ids.

**Why it matters:** orphan detection is how you find lifecycle debt. If it is unreliable, sprawl
accumulates invisibly.

**Diagnose & resolve:**
- **Names don't match the standard.** If groups aren't named `PRJ-projectId-ROLE (ROLE = READ, WRITE, or PRIV)`, the
  project id can't be parsed. Confirm with `RIDCAP-Validation.ps1` (naming check) and rename to
  standard. Adjust `-ProjectIdField` only if your id sits in a different hyphen-delimited position.
- **Active-projects list is wrong.** Ensure `active-projects.txt` has **one project id per line** and
  the ids match exactly what's embedded in the group names (comparison is case-insensitive but the id
  strings must correspond). A stale list makes live projects look orphaned.
- **Groups live outside the OU.** `RIDCAP-Report.ps1` only searches the supplied OU. Consolidate all
  project groups into `OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn` (requirement R5).

---

## Replication of large groups

**Symptoms:** membership changes on high-count groups cause noticeable inter-site replication traffic
or lag; GC replication spikes.

**Why it matters:** at scale, **large-membership** groups matter more than the raw count of small
groups. Without linked-value replication, a single membership change re-sends the entire member list.

**Diagnose & resolve:**
- Confirm the forest functional level supports **linked-value replication** (Windows Server 2003+ so
  membership replicates **per member**, not whole-list). Raise the functional level if it is lower.
- Prefer many small resource groups over a few very large ones where the design allows; the per-project
  model already favors this.
- Monitor replication with `repadmin /showrepl` and `repadmin /replsummary`; investigate any DC with
  persistent backlog.
- Keep universal-group membership churn modest, since universal group membership is GC-replicated.

---

## Discovery numbers look wrong

**Symptoms:** consumed count seems implausibly high or low, or percent-consumed is unexpected.

**Resolve:**
- Remember consumption is **cumulative and never reclaimed** — a high count on an old domain with
  historical bulk creation is normal and not a leak.
- Re-run `RIDCAP-Discovery.ps1` against the **RID Master** specifically to rule out a stale replica.
- Verify the decode: low 32 bits = consumed/next RID, high 32 bits = pool ceiling
  (default 1,073,741,823). A ceiling of ~2.1 billion means the **extended RID pool** was already
  unlocked.
