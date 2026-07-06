# 2. Requirements Guide — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

Verify every requirement before promoting anything. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites (entitlement, certified stack, WLST/shell/SQL tooling,
change control) are in `global-requirements-oracle.md` and are assumed here.

## 2.1 Source and target environments at compatible levels
Description: A **source** environment (where the change is authored — Dev) and a **target** environment
(QA, then Prod) running the same C2M/OUAF release and, ideally, the same patch level. CMA supports
migrating across framework versions, but same-version promotion is the safe default for a release.
Why: CMA import compares and replaces objects in the target; a large framework-version gap between
source and target introduces schema and object-definition differences that must be reconciled first.
Verify: Record the C2M release, OUAF version, and patch/bundle level on both environments; run
`OC2MMIG-Discovery.sh` against each. Confirm they match (or that any gap is intended and understood).
Implement-if-missing: Align the target to the source's release/patch level before promoting, or plan the
version-upgrade path per Oracle's cross-version CMA guidance (verify for your version on MOS).

## 2.2 Migration Assistant Configuration enabled on both environments
Description: The system-wide **Migration Assistant Configuration** master record configured on the source
and the target so CMA can export and import.
Why: CMA will not export or import without its master configuration in place; it defines the export/import
directories and framework behavior on each environment.
Verify: The Migration Assistant Configuration record exists and its export/import file directories are
readable/writable by the product OS account; `OC2MMIG-Validation.sh` reports the CMA-readiness signal.
Implement-if-missing: Complete the Migration Assistant Configuration on each environment and confirm the
export and import directories exist on the file system with the correct ownership.

## 2.3 Migration Plans for all objects in scope (including custom)
Description: A **Migration Plan** for every configuration object type being promoted. The delivered plans
cover framework and product objects; any **custom** maintenance object/business object needs its own plan.
Why: A Migration Request can only bundle object types that have a Migration Plan; a custom object with no
plan is silently left out of the promotion — a classic cause of "it worked in QA but is missing in Prod."
Verify: For each custom object in scope, confirm a Migration Plan exists that names its MO and business
object and pulls the related records. Inventory with `OC2MMIG-Discovery.sh`.
Implement-if-missing: Author a Migration Plan for each custom object type (MO + business object + related
records) before building the Migration Request.

## 2.4 A named Migration Request per promotion scope
Description: A reusable **Migration Request** that defines exactly which configuration this promotion
bundles — built once per logical scope and reused every release.
Why: The Migration Request is the unit of promotion. A stable, named request is what makes releases
repeatable and auditable; ad-hoc "select everything" exports are neither.
Verify: The Migration Request for the scope exists and lists the intended objects; `OC2MMIG-ScopeHelper.sh`
prints the request's declared scope so you can confirm it matches the change.
Implement-if-missing: Create a Migration Request scoped to the change (for example, one for rate
configuration, one for a to-do/algorithm set) and name it so it is reused, not recreated, each release.

## 2.5 File transfer path between environments
Description: A controlled way to move the CMA **binary export file** from the source's export directory to
the target's import directory (secure copy, a shared staging area, or a version-control checkout).
Why: CMA export and import are two steps joined by a file; if the file cannot reach the target's import
directory the promotion cannot proceed.
Verify: You can copy a test file from the source export directory to the target import directory with the
product OS account and correct permissions.
Implement-if-missing: Establish the transfer path (scp/sftp or shared mount) and, preferably, a
version-control location so every promoted bundle is retained and auditable.

## 2.6 Code build / patch artifact and IWS deployment access
Description: The promotable **code build or patch** (the same artifact installed into each environment)
and command-line access to run `iwsdeploy[.sh]` under the product environment (`splenviron`) on the
target for **Inbound Web Services** deployment.
Why: Configuration alone is not the whole change; custom code and IWS must be promoted too. IWS
deployment to QA/Prod is command-line only — the online deployment portal is supported **only in
non-production** environments.
Verify: The build/patch artifact is identified and versioned; you can source the product environment and
run `iwsdeploy` on the target. `OC2MMIG-Validation.sh` reports the IWS deployment-status signal.
Implement-if-missing: Produce a versioned build/patch, stage it for each environment, and confirm shell
access to run the OUAF install steps and `iwsdeploy` on QA and Prod.

## 2.7 Change control, backups, and a rollback point per environment
Description: A change window and approval for the target, a verified **backup** taken before import
(database/config export, and note of the current bundle/patch level), and a defined rollback.
Why: CMA import **replaces** existing target objects and does not delete extras; a bad promotion must be
recoverable. Production import happens inside change control with a proven restore path.
Verify: A backup/restore path is confirmed and a change window/approval exists for the target; the current
target bundle level is recorded so you can re-import it if needed.
Implement-if-missing: Establish the backup/restore procedure and change-control approval before importing
into QA or Prod (see `global-requirements-oracle.md` §5).

## 2.8 A pilot promotion scope
Description: A bounded, well-understood first promotion — a single Migration Request covering one object
family — to prove the Dev → QA path before promoting the full release or touching Production.
Why: The method is validated on a pilot scope first so the migration objects, transfer path, IWS
deployment, and comparison are confirmed end to end cheaply.
Verify: A pilot Migration Request and its owners are identified; `OC2MMIG-ScopeHelper.sh` resolves its
scope.
Implement-if-missing: Choose a small, representative configuration set as the first promotion.

---
## Checklist
- [ ] Source/target at compatible C2M/OUAF levels — `OC2MMIG-Discovery.sh`
- [ ] Migration Assistant Configuration enabled on both — `OC2MMIG-Validation.sh`
- [ ] Migration Plans exist for all in-scope objects (incl. custom) — `OC2MMIG-Discovery.sh`
- [ ] Named Migration Request per scope — `OC2MMIG-ScopeHelper.sh`
- [ ] File transfer path source export dir → target import dir
- [ ] Code build/patch artifact + `iwsdeploy` access — `OC2MMIG-Validation.sh`
- [ ] Backups, change control, and rollback point per environment
- [ ] Pilot promotion scope identified — `OC2MMIG-ScopeHelper.sh`
