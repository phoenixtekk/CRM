# 1. Solution Overview — Oracle C2M DevOps Release Management & CI/CD Automation

## What this solution is
This is the repeatable **DevOps model** for Oracle Utilities **Customer to Meter (C2M)**: a pipeline
that builds, promotes, and deploys OUAF configuration and code across environments, plus automation for
the routine administrative tasks a release depends on (environment restarts, health checks, batch and
web-service actions). It is not a one-off script and it is not a promotion of a single change — it is a
**named, staged pipeline** you define once and run every release, with explicit go/no-go gates between
stages and a documented rollback at each hop.

C2M runs on the **Oracle Utilities Application Framework (OUAF)** on **Oracle WebLogic Server 14c**, and
OUAF administration is deliberately command-line and file-based (`splenviron`, `initialSetup`,
`configureEnv`, `threadpoolworker`, `iwsdeploy`, and the SQL schema) rather than GUI-only. That is
exactly what makes it automatable: every step a release performs has a scriptable, version-controllable
form. This solution wires those steps into a governed pipeline.

> **Version boundary.** The OUAF command-line utilities, the Configuration Migration Assistant (CMA),
> `iwsdeploy`, and the install/patch tooling are authored from Oracle's official OUAF / C2M product and
> Server Administration documentation. Version-specific utility names, switches, batch codes, and object
> names are **cited or flagged "verify for your version"** (C2M 25.4 / minimum v2.9, WebLogic 14c per the
> certification matrix). Some reference detail and patches are gated on **My Oracle Support (MOS)**; where
> a step needs a MOS note or patch, this solution points to it rather than reproducing gated content. All
> pipeline runs assume a **non-production environment first** and change control for Production.

> **Relationship to the migration solution.** The mechanics of *moving one change* — CMA Migration
> Assistant Configuration, Migration Plans, the Migration Request, the binary export bundle, `iwsdeploy`,
> and the source-vs-target parity compare — are defined in the sibling **C2M Environment Migration & Code
> Promotion** solution. **This solution references that method and does not duplicate it.** Here the focus
> is the layer *above* it: the **pipeline** that orchestrates build → migrate → deploy → validate as
> governed, repeatable stages, and the **automation** of the routine admin tasks around each release.

## The C2M DevOps model — three parts

### Part 1 — Source control for OUAF config and code
The release artifacts are put under version control so a release is an auditable, reproducible thing, not
a memory:

- **Code and extensions** — custom Java/Groovy, framework hooks, and the OUAF **SDK** project artifacts
  live in a source-control repository and produce a versioned **build**.
- **Configuration** — OUAF configuration is exported by CMA as a **binary export bundle** (a file), which
  is retained in version control alongside the build. The reviewed bundle that passed a lower environment
  is the exact artifact promoted onward.
- **Environment settings** — the per-environment `ENVIRON.INI` / `configureEnv` values and property files
  (e.g. `threadpoolworker.properties`, `submitbatch.properties`) are captured so an environment can be
  reconstructed and so differences between environments are visible, not accidental.

A **release** is therefore a named tuple — *build version + configuration bundle + IWS list + environment
settings* — that moves through the pipeline together.

### Part 2 — The build → promote → deploy pipeline
The pipeline has named, ordered **stages**, each producing an **artifact** and each ending in a **gate**:

1. **Build** — compile the code/extension build from source (OUAF SDK / product install tooling), export
   the configuration bundle from the source environment via CMA, and stamp both with the release version.
   *Artifact:* the versioned build + the CMA bundle. *Gate:* build succeeds, bundle exports clean.
2. **Migrate config** — import the configuration bundle into the target environment (CMA import, reviewed
   before apply). *Artifact:* imported configuration. *Gate:* import applied, review showed only the
   intended scope. (Mechanics per the migration sibling.)
3. **Deploy** — install the same versioned build, run the framework post-install (`initialSetup` and the
   build's post-install steps), and deploy the in-scope **Inbound Web Services** with `iwsdeploy` (the
   online IWS deployment portal is dev-only; QA/Prod are command-line). *Artifact:* the running,
   deployed target. *Gate:* build level matches, IWS deployment status current.
4. **Validate** — run the read-only parity and health checks (config objects present and matching, IWS
   current, build level identical, environment healthy) and prove the target equals the source for the
   promoted scope. *Artifact:* the validation report. *Gate:* full parity + healthy environment.

The stages run **Dev → QA → Prod**, one direction only. The *same reviewed artifacts* that passed the QA
gate are the ones promoted to Production inside a change window with backups taken first.

### Part 3 — Automation of routine admin
Around every release sit routine administrative tasks that are error-prone when done by hand. The pipeline
automates them as reusable, named actions so a release is hands-off and consistent:

- **Environment lifecycle** — graceful stop/start of the C2M managed server and admin server, sourced
  through `splenviron`, so a deploy that needs a restart does not rely on a human remembering the order.
- **Batch / threadpool control** — quiescing and resuming the `threadpoolworker`s (and any online batch
  submission) around a config/code change, using the OUAF batch utilities, so no batch runs against a
  half-promoted environment.
- **Health and readiness checks** — post-deploy checks that the domain is up, the IWS are active, the
  schema is reachable, and the log is clean, wired as an automated gate rather than a manual glance.
- **Promotion glue** — the scripted orchestration that runs the CMA import, the build install, and
  `iwsdeploy` in the correct order with the correct environment sourced — the repeatable "run the
  release" action.

The five included scripts are the read-only and dry-run backbone of this automation: discover the
pipeline/environment inventory, validate a stage's parity/health, report on it, remediate a gap
(dry-run by default), and resolve the release scope.

## The Dev → QA → Prod pipeline with gates
Promotion is always one direction and always gated:

- **Dev → QA.** Build from source, export the config bundle, and run the pipeline into QA: migrate config,
  deploy build + IWS, validate. **Gate:** QA parity confirmed, environment healthy, and QA functional
  testing passed before anything targets Production.
- **QA → Prod.** Promote the *same* build, the *same* reviewed bundle, and the *same* IWS list to
  Production inside a change window, with backups taken first and the routine-admin automation (quiesce
  batch, restart in order) run as part of the deploy. **Gate:** Production parity confirmed against QA and
  a verified rollback point.

Every gate has an explicit pass/fail check (see the Testing Guide) and a documented rollback (restore the
pre-deploy backup, re-import the prior bundle, re-install the prior build).

## What this is not
This solution defines and automates the *release pipeline and routine admin*; it does not author your C2M
configuration or write your extension code, and it does not re-explain CMA/`iwsdeploy` mechanics (that is
the migration sibling). The included scripts are **read-only where they touch live systems** — discovery,
validation, and reporting — plus one remediation helper that is **dry-run by default**. They inventory,
prove readiness, and preview corrective actions; they do not push config, move code, or restart anything
on their own unless explicitly told to.

## The deployment model
> Assess the environments and the release scope, configure the pipeline and its routine-admin automation,
> pilot the pipeline Dev → QA on a bounded scope, validate parity and health against the gate, then expand
> to QA → Prod. The repeatable way: **Assess, then Configure, then Pilot, then Validate, then Expand.**
