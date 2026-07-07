# Implementation

Execute these steps in order. They follow the house model — **Assess → Design → Configure → Pilot →
Validate → Expand** — pilot-first, with explicit pass/fail gates and a rollback for every production
change. Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused by that exact name in
Testing (05), Troubleshooting (06), and the scripts.

> **Verify for your version.** Steps that touch GWMME's own installer, connection dialogs, mapping-file
> columns, scopes, or supported Exchange/EWS versions are given at the **procedural level**. Confirm
> the exact clicks/columns/values against **Google's current GWMME documentation** for the build you
> download before running against production.

---

## Phase A — Assess (read-only)

**A1. Inventory the source.** Using read-only access to the Microsoft source (GR-2), enumerate every
in-scope mailbox with **item counts and sizes** and flag special cases (shared mailboxes, resource/room
calendars, very large mailboxes, archives). Produce `Source Inventory – Exchange – Assess`.
*Tool:* `gwmme_discovery.py` reconciles the source list against provisioned Google users and emits the
inventory + a mapping skeleton.

**A2. Reconcile targets.** Confirm every source mailbox has a **provisioned, licensed** Google target
user (R4). List any source with no target (must be provisioned first) and any target with no source
(out of scope). Output feeds `Mapping – Users – Master`.

**A3. Confirm GWMME fit.** Verify the move is **mail/calendar/contacts** only and within a scale GWMME
handles (Overview). If file data (Drive/OneDrive/SharePoint) is in scope, plan a **separate** tool for
that portion now — do not attempt it with GWMME.

> **Gate A (Assess → Design):** complete inventory with sizes; every in-scope source has a licensed
> target; GWMME confirmed as the right tool for the data types in scope. **Fail → stop:** provision
> missing targets or re-scope the tool choice before proceeding.

---

## Phase B — Design

**B1. Define waves.** Group mailboxes into batches `Migration Wave – <Scope> – <NN>` sized to the
throttling budget (Phase D) — start with a small representative **pilot** wave
(`Migration Wave – Pilot – 01`), then business-unit waves. Keep very large mailboxes and special cases
in their own smaller waves.
*Tool:* `gwmme_batch_planner.py` proposes throttle-aware waves from the inventory (dry-run).

**B2. Set the throttling budget.** From source/destination throttling guidance (verify for your
source), decide concurrent mailboxes per run and per-wave size. Record it with the wave plan.

**B3. Decide coexistence & cutover.** Decide how mail flows during migration and when **MX/DNS** cut
over to Google (R6, GR-3). Author `Rollback Plan – Cutover – Mail` (revert MX, re-point clients) and
get it approved under change control (GR-5).

**B4. Define pass/fail gates.** Write the completeness criteria each wave must meet in Validate
(Phase F) — e.g. mail folder/item counts within tolerance, calendar events present, contacts present,
errors triaged.

> **Gate B (Design → Configure):** waves defined and sized; throttling budget set; cutover model +
> `Rollback Plan – Cutover – Mail` approved; validation gates written. **Fail → stop:** finish the
> design before touching production access.

---

## Phase C — Configure

**C1. Build the host.** Stand up `Migration Host – GWMME – Primary` (R1): patched Windows VM meeting
GWMME's prerequisites, with reachability to the source EWS and Google endpoints, and disk headroom for
logs. Restrict access to the migration team.

**C2. Grant source access.** On the Microsoft side, create/authorize
`Source Access – Exchange – App Impersonation` (R2) — the read identity with impersonation/application
access over the in-scope mailboxes — and confirm EWS is enabled and reachable. *(Exact grant mechanism
depends on Exchange Online vs. on-prem — verify for your source.)*

**C3. Create the Google service identity.** Create `Service Identity – Google – Migration` (R3): enable
the required APIs and authorize the migration scopes GWMME needs. **Store its credential securely; do
not export or commit any key.**
*Tool:* `gwmme_prereq_validator.py` checks host reachability, source/destination access, and mapping
readiness **read-only** before you install GWMME.

**C4. Install & configure GWMME.** On the host, install GWMME per Google's current documentation for
your version, and configure its **source connection** (to the Exchange source via EWS using
`Source Access – Exchange – App Impersonation`) and its **destination connection** (to Google using
`Service Identity – Google – Migration`). *(Installer, dialogs, and connection fields — verify for your
version.)*

