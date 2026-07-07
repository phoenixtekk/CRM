# 3. Implementation Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Follow these steps **in order**. The Entra side and the Intune side are documented click-by-click;
the Apple Business Manager side names the action and defers the exact ABM menu paths to Apple's
official documentation (they change over time).

Consoles used:
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com` (menu paths deferred to Apple docs)

> **Model:** Federate ABM with Entra, turn on Managed Apple ID provisioning **scoped to a pilot
> group**, resolve existing-Apple-ID conflicts, then stand up COD / BYOD / Shared enrollment, validate
> on the pilot, and expand. **Assess → Configure → Pilot → Validate → Expand.**

> **Artifact names (use verbatim):** provisioning app `Apple Business Manager – Federation – Prod`;
> provisioning job `ABM SCIM Provisioning – Corp – Prod`; provisioning pilot group
> `Managed Apple ID Provisioning – Pilot – Stage`; provisioning prod group
> `Managed Apple ID Provisioning – Corp – Prod`; per-scenario groups `iOS COD – Devices – Pilot`,
> `iOS BYOD – Users – Pilot`, `iOS Shared – Devices – Pilot`; ADE profiles `iOS COD – ADE – Pilot`,
> `iOS Shared – ADE – Pilot`.

> **Risk + rollback (read first):** Federating a domain changes Apple sign-in for **everyone** whose
> email is in that domain. Always **scope provisioning to the pilot group first** and resolve
> conflicts before widening. **Rollback:** set the provisioning job to **Off** and remove the pilot
> group's assignment to stop creating Managed Apple IDs; the federation link itself is removed on the
> ABM side (deferred to Apple docs) only if you must fully revert — coordinate this, as it affects
> sign-in.

---

## Phase 1 — Scope groups and the provisioning application

### Step 1 — Create the scope groups
1. Entra → **Groups → New group → Security** → `Managed Apple ID Provisioning – Pilot – Stage` (a few
   representative users). **Create**.
2. Repeat for `Managed Apple ID Provisioning – Corp – Prod` (the full population, used later at expand).
3. Create the per-scenario groups: `iOS COD – Devices – Pilot`, `iOS BYOD – Users – Pilot`, and
   `iOS Shared – Devices – Pilot`. **Create** each.

> Prefer automation? Run **`ABMPROV-Set-ScopeTargeting.ps1`** to create all of these groups in one pass
> (default `-WhatIf`; add `-Apply`).

### Step 2 — Add the Apple Business Manager provisioning application (Entra)
1. Entra → **Identity → Applications → Enterprise applications → New application**.
2. Search the gallery for **Apple Business Manager**, select it, and add it. **Name it**
   `Apple Business Manager – Federation – Prod`. **Create**.
3. Open `Apple Business Manager – Federation – Prod` → **Users and groups → Add user/group** → add
   `Managed Apple ID Provisioning – Pilot – Stage` only (pilot scope). **Assign**.

---

## Phase 2 — Federate ABM with Entra ID

### Step 3 — Link Apple Business Manager to Entra ID (federated authentication)
1. In **ABM**, open the identity / federation settings and **add Microsoft Entra ID as the identity
   provider**, then **federate your verified domain** (the exact ABM screen/menu is deferred to Apple's
   official documentation).
2. Complete the trust between ABM and Entra: when ABM prompts, **sign in / consent with an Entra
   administrator** so Apple can redirect sign-ins for that domain to Entra ID.
3. The value that links the two sides is your **verified domain** (Requirement 2.3) — confirm it is the
   domain you intend to federate before saving. After this, users in that domain authenticate to Apple
   services via Entra.

> Federation now covers the **whole domain** for Apple sign-in. Provisioning, however, is still scoped
> to the pilot group from Step 2 — keep it that way until conflicts are resolved (Step 4) and the pilot
> passes.

### Step 4 — Detect and resolve existing-Apple-ID conflicts (do this before widening)
1. In **ABM**, open the **domain capture / Managed Apple ID conflict** report for the federated domain
   (the exact ABM location is deferred to Apple docs). It lists personal Apple IDs that use an email in
   your domain.
2. For each conflicted user, Apple provides a process to have the user **change their personal Apple ID
   to a different (personal) email**, freeing the work-email identity for a Managed Apple ID. Notify
   those users with a deadline (the change window).
3. Re-open the conflict report and confirm it is **clear for the pilot users** before turning on
   provisioning. Do not expand beyond the pilot while conflicts remain for in-scope users.

---

## Phase 3 — Automatic Managed Apple ID provisioning

### Step 5 — Configure SCIM provisioning of Managed Apple IDs (Entra side, pilot-scoped)
1. Entra → **Identity → Applications → Enterprise applications → open**
   `Apple Business Manager – Federation – Prod` **→ Provisioning → Get started**.
2. Set **Provisioning Mode** to **Automatic**.
3. Under **Admin Credentials**, authorize Entra to ABM as the connector requires (for the Apple
   Business Manager gallery app this is an OAuth authorization to ABM; complete the ABM-side
   authorization prompt — deferred to Apple docs for the exact ABM screen). **Test Connection**; when
   it succeeds, treat this provisioning configuration as `ABM SCIM Provisioning – Corp – Prod`.
4. Under **Mappings**, confirm the user attribute mappings ABM expects — at minimum a stable user
   identifier and the attributes that form the **Managed Apple ID** (the verified-domain email / UPN).
5. Under **Settings**, set **Scope** to **Sync only assigned users and groups**, then **Save**. (Only
   `Managed Apple ID Provisioning – Pilot – Stage` is assigned, so only the pilot provisions.)

### Step 6 — Start provisioning to the pilot scope
1. On the **Provisioning** page, set **Provisioning Status** to **On**.
2. Provisioning runs on a recurring cycle; the first cycle creates Managed Apple IDs in ABM for the
   members of `Managed Apple ID Provisioning – Pilot – Stage`. Monitor **Provisioning logs** for
   success and address any per-user errors (often a remaining conflict from Step 4).
3. Run **`ABMPROV-Discovery.ps1`** (provisioning job status) and **`ABMPROV-Validation.ps1`**
   (per-user Managed Apple ID provisioned/federated) for the pilot users.

> **Just-in-time backfill:** with federation in place, a scoped user without a Managed Apple ID can
> have one created on **first federated sign-in** to an Apple service. Use SCIM as the primary path and
> JIT as the safety net so no pilot user is blocked waiting for a cycle.

---

## Phase 4 — Intune Apple connection (shared by all enrollment models)

### Step 7 — Create the Apple MDM Push (APNs) certificate
1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, **Download** the CSR.
3. **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a **company Apple
   ID** (record it — reuse it every year).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`; back in Intune enter the **Apple
   ID**, **Browse** to the `.pem`, **Upload**. Confirm status **Active** (~1 year out).

