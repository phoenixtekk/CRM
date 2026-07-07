# Implementation

Run these steps in order. They follow the house model **Assess → Design → Configure → Pilot →
Validate → Expand**, pilot-first, with explicit pass/fail gates and a documented rollback for every
production change. Every artifact is named with the convention `<Purpose> – <Scope> – <Stage>`;
reuse the exact names in testing, troubleshooting, and the scripts.

> **Tool-console boundary.** Where a step drives Google Workspace Migrate's own console (node
> installer prompts, connection wizard, scan/migration screens), the **procedure and sequence** are
> given here but the **exact screen labels and version-specific options are deferred to Google's
> Google Workspace Migrate documentation** — confirm them **for your version** as you go. The Python
> tools operate outside the console against the Admin SDK / Graph and generate the artifacts the
> console imports.

---

## Phase 1 — Assess

### 1.1 Baseline the source (read-only)
Run the discovery to quantify the migration and feed sizing:

```
python node-sizing-assessment.py --graph --out baseline-source.json
```

This reads Microsoft Graph (read-only) for mailbox/OneDrive/SharePoint counts, sizes, largest
objects, and sharing complexity, and prints a recommended **worker-node count** for a target
throughput and window. Store the output as `baseline-source.json` — it is the reference every
validation gate compares against.

### 1.2 Confirm prerequisites
Verify R1–R7 (Requirements) and the shared GR-1…GR-6. Do not proceed until the node hosts (R1), both
connection identities (R2/R3), network egress (R4), and the pilot scope (GR-5) are confirmed.

**Gate A (enter Design):** baseline captured; node hosts provisioned; both connection identities
created and consented; pilot OU/group named.

---

## Phase 2 — Design

### 2.1 Size the platform
Using `baseline-source.json`, fix the node platform:
- **`GWSM Platform Node – Migration – Prod`** — one management/database node (verify current spec).
- **`GWSM Worker Node – Migration – NN`** — worker nodes at the count `node-sizing-assessment.py`
  recommends for the throughput needed to finish within the window (round up for delta passes).

### 2.2 Design mappings and the identity bridge
Decide the target shape and generate the artifacts (dry-run):

```
python connection-mapping-generator.py --dry-run \
    --graph --directory --out mapping-plan/
```

Standard mapping design:
- **OneDrive → My Drive** per user (`Mapping – <Dept> OneDrive – <Stage>`).
- **SharePoint site/library → Shared Drive** (`Mapping – <Site> SharePoint – <Stage>`).
- **Mailbox → Gmail** per user (`Mapping – <Dept> Mail – <Stage>`).
- **`Bridge – Identity – Corp`** — resolves every source identity to a target identity so ownership
  and sharing survive. Every in-scope source object must resolve to exactly one target.

### 2.3 Plan waves and the throttling budget
Group in-scope users/sites into waves and compute a safe throttling budget:

```
python wave-batch-builder.py --dry-run \
    --baseline baseline-source.json --wave-size 250 --out waves/
```

This emits per-wave batch files (`Migration Wave – <Scope> – <Stage>`) and a **throttling plan**
(concurrency per node, requests/sec ceilings) sized to stay under source/target API limits. Start
conservative; the pilot will calibrate the real ceiling.

**Gate B (enter Configure):** node count fixed; mappings + `Bridge – Identity – Corp` generated and
reviewed (every object resolves once); wave plan + throttling budget drafted.

---

## Phase 3 — Configure

