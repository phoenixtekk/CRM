# 3. Implementation Guide — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

Follow these steps in order. This guide promotes C2M configuration and code across environments:
export/import the OUAF configuration bundle, promote the code build, deploy Inbound Web Services, compare
environments, and validate parity — Dev → QA first, then QA → Prod, each behind an explicit gate. Object
names are fixed; build the Migration Request once and reuse it every release.

> Model: prove the promotion on a bounded scope Dev → QA, validate parity against the gate, then repeat
> QA → Prod inside change control. The repeatable way: **Assess, then Configure, then Pilot, then
> Validate, then Expand.**

> **Direction and safety.** Promotion is always source → target and one-way. Always take a backup of the
> target before import (CMA replaces existing objects and does not delete extras). Production is always
> touched inside a change window with a verified rollback point.

## Step 1 — Assess the environments and scope
1. Run `OC2MMIG-Discovery.sh` against the **source** (Dev) and each **target** (QA, Prod) to inventory the
   C2M/OUAF release and patch level, CMA readiness, and the Migration Plans/Migration Requests present.
2. Confirm source and target are at compatible framework levels (Requirement 2.1). Record any gap; do not
   proceed past a version mismatch you have not planned for.
3. Define the promotion scope in writing: which configuration objects, which custom objects, which code
   build/patch, and which Inbound Web Services are changing.

## Step 2 — Configure the migration objects
1. Confirm the **Migration Assistant Configuration** master record is enabled on the source and each
   target, with valid export/import directories (Requirement 2.2).
2. For every configuration object type in scope — including **custom** MOs/business objects — confirm a
   **Migration Plan** exists (delivered plan reused, or a custom plan authored). A missing plan means the
   object is silently excluded from the bundle.
3. Create or confirm the named **Migration Request** for this scope. Build it once and reuse it every
   release; verify its declared scope with `OC2MMIG-ScopeHelper.sh`.

## Step 3 — Export the configuration bundle from the source
1. On the source (Dev), run the CMA export for the Migration Request. This produces a **binary export
   file** (the bundle) in the export directory.
2. Retain the bundle in **version control** (or the controlled staging location) so the exact reviewed
   artifact is the one promoted onward — this is what makes the release auditable and repeatable.
3. Record the bundle name/version alongside the code build/patch version and the IWS list; these three
   travel together as one release.

## Step 4 — Promote the code build
1. Install the same versioned **code build / patch** into the target that was tested in the source, using
   the OUAF product install/patch steps. Configuration migrates by bundle; code migrates by installed
   build — keep them in lockstep.
2. Run the framework post-install steps required by the build (verify for your version), so the target's
   file-system artifacts and framework hooks match the source.

## Step 5 — Import the bundle into the target
1. Transfer the binary export file from the source export directory to the **target import directory**
   (Requirement 2.5).
2. Back up the target first (Requirement 2.7): database/config export and a note of the current bundle
   level, so you can re-import the prior bundle if needed.
3. Run the CMA import. CMA reads the file, compares each object to the target, and presents the **proposed
   changes** for review. Review them — confirm the objects match the intended scope — before applying.
4. Apply the import. Remember: matching objects are **fully replaced** from the source; target-only
   objects are **not deleted**. Anything unexpected in the review is your signal to stop and reconcile.

## Step 6 — Deploy Inbound Web Services on the target
1. IWS *metadata* arrived with the bundle, but the running service must be deployed. On the target,
   source the product environment (`splenviron`) and run **`iwsdeploy[.sh]`** to deploy the in-scope
   Inbound Web Services.
2. Use the **command line** for QA and Production — the online *Inbound Web Service Deployment* portal
   (Admin → Integration) is supported **only in non-production** environments.
3. Confirm the *Deployment Status* zone shows each in-scope service as **current** (its service revision
   matches the deployed value); a stale status means the service still needs deployment.

## Step 7 — Compare environments and confirm parity
1. Run `OC2MMIG-Report.sh` to produce a source-vs-target **compare report** for the promoted scope:
   configuration objects present and matching, IWS deployment status current, and code build/patch level
   identical.
2. Run `OC2MMIG-Validation.sh` on the target to confirm the parity signals (CMA import applied, IWS
   current, build level matched) with no gaps.
3. If the compare report shows a gap, remediate the *cause* — re-run the missing part (re-import the
   bundle, re-deploy an IWS, or re-apply the build) — then re-compare. Use `OC2MMIG-Remediation.sh`
   (dry-run by default) to preview any corrective action before applying it.

## Step 8 — Validate against the environment gate
1. Complete the Testing Guide for this target. The promotion passes the gate only when the compare report
   shows **parity for the full scope**, IWS deployment status is current, and the code build level matches
   the source.
2. For **QA**, also confirm functional testing passed on the promoted change before promoting onward.
3. For **Production**, confirm the backup/rollback point is verified and the change window/approval is in
   place before and after the import.

## Step 9 — Pilot Dev → QA, then expand QA → Prod
1. **Pilot:** run Steps 3–8 for the bounded pilot Migration Request Dev → QA. Passing the QA gate proves
   the migration objects, transfer path, IWS deployment, and comparison all work end to end.
2. **Expand:** promote the full release Dev → QA, pass the gate, then promote the **same reviewed bundle
   and same build** QA → Prod inside change control. Re-run `OC2MMIG-Report.sh` and `OC2MMIG-Validation.sh`
   for Production and pass the Production gate.
3. Keep the Migration Request, the bundle-in-version-control practice, and the compare step for every
   future release — the method is now repeatable.

---
### Order of operations
`Assess -> Configure migration objects -> Export bundle -> Promote code build -> Import bundle -> Deploy IWS -> Compare/parity -> Validate gate -> Pilot Dev→QA -> Expand QA→Prod`