### Step 8 — Connect Apple Business Manager to Intune (ADE token — for Corporate-Owned)
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check **I agree** →
   **Download** the Intune **public key** (`.pem`).
2. In **ABM**, add an **MDM server** and **upload the Intune public key**, then **download the server
   token** (`.p7m`) (exact ABM menu deferred to Apple docs). Name the MDM server `Intune – iOS COD`.
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**. The token
   appears under **Enrollment program tokens**.

---

## Phase 5 — Stand up the three enrollment models

### Step 9 — Corporate-Owned (COD): ADE enrollment profile (supervised, account-driven)
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens →** open the token from Step 8
   **→ Profiles → Create profile → iOS/iPadOS**. **Name it** `iOS COD – ADE – Pilot`; add a description.
2. **User affinity** = **Enroll with user affinity**, and select **account-driven** enrollment so the
   user signs in with their **Entra identity / Managed Apple ID** during Setup Assistant.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes**.
4. **Setup Assistant:** hide non-essential panes for a clean first-run.
5. **Review + Create.**
6. Assign devices: in **ABM**, assign the company-owned iPhone serials to the **`Intune – iOS COD`**
   MDM server (deferred to Apple docs); in Intune, on the token → **Devices**, **Sync** (Apple
   rate-limits — allow a few minutes), select the serials → **Assign profile** → `iOS COD – ADE – Pilot`.

### Step 10 — BYOD: account-driven User Enrollment
1. Intune → **Devices → Enrollment → Enrollment types** (Apple) → **Create** a profile for
   **User Enrollment**; **name it** `iOS BYOD – User Enrollment – Pilot`.
2. Set the enrollment type to **account-driven User Enrollment** (the modern, privacy-preserving model
   that uses the **Managed Apple ID + Entra federated sign-in**).
3. **Assignments:** assign to **`iOS BYOD – Users – Pilot`** (users, not devices — BYOD is user-scoped).
   **Create.**

> No ADE token is needed for BYOD; the user starts enrollment from the device's settings and
> authenticates with their federated Managed Apple ID, which creates the managed work partition.

### Step 11 — Shared: no-user-affinity enrollment
1. On the ADE token, **Profiles → Create profile → iOS/iPadOS**; **name it** `iOS Shared – ADE – Pilot`.
2. **User affinity** = **Enroll without user affinity** (this is what makes the device shared — no
   primary user). Enable **Supervised**; **Locked enrollment = Yes**.
