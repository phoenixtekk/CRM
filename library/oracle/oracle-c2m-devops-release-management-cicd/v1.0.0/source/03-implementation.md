# 3. Implementation Guide — Oracle C2M DevOps Release Management & CI/CD Automation

Follow these steps in order. This guide **defines the C2M release pipeline** and wires the routine-admin
automation: build the release artifacts, migrate configuration, deploy code and Inbound Web Services,
validate parity and health — Dev → QA first, then QA → Prod, each behind an explicit gate. Stage names and
artifacts are fixed; define the pipeline once and run it every release. The single-change CMA/`iwsdeploy`
mechanics are covered in the **C2M Environment Migration & Code Promotion** sibling and are referenced,
not repeated, here.

> Model: prove the pipeline on a bounded release Dev → QA, validate parity + health against the gate, then
> repeat QA → Prod inside change control. The repeatable way: **Assess, then Configure, then Pilot, then
> Validate, then Expand.**

> **Direction and safety.** Promotion is always source → target and one-way. Always take a backup of the
> target before the deploy stage (the pipeline installs a build and imports a bundle that replaces target
> config). Production is always touched inside a change window with a verified rollback point, with the
> routine-admin automation (quiesce batch, restart in order) run as part of the deploy.

## Step 1 — Assess the environments and the release scope
1. Run `OC2MDEVOPS-Discovery.sh` against the **source** (Dev) and each **target** (QA, Prod) to inventory
   environment reachability, the OUAF release/patch level, the utilities present (`splenviron`,
   `iwsdeploy`, batch/threadpool), and whether the release-artifact locations (build, bundle, settings) are
   in place.
2. Confirm source and target are at compatible framework levels; record any gap and do not proceed past a
   version mismatch you have not planned for.
3. Define the **release scope** in writing: the code build version, the configuration bundle, the in-scope
   Inbound Web Services, and the environment settings that change. Register it so a run's inputs are
   explicit; confirm with `OC2MDEVOPS-ScopeHelper.sh`.

## Step 2 — Configure the pipeline stages and routine-admin automation
1. Define the four **stages** and their **gates** (Requirement 2.2): **Build → Migrate config → Deploy →
   Validate**. For each, name the artifact it produces and the pass/fail gate it must clear.
2. Wire the **source-control** locations (Requirement 2.1): where the code build, the CMA export bundle,
   and the per-environment settings snapshots are retained, so the same reviewed artifacts flow onward.
3. Wire the **routine-admin automation** (Requirement 2.6) into the deploy stage: the graceful
   stop/start order for the C2M managed and admin servers (sourced through `splenviron`), the
   `threadpoolworker` / batch quiesce-and-resume, and the post-deploy health checks. Use
   `OC2MDEVOPS-Validation.py` as the automated health gate.

## Step 3 — Build stage: produce the release artifacts
1. Compile the versioned **code/extension build** from source (OUAF SDK / product install tooling) and
   stamp it with the release version.
2. Export the reviewed **configuration bundle** from the source (Dev) via CMA (mechanics: migration
   sibling) and retain it in source control alongside the build.
3. Record the **release tuple** — build version + bundle + IWS list + settings — as one unit. **Gate:** the
   build compiles clean and the bundle exports without error.

## Step 4 — Migrate-config stage: import configuration into the target
1. Back up the target first (Requirement 2.7): database/config export, and note the current bundle and
   build levels so you can re-promote the prior release if needed.
2. Import the configuration bundle into the target (CMA import), **reviewing the proposed changes before
   applying** — matching objects are fully replaced from the source; target-only objects are not deleted.
3. **Gate:** the import applied and the review showed only the intended scope. Anything unexpected is your
   signal to stop and reconcile (see the migration sibling for the review discipline).

## Step 5 — Deploy stage: install code, run routine-admin, deploy IWS
1. **Quiesce** the target with the routine-admin automation: pause the `threadpoolworker`s / online batch
   submission so nothing runs against a half-promoted environment, then gracefully stop the C2M managed
   server if the build requires it.
2. Install the same versioned **code build / patch** that was tested in the source, then run the framework
   post-install steps (`initialSetup` and the build's post-install; verify for your version) so the
   target's file-system artifacts and framework hooks match the source.
3. Deploy the in-scope **Inbound Web Services** with **`iwsdeploy[.sh]`** under `splenviron` — command-line
   for QA and Production (the online IWS deployment portal is non-production only).
4. **Resume** with the routine-admin automation: start the admin/managed servers in order and re-enable the
   `threadpoolworker`s / batch. **Gate:** servers up, build level matched, IWS deployment status current.

## Step 6 — Validate stage: prove parity and health
1. Run `OC2MDEVOPS-Report.sql` (or the SQL report) to produce the source-vs-target **compare** for the
   promoted scope: configuration objects present and matching, code build/patch level identical, IWS status
   current.
2. Run `OC2MDEVOPS-Validation.py` on the target (WLST) to confirm the server-running and IWS runtime-state
   signals with no gaps — this is the environment/health side of the parity gate.
3. If a signal is a gap, remediate the *cause* — re-run the relevant stage (re-import the bundle, re-install
   the build, re-deploy an IWS, or re-run a routine-admin step) — then re-validate. Use
   `OC2MDEVOPS-Remediation.sh` (dry-run by default) to preview any corrective action before applying it.

## Step 7 — Validate against the environment gate
1. Complete the Testing Guide for this target. The release passes the gate only when the compare shows
   **parity for the full scope**, the code build level matches the source, IWS deployment status is
   current, and the environment health checks pass.
2. For **QA**, also confirm functional testing passed on the promoted change before promoting onward.
3. For **Production**, confirm the backup/rollback point is verified and the change window/approval is in
   place before and after the deploy.

## Step 8 — Pilot Dev → QA, then expand QA → Prod
1. **Pilot:** run Steps 3–7 for the bounded pilot release Dev → QA. Passing the QA gate proves the pipeline
   stages, the routine-admin automation, the IWS deployment, and the parity/health checks all work end to
   end.
2. **Expand:** run the full release Dev → QA, pass the gate, then promote the **same build, same reviewed
   bundle, and same IWS list** QA → Prod inside change control, with the routine-admin automation run as
   part of the deploy. Re-run `OC2MDEVOPS-Report.sql` and the validations for Production and pass the gate.
3. Keep the pipeline definition, the source-control-of-artifacts practice, and the validate stage for every
   future release — the release is now repeatable, governed, and hands-off.

---
### Order of operations
`Assess -> Configure pipeline + routine-admin -> Build artifacts -> Migrate config -> Deploy (quiesce, install, iwsdeploy, resume) -> Validate parity/health -> Pass gate -> Pilot Dev→QA -> Expand QA→Prod`
