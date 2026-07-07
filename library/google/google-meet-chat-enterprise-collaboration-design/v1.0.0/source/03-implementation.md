# Implementation

Follow the house model **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first.
Configure everything against the **Pilot OU/group** first, validate against the gates, then expand OU
by OU. Every artifact is **named** on first creation and the exact name is reused later. Admin-console
labels are current-at-authoring — **verify in your tenant**, as edition and UI wording change.

> **High-impact changes** (external access, Chat history/retention, recording storage) are staged
> under change control. Each phase below states its **pass/fail gate** and a **rollback**.

---

## Phase 0 — Assess (read-only)

1. Sign in to **admin.google.com** as super-admin.
2. Run the assessment tool to capture the current state into a baseline report:
   ```
   python meet_chat_settings_assessment.py --domain your-domain.com --out baseline.json
   ```
   This records Meet and Chat settings visible via the Admin SDK, the OU/group structure, and
   installed Chat apps. Name the artifact `Meet+Chat Baseline – Enterprise – Assess`.
3. Run the usage/adoption report (Reports API, read-only) to size current Meet/Chat activity and
   external exposure:
   ```
   python meet_chat_usage_report.py --domain your-domain.com --days 30 --out usage.csv
   ```
4. In the Admin console, manually confirm settings the API does not expose (some safety and space-
   management toggles are UI-only). Record them in the baseline.

**Gate 0 (pass/fail):** PASS when the baseline documents current Meet safety, recording location,
external Meet/Chat posture, spaces creation scope, history/retention, and installed apps for the whole
tenant. FAIL if any of these is unknown — do not configure blind.

---

## Phase 1 — Design

Decide the target policy and record it in a design register (the design doc + the config helper's
input file). For each control, choose the **narrowest scope** that satisfies policy:

- **Meet safety/host:** host management on; who can join (organization-only vs. allow external);
  quick access; moderation defaults. Artifacts: `Meet Safety Policy – Pilot OU – Configure`,
  `Meet Host Management – All Staff – Enforce`.
- **Recording/transcription storage:** who may record (`Meet Recorders – Approved` group); recordings/
  transcripts/notes to `Recording Storage – Meet Recordings Shared Drive – Configure`.
- **External Meet:** `Meet External Access – Partners Group – Scoped` (allowed for the partner group,
  blocked elsewhere); external-participant warning on.
- **Chat spaces taxonomy:** `Chat Spaces Taxonomy – Enterprise – Design` — space types, naming
  convention `<type>-<owner>-<purpose>`, ownership, and who can create spaces.
- **External/file Chat policy:** `Chat External Policy – Allowlisted Domains – Enforce`; file-sharing
  in Chat controlled per policy.
