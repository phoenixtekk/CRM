# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — the tool-agnostic cutover-operations model: wave batching, throttling/API-limit
  management, pre-stage→delta→cutover sequencing, post-migration validation, and hypercare; and how this
  solution positions against the program-plan and per-service/tool migration solutions.
- **Requirements Guide** — solution-specific prerequisites (chosen/connected engine, discovery user set,
  both-vendor limit model, read-only service identity, validation criteria, hypercare team + SLA, change
  window + rollback authority), building on the shared Google category requirements.
- **Implementation Guide** — exact ordered steps through **Assess → Design → Configure → Pilot →
  Validate → Expand**, pilot-first, with every artifact named (`Migration Wave – <Scope> – <Stage>`),
  explicit pass/fail gates, and a documented cutover rollback.
- **Testing & Validation** — 11 tests (T1–T11) each with an expected pass/fail signal, covering discovery
  completeness, cluster integrity, throttle-budget fit, pre-stage throttling, cutover readiness,
  item-count/permission/mail/delegate/calendar parity, hypercare SLA, and safe-by-default tool behavior.
- **Troubleshooting** — common failure modes and resolutions: throttling / API-limit 429s, permission
  errors, incomplete-item / delta issues, split-cluster cutover breakage, mail-flow/coexistence problems,
  and hypercare SLA breaches.
- **Best Practices** — durable practices for wave design, throttling, sequencing, validation, hypercare,
  and safe automation.
- **Executive Summary** — outcome, approach, and why the solution is low-risk.

## The 5 Python tools (`scripts/`)
Google Workspace Admin SDK / API automation (with Microsoft Graph read where the source must be read).
Each is **read-only or `--dry-run` by default**, uses OAuth / ADC, and carries **no secrets in code**.

1. **`discovery-profile.py`** — *Assessment / discovery (read-only).* Profiles the discovery user-set
   export (and optionally the live Google directory via Admin SDK Directory) to report user count, data
   distribution, delegate and shared-mailbox **clusters**, and any rows missing attributes the batcher
   needs. Produces `Discovery Profile – Enterprise – Assess`.

2. **`wave-batcher.py`** — *Orchestration helper (read-only planning; writes only the plan files).*
   Batches the user set into ordered, size-limited, **dependency-aware** waves (keeps delegate and
   shared-mailbox clusters together), carving a small pilot wave first. Emits `waves.csv` and the
   `Migration Wave – <Scope> – <Stage>` plan; flags any split clusters.

3. **`throttle-planner.py`** — *Policy / throttling / API-limit check (read-only).* Computes a per-wave
   **throttle budget** (concurrent workers + pacing) that keeps projected request rate under both the
   Microsoft Graph throttling model and the Google API quotas for the wave's volume and window, with
   headroom; `--observe` mode checks a sampled rate file against budget. Produces `Throttle Budget –
   <Wave> – Design`.

4. **`cutover-readiness.py`** — *Cutover-readiness / config-scope helper (read-only).* Runs the pre-cutover
   go/no-go checks for a wave — target accounts exist & licensed, no split clusters, pre-stage/delta
   complete, coexistence routing in place — and emits an all-green/red `Cutover Readiness – <Wave> –
   <Stage>` report that gates the mail-flow switch.

5. **`validate-migration.py`** — *Validation / report generator (read-only).* Post-migration validation:
   compares per-user **item counts** (vs. a source manifest), **permissions/sharing**, **mail flow**,
   **delegates**, and **calendar/free-busy** against the agreed criteria; emits the JSON + HTML
   `Validation Report – <Wave> – <Stage>` — the evidence a wave is done. *(A companion
   `hypercare-triage.py` tracker records post-cutover issues against the SLA; it is bundled with the
   validation tool as the evidence/close-out pair.)*

> Safe-by-default: every write path is gated behind an explicit `--apply`; assessment, batching,
> planning, readiness, and validation are read-only. Credentials are supplied via OAuth / Application
> Default Credentials or a least-privilege domain-wide-delegated service account — never hardcoded.
> `pip install google-api-python-client google-auth` where the Google APIs are used.
