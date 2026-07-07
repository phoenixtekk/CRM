# Requirements

These are the **solution-specific** prerequisites for the adoption, change-management, and training
program. They build **on top of** the shared category requirements in
`global-requirements-google.md` (Workspace/Cloud Identity tenant with a super-admin, the source
M365/Entra environment, DNS control, an identity source of truth, a pilot OU/group with change
control, and engaged security/compliance stakeholders) — those are assumed in place and are **not**
repeated here. Verify each item below before starting the implementation steps.

---

## 1. An approved migration / rollout plan with a wave schedule

- **Description:** A documented migration plan that defines the **waves** (which OUs/groups/business
  units cut over from M365 to Google Workspace, in what order, on what dates) and the cutover method
  (big-bang per wave vs. coexistence). The adoption program aligns every OCM cycle to these waves.
- **Why required:** Awareness, training, and hypercare are all timed **relative to each cohort's
  cutover date**. Without a wave schedule there is nothing to align to and cohorts will land
  unprepared.
- **How to verify:** Obtain the current wave schedule (cohort → date → user count) from the migration
  program. Confirm it maps to real OUs/groups in the Google Admin console
  (**admin.google.com → Directory → Organizational units / Groups**).
- **How to implement if missing:** Work with the migration program to define waves and dates before
  building the OCM calendar; at minimum define `Adoption Pilot – Wave 0 – Pilot` and Wave 1.

## 2. Executive sponsorship and a change mandate

- **Description:** A named **executive sponsor** (or sponsor coalition) who will visibly back the
  change — fund the program, send "tone from the top" communications, and make training expectations
  clear.
- **Why required:** Adoption programs succeed or fail on visible leadership. Champions, mandatory-
  training expectations, and comms all draw authority from the sponsor.
- **How to verify:** Confirm a named sponsor has agreed in writing to the mandate and to send at least
  the launch and per-wave leadership messages.
- **How to implement if missing:** Escalate through the migration steering committee to secure a
  sponsor before launch; a program without one should not proceed to Expand.

## 3. Communication channels to reach every user

- **Description:** Working channels to reach all in-scope users **before and after** cutover — email
  (both the M365 source mailbox pre-cutover and the new Google mailbox post-cutover), intranet, digital
  signage, Chat/Spaces, and manager cascades.
- **Why required:** Awareness must reach users on whatever tool they still use. Pre-cutover comms must
  land in the **old** mailbox; post-cutover in the **new** one.
- **How to verify:** Confirm you can publish to each channel and that a distribution mechanism exists
  for the wave cohorts (e.g. dynamic groups per wave).
- **How to implement if missing:** Establish the channels and the per-wave distribution lists; create
  Google Groups per wave if needed (**Directory → Groups**).

## 4. Training delivery capacity and an LMS / completion source

- **Description:** The capacity to **deliver** role-based training (live virtual sessions, recorded
  micro-learning, quick-reference guides) and a **system of record for completion** — an LMS, or at
  minimum a tracked roster — so completion can gate go-live.
- **Why required:** Training completion is a **go-live gate**; you must be able to record and report
  who completed which `Learning Path – <Role> – v1`.
- **How to verify:** Confirm the LMS/roster exists and that completion can be exported (CSV/API) for
  the completion tracker tool.
- **How to implement if missing:** Stand up a completion roster (even a governed spreadsheet) and a
  content-hosting location before Wave 0.

## 5. Google Workspace admin roles for adoption **measurement** (read-only)

- **Description:** A least-privilege admin role (or delegated service account with domain-wide
  delegation) that can **read** the **Admin SDK Reports API** (Workspace usage/activity reports) and
  the **Directory API** — for adoption metrics only. **No write scopes are required by this program.**
- **Why required:** Adoption metrics are computed from Workspace usage reports; the program reads them
  and never writes user data.
- **How to verify:** In the Admin console (**Account → Admin roles**) confirm a role with the
  **Reports** privilege; test the Reports API returns data (see Testing). Reports data can lag ~1–3
  days and some metrics require the tenant's edition — **verify in your tenant**.
- **How to implement if missing:** Create a custom admin role limited to **Reports** (and Directory
  read) and assign it to the measurement account/service account; enable the **Admin SDK API** in the
  associated Google Cloud project. Never export or commit a service-account key — use Application
  Default Credentials (ADC).

## 6. A champion-network mandate (time allocation)

- **Description:** Agreement from business-unit leaders that nominated **champions** get **allocated
  time** (a defined % of their week during their wave) to be trained ahead, support peers, and floor-
  walk at cutover.
- **Why required:** Champions are the program's distributed workforce; without protected time the
  network is nominal and hypercare collapses onto central IT.
- **How to verify:** Confirm BU leaders have agreed a champion ratio and time allocation, and can
  nominate names for `Champion Cohort – <BU> – Wave N`.
- **How to implement if missing:** Negotiate the mandate through the sponsor before recruiting
  champions.

## 7. Gemini licensing clarity (per cohort)

- **Description:** A clear record of **which cohorts/waves are licensed for Gemini** (Gemini for
  Workspace / Gemini Enterprise add-on) and **which Gemini features are enabled** for them in the
  Admin console.
- **Why required:** The Gemini learning path is delivered **only** to licensed cohorts, and only for
  features that are actually turned on. Gemini feature availability is version- and rollout-dependent.
- **How to verify:** In **admin.google.com → Billing / Subscriptions** confirm the Gemini add-on and
  seat counts; in **Apps → Google Workspace → (Gemini/AI settings)** confirm which features are on for
  which OUs. **Verify in your tenant** — do not assume a feature is available.
- **How to implement if missing:** Confirm licensing with the migration/licensing owner; if a cohort
  is unlicensed, omit the Gemini path for that cohort (do not promise features they cannot use).
