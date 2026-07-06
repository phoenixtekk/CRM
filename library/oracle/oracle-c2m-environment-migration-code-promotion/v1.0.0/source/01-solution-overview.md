# 1. Solution Overview — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

## What this solution is
This is the repeatable method for moving Oracle Utilities **Customer to Meter (C2M)** configuration and
code cleanly across environments — **Development → QA → Production** — without drift and without
manual mistakes. It is not a one-off script; it is a defined promotion model with named migration
objects you build once and reuse every release, explicit go/no-go gates between environments, and an
environment-comparison step that proves what you tested is exactly what goes live.

C2M runs on the **Oracle Utilities Application Framework (OUAF)**, so promotion has three moving parts,
each with its own tooling:

1. **OUAF configuration migration** — metadata and configuration objects (business objects, algorithms,
   scripts, UI maps, lookups, batch controls, portals, and the rest) move through the framework's
   **Configuration Migration Assistant (CMA)** as **export/import bundles**.
2. **Code and web-service (IWS) promotion** — custom Java/Groovy extensions and **Inbound Web Services
   (IWS)** are promoted through the OUAF product install/patch tooling and the `iwsdeploy` utility, not
   through CMA.
3. **Environment comparison** — a deliberate parity check confirms the target now matches the source for
   the promoted scope, so nothing was dropped or silently overwritten.

> **Version boundary.** CMA, IWS deployment, and the OUAF install tooling are authored from Oracle's
> official OUAF / C2M product documentation. Version-specific object names, batch codes, and command
> switches are cited or flagged **"verify for your version"** (C2M 25.4 / minimum v2.9, WebLogic 14c per
> the certification matrix). Some CMA reference detail and patches are gated on **My Oracle Support
> (MOS)**; where a step needs a MOS note or patch, this solution points to it rather than reproducing
> gated content. All promotion assumes a **non-production environment first** and change control for
> production.

## Part 1 — OUAF configuration migration (CMA / bundles)
CMA is the framework's facility for exporting configuration from a source environment and importing it
into a target, as a self-contained file. The moving parts are named framework objects you define once:

- **Migration Assistant Configuration** — the system-wide master configuration record that enables and
  parameterizes CMA on each environment.
- **Migration Plan** — defines *what a record type looks like* to CMA: the maintenance object (MO) and
  business object to copy, and the related records to pull along with it. You reuse the delivered plans
  and add plans only for custom objects.
- **Migration Request** — defines *the specific set of data* to include in a given export: which
  configuration to bundle for this promotion. The Migration Request is your reusable, named unit of
  promotion — build one per logical scope (for example, one for rate configuration, one for a to-do
  type set) and reuse it every release.

The export produces a **binary export file** (the "bundle"). That file is transferred from the source's
export directory to the target's import directory, then imported. On import, CMA reads the file,
compares each object to what already exists in the target, lets you **review the proposed changes**, and
then applies them. Two behaviors matter for gating: when a record exists in both source and target, CMA
**fully replaces** the target object with the source version; and the import **does not delete** records
that exist only in the target. That is why the comparison step (Part 3) is not optional.

Because the export file is just a file, it can be **checked into version control** — which is what makes
promotion auditable and repeatable: the same reviewed bundle that passed QA is the artifact you apply to
Production.

## Part 2 — Code and web-service (IWS) promotion
Configuration is not code. Custom extension code (Java/Groovy, framework hooks) and any file-system
artifacts are promoted through the **OUAF product install/patch mechanism** — you deploy the same build
into each environment and run the framework's post-install steps — not through CMA.

**Inbound Web Services (IWS)** are a special case. IWS metadata migrates as configuration through CMA,
but the running service must be **deployed** into WebLogic afterward. The online *Inbound Web Service
Deployment* portal (Admin → Integration) is **supported only in development / non-production
environments**; for QA and Production, deployment is done at the command line with **`iwsdeploy[.sh]`**,
run under the product environment (`splenviron`). After deployment, the *Deployment Status* zone shows
each service as current or stale by comparing its service revision against the value captured at deploy
time — a built-in parity signal.

## Part 3 — Environment comparison (parity)
The final step of every promotion is a **comparison** of source and target for the promoted scope:
confirm the configuration objects in the Migration Request now match, confirm the IWS deployment status
is current, and confirm the code build/patch level is identical. Parity confirmed is the evidence that
"what you tested is what went live." The included scripts automate the read-only side of this: inventory
what is present, validate parity, and produce a compare report.

## The Dev → QA → Prod flow with gates
Promotion is always one direction and always gated:

- **Dev → QA.** Author and unit-test in Dev. Export the Migration Request bundle, promote the code build,
  deploy IWS, import into QA, then compare. **Gate:** QA parity confirmed and QA functional testing
  passed before anything targets Production.
- **QA → Prod.** Promote the *same* reviewed bundle and the *same* build to Production inside a change
  window, with backups taken first. Import, deploy IWS with `iwsdeploy`, then compare. **Gate:**
  Production parity confirmed against QA and a rollback point verified.

Every gate has an explicit pass/fail check (see the Testing Guide) and a documented rollback (restore the
pre-import backup / re-import the prior bundle).

## What this is not
This solution defines and automates the *promotion method*; it does not author your C2M configuration or
write your extension code. The included scripts are **read-only where they touch live systems** —
discovery, validation, and comparison — plus one remediation helper that is **dry-run by default**. They
inventory and prove parity; they do not push configuration or move code on their own.

## The deployment model
> Assess the environments and scope, configure the migration objects (Migration Request, plans, IWS
> deployment), pilot the promotion Dev → QA on a bounded scope, validate parity against the gate, then
> expand to QA → Prod. The repeatable way: **Assess, then Configure, then Pilot, then Validate, then
> Expand.**
