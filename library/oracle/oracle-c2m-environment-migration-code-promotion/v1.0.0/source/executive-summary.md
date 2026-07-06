# Executive Summary — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

Oracle Utilities **Customer to Meter (C2M)** configuration and code have to move from **Development to
QA to Production** without drift and without manual mistakes. When promotion is ad-hoc — hand-edited
configuration in each environment, code that lags the config, web services deployed inconsistently — what
goes live is not what was tested, and the first sign of trouble is a production incident. This solution
defines the **migration and code-promotion method**: OUAF configuration migration through the
**Configuration Migration Assistant (CMA)** as reusable export/import bundles, code and **Inbound Web
Service (IWS)** promotion, and a deliberate **environment-comparison** step — so what you tested is exactly
what goes live, pilot-first and rollback-ready.

This is a complete, do-it-today package written for an experienced C2M administrator. Every migration
object is named once and reused every release, so you build the promotion once and repeat it across
environments and releases instead of improvising each time.

## What you get
- A plain-language Solution Overview of the C2M promotion model: OUAF configuration migration (CMA /
  bundles), code and IWS promotion, environment comparison, and the Dev → QA → Prod flow with explicit
  go/no-go gates.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — compatible source/target
  levels, Migration Assistant Configuration, Migration Plans for custom objects, a named Migration Request,
  the file-transfer path, code build and `iwsdeploy` access, and change control with a rollback point.
- An Implementation Guide of precise, ordered steps: configure the migration objects, export the bundle,
  promote the code build, import into the target, deploy IWS from the command line, compare environments,
  and validate parity — Dev → QA first, then QA → Prod inside change control.
- Five automation scripts (**shell / WLST / SQL**, not PowerShell) for read-only environment/config
  discovery, parity validation, a source-vs-target compare report, dry-run-by-default remediation, and a
  Migration Request scope helper.
- Testing and Troubleshooting guides with per-environment pass/fail gates, plus Best Practices for a
  repeatable promotion.

## What this delivers
A repeatable, gated promotion method — reusable CMA bundles, code and IWS in lockstep, and a compare step
that proves parity — so configuration and code move cleanly across environments with no drift and a
verified rollback at every hop.

> **Boundary.** Authored from Oracle's official OUAF / C2M documentation. Version-specific object names and
> commands are cited or flagged "verify for your version" (C2M 25.4 / min v2.9, WebLogic 14c); MOS-gated
> reference detail and patches are pointed to, not reproduced. All promotion assumes a non-production
> environment first and change control for Production.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — prove the promotion Dev → QA on a bounded
scope, pass the gate, then repeat QA → Prod with backups and a verified rollback.

## Outcome
C2M configuration and code promoted cleanly from Dev to QA to Production — parity confirmed, no drift — so
what you tested is exactly what goes live.
