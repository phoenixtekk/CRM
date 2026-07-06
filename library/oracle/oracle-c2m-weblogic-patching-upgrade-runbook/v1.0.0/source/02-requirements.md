# 2. Requirements Guide — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

Verify every requirement before you apply a patch or start an upgrade. Each entry: Description, Why,
Verify, Implement-if-missing. Category-wide prerequisites are in `global-requirements-oracle.md`.

> Version note: C2M 25.4 / minimum OUAF v2.9 / WebLogic 14c are the in-scope versions — **verify for
> your version** against the release's certification and upgrade documentation on My Oracle Support
> (MOS). Specific patch numbers and MOS notes are pointed to, not reproduced.

## 2.1 My Oracle Support (MOS) access and the patch/upgrade media
Description: A valid Oracle support entitlement and My Oracle Support access to download the C2M/OUAF
patches, WebLogic patches (OPatch patch ZIPs), and — for an upgrade — the target release
installation/upgrade media and its README/upgrade guide.
Why: Patches, media, and the certification matrix all flow from the entitlement; without MOS access
you cannot obtain the fix or read the patch README that governs how it is applied.
Verify: You can sign in to MOS, locate a patch by number for your platform, and download it; run
`OC2MPATCH-Discovery.sh` to record the current patch/version baseline you will patch from.
Implement-if-missing: Obtain the support entitlement and MOS credentials before proceeding; do not
substitute an unofficial patch source.

## 2.2 Certified target release and stack
Description: A confirmed **target** C2M release (for a patch, your current release; for an upgrade,
e.g. C2M 25.4) and an OS / JDK / Oracle Database / WebLogic combination **certified** for it per the
release's certification matrix.
Why: C2M/OUAF only supports certified combinations; patching or upgrading into an uncertified stack
fails and loses supportability.
Verify: Compare the environment's OS, JDK, DB, and WebLogic versions against the target release's
certification matrix (MOS); run `OC2MPATCH-Discovery.sh` to capture the installed versions to compare.
Implement-if-missing: Align OS/JDK/DB/WebLogic to a certified combination first — treat that alignment
as its own change, backed up and validated, before the C2M patch/upgrade.

## 2.3 Verified backups (domain config, OUAF product/config, database)
Description: A **verified, restorable** backup taken immediately before any apply: the WebLogic domain
configuration and Oracle Home, the OUAF product and configuration (splenviron/config), and the C2M
database (or a guaranteed DB restore point/RMAN backup).
Why: A patch is only safely reversible if you can get back to the pre-patch state; an upgrade is
reversed by restore, not rollback. A backup you have not verified is not a backup.
Verify: The backup completed and a restore has been proven at least once in a lower environment; run
`OC2MPATCH-Validation.sh --pre-check` to confirm backup markers are present before apply.
Implement-if-missing: Establish and test the backup/restore path (DB restore point + RMAN, Oracle Home
and domain archive, OUAF config archive) before touching any environment.

## 2.4 The patch README / upgrade guide read and understood
Description: The specific patch README (for OPatch or OUAF fixes) or the release upgrade guide has been
read, including prerequisites, ordering (database component before app-server component for OUAF),
conflicts, and the documented rollback.
Why: Each patch/upgrade has its own prerequisites and order; applying without reading the README is the
most common cause of a failed or half-applied change.
Verify: You can state the patch's prerequisites, whether it conflicts with an applied patch
(`opatch lsinventory` / OUAF inventory), and its documented rollback path.
Implement-if-missing: Download and read the README/upgrade guide from MOS before scheduling the change.

## 2.5 Change control and a maintenance window
Description: An approved **change record** and a **maintenance window** for each environment, with
production changes gated on successful lower-environment validation.
Why: Patching and upgrading are high-impact; production changes must be approved, scheduled, and
communicated, and must not proceed until lower environments have passed their gate.
Verify: A change record exists with an approved window, a rollback plan, and named approvers; the lower
environments' validation results are attached.
Implement-if-missing: Raise the change with the rollback plan and window; do not apply to production
without approval and a passing lower-environment gate.

## 2.6 A non-production pilot environment
Description: A representative **non-production** environment (Dev, then Test/QA/UAT) that mirrors
production closely enough (same certified stack, comparable data) to prove the patch/upgrade first.
Why: Every patch and upgrade is proven in a lower environment before production; the pilot is where you
catch conflicts, data issues, and rollback problems cheaply.
Verify: A pilot environment exists at the same certified stack as production; run
`OC2MPATCH-ScopeHelper.sh` to confirm the environment order and produce the target list for this
change.
Implement-if-missing: Stand up or refresh a non-production environment to a production-like state
before scheduling the production change.

## 2.7 Administrative access and tooling (OPatch, OUAF utilities, SQL, WLST)
Description: Administrative access and the toolchain: **OPatch** in the WebLogic Oracle Home, the OUAF
utilities (`configureEnv.sh`, `initialSetup.sh`, `installSF.sh`/`installSFgroup.sh`,
`ouafDatabasePatch.sh`, `spl.sh`), **WLST (Jython)** for WebLogic, and **SQL*Plus / SQLcl** for the
database.
Why: The runbook applies and validates changes through these interfaces; without them you cannot apply,
inventory, or verify a patch.
Verify: `opatch version` runs from the Oracle Home, the OUAF product account can run the framework
utilities, WLST connects to the domain, and SQL connects to the C2M schema; run
`OC2MPATCH-Discovery.sh` (exercises the read-only paths of each).
Implement-if-missing: Provision the access and install/locate the client tooling before the change.

## 2.8 A go/no-go gate and rollback plan per environment
Description: A defined pass/fail **gate** (what must be true to promote the change up) and a
documented **rollback** (OPatch rollback / OUAF back-out for patches; restore-from-backup for upgrades)
for each environment.
Why: Promotion between environments must be a decision against a gate, not a habit; and every apply
must have a rehearsed way back.
Verify: The gate criteria and rollback steps are written into the change record; run
`OC2MPATCH-Validation.sh` in a lower environment to confirm the gate can be evaluated.
Implement-if-missing: Author the gate from the Testing Guide and the rollback from the patch README
before the first apply.

---
## Checklist
- [ ] MOS access + patch/upgrade media obtained — `OC2MPATCH-Discovery.sh`
- [ ] Certified target release and stack confirmed
- [ ] Verified, restorable backups taken — `OC2MPATCH-Validation.sh --pre-check`
- [ ] Patch README / upgrade guide read (prereqs, order, rollback)
- [ ] Change record + maintenance window approved
- [ ] Non-production pilot environment ready — `OC2MPATCH-ScopeHelper.sh`
- [ ] Admin access + tooling verified (OPatch, OUAF utilities, WLST, SQL) — `OC2MPATCH-Discovery.sh`
- [ ] Go/no-go gate + rollback plan documented per environment — `OC2MPATCH-Validation.sh`
