# Requirements

These are the **solution-specific** prerequisites for designing and configuring Google Meet and
Google Chat. They build on the shared **Global Requirements — Google Workspace & Gemini Solutions**
(`global-requirements-google.md`): a provisioned Workspace/Cloud Identity tenant with a super-admin
and appropriate edition (#1), a defined identity source of truth and provisioning (#4), a **pilot
OU/group and change control** (#5), and engagement with **security/legal/data-governance
stakeholders** (#6). Verify those first; the items below are what *this* solution additionally needs.
(Requirements #2 M365/Entra and #3 DNS from the global set do not apply here — this is steady-state
Meet/Chat configuration, not a migration or mail-flow change.)

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing.**

---

## 1. Workspace edition that includes the required Meet, Chat, and Vault controls

- **Description:** A Workspace edition whose feature set includes the Meet safety/host controls,
  recording/transcription, Chat history and space-management controls, and **Google Vault** retention/
  holds that the design relies on (generally a Business Plus / Enterprise Standard-or-Plus /
  Education Plus tier — *verify the exact matrix for your edition*).
- **Why required:** Recording, transcription, advanced host management, and Vault retention/holds are
  not present in every edition. Designing a control the edition cannot enforce fails validation.
- **How to verify:** In the Admin console, **Billing → Subscriptions**, confirm the edition and seat
  counts; cross-check that **Google Vault** appears under **Apps** and that Meet **recording** and
  **Chat history** controls are visible under each app's settings.
- **How to implement if missing:** Upgrade the edition or add the required add-on through Google or an
  authorized reseller before configuring the dependent controls; until then, scope the design to the
  controls the edition supports and flag the rest.

## 2. OU and configuration-group structure for policy targeting

- **Description:** An organizational-unit tree plus a small set of **configuration groups** that model
  how Meet/Chat policy should differ across the organization — at minimum a **Pilot OU**, an
  all-staff baseline, and groups for special cases (e.g. `External Collaboration – Partners` for users
  allowed external chat/Meet, `Meet Recorders – Approved` for who may record).
- **Why required:** Meet settings apply by OU; Chat supports OU **and** configuration-group targeting.
  Without the right scopes you cannot apply a permissive external policy to a partner-facing team
  while keeping the rest of the organization locked down.
- **How to verify:** In **Directory → Organizational units**, confirm the OU tree; in **Directory →
  Groups**, confirm the configuration groups exist and membership is accurate.
- **How to implement if missing:** Create the Pilot OU/group (global requirement #5) and the special-
  case groups; agree membership ownership with the business before applying policy.

## 3. A governed Shared Drive for recordings, transcripts, and meeting notes

- **Description:** A dedicated **Shared Drive** — named `Recording Storage – Meet Recordings Shared
  Drive – Configure` — with defined membership, access levels, and sharing restrictions, to receive
  Meet recordings, transcripts, and Gemini meeting notes.
- **Why required:** By default recordings save to the organizer's My Drive, scattering sensitive
  artifacts with inconsistent access and no central retention. A governed Shared Drive gives one
  controlled location where access and Vault/Drive retention apply uniformly.
- **How to verify:** In **Apps → Google Drive and Docs → Manage Shared Drives**, confirm the Shared
  Drive exists with the intended members and sharing settings.
- **How to implement if missing:** Create the Shared Drive, set membership (managers/legal/records as
  content managers, meeting owners as contributors as policy dictates), restrict external sharing, and
  record its ID for use in the recording-storage configuration and the Python tools.

## 4. Documented retention and eDiscovery policy for Meet and Chat data

- **Description:** A written **retention schedule** and **legal-hold process** owned by legal/records
  governance that states how long Chat messages and Meet recordings/transcripts must be kept, per
  space type or OU, and how holds are placed.
- **Why required:** Chat history and Vault retention are governance decisions, not technical defaults;
  turning history off where the record must be kept, or retaining forever where policy says delete,
  both create risk.
- **How to verify:** Obtain the retention schedule and confirm the named approver (ties to global
  requirement #6).
- **How to implement if missing:** Work with legal/records to define retention periods per data type
  and the hold procedure before configuring Vault rules (`Vault Retention – Chat 3yr – Enforce` and
  peers are placeholders until the real periods are agreed).

## 5. External-collaboration policy decision (Meet join & external Chat)

- **Description:** A business decision, approved by security, on **whether external participants may
  join Meet**, **whether external (cross-organization) Chat is allowed**, and if so, to **which
  domains** — captured as an allowlist for `Chat External Policy – Allowlisted Domains – Enforce`.
- **Why required:** External access is the highest-risk collaboration setting. The design must apply a
  deliberate, approved posture (open to named domains vs. blocked) rather than the permissive default.
- **How to verify:** Confirm a signed-off external-collaboration statement and the domain allowlist.
- **How to implement if missing:** Facilitate the decision with security/business owners; default to
  the restrictive posture (external blocked, warning banners on) until an allowlist is approved.

## 6. Chat apps/bots inventory and an approved allowlist

- **Description:** An inventory of Chat apps/bots currently in use and an **approved allowlist** of
  which third-party apps may be installed — `Chat App Allowlist – Approved Bots – Enforce`.
- **Why required:** Unrestricted app installation lets any user add a third-party bot with access to
  space content; governance requires an allowlist and a request path for new apps.
- **How to verify:** Use the assessment tool / Admin console to list installed Chat apps; confirm
  security has reviewed and approved the allowlist.
- **How to implement if missing:** Produce the inventory (assessment tool below), have security
  approve the allowlist, and define how users request additions before enforcing app restrictions.

## 7. API access for the automation tools (least-privilege service identity)

- **Description:** A way to run the Python tools against the Admin SDK and Reports API — either an
  admin running with **OAuth** and read-only admin scopes, or a **service account with domain-wide
  delegation** limited to the read-only Directory/Reports scopes the tools declare, plus (only where a
  tool applies a change) the specific write scope, gated behind `--apply`.
- **Why required:** The assessment, validation, health, and reporting tools call
  `admin.googleapis.com` (Directory + Reports). Least-privilege credentials keep the automation safe
  and auditable; no keys are embedded in code.
- **How to verify:** Confirm the OAuth client or service account exists, the required scopes are
  authorized in **Security → API controls → Domain-wide delegation** (for a service account), and a
  read-only run of the assessment tool succeeds.
- **How to implement if missing:** Create the OAuth client / service account, authorize **only** the
  read-only scopes for assessment/validation, and add a write scope only for the configuration helper
  under change control. Store credentials via ADC / a secured secret store — never in the repo.
