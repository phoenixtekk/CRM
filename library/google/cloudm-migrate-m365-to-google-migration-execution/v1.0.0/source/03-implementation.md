# Implementation

Execute the migration following the house model **Assess → Design → Configure → Pilot → Validate →
Expand**, pilot-first, with explicit pass/fail gates and a documented rollback. Every artifact is
named with the `<Purpose> – <Scope> – <Stage>` convention and reused verbatim in testing,
troubleshooting, and the scripts.

> **CloudM console internals are deferred to CloudM's documentation.** Where a step happens *inside*
> the CloudM Migrate console (creating the connection object, building the profile, launching a run),
> the **procedure and sequencing** are given here; the exact screen labels and clicks are CloudM's to
> document and may change by version — **verify for your version.** Google Admin console and Entra
> steps are exact.

---

## Stage 1 — Assess (read-only discovery)

**1.1 Inventory the source.** Run `assess-migration-readiness.py` (read-only) against the Google
destination directory and a source export to size the migration: user counts, mailbox and OneDrive
sizes, SharePoint site inventory, and license coverage. Save the output as the assessment baseline.

**1.2 Confirm quotas and endpoints.** Confirm the Google project has the required APIs enabled and
that both Microsoft and Google API endpoints are reachable from the platform's network (self-hosted:
from each migration server). Record the provider throttling ceilings you expect to hit (Graph
per-app/per-mailbox limits, Gmail API quotas) — `plan-migration-waves.py` uses these to advise
throttling.

**1.3 Verify all requirements.** Walk R1–R7 and the global GR-1…GR-6. **Gate 1 (Assess):** every
requirement verified, assessment baseline captured. Do not proceed until met.

## Stage 2 — Design

**2.1 Design waves.** Group users into waves aligned to departments/sites. Reserve
`Migration Wave – Pilot – Wave0` (25–50 low-risk, cooperative users spanning the data types you must
prove: heavy mailbox, large OneDrive, Shared-Drive/SharePoint user). Run `plan-migration-waves.py`
to produce a sequenced wave plan with pre-stage/delta ordering and throttling guidance.

**2.2 Design the profile.** Finalize `Migration Profile – Mail+Drive – Standard` per R6: what to
migrate, date-range filters, exclusions, fidelity expectations, and throttling limits.

**2.3 Design the user list.** Generate the mapping CSV with `build-migration-userlist.py` (dry-run
default), reconciling source UPNs to destination Google addresses and file sources to Shared Drives.
Align headers to CloudM's import template (**verify for your version**).

**Gate 2 (Design):** wave plan, profile design, and pilot user list reviewed and approved by the
migration + security owners.

## Stage 3 — Configure

**3.1 Stand up the platform.** Confirm `Migration Platform – Enterprise – Prod` is reachable
(hosted) or installed/scaled (self-hosted) per R1.

**3.2 Build the source connection.** In CloudM, create `Source Connection – M365 – Prod` using the
Entra app registration from R2 (Application/Directory IDs + secret/cert). *(CloudM console steps
deferred — verify for your version.)* Test the connection; it must authenticate and enumerate a
sample mailbox.

**3.3 Build the destination connection.** Create `Destination Connection – Google – Prod` using the
service account + DWD from R3. Test; it must authenticate and impersonate a sample destination user.
If it fails, re-check the DWD scope list in **admin.google.com → Security → API controls →
Domain-wide delegation** (see Troubleshooting).

**3.4 Build the profile.** Create `Migration Profile – Mail+Drive – Standard` from the R6 design.

**3.5 Import the pilot user list.** Import the `Migration Wave – Pilot – Wave0` CSV into a run bound
to the profile.

**Gate 3 (Configure):** both connections test green; profile and pilot list imported without errors.

## Stage 4 — Pilot (`Migration Wave – Pilot – Wave0`)

Run the full pass sequence on the pilot cohort. **This proves the design before any production wave.**

**4.1 Scan (read-only).** Launch a **Scan** pass for Wave0. It discovers item counts/sizes per user
without writing. Record the scan totals as the expected baseline for validation.

**4.2 Pre-stage.** Launch `Pre-stage Run – Pilot – Wave0` to bulk-copy historical mail and files
into Google while pilot users still work in M365. Monitor throughput; if you hit provider throttling,
lower concurrency per `plan-migration-waves.py` guidance (see Troubleshooting).

**4.3 Delta + cutover.** In the approved change window (R7):
  1. Run `Delta Run – Pilot – Wave0` to copy everything changed since pre-stage.
  2. Execute the **MX/mail-routing cutover** for the pilot users' domain/routing per the cutover
     runbook (DNS is high-impact — GR-3).
  3. Run a **post-cutover** `Delta Run – Pilot – Wave0` to sweep the final items delivered to M365
     during the switch.

**Gate 4 (Pilot pass/fail):** proceed to validation only if all pilot users completed with errors
triaged (not necessarily zero, but every error explained). **Rollback if failed:** revert MX to
M365, keep M365 authoritative, retriage, and re-run — no production wave starts until the pilot
passes.

## Stage 5 — Validate

**5.1 Run validation.** Execute `Validation Report – Pilot – Wave0` with
`validate-migration-report.py`: compare migrated item counts against the scan baseline per user,
spot-check Drive/Shared-Drive permissions, and confirm mail is delivering to Google (test message
in/out). See `05-testing.md` for the full test matrix and expected results.

**5.2 Confirm mail flow.** Send a message from an external address to a pilot user and confirm
delivery to Gmail; send from the pilot user outbound and confirm SPF/DKIM/DMARC pass.

**Gate 5 (Validate):** item-count variance within the agreed tolerance, permissions intact, mail
flowing both ways, users confirm access. Only now is the profile/connection design blessed for
production.

## Stage 6 — Expand (production waves)

For each production wave (e.g. `Migration Wave – Finance – Wave3`), repeat the proven sequence:

1. Import the wave's user list into a run on `Migration Profile – Mail+Drive – Standard`.
2. **Scan** → record baseline.
3. `Pre-stage Run – <Dept> – <Wave>` well ahead of the change window.
4. In the change window: `Delta Run` → **MX cutover** (per runbook, rollback ready) → post-cutover
   `Delta Run`.
5. `Validation Report – <Dept> – <Wave>` — must pass the Gate 5 criteria before the wave is closed.

Sequence waves per `plan-migration-waves.py` so concurrent pre-stage/delta load stays under provider
throttling ceilings. Run `check-migration-health.py` between passes to watch error rates, throttling
signals, and destination account/license health, and to catch drift before it compounds.

**Per-wave rollback (production):** if a wave fails validation, revert its MX/routing to M365, keep
M365 authoritative for that cohort, triage errors, and re-run the delta+cutover in the next window.
Because waves are cohort-scoped, a failure is contained.
