# Testing & Validation

Run these after configuring the **Pilot OU/group** (Phase 4) and again for each scope during
**Expand** (Phase 5). Each test states the procedure and an explicit **pass/fail** expectation. The
validator and health-check tools automate the settings-level checks; the manual tests confirm the
lived behavior the API cannot see.

Reference artifacts from Implementation are reused by name below.

---

## Test 1 — Meet safety & host controls enforce (`Meet Safety Policy – Pilot OU – Configure`)

- **Procedure:** As a pilot user, start a Meet meeting. Confirm **host management** is on (host sees
  moderation controls: mute all, remove participant, present locks). Have a second internal user
  join and confirm the host can moderate.
- **Pass:** Host controls are present and functional; join behavior matches the configured "who can
  join" value.
- **Fail:** Host controls absent, or anyone can join/take over → re-check the OU override in **Meet →
  Safety settings**; ensure the OU shows the value, not "Inherited".

## Test 2 — External Meet access is scoped (`Meet External Access – Partners Group – Scoped`)

- **Procedure:** As a **general-population** user, attempt to admit an external participant. Then as a
  **`Meet External Access – Partners Group – Scoped`** member, do the same.
- **Pass:** General user is blocked (or warned per posture); partner-group user can admit external, and
  the **external-participant warning banner** shows in both cases.
- **Fail:** General user can freely admit external, or partner user is blocked → re-check the OU/group
  scoping of the external-access setting.

## Test 3 — Recordings land in the governed Shared Drive (`Recording Storage – Meet Recordings Shared Drive – Configure`)

- **Procedure:** As a `Meet Recorders – Approved` member, record a short pilot meeting. After it
  finishes, locate the recording and transcript.
- **Pass:** Recording, transcript (and Gemini notes where enabled — *verify in your tenant*) appear in
  the **Recording Storage Shared Drive**, not in the organizer's My Drive; a non-approved user cannot
  record.
- **Fail:** Artifact lands in My Drive, or a non-approved user can record → re-check recording enablement
  scope and the storage-location enforcement (operational or console).

## Test 4 — Chat external policy matches the allowlist (`Chat External Policy – Allowlisted Domains – Enforce`)

- **Procedure:** As a general user, try to start an external chat with (a) an **allowlisted** domain and
  (b) a **non-allowlisted** domain. Repeat as an `External Collaboration – Partners` member.
- **Pass:** External chat succeeds only to allowlisted domains for permitted users; non-allowlisted and
  non-permitted attempts are blocked. `external_retention_policy_validator.py` reports the external
  posture matching `design.json`.
- **Fail:** External chat works to a non-allowlisted domain, or fails to an allowlisted one → re-check
  external chat setting and the domain allowlist for the OU/group.

## Test 5 — File sharing in Chat follows policy

- **Procedure:** Share a file in an internal space and in an external space.
- **Pass:** Sharing behaves per the configured Chat file-sharing policy (e.g. internal allowed, external
  restricted).
- **Fail:** File sharing is more permissive than designed → re-check the Chat file-sharing setting.

## Test 6 — Chat history & Vault retention apply (`Chat History – Default On – Enforce`, `Vault Retention – Chat 3yr – Enforce`)

- **Procedure:** Confirm the history default in a new space matches policy. In **Google Vault →
  Retention → Google Chat**, confirm the rule exists, is scoped correctly, and (in a controlled test)
  that a message is retained/discoverable per the period.
- **Pass:** History default matches policy; the Vault Chat retention rule is present, correctly scoped,
  and messages are discoverable in Vault. `meet_chat_policy_health_check.py` flags no history/retention
  gap for the scope.
- **Fail:** History off where it should be on (or vice-versa), or no retention rule → re-apply in
  **Chat → Chat history** and Vault; do not expand until retention is confirmed.

## Test 7 — Spaces taxonomy & creation scope (`Chat Spaces Taxonomy – Enterprise – Design`)

- **Procedure:** Attempt to create spaces as permitted and non-permitted users; check that new spaces
  follow the naming convention and have owners.
- **Pass:** Space creation is limited to permitted users; new spaces conform to naming/ownership.
- **Fail:** Anyone can create spaces or naming is unenforced → re-check space-creation scope and reinforce
  the taxonomy convention.

## Test 8 — App/bot allowlist enforces (`Chat App Allowlist – Approved Bots – Enforce`)

- **Procedure:** As a pilot user, attempt to install an **approved** Chat app and a **non-approved** one.
- **Pass:** Only approved apps install; non-approved apps are blocked. The assessment/health tool lists
  installed apps matching the allowlist.
- **Fail:** A non-approved app installs → re-check Chat apps setting is restricted/allowlist-only for the
  OU.

## Test 9 — Automated settings & health validation

- **Procedure:** Run:
  ```
  python external_retention_policy_validator.py --domain your-domain.com --config design.json --out validation.json
  python meet_chat_policy_health_check.py --domain your-domain.com --out health.json
  ```
- **Pass:** The validator reports **no drift** between `design.json` and the live settings it can read
  (external posture, retention presence, recording-storage config where exposed); the health check
  reports no high-severity findings for the scope.
- **Fail:** Any drift or high-severity finding → remediate the specific control and re-run before
  expanding.

---

### Overall gate

The scope **passes** only when Tests 1–9 pass for that OU/group. Record results in `Meet+Chat
Validation – Pilot – Validate`. Any failing test blocks expansion to the next wave.