3. **Setup Assistant:** hide non-essential panes. **Review + Create.**
4. In **ABM**, assign the shared iPhone serials to the `Intune – iOS COD` MDM server (or a dedicated
   server entry) (deferred to Apple docs); in Intune, on the token → **Devices → Sync**, select the
   serials → **Assign profile** → `iOS Shared – ADE – Pilot`.
5. Staff identity on shared phones lives in the **Managed Apple ID / shared app sign-in**, not bound to
   a primary user. (iPhones have no Apple "Shared iPad" — see Overview.)

> **Shared device group targeting — make `iOS Shared – Devices – Pilot` an Assigned group owned by the
> Intune Provisioning Client (enrollment-time grouping).** For deterministic shared-device enrollment,
> keep `iOS Shared – Devices – Pilot` (created in Step 1) an **Assigned** security group and add the
> **Intune Provisioning Client** first-party service principal — **AppId
> `f1346770-5b25-470b-88bd-d5744ab7952c`**, in many tenants displayed as **`Intune Autopilot
> ConfidentialClient`** — as an **Owner** of the group. In Entra: **Groups → `iOS Shared – Devices –
> Pilot` → Owners → Add owners**, and search by that **AppId** (match by AppId, **not** the display
> name, which varies by tenant). Enrollment-time device grouping works by this principal *owning* the
> Assigned group — without the owner the group stays **empty at enrollment** and **none of the
> shared-device profiles (e.g. `iOS Shared – Compliance – Pilot`) or apps deploy**. The group must be
> **Assigned**, never Dynamic, for this mechanism. This is the same first-party principal and mechanism
> Windows Autopilot device preparation uses. **Verify the owner is present before each pilot.** *(If the
> principal isn't present in the tenant, open the Intune portal once as Global Administrator to
> provision it, then add it as owner.)*

### Step 12 — Compliance policies per model
1. Intune → **Devices → Compliance → Create policy → iOS/iPadOS**; create one each:
   `iOS COD – Compliance – Pilot`, `iOS BYOD – Compliance – Pilot`, `iOS Shared – Compliance – Pilot`.
2. Set rules appropriate to each model (e.g. min iOS version; jailbreak detection; a passcode rule for
   COD/BYOD; relaxed/no passcode for hand-off-speed shared phones).
3. **Assignments:** `iOS COD – Compliance – Pilot` → `iOS COD – Devices – Pilot`;
   `iOS BYOD – Compliance – Pilot` → `iOS BYOD – Users – Pilot`;
   `iOS Shared – Compliance – Pilot` → `iOS Shared – Devices – Pilot`. **Create** each.

---

## Phase 6 — Pilot, validate, expand

### Step 13 — Pilot-enroll one device per model
1. **COD:** erase a pilot company iPhone (**Settings → General → Transfer or Reset → Erase All Content
   and Settings**), power on, and complete **Remote Management** — it enrolls supervised, account-driven,
   and the user signs in with their federated Managed Apple ID.
2. **BYOD:** on a personal iPhone, start **account-driven User Enrollment** from device settings and
   sign in with the federated Managed Apple ID — a managed work partition is created.
3. **Shared:** erase a pilot shared iPhone and enroll via ADE with `iOS Shared – ADE – Pilot` — it
   enrolls **no user affinity**; staff sign in to the relevant app/service with the Managed Apple ID.

### Step 14 — Validate the pilot
1. Run **`ABMPROV-Discovery.ps1`** (federation + provisioning job + ADE token + APNs readiness).
2. Run **`ABMPROV-Validation.ps1`** (per-user Managed Apple ID provisioned/federated; per-device correct
   enrollment model).
3. Run **`ABMPROV-Report.ps1`** (provisioning coverage + COD/BYOD/Shared breakdown). Complete the
   **Testing Guide** pilot gate before expanding.

### Step 15 — Expand to production
1. **Provisioning:** Entra → `Apple Business Manager – Federation – Prod` → **Users and groups** → add
   `Managed Apple ID Provisioning – Corp – Prod`; the next cycle provisions the full population. Confirm
   conflicts are clear org-wide first.
2. **COD / Shared:** add remaining serials to the ADE token and assign the `… – ADE – Pilot` profiles
   (or make them the **default** profile for the token); add devices to the per-scenario groups.
3. **BYOD:** extend `iOS BYOD – User Enrollment – Pilot` to the broader BYOD user population.
4. Re-run **`ABMPROV-Report.ps1`** and roll out in waves, validating each wave before widening.

---
### Order of operations
`Scope groups → ABM provisioning app (Entra) → federate ABM↔Entra → resolve conflicts → SCIM
provisioning (pilot) → APNs → ADE token → COD ADE / BYOD User Enrollment / Shared no-affinity →
compliance → pilot-enroll → validate → expand`
