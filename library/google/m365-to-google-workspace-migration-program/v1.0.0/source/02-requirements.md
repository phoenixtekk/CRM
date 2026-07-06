# 2. Requirements Guide — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Verify every requirement before running the program. Each entry gives Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites (the Google tenant, the source M365/Entra
environment, DNS control, identity source of truth, pilot scope, and governance stakeholders) are in
`global-requirements-google.md`; this guide adds what the migration program specifically needs.

## 2.1 A source-estate baseline
Description: A current inventory of the Microsoft 365 source — user and mailbox counts, mailbox and
OneDrive/SharePoint data volumes, shared mailboxes and resource/room calendars, distribution lists and
groups, and the mail-touching integrations (relay connectors, service accounts, apps) — captured as
`GWMIGPROG Discovery - Source Estate - Baseline`.
Why: The wave plan, the tooling strategy, and the coexistence design are all built from this baseline;
without accurate counts and data volumes, waves are sized by guesswork and throughput estimates fail
at scale.
Verify: You can produce current user/mailbox counts and per-user data volumes for a representative
sample; run `GWMIGPROG-Discovery.ps1`.
Implement-if-missing: Run `GWMIGPROG-Discovery.ps1` against the source tenant to capture the baseline,
then fill in the data-volume and integration details it cannot read, and declare it the baseline of
record.

## 2.2 A target & tooling design
Description: A decision record — `GWMIGPROG Design - Target & Tooling - Program` — fixing the target
Google Workspace architecture (edition/licensing, org-unit structure), the identity/provisioning model,
and the migration tooling/pattern chosen per service (mail, Drive, chat/collaboration).
Why: Waves must execute the *same* design; deciding tooling or target structure per wave guarantees
rework and inconsistent outcomes across 150k users.
Verify: The design names the provisioning model and the per-service tooling pattern, and it is agreed
by the program's technical owners.
Implement-if-missing: Hold the design step (Implementation Step 2), record the decisions, and freeze
the design before Wave 0.

## 2.3 Identity & provisioning into Google
Description: Users and groups flow from the identity source of truth into Google before their data
moves — via Google Cloud Directory Sync (GCDS) or SCIM-based provisioning — per the source of truth
defined in the global requirements.
Why: A user's mailbox, Drive, and chat cannot land, and coexistence cannot route to them, until the
account exists in Google; identity is the first workstream and every wave depends on it.
Verify: A sample wave's users and groups appear in the Google Admin console before any data move; run
`GWMIGPROG-Validation.ps1` for that wave.
Implement-if-missing: Stand up GCDS/SCIM provisioning against the source of truth and confirm a test
population provisions correctly before scheduling Wave 0.

## 2.4 A coexistence design (mail routing + calendar interop)
Description: A designed transition state — `GWMIGPROG Coexistence - Mail & Calendar - Transition` —
defining how inbound mail routes while the estate is split (dual or split delivery), how migrated and
not-yet-migrated users still exchange mail, and how calendar free/busy works across the two platforms.
Why: During the months the estate is split, mail must reach the right platform for each user and
free/busy must resolve across the divide; without a coexistence design mail is lost or double-delivered
and cross-platform scheduling fails. Split delivery routes inbound mail to Google or Microsoft 365 per
recipient/mailbox rules; dual delivery delivers to a primary and forwards to a secondary
([Google — dual delivery](https://support.google.com/a/answer/9228551),
[Google — split delivery](https://support.google.com/a/answer/12971016)).
Verify: The design specifies the routing pattern and the free/busy interop approach, and a test
message and a test cross-platform meeting resolve correctly in a lab.
Implement-if-missing: Design coexistence in Step 3, stand up routing on a test domain/host, and prove
it before the first production wave. Coexistence is transitional — set its intended end.

## 2.5 A wave plan
Description: A segmentation of the 150k-user population into sized, bounded, scheduled waves — named
`GWMIGPROG Wave Plan - Segmentation - 150k` — with Wave 0 as the pilot.
Why: Wave count and size are driven by user numbers, data volume, and data types
([Google — plan your phases](https://support.google.com/workspacemigrate/answer/9275515)); a plan is
what turns a 150k population into executable, gated units and keeps data-heavy users from swamping any
single wave.
Verify: Every in-scope user is assigned to exactly one wave, waves are sized against migration
throughput, and the pilot wave is identified.
Implement-if-missing: Build the wave plan from the discovery baseline using the sizing method in the
Implementation Guide; build each wave's target group with `GWMIGPROG-Set-ScopeTargeting.ps1`.

## 2.6 Per-wave cutover runbook and go/no-go gate
Description: A repeatable per-wave runbook — `GWMIGPROG Runbook - Cutover - Per Wave` — with the fixed
sequence (readiness → mail-flow/DNS → data move → validation → rollback) and an explicit
`GWMIGPROG Gate - Go/No-Go - Per Wave` that must pass before the next wave starts.
Why: Every wave executes the same governed cutover; an ungoverned cutover is declared done before its
validation completes, and a failed cutover with no rollback becomes an incident.
Verify: The runbook exists with all five stages and a documented rollback, and the gate criteria are
defined and owned.
Implement-if-missing: Author the runbook and gate in Steps 5–6, prove them on Wave 0, and reuse them
unchanged for every subsequent wave.

## 2.7 A program cadence, RACI, and change control
Description: A recurring program forum with a RACI — `GWMIGPROG Cadence & RACI - Program - All Stages`
— that owns the wave schedule, chairs each go/no-go, and operates under the change-control process for
production mail-flow, DNS, and identity changes.
Why: A months-long program across mail, DNS, identity, and multiple business units needs named owners
and a decision forum, or waves stall and high-impact changes go in unreviewed.
Verify: A recurring forum exists with the right owners, and every wave's cutover stages have a named
Responsible and Accountable owner.
Implement-if-missing: Stand up the cadence and RACI in Step 1 and align it to the change-control
process from the global requirements.

---
## Checklist
- [ ] Source-estate baseline captured — `GWMIGPROG-Discovery.ps1` → `GWMIGPROG Discovery - Source Estate - Baseline`
- [ ] Target & tooling design frozen — `GWMIGPROG Design - Target & Tooling - Program`
- [ ] Identity/provisioning into Google live — `GWMIGPROG-Validation.ps1`
- [ ] Coexistence design proven — `GWMIGPROG Coexistence - Mail & Calendar - Transition`
- [ ] Wave plan built (every user in one wave) — `GWMIGPROG Wave Plan - Segmentation - 150k`
- [ ] Per-wave runbook + go/no-go gate authored — `GWMIGPROG Runbook - Cutover - Per Wave`
- [ ] Program cadence + RACI + change control — `GWMIGPROG Cadence & RACI - Program - All Stages`