- **History/retention:** `Chat History – Default On – Enforce`; `Vault Retention – Chat 3yr – Enforce`
  (use real periods from Requirement #4); Meet-artifact retention via Drive/Vault rules on the Shared
  Drive.
- **App/bot governance:** `Chat App Allowlist – Approved Bots – Enforce`.

**Gate 1:** PASS when every control has a named target value, a scope (OU or group), and an approver
where governance requires one (external policy, retention, recording storage). FAIL if any control is
undecided.

---

## Phase 2 — Configure (Pilot OU/group first)

### 2a. Meet safety & host controls

1. **Apps → Google Workspace → Google Meet → Safety settings.** Scope the console to the **Pilot OU**.
2. Set **Host management** default **on** so hosts control moderation — artifact `Meet Host Management
   – All Staff – Enforce`.
3. Set **Who can join meetings created by your organization** and **Warn for external participants** to
   the designed values; enable moderation defaults (mute, present locks). This is `Meet Safety Policy –
   Pilot OU – Configure`.
4. Save; confirm the OU shows the overridden values (not "Inherited").

### 2b. Recording / transcription storage

1. Ensure the Shared Drive `Recording Storage – Meet Recordings Shared Drive – Configure` exists with
   restricted external sharing (Requirement #3).
2. **Google Meet → Meet video settings → Recording.** Enable recording only for the **Pilot OU** and
   restrict who can record to the `Meet Recorders – Approved` group.
3. Configure recordings/transcripts (and Gemini notes where the edition provides them — *verify in your
   tenant*) to save to the governed Shared Drive per the current Admin-console option for recording
   storage location. Where the console does not expose a storage-location control, enforce it
   operationally (organizers record into the Shared Drive) and validate location in Phase 4.

### 2c. External participant rules (Meet)

1. For the general population OU, set **Meet external access** to the restrictive posture (organization
   participants only or external with warning), per the approved decision (Requirement #5).
2. For the `Meet External Access – Partners Group – Scoped` group (via a group override or a partner
   OU), allow external join. Keep the external-participant **warning banner** on everywhere.

### 2d. Chat spaces architecture & creation scope

1. **Apps → Google Workspace → Google Chat → Space creation.** Scope to the Pilot OU.
2. Apply `Chat Spaces Taxonomy – Enterprise – Design`: publish the naming convention and, if the
   edition supports it, restrict who can create spaces / restrict space types per policy.
3. Assign owners for baseline spaces; document ownership in the taxonomy register.

### 2e. External chat & file-sharing policy

1. **Google Chat → External chat settings.** For the general OU, set external chat to **blocked** or
   **allowlisted-domains-only** per the approved posture.
2. Add the approved domains to `Chat External Policy – Allowlisted Domains – Enforce`.
3. Grant permissive external chat to the `External Collaboration – Partners` configuration group where
   the business needs it. Configure **file sharing in Chat** to the designed value.

### 2f. History & retention

1. **Google Chat → Chat history.** Set the default per policy — `Chat History – Default On – Enforce`
   (or off where policy requires), and whether users can change it per space.
2. In **Google Vault → Retention → Google Chat**, create the retention rule `Vault Retention – Chat 3yr
   – Enforce` (use the real period from Requirement #4), scoped to the Pilot OU first.
3. Apply Meet-artifact retention to the Shared Drive (Vault Drive rule / Drive retention) so recordings/
   transcripts follow the schedule.

### 2g. App & bot governance

1. **Google Chat → Chat apps settings.** Set third-party app installation to **restricted /
   allowlist-only** and populate `Chat App Allowlist – Approved Bots – Enforce` with the approved apps
   (Requirement #6).
2. Define the request path for adding a new app to the allowlist.

**Rollback (Phase 2):** each setting is reversible in the same console page. Before changing external
access, history, retention, or recording storage, record the prior value from `Meet+Chat Baseline –
Enterprise – Assess`; to roll back, restore the OU/group setting to that value (for Chat history,
re-enable/disable to match baseline; for Vault, disable or delete the retention rule — **note that
retention already applied may not be reversible**, so pilot on a non-production OU).

---

## Phase 3 — Pilot

1. Add a representative set of users to the **Pilot OU** and the special-case groups (`Meet Recorders –
   Approved`, `External Collaboration – Partners`).
2. Have them run real Meet meetings (internal + one external) and use Chat spaces (internal + one
   allowlisted-external), record a meeting, and share a file in Chat.
3. Collect their experience and any blocked-but-should-be-allowed cases.

**Gate 3:** PASS when pilot users can do their legitimate collaboration and the intended controls
visibly enforce (host controls present, external warning shown, recording lands in the Shared Drive,
external chat only to allowlisted domains). FAIL → adjust the design and re-configure before expanding.

---

## Phase 4 — Validate

Run the validation tools and the procedures in **05-testing.md**:
```
python external_retention_policy_validator.py --domain your-domain.com --config design.json --out validation.json
python meet_chat_policy_health_check.py --domain your-domain.com --out health.json
```
Confirm each gate in the testing guide (controls enforced by OU/group, external scoped to allowlist,
recordings in the Shared Drive, retention applied). Name the artifact `Meet+Chat Validation – Pilot –
Validate`.

**Gate 4:** PASS only when every test passes for the Pilot OU/group. Any FAIL blocks expansion.

---

## Phase 5 — Expand

1. Roll the validated policy outward one OU (or wave of OUs) at a time using
   `meet_chat_settings_config_helper.py` in `--dry-run` first, then `--apply` under change control:
   ```
   python meet_chat_settings_config_helper.py --config design.json --scope ou:/Sales --dry-run
   python meet_chat_settings_config_helper.py --config design.json --scope ou:/Sales --apply
   ```
2. Re-run the validator and health check for each expanded scope.
3. Keep the rollback (baseline values) ready for each wave; expand only after the prior wave passes.

**Gate 5 (exit):** PASS when all in-scope OUs/groups enforce the design, every wave validated, and the
baseline/rollback is documented. The engagement is complete when Meet and Chat are configured for
productive, governed collaboration across the enterprise.
