# 3. Upgrade & Patch Runbook — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

Follow these steps in order, **per environment**, lowest first (Dev → Test/QA/UAT → Production). The
runbook is the same in each environment; what changes is the go/no-go gate that must pass before the
change is promoted up. Nothing is applied to production until every lower environment has passed its
gate. Exact patch numbers, service-pack IDs, and release upgrade instructions live in the patch README
and the release upgrade guide on My Oracle Support (MOS) — read them first; this runbook is the method,
not a substitute for the vendor's per-patch instructions.

> Model: prove the change in the lowest environment, back up before every apply, validate against a
> gate, then promote up. The repeatable way: Assess, then Configure, then Pilot, then Validate, then
> Expand — with a verified backup and a documented rollback at every step.
>
> Placeholders below use plain names (your-oracle-home, your-env) — substitute your environment's
> values. Commands are illustrative of the OPatch / OUAF / WLST / SQL interfaces; always follow the
> specific patch README.

## Phase A — Readiness and backup (every environment, before any apply)

### Step 1 — Establish the current baseline (Assess)
1. Run `OC2MPATCH-Discovery.sh` to capture, read-only, the current state: C2M/OUAF release and applied
   fixes (OUAF inventory), WebLogic Oracle Home patches (`opatch lsinventory`), OS/JDK/DB/WebLogic
   versions, and domain/managed-server layout. Keep the output — it is the baseline you patch from and
   compare against afterward.
2. Confirm the change target: for a patch, the patch number(s) and their README; for an upgrade, the
   target release (e.g. C2M 25.4) and its upgrade guide.

### Step 2 — Confirm certification and prerequisites
1. Compare the discovered OS/JDK/DB/WebLogic versions against the target release's certification matrix
   (MOS). If the stack is not certified for the target, align it first (its own backed-up change).
2. From the patch README / upgrade guide, confirm prerequisites and conflicts:
   `opatch lsinventory` for WebLogic conflicts; the OUAF fix inventory for C2M conflicts.
3. Confirm the environment order and produce the target list for this change with
   `OC2MPATCH-ScopeHelper.sh`.

### Step 3 — Take verified backups
1. Stop the environment cleanly for a consistent backup where required: `spl.sh -stop` (OUAF) and stop
   the WebLogic managed/admin servers (or use the runbook's WLST stop). OUAF shuts WebLogic down
   automatically during install, but back up from a known-stopped state.
2. Back up, and verify each is restorable:
   - Database: create a guaranteed restore point and/or RMAN backup of the C2M schema/database.
   - WebLogic: archive the Oracle Home and the domain configuration.
   - OUAF: archive the product home and configuration (splenviron/config).
3. Run `OC2MPATCH-Validation.sh --pre-check` to confirm the backup markers are present. Do not proceed
   past a missing or unverified backup.

> **Gate A (readiness):** baseline captured, target certified, prerequisites/conflicts cleared, and
> verified backups present. Do not apply until Gate A passes.

## Phase B — Apply the patch / perform the upgrade

### Step 4 — Apply WebLogic (OPatch) patches
1. Set the environment to the WebLogic Oracle Home (your-oracle-home) and unzip the patch to a staging
   directory outside the Oracle Home.
2. From the patch directory, verify then apply per the README:
   - `opatch lsinventory` — record the pre-apply inventory.
   - `opatch apply` — apply the patch (run from the unzipped patch directory; follow README ordering
     for multiple patches).
   - `opatch lsinventory` — confirm the patch now shows as applied.
3. If OPatch reports a conflict, stop and resolve per the README (do not force) — this is a no-go for
   this environment until resolved.

### Step 5 — Apply C2M / OUAF patches
1. As the OUAF product account, source the environment (`configureEnv.sh` / splenviron) for your-env.
2. Apply per the README, database component first then application-server component:
   - Single/group software fixes: `installSF.sh` / `installSFgroup.sh`.
   - Database patches: `ouafDatabasePatch.sh`.
   - Apply configuration: `initialSetup.sh`.
3. Let the OUAF error-checker run at the end of install; a failed error-check is a no-go for this
   environment.

### Step 6 — Perform a version upgrade (when the change is an upgrade, not a patch)
1. Follow the target release's **upgrade guide** (e.g. C2M 25.4): install the new OUAF/C2M version
   against the environment, run the upgrade/`initialSetup.sh` steps, and apply any post-upgrade fixes
   the guide specifies.
2. An upgrade moves the release (and often the certified stack). Its "rollback" is **restore from the
   Phase A backup**, not an OPatch/OUAF back-out — confirm the restore path before you start.
3. Redeploy/restart the WebLogic domain and C2M as the guide directs.

### Step 7 — Restart and bring the environment up
1. Start WebLogic (admin then managed servers) and the OUAF environment: `spl.sh -start`.
2. Confirm all managed servers reach RUNNING (WLST or the Administration Console) before validation.

## Phase C — Post-apply validation (every environment)

### Step 8 — Validate the applied change
1. Run `OC2MPATCH-Validation.sh` to confirm, read-only: the expected patch/version now shows in the
   OUAF and OPatch inventories, managed servers are RUNNING, key C2M health checks pass, and the
   database is at the expected level.
2. Run `OC2MPATCH-Report.sh` to produce the patch/version coverage report for this environment
   (baseline vs post-apply, per node), for the change record.
3. Execute the functional smoke tests in the Testing Guide for this environment.

> **Gate C (post-apply):** inventories show the expected change, servers RUNNING, health and smoke
> tests pass, report clean. Only when Gate C passes is the change promoted to the next environment up.

## Phase D — Rollback (if a gate fails)

### Step 9 — Roll back or restore
1. For a **patch** that failed validation: `opatch rollback` (WebLogic) and/or the OUAF back-out per the
   README, then re-run `OC2MPATCH-Validation.sh` to confirm the environment is back at baseline.
2. For an **upgrade** that failed validation, or a patch with no clean back-out: **restore from the
   Phase A backup** (DB restore point/RMAN, Oracle Home, domain, OUAF config), restart, and re-validate
   against the baseline.
3. Record the failure, the root cause, and the rollback outcome in the change record. Do not promote a
   change that failed a lower-environment gate.

## Phase E — Promote up, then production

### Step 10 — Promote through the environment progression
1. After a lower environment passes Gate C, repeat Phases A–C in the next environment up (Test/QA/UAT),
   inside its change window, with its own fresh backup.
2. Apply to **Production** only after every lower environment has passed its gate — inside the approved
   production maintenance window, with a fresh verified backup and the rehearsed rollback ready.
3. After production passes Gate C, run `OC2MPATCH-Report.sh` for the final coverage record and close the
   change.

---
### Order of operations
`Baseline -> Certify + prereqs -> Backup (Gate A) -> Apply WebLogic/OUAF or Upgrade -> Restart -> Validate (Gate C) -> [Rollback if fail] -> Promote up -> Production`
