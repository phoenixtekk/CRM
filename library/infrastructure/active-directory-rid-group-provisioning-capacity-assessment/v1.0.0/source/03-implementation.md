# Assessment Methodology

This is the ordered method. Run the five steps in sequence; each produces evidence that feeds the
final findings. All measurement steps are **read-only**. Every number shown is a **labeled
example** — substitute your own measured values.

---

## Step 1 — Measure current RID consumption and RID Master health

**Goal:** establish the two facts the whole projection rests on — how much of the pool is already
consumed, and whether the RID Master is healthy enough to issue RIDs at all.

1. Identify the RID Master and confirm its health (R3):
   `Get-ADDomain | Select RIDMaster`, then `dcdiag /test:RidManager /v` on that DC.
2. Run **`RIDCAP-Discovery.ps1`**. It reads the `rIDAvailablePool` attribute from the
   **RID Manager$** object and decodes it. That attribute is a 64-bit value packing two 32-bit
   halves:
   - **low 32 bits** = the **next RID to be issued** = the count already **consumed**;
   - **high 32 bits** = the **pool ceiling** = the maximum RIDs (default `1,073,741,823`).
3. Record: **RIDs consumed**, **pool maximum**, **RIDs remaining**, **percent consumed**, and the
   **RID Master identity**.

**Worked example (substitute your own):** a domain reports `rIDAvailablePool` decoding to
**consumed = 1,478,144** against a **maximum of 1,073,741,823** → **remaining = 1,072,263,679**,
**percent consumed ≈ 0.138%**. Your numbers will differ; the script prints yours.

---

## Step 2 — Project the pool lifetime

**Goal:** convert the measured consumption and your provisioning rate into a runway in years, both
for the app alone and for the blended whole-domain view.

**Formulas:**

```
annual app burn        = groups-per-project  x  projects-per-week  x  52
years to exhaust (app) = RIDs remaining  /  annual app burn
years to exhaust (org) = RIDs remaining  /  (blended org burn/yr  +  annual app burn)
```

### 2a. App-only projection (worked EXAMPLE — substitute your rate)

Example workload: **3 groups per project**, worst-case **40 projects/week**.
Annual app burn = `3 x 40 x 52 = 6,240 groups/year`.

| Metric | Example value |
|---|---|
| Groups per project | 3 |
| Projects per week (worst case) | 40 |
| **Annual app burn** | **6,240 RIDs/yr** |
| RIDs remaining (from Step 1 example) | 1,072,263,679 |
| **Years to exhaust — app alone (worst case)** | **≈ 171,800 years** |
| Years to exhaust — app alone (low case, 30/wk → 4,680/yr) | ≈ 229,100 years |

### 2b. Blended whole-domain projection (worked EXAMPLE)

RIDs are consumed by **every** principal ever created, not just this app. Add the app burn to an
assumed organization-wide annual burn (measure yours per R4; these rows are illustrative):

| Assumed org burn/yr | + app burn (6,240) | Years to exhaust remaining |
|---|---|---|
| 50,000 | 56,240 | ≈ 19,070 years |
| 100,000 | 106,240 | ≈ 10,090 years |
| 250,000 | 256,240 | ≈ 4,185 years |
| 500,000 | 506,240 | ≈ 2,118 years |

**How to read this:** even under an aggressive blended burn, the runway is measured in **millennia**,
and the **extended RID pool** (2^31) doubles it if ever needed. The incremental burn from a
per-project group model is statistically negligible against the remaining pool.

**Typical finding:** *RID exhaustion risk = Very Low.* This is not, on its own, a basis to block or
approve the design — which is why Steps 3–4 exist.

---

## Step 3 — Evaluate the non-RID risks (the ones that actually matter)

Assess each of the following against your measured workload. These, not RIDs, are where a
per-project group model creates real exposure at scale.

### 3.1 Kerberos token bloat — usually the highest practical risk
- A user's Kerberos ticket (**PAC**) carries the **SID of every group they belong to** — including,
  under AGDLP, the domain-local resource-group SIDs, plus any SID history.
- Default **MaxTokenSize = 48,000 bytes** (Server 2012+), and there is a hard ceiling of roughly
  **1,015 group SIDs** before authentication fails outright. (Microsoft: *MaxTokenSize / token-size
  problems*.)
- **Where it bites:** a **user, service account, or automation identity attached to many projects.**
  At 3 groups/project, an identity on 100 projects carries **~300 project-group SIDs** before its
  baseline enterprise groups. Portfolio-spanning PMs, power users, and service accounts are the
  exposure — not the average member.
- **Measure it:** run **`RIDCAP-TokenExposure.ps1`** to count `tokenGroups` (effective SID count,
  including nesting) for the identities that span the most projects, and compare against thresholds.