**C5. Build the mapping.** Complete `Mapping – Users – Master` — the source→target CSV GWMME consumes —
from the assessment output. Derive each wave's mapping subset from it.
*Tool:* `gwmme_config_helper.py` builds/validates the mapping CSV and derives per-wave subsets.

> **Gate C (Configure → Pilot):** host ready; source and destination access verified by
> `gwmme_prereq_validator.py` (all checks green); GWMME installed and both connections configured;
> `Mapping – Users – Master` validated. **Fail → stop:** resolve every failed prereq before running any
> migration.

---

## Phase D — Pilot

**D1. Run the pilot wave.** Execute `Migration Wave – Pilot – 01` — a small, representative set
(a handful of mailboxes including at least one with a busy calendar and a full contacts list) — through
GWMME using the pilot's mapping subset. Keep to the throttling budget (B2).

**D2. Capture logs.** Retain GWMME's run logs and per-item results for the pilot for triage in
Validate/Troubleshooting.

**D3. Do not cut over yet.** The pilot proves the pipeline; **no MX/DNS change** happens until pilot
validation passes.

> **Gate D (Pilot → Validate):** the pilot wave ran to completion (with errors captured, not ignored).
> **Fail → Troubleshooting (06):** fix permission/throttling/connection issues and re-run the pilot
> before validating.

---

## Phase E — Validate the pilot

**E1. Validate completeness.** For each pilot mailbox, compare **source vs. destination** for mail
(folder/item counts within tolerance), **calendar** (events present, including recurring), and
**contacts** (present). Produce `Validation Report – Pilot – 01`.
*Tool:* `gwmme_validation_report.py` builds the per-user mail/calendar/contacts completeness report and
flags shortfalls.

**E2. Triage errors.** Classify every error (permission, throttling, unsupported/oversized item,
delta gaps) using Troubleshooting (06). Re-run deltas where needed.

**E3. Spot-check quality.** Manually open a sample of migrated mailboxes: verify folder structure,
a recurring meeting, and a contact render correctly in Gmail.

> **Gate E (Validate → Expand):** `Validation Report – Pilot – 01` shows mail/calendar/contacts
> complete within tolerance and all errors triaged/resolved; spot-checks pass. **Fail → stop:** do not
> scale a broken pipeline — fix and re-validate the pilot first.

---

## Phase F — Expand (wave by wave), then cut over

**F1. Run each production wave.** Execute `Migration Wave – <Scope> – <NN>` in sequence, each sized to
the throttling budget. Do **not** start the next wave until the current one passes its gate.

**F2. Validate each wave.** Produce `Validation Report – <Scope> – <NN>` with `gwmme_validation_report.py`
and triage errors before proceeding.

**F3. Run final deltas.** Immediately before cutover for a wave, run a **delta** pass to catch mail that
arrived at the source after the initial run.

**F4. Cut over mail flow.** When all waves for a domain are validated, execute the **MX/DNS cutover**
(R6, GR-3) under the approved change window so new mail delivers to Google.
`Rollback Plan – Cutover – Mail` is on standby.

**F5. Verify post-cutover mail flow.** Confirm inbound test mail delivers to Google and no mail bounces.

> **Gate F (per wave, and at cutover):** each wave's validation report passes before the next; after
> cutover, inbound mail delivers to Google. **Fail at cutover → rollback:** execute
> `Rollback Plan – Cutover – Mail` (revert MX/DNS, re-point clients), restore source mail flow, then
> diagnose before re-attempting.

---

## Rollback summary

| Change (high-impact) | Rollback |
|---|---|
| MX/DNS cutover to Google (`Rollback Plan – Cutover – Mail`) | Revert MX/DNS to the source, re-point clients, confirm source mail flow restored. |
| Source impersonation/app access grant | Remove the grant if migration is aborted; it is read-only, so no source data changes. |
| Google service identity scopes | Revoke the migration scopes / disable the service identity when the program completes. |
| A bad wave run | GWMME copies (does not delete source); re-run the wave into the target after fixing the root cause. |

*Data movement itself is low-risk to roll back — GWMME reads the source and writes the destination; it
does not delete source data. The genuine production risk is **mail-flow/DNS cutover**, which is why it
is gated and has an explicit, approved rollback.*
