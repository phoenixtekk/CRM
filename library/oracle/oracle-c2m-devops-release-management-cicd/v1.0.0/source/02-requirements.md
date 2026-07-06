# 2. Requirements Guide — Oracle C2M DevOps Release Management & CI/CD Automation

Verify every requirement before wiring the pipeline. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites (entitlement, certified stack, WLST/shell/SQL tooling,
change control) are in `global-requirements-oracle.md` and are assumed here. The single-change promotion
mechanics (CMA objects, `iwsdeploy`) are covered by the **C2M Environment Migration & Code Promotion**
sibling and referenced, not repeated.

## 2.1 A source-control repository for code, config bundles, and settings
Description: A **version-control repository** (Git or equivalent) that holds the code/extension build
sources, the retained CMA **configuration export bundles**, and the per-environment settings snapshots so
each release is a reproducible, auditable artifact set.
Why: DevOps for C2M starts with treating a release as a versioned tuple (build + bundle + IWS list +
settings). Without source control there is no reliable "the same reviewed artifact goes to Prod" — the
core promise of the pipeline.
Verify: Confirm a repository exists and that a build, a CMA export bundle, and an environment settings
snapshot can be checked in and retrieved. `OC2MDEVOPS-Discovery.sh` reports whether the release-artifact
locations are present.
Implement-if-missing: Stand up a repository and define where builds, bundles, and settings snapshots are
retained before running the pipeline.

## 2.2 Defined pipeline stages, artifacts, and gates
Description: The pipeline's named **stages** (build → migrate config → deploy → validate), the **artifact**
each produces, and the **gate** each must pass — written down, not improvised per release.
Why: A pipeline is only repeatable if every run performs the same ordered stages with the same pass/fail
gate; ad-hoc "do the steps I remember" releases are neither auditable nor safe.
Verify: The stage/gate definition exists and names the artifact and gate for each stage;
`OC2MDEVOPS-ScopeHelper.sh` prints the release scope (build version, bundle, IWS list) so you confirm a
run's inputs match the change.
Implement-if-missing: Document the four stages, their artifacts, and their gates (see the Implementation
Guide) and register the release scope before the first pilot run.

## 2.3 Environment access to run OUAF utilities non-interactively
Description: The product OS account and access to source **`splenviron`** and run the OUAF command-line
utilities (`initialSetup`, `configureEnv`, `threadpoolworker`, `iwsdeploy`, the batch/submit utilities)
and WLST against each environment the pipeline targets, in a **non-interactive** (scriptable) way.
Why: The pipeline automates the release by invoking these utilities; if they can only be run by hand at an
interactive prompt, the pipeline cannot orchestrate them.
Verify: You can source `splenviron` for the environment and run the utilities from a script/service
account; WLST connects to the domain. `OC2MDEVOPS-Discovery.sh` reports environment reachability and the
utilities present.
Implement-if-missing: Provision the product/service account, confirm the utilities are on the path under
`splenviron`, and (per the global rules) run app-side steps under `sudo -u <product-user>` / the correct
JDK, never a bare shell.

## 2.4 A promotable code build and configuration bundle
Description: The versioned **code/extension build** (produced from the OUAF SDK / product install tooling)
and the reviewed **CMA configuration export bundle** for the release — the two artifacts the pipeline
promotes together, in lockstep, across environments.
Why: Configuration migrates by bundle and code migrates by installed build; a release that promotes one
without the other is a half-promotion and a classic source of "config is live but behaves wrong."
Verify: A build artifact is identified and versioned, and a CMA export bundle exists for the scope;
`OC2MDEVOPS-Validation.py` reports the build level and the presence of the bundle. (Bundle/CMA mechanics:
migration sibling.)
Implement-if-missing: Produce a versioned build and export the reviewed CMA bundle; retain both in the
source-control repository (2.1) as one release.

## 2.5 Inbound Web Service deployment access on each target
Description: Command-line access to run **`iwsdeploy[.sh]`** under the product environment (`splenviron`)
on every target environment, to deploy the in-scope **Inbound Web Services** as part of the deploy stage.
Why: IWS metadata travels with the configuration bundle, but the running service must be deployed — and for
QA/Production that deployment is command-line only (the online IWS deployment portal is supported in
non-production environments only).
Verify: You can source the product environment and run `iwsdeploy` on each target; the *Deployment Status*
zone reflects the result. `OC2MDEVOPS-Validation.py` reports each in-scope IWS module's runtime state.
Implement-if-missing: Confirm shell access and the in-scope IWS list on each target, and script the
`iwsdeploy` invocation into the deploy stage.

## 2.6 Routine-admin automation targets (lifecycle, batch, health)
Description: The **routine tasks** the pipeline will automate around a release: graceful stop/start of the
C2M managed/admin servers, quiescing and resuming the `threadpoolworker`s (and online batch submission),
and the post-deploy health/readiness checks (domain up, IWS active, schema reachable, log clean).
Why: A release usually needs a controlled restart and a batch quiesce; done by hand these are the most
common source of a botched deploy (batch running against a half-promoted schema, servers started out of
order). Automating them makes the release consistent and hands-off.
Verify: The start/stop order, the batch-quiesce approach, and the health checks are defined for each
environment; `OC2MDEVOPS-Validation.py` reports the health signals it can read.
Implement-if-missing: Document the lifecycle order and batch-quiesce steps and wire them into the deploy
stage; use the included validation as the automated post-deploy health gate.

## 2.7 Change control, backups, and a rollback point per environment
Description: A change window and approval for each target, a verified **backup** taken before the deploy
stage (database/config export, current bundle level, current build/patch level), and a defined rollback.
Why: The deploy stage installs a build and imports a bundle that **replaces** existing target
configuration; a bad release must be recoverable. Production runs inside change control with a proven
restore path.
Verify: A backup/restore path is confirmed and a change window/approval exists; the current target bundle
and build levels are recorded so you can re-promote the prior release if needed.
Implement-if-missing: Establish the backup/restore procedure and change-control approval before running the
pipeline into QA or Prod (see `global-requirements-oracle.md` §5).

## 2.8 A pilot release scope
Description: A bounded, well-understood first **release** — a single small build + one scoped configuration
bundle + a short IWS list — to prove the whole pipeline Dev → QA before running a full release or touching
Production.
Why: The pipeline, its gates, and its routine-admin automation are validated on a pilot release first, so
the stages, artifacts, restart order, and health checks are confirmed end to end cheaply.
Verify: A pilot release scope and its owners are identified; `OC2MDEVOPS-ScopeHelper.sh` resolves and
prints it.
Implement-if-missing: Choose a small, representative release (one bounded change) as the first pipeline run.

---
## Checklist
- [ ] Source-control repo for build + config bundle + settings — `OC2MDEVOPS-Discovery.sh`
- [ ] Pipeline stages / artifacts / gates defined — `OC2MDEVOPS-ScopeHelper.sh`
- [ ] Non-interactive OUAF-utility access per environment — `OC2MDEVOPS-Discovery.sh`
- [ ] Promotable code build + reviewed CMA bundle — `OC2MDEVOPS-Validation.py`
- [ ] `iwsdeploy` access on each target — `OC2MDEVOPS-Validation.py`
- [ ] Routine-admin automation targets defined (lifecycle, batch, health) — `OC2MDEVOPS-Validation.py`
- [ ] Backups, change control, and rollback point per environment
- [ ] Pilot release scope identified — `OC2MDEVOPS-ScopeHelper.sh`
