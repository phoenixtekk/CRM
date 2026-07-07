# Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** (`01-solution-overview.md`) — the Google Workspace Migrate architecture
  (platform/worker nodes, database, connections, mappings, bridges), where it fits versus the other
  migration solutions, the wave model, and the Assess → Design → Configure → Pilot → Validate →
  Expand deployment model.
- **Requirements Guide** (`02-requirements.md`) — solution-specific prerequisites (node platform,
  M365 app registration + scopes, Google Cloud project + delegated service account, network egress,
  source inventory, mapping/bridge data, service identities), each with how to verify/implement,
  building on the shared Google global requirements.
- **Implementation Guide** (`03-implementation.md`) — exact ordered steps: baseline, size the
  platform, build connections and mappings, scan, run the pilot wave (pre-stage → delta → cutover),
  validate, then expand — with pass/fail gates and documented rollback. Tool-console internals
  deferred to Google's docs; procedure and sequencing given.
- **Testing & Validation** (`05-testing.md`) — ten tests (T1–T10) mapped to the gates, each with an
  explicit pass/fail result.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes (throttling/API limits,
  connection/permission errors, delta/incomplete-item issues, mapping/bridge errors, mail-flow) and
  resolutions.
- **Best Practices** (`07-best-practices.md`) — durable practices for platform sizing, connections/
  identity, waves/throttling/sequencing, validation, and change control.
- **Executive Summary** (`executive-summary.md`) — outcome, approach, and why it is low-risk.

## Python tools (5) — Google Workspace Admin SDK / Microsoft Graph, safe-by-default
1. **`node-sizing-assessment.py`** — read-only source discovery (Microsoft Graph): inventories
   mailbox/OneDrive/SharePoint counts, sizes, largest objects, and sharing complexity, and
   recommends a worker-node count for a target throughput and window. Produces `baseline-source.json`,
   the validation reference.
2. **`connection-mapping-generator.py`** — generates and validates the **mapping CSVs** and the
   **identity bridge** (`Bridge – Identity – Corp`) Google Workspace Migrate consumes, from directory
   data (Admin SDK + Graph). Dry-run/validate by default; never writes to a live system.
3. **`wave-batch-builder.py`** — groups in-scope users/sites into **waves**
   (`Migration Wave – <Scope> – <Stage>`) and emits a **throttling plan** (concurrency, rate
   ceilings) sized to stay under source/target API limits; `--calibrate` retunes from measured pilot
   throughput.
4. **`migration-health-check.py`** — checks connection health and **watches a running wave** for
   throughput, error rate, and sustained **throttling** (Graph 429 / Google rate limits), signaling
   when to back off. Read-only.
5. **`post-migration-validation.py`** — post-wave **validation report**: target-vs-baseline
   item-count parity, permission/ownership fidelity, and mail count + flow checks (Admin SDK / Drive
   / Gmail read APIs). Read-only.

All scripts require Python 3.10+, use OAuth / ADC (no hardcoded credentials, no keys committed), take
`--help`, and gate any write behind `--apply` (default is read-only or `--dry-run`).

## Packaged outputs
- **`GWMIGRATE-Solution.pdf`** — the compiled solution document (all sections above).
- **`GWMIGRATE-Scripts.zip`** — the five Python tools.
