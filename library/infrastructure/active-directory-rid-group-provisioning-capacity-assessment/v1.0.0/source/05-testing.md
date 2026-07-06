# Testing & Validation

This section validates that the assessment's **monitoring and guardrails are actually in place** —
not merely recommended. Each check has an explicit **pass/fail gate**. Run these after Step 5 of the
methodology and re-run them on every recertification cycle. All checks are read-only.

## How to run the gates

Run the discovery, validation, report, and token-exposure scripts, then evaluate each gate below
against their output:

```
powershell -ExecutionPolicy Bypass -File .\RIDCAP-Discovery.ps1
powershell -ExecutionPolicy Bypass -File .\RIDCAP-Validation.ps1     -ProjectGroupsOU "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn"
powershell -ExecutionPolicy Bypass -File .\RIDCAP-Report.ps1         -ProjectGroupsOU "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn" -ActiveProjectsFile .\active-projects.txt -AnnualBurn 6240
powershell -ExecutionPolicy Bypass -File .\RIDCAP-TokenExposure.ps1  -Top 25
```

---

## Gate 1 — RID Master is healthy and the pool is measurable

**Check:** `RIDCAP-Discovery.ps1` returns a RID Master identity, a decoded consumed/maximum/remaining,
and a percent consumed.

- **PASS:** all fields populate, RID Master is reachable, and `dcdiag /test:RidManager` reports no
  errors on the holder.
- **FAIL:** the script cannot read `rIDAvailablePool`, or the RID Master is unreachable/unhealthy.
  Resolve per `06-troubleshooting.md` before trusting any projection.

## Gate 2 — RID consumption is below the alert threshold

**Check:** percent consumed from `RIDCAP-Discovery.ps1`.

- **PASS:** percent consumed **< 80%** of the pool ceiling.
- **FAIL:** **≥ 80%** — investigate the burn source and plan the extended RID pool. (For context, a
  healthy directory running a per-project group model typically reads a fraction of one percent.)

## Gate 3 — A dedicated OU exists and holds only project groups

**Check:** `RIDCAP-Validation.ps1` confirms the OU
`OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn` exists and that the groups within it are the
provisioned project groups.

- **PASS:** the OU resolves and contains the project groups; no unrelated principals are mixed in.
- **FAIL:** OU missing, or project groups scattered outside it. Create/consolidate per requirement R5.

## Gate 4 — Naming standard conformance

**Check:** `RIDCAP-Validation.ps1` reports the count of groups that do **not** match
`PRJ-projectId-ROLE (ROLE = READ, WRITE, or PRIV)`.

- **PASS:** non-conforming count = **0** (100% conformance).
- **FAIL:** any non-conforming names — reporting and cleanup cannot reliably parse project IDs.
  Rename to standard.

## Gate 5 — Ownership metadata present

**Check:** `RIDCAP-Validation.ps1` reports the percentage of project groups missing ownership
metadata (`managedBy`/`info`) or a creation date.

- **PASS:** **≥ 95%** of project groups carry ownership metadata and a creation date.
- **FAIL:** below 95% — orphan detection and recertification cannot be automated. Backfill metadata.

## Gate 6 — AGDLP scope conformance

**Check:** `RIDCAP-Validation.ps1` reports each project group's scope.

- **PASS:** project resource groups are **Domain Local** (per AGDLP), and members arrive via nested
  Global role groups.
- **FAIL:** resource groups created as Global/Universal, or users added directly to resource groups.
  Rework toward AGDLP per methodology Step 4.

## Gate 7 — No unmanaged orphans

**Check:** `RIDCAP-Report.ps1` flags project groups whose project ID is not on the supplied
active-projects list.

- **PASS:** orphan count is **0**, or every flagged group is already in the lifecycle
  disable/stage/delete pipeline.
- **FAIL:** orphans exist outside the lifecycle pipeline — sprawl is accumulating. Run the lifecycle
  cleanup (preview first).

## Gate 8 — Token exposure within limits

**Check:** `RIDCAP-TokenExposure.ps1` lists the highest-membership principals and their effective
group-SID counts.

- **PASS:** no principal's group-SID count exceeds the **warning threshold** (default 900, below the
  ~1,015 hard ceiling), and none exceeds MaxTokenSize modeling.
- **FAIL:** any principal at/over the warning threshold — scope that identity's project membership
  down or consolidate groups per methodology Step 4.

## Gate 9 — Monitoring is scheduled

**Check:** confirm `RIDCAP-Discovery.ps1` and `RIDCAP-TokenExposure.ps1` run on a schedule and feed
your monitoring platform with alert thresholds configured (R7).

- **PASS:** both are scheduled and alerting (RID at 80%; token at the warning threshold).
- **FAIL:** either is run only ad hoc. Schedule them — the approval is conditional on monitoring.

---

**Overall result:** the assessment's guardrails are considered validated only when **Gates 1–9 all
PASS**. Any FAIL is a condition of approval that has not yet been met; record it and remediate before
the provisioning model is treated as production-approved.
