# 1. Solution Overview — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

## What this runbook is
Oracle Utilities Customer to Meter (C2M) is a layered product: the Oracle Utilities Application
Framework (OUAF) and the C2M application on top, deployed on Oracle WebLogic Server, backed by an
Oracle Database, running on a certified OS and JDK. Keeping it supportable means keeping every layer
current — applying Oracle **patches** (single fixes, rollups, service packs, and WebLogic
patch-set updates) and periodically performing **version upgrades** (for example, toward
**C2M 25.4**). This runbook is not a one-time script; it is the disciplined, repeatable method to
apply patches and perform upgrades across environments without taking production down: readiness,
backup, apply, validate, rollback.

## Why this matters
Patching and upgrading is where most self-inflicted C2M outages come from. The failure modes are
predictable: a patch applied to production with no verified backup and therefore no way back; an
upgrade run first (or only) against production, so the first time anyone sees the new behavior is in
front of users; a patch applied to an uncertified WebLogic/JDK/DB combination that loses
supportability; a "quick" fix with no rollback that leaves the domain half-patched. The fix is not a
better one-off — it is a governed operation applied the same way every time: prove it in a lower
environment, back up before you touch anything, apply with the vendor's own utilities, validate
against a gate, and keep a rollback you have actually tested. This section is the why; the
Implementation Guide (titled *Upgrade & Patch Runbook*) is the how.

## Supportability — why staying current is not optional
Oracle support and security are tied to release and patch level. Running an out-of-support C2M/OUAF
release or an unpatched WebLogic means security exposure and, when you open a service request, a
"patch to a supported level first" response before Oracle will engage. Staying current on a
disciplined cadence keeps you inside the support window and closes known vulnerabilities before they
are exploited — which is the entire point of doing this deliberately rather than reactively.

## The certified-version matrix
Every C2M release is certified against specific OS, JDK, Oracle Database, and WebLogic versions. C2M
25.4 (minimum OUAF v2.9, WebLogic 14c — **verify for your version** against the release's
certification matrix on My Oracle Support) only supports certified combinations. Before any upgrade
you confirm the target C2M release and align OS/JDK/DB/WebLogic to a certified combination; before any
patch you confirm the patch is for your release. Patching or upgrading into an uncertified stack is
how installs fail and supportability is lost.

## The tooling — OPatch and the OUAF utilities
Two families of tooling do the work, and this runbook uses them, not a GUI-only workflow:

- **WebLogic / Fusion Middleware — OPatch.** `opatch lsinventory` reports what is applied to a
  WebLogic Oracle Home; `opatch apply` applies a patch; `opatch rollback` removes it. OPatch is
  shipped in the Oracle Home (`$ORACLE_HOME/OPatch`); WebLogic 14c uses the OPatch version shipped
  with that release (**verify for your version**). Always read the patch README first.
- **C2M / OUAF — the framework utilities.** `configureEnv.sh` sets the environment configuration;
  `initialSetup.sh` applies configuration to the product/domain; `installSF.sh` and
  `installSFgroup.sh` install single/group software fixes; `ouafDatabasePatch.sh` applies database
  patches; `spl.sh` starts and stops the environment. OUAF installs the database component first,
  then the application-server component, then runs an error-checker — and shuts WebLogic environments
  down automatically during install (non-WebLogic environments are stopped manually).

The included automation is authored in **WLST (Jython), shell, and SQL** — the same interfaces an
administrator uses — never PowerShell.

## The environment progression (lower first)
Nothing is applied to production first. The progression is fixed: apply and validate in the lowest
environment (Dev), promote to the next (Test/QA/UAT), and only after each lower environment passes its
gate does the change reach Production — inside a change window, with a verified backup and a documented
rollback. The same runbook runs in each environment; what changes is the go/no-go gate that must pass
before the change moves up.

## Patch vs upgrade — same discipline, different scope
A **patch** (single fix, rollup, service pack, or WebLogic PSU) is a targeted change applied with
OPatch or the OUAF install utilities and is generally reversible with a rollback. A **version upgrade**
(for example C2M to 25.4) is a larger, forward operation that moves the release and often the certified
stack; it is reversed by restoring from backup rather than a simple rollback. This runbook applies the
same discipline to both — readiness, backup, apply, validate, rollback/restore — and calls out where
they differ.

## What this is not
This runbook governs the operation of patching and upgrading. It does not invent patch numbers or
reproduce entitlement-gated content: specific patch IDs, service-pack numbers, and step-by-step
release instructions live in each patch's README and in the release's Installation/Upgrade guide on
My Oracle Support, which this runbook points you to. The included scripts are read-only where they
touch live systems (discovery, validation, reporting); the one remediation helper runs dry-run by
default and never applies a patch itself.

## The deployment model
> Assess readiness and back up, apply the patch or upgrade in the lowest environment, prove it,
> validate against the gate, then promote up to production. The repeatable way: Assess, then
> Configure, then Pilot, then Validate, then Expand — with a verified backup and a documented rollback
> at every step.
