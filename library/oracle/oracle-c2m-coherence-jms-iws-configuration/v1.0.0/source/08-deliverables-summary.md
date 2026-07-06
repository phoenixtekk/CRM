# Deliverables Summary — C2M Coherence, JMS & IWS Configuration

What this solution includes and how the pieces fit together.

## Documentation

| Document | Purpose |
|----------|---------|
| **Solution Overview** (`01`) | The C2M runtime — Coherence clustering, JMS messaging, Inbound Web Services — and how they support batch, real-time, and integration. |
| **Requirements Guide** (`02`) | Every prerequisite with how to *verify* and *implement* (domain, topology, Coherence network/ports, JMS store, C2M message-sender reconciliation, IWS enablement). |
| **Implementation Guide** (`03`) | Exact steps: Coherence cluster → JMS server/module/destinations/CF → IWS deploy/enable → validate, pilot-first, with pass/fail gates and rollback. |
| **Testing Guide** (`05`) | Objective/steps/pass-criterion tests for clustering, messaging, and web-service calls, plus a consolidated health gate. |
| **Best Practices** (`07`) | Production-safe guidance across Coherence, JMS, and IWS. |
| **Troubleshooting Guide** (`06`) | Symptom → likely cause → resolution for the common runtime failures. |
| **Executive Summary** | One-page business framing for sponsors. |
| **Global Requirements** | The Oracle-category prerequisites shared by every C2M/WebLogic solution. |

## Automation scripts (`scripts/`)

Five scripts authored in the authentic C2M/WebLogic toolchain — **WLST (Jython), shell, and SQL**
(never PowerShell). Read-only scripts are safe to run anywhere; the remediation script is **dry-run by
default**.

| Script | Type | Mode | What it does |
|--------|------|------|--------------|
| **`OC2MRUNTIME-Discovery`** | WLST | Read-only | Snapshots the current Coherence cluster(s), JMS servers/modules/destinations/CF, and IWS deployment to an evidence file. |
| **`OC2MRUNTIME-Validation`** | WLST | Read-only | Per-node pass/fail checks: Coherence membership, JMS destination health, `spl-web-services` deployment status. |
| **`OC2MRUNTIME-Report`** | WLST | Read-only | Health/coverage report across scope — members present, destination pending/consumer counts, inbound services enabled/responding. |
| **`OC2MRUNTIME-Remediation`** | WLST | **Dry-run default** | Plans/creates missing runtime objects (cluster association, JMS destinations/CF/subdeployment targeting) — prints the plan unless an explicit apply flag is set. |
| **`OC2MRUNTIME-ScopeHelper`** | shell | Helper | Resolves and validates the target scope (servers/cluster, connection details) and exports it so the other scripts act only in scope, portably across environments. |

> A small SQL helper query is included inline within the report tooling notes for reconciling C2M
> Inbound Web Service / Message Sender metadata where a database read is the fastest cross-check.

## How they work together

`ScopeHelper` fixes the target set → `Discovery` captures the baseline → `Validation` gates each phase
→ `Remediation` (dry-run first) fills gaps → `Report` produces the sign-off artifact. Reuse the same
named objects and rerun the same scripts in each environment (retargeted via `ScopeHelper`) so Test
and Prod get the identical, validated configuration.

## Outcome

The C2M runtime wired correctly — Coherence clustering, JMS messaging, and IWS integration all
healthy — proven on a pilot before scaling, with saved evidence for change control.