### 3.1 Stand up the node platform
1. Install Google Workspace Migrate on **`GWSM Platform Node – Migration – Prod`** (follow Google's
   node installer for your version — screen labels deferred to Google's docs). Point it at the
   dedicated encrypted database volume (R1).
2. Install and register each **`GWSM Worker Node – Migration – NN`** to the platform node.
3. Confirm all nodes report healthy in the console before creating connections.

### 3.2 Create the connections
1. **`Connection – Microsoft 365 – Source`** — enter the Entra app registration (R2) client ID +
   secret reference and the scopes; test the connection until it authenticates.
2. **`Connection – Google Workspace – Target`** — enter the Google delegated service account (R3);
   test until it authenticates and can impersonate a target user.

Validate connection health before importing anything:

```
python migration-health-check.py --connections --dry-run
```

### 3.3 Import mappings and the bridge
Import the reviewed `mapping-plan/` CSVs and `Bridge – Identity – Corp` into the project (console
import — verify the import screen for your version). Re-run the generator with `--validate` to
confirm the imported set matches what was generated.

### 3.4 Run a scan (read-only discovery)
Run a **scan** over the pilot scope only. A scan is read-only: it discovers what exists and how big,
with no writes to the target. Review the scan for unsupported items, oversized objects, and
permission anomalies before any migration.

**Gate C (enter Pilot):** all nodes healthy; both connections test-pass; mappings + bridge imported
and validated; pilot scan complete and reviewed with no blocking anomalies.

---

## Phase 4 — Pilot (pilot-first, on `Migration Wave – Finance – Pilot`)

Run the pilot wave through the full pre-stage → delta → cutover sequence on the named pilot scope
(GR-5). **Rollback** for each step is defined below.

### 4.1 Pre-stage (bulk) pass
Start the migration for `Migration Wave – Finance – Pilot` with the throttling plan from Phase 2.
Users keep working on the source; nothing is cut over. Monitor throughput and error rate:

```
python migration-health-check.py --wave "Migration Wave - Finance - Pilot" --watch
```

**Rollback (pre-stage):** the source is untouched and the target is not yet live to users — pause
or stop the run, delete the partially-migrated target content for the wave, correct the mapping or
throttling, and re-run. No user impact.

### 4.2 Delta pass
Re-run the wave in **delta** mode to carry only what changed since the pre-stage pass. Confirm the
delta completes cleanly and the incremental item count is small and expected.

### 4.3 Cutover (high-impact — gated)
Only inside the agreed change window (R7/GR-5):
1. Run the **final delta**.
2. Switch the pilot users to the target per the routing/communication plan (mail routing is the
   high-impact change — coordinate DNS/routing under change control, GR-3).

**Rollback (cutover):** if validation (Phase 5) fails, revert mail routing to the source under the
same change window, keep users on the source, and treat the migrated target content as staging until
re-validated. Because routing is reversible and the source data is preserved through cutover, the
wave can be re-run.

**Gate D (Pilot passes → enter Validate/Expand):** pre-stage + delta + cutover completed for the
pilot wave; error rate within threshold; throttling stable (no sustained source/target throttling).

---

## Phase 5 — Validate

Validate the pilot against the baseline before scaling. Run the post-migration validation report:

```
python post-migration-validation.py \
    --wave "Migration Wave - Finance - Pilot" \
    --baseline baseline-source.json --out validate-pilot/
```

It compares **target item counts vs. source baseline**, checks **ownership/permission fidelity**
(sharing preserved via `Bridge – Identity – Corp`), and, for mail, checks **message-count parity and
basic mail-flow**. See `05-testing.md` for the pass/fail criteria of each gate.

**Gate E (enter Expand):** item-count parity within threshold; permissions/ownership preserved; mail
count + flow pass. Any gate failure → do not expand; fix and re-validate.

---

## Phase 6 — Expand

Only after the pilot passes Gate E:
1. Tune **node count** and the **throttling plan** using the pilot's measured throughput
   (`wave-batch-builder.py --calibrate --from validate-pilot/`).
2. Schedule production waves (`Migration Wave – Sales – Prod`, etc.) in dependency order, each with
   the same pre-stage → delta → cutover sequence, gates, and rollback.
3. Validate **every** production wave with `post-migration-validation.py` before closing it; keep
   `migration-health-check.py --watch` running through each wave to catch throttling early.
4. Decommission node infrastructure and revoke the migration service identities (R7) only after the
   final wave is validated and closed.