### 3.2 Group sprawl and lifecycle debt — usually the highest operational risk
- At the example rate, 6,240 groups/year with **no deprovisioning** = **62,400 groups in 10 years**
  from this app alone.
- Without automated cleanup, completed and abandoned projects leave **orphaned groups** that inflate
  backups, replication, search, audit scope, and erode least-privilege over time.
- **Measure it:** run **`RIDCAP-Report.ps1`** to count project groups by project ID and flag those
  whose project is closed (not on your active-projects list).
- **The single most important guardrail** is lifecycle automation tied to project state (see
  `07-best-practices.md`). Its absence, not RID capacity, is what makes a model unsustainable.

### 3.3 Replication and Global Catalog
- Groups and their memberships replicate to all DCs; universal groups and GC-replicated attributes
  add inter-site traffic. At thousands of small groups per year this is **modest but non-zero**.
- **Large-membership** groups matter more than group *count*. Ensure the forest is at a functional
  level with **linked-value replication** (Windows Server 2003+), so a membership change replicates
  **per member** rather than re-sending the whole member list.

### 3.4 Backup / DIT size
- Every object adds to the **NTDS.DIT** and system-state backup. Thousands/year is small relative to
  a typical enterprise directory, but it **compounds with 3.2** if cleanup is absent.

### 3.5 Administration and governance overhead
- Naming collisions, ownership ambiguity, unclear scope, and audit fatigue all scale with object
  count. This is contained by naming standards, a dedicated OU subtree, and ownership metadata.

### 3.6 SYSVOL — not impacted
- These are **permission/security groups**, not GPO objects. SYSVOL/GPO scale is **not** a factor
  **unless** the groups are used for GPO security filtering. For a resource-permission model they
  are not, so SYSVOL is out of scope.

---

## Step 4 — Review the authorization architecture

**Goal:** confirm the group model is the right *shape*, and identify whether nesting/RBAC can bound
object growth without sacrificing clarity.

### 4.1 Apply AGDLP; do not flatten
Microsoft's canonical pattern is **A → G → DL → P**:
**Accounts → Global groups (roles) → Domain Local groups (resource permissions) → Permissions.**

- Map the **per-project Read/Write/Privileged groups to Domain Local "resource" groups** applied to
  the project's file shares / SharePoint / resources.
- Add users via **Global "role" groups** nested into those resource groups.
- This keeps ACLs clean, supports multi-domain/forest, and localizes churn to **membership** changes
  (linked-value replication) instead of ACL rewrites.
- Validate conformance with **`RIDCAP-Validation.ps1`** (group scope, dedicated OU, naming,
  ownership metadata).

### 4.2 Options to bound object growth (choose deliberately)

| Approach | Effect | Trade-off |
|---|---|---|
| **Keep 3 resource groups/project** (default) | Cleanest least-privilege; RID-safe | Highest object count (acceptable at these rates) |
| **1 project group + roles via nested global groups** | Fewer per-project objects | Permission logic moves into nesting; less transparent ACLs |
| **RBAC via reused enterprise role groups + resource groups** | Reuses existing roles; fewer new objects | Requires a maintained role catalog |
| **Entra ID / dynamic groups** | Good for **cloud** resources | Does **not** set on-prem NTFS/SharePoint-Server ACLs — not a substitute for AD groups on file resources |

**Guidance:** retain the multi-group-per-project resource model unless **measured token bloat**
(3.1) on portfolio-spanning identities forces consolidation. Collapse groups only to solve a
demonstrated token problem, accepting the loss of ACL transparency.

---

## Step 5 — Produce findings and conditions of approval

Assemble the evidence into a decision:

1. **State the RID finding** with your measured numbers (Step 1–2): consumed %, remaining, projected
   lifetime (app-only and blended). Typically *Very Low* risk.
2. **State the non-RID findings** (Step 3): token-bloat exposure for named high-membership
   identities, current orphan/sprawl count, replication/backup notes.
3. **State the architecture finding** (Step 4): AGDLP conformance and whether growth-bounding is
   warranted.
4. **Record the decision as go / no-go with conditions.** The standard outcome is **approve,
   conditional on the guardrails** in `07-best-practices.md`: lifecycle automation, dedicated OU +
   naming standard, AGDLP implementation, ownership metadata, RID/token/orphan monitoring, and
   access recertification.
5. **Set re-review triggers:** revisit if per-project group count increases, if any identity
   approaches token limits, or if the RID trend alert fires at ≥ 80% of the pool.

Capture all of this in the reusable **Assessment Report** template outlined in
`08-deliverables-summary.md`.
