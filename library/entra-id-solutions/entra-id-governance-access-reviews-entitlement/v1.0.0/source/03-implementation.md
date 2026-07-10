# 3. Implementation Guide — Entra ID Governance: Access Reviews & Entitlement Management

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`
→ **Identity governance**). Names in `code` are the exact objects to create — keep them consistent so
the scripts, testing, and troubleshooting all refer to the same objects. Portal blade names evolve; if a
label differs, match by intent and verify against current Microsoft guidance.

**Object naming convention:** `ENTIGA – <Purpose> – <Scope> – <Stage>`. The objects you will build:

| Object | Name |
|--------|------|
| Governance catalog | `ENTIGA – Catalog – Corp` |
| Access package | `ENTIGA – Package – LOBApp – Prod` |
| Assignment policy (employees) | `ENTIGA – Policy – Employees – Approval` |
| Assignment policy (guests) | `ENTIGA – Policy – Guests – TimeBound` |
| Access review (group) | `ENTIGA – Review – PrivGroup – Quarterly` |
| Access review (app) | `ENTIGA – Review – LOBApp – Quarterly` |
| Access review (guests) | `ENTIGA – Review – AllGuests – Quarterly` |
| Joiner workflow | `ENTIGA – Joiner – Onboarding` |
| Leaver workflow | `ENTIGA – Leaver – Offboarding` |
| Pilot group | `ENTIGA-Pilot` |

> **Model:** Assess → Configure → Pilot → Validate → Expand. Build each object, target **`ENTIGA-Pilot`
> first**, prove the gates in §5, then expand. Every production change has a rollback (see end of file).

## Step 1 — Assess and baseline the current state
1. Run **`ENTIGA-Discovery.ps1`** — inventories existing catalogs, access packages, policies, access
   review definitions, and lifecycle workflows so you know your starting posture (likely empty on a new
   tenant).
2. Run **`ENTIGA-GuestReview.ps1`** — lists current guest accounts with last sign-in, to size the guest
   governance problem.
3. Confirm the pilot group `ENTIGA-Pilot` exists (Entra → **Groups**) with test users and, ideally, one
   test **guest** account.

## Step 2 — Create the governance catalog
1. **Identity governance → Entitlement management → Catalogs → + New catalog**.
2. **Name:** `ENTIGA – Catalog – Corp`. **Description:** a short purpose line. **Enabled:** Yes.
   **Enabled for external users:** **Yes** (required so guests can request packages from this catalog).
   **Create**.
3. Open the catalog → **Resources → + Add resources** → add the resource(s) the pilot package will grant:
   - a **Group** (e.g. an app-access security group),
   - an **Application** (an enterprise app), and/or
   - a **SharePoint site**.
   Only resources added to the catalog can be bundled into its packages.

## Step 3 — Create the pilot access package
1. In `ENTIGA – Catalog – Corp` → **Access packages → + New access package**.
2. **Basics:** Name `ENTIGA – Package – LOBApp – Prod`; description of what access it grants.
3. **Resource roles:** add the role(s) users receive — e.g. **Member** of the group, a specific **app
   role**, and/or a **site** role from the catalog's resources.
4. Leave policy creation for the next step. **Create**.

## Step 4 — Add the employee assignment policy (request + approval + expiry)
1. Open `ENTIGA – Package – LOBApp – Prod` → **Policies → + Add policy**.
2. **Name:** `ENTIGA – Policy – Employees – Approval`.
3. **Users who can request:** **For users in your directory → Specific users and groups →** add
   **`ENTIGA-Pilot`** (pilot-first; you will add the broader audience at Expand).
4. **Approval:** **Require approval = Yes**; **Stage 1 approver = Manager** (or a named approver / the
   resource owner); require **justification**. (Add a second stage only if your process needs it.)
5. **Requestor information:** optionally add a question (e.g. business justification).
6. **Lifecycle:** set **Expiration → Access expires → After number of days** (e.g. **90**) so the grant is
   **time-bound**; enable **Require access reviews** on renewal if you want the package itself reviewed.
7. **Create.** This is the core "request → approve → time-bound grant → expire" loop.

## Step 5 — Add the guest (time-bound external) assignment policy
1. Same package → **Policies → + Add policy**.
2. **Name:** `ENTIGA – Policy – Guests – TimeBound`.
3. **Users who can request:** **For users not in your directory** → choose **Specific connected
   organizations** (from Requirement 2.7) or **All configured connected organizations**.
4. **Approval:** **Require approval = Yes**; approver = an **internal sponsor** (a named internal
   approver — external requestors must have an internal approver).
5. **Lifecycle:** set a **shorter expiry** for guests (e.g. **30 days**) so external access is strictly
   time-bound, and enable **Require access reviews** so continued guest access is re-certified.
6. **Create.** Guests now request via **My Access** and receive **time-bound** access only.

## Step 6 — Create the recurring access reviews
Create three reviews under **Identity governance → Access reviews → + New access review**.

**6a — Group membership review**
1. **Review type:** **Teams + Groups → Select Teams + groups →** pick a privileged/sensitive group.
2. **Scope:** All users (or Guest users only for a guest-focused group).
3. **Name:** `ENTIGA – Review – PrivGroup – Quarterly`. **Recurrence:** Quarterly.
4. **Reviewers:** **Group owner(s)** or **Manager of the user** (or named reviewers).
5. **Settings:** **Auto apply results = Enabled**; **If reviewers don't respond →** **Remove access**
   (or **No change** while piloting — see the note); enable **Justification required** and reviewer
   **recommendations**. **Create.**

**6b — Application assignment review**
1. **Review type:** **Applications → Select applications →** the enterprise app.
2. **Name:** `ENTIGA – Review – LOBApp – Quarterly`. Reviewers = app owner / manager. Same auto-apply
   settings. **Create.**

**6c — Guest access review**
1. **Review type:** review **guest users' access** — scope to **Guest users** across the target
   group(s)/app(s) or across the tenant per your standard.
2. **Name:** `ENTIGA – Review – AllGuests – Quarterly`. **Reviewers:** manager or the guest's **sponsor**;
   optionally enable **self-review** with manager fallback. **Auto apply = Enabled**; don't-respond →
   **Remove access**. **Create.**

> **Pilot safely:** for the **first** run set "if reviewers don't respond" to **No change** and review
> the decisions manually, so an unanswered review doesn't remove access before reviewers are trained.
> Switch to **Remove access** once the process is trusted.

## Step 7 — Create the lifecycle workflows (joiner / leaver)
Under **Identity governance → Lifecycle workflows → Workflows → + Create a workflow**.

**7a — Joiner (onboarding)**
1. **Choose a template:** **Onboard pre-hire employee** (or **New hire**). **Next.**
2. **Basics:** Name `ENTIGA – Joiner – Onboarding`.
3. **Execution conditions:** **Trigger = days relative to `employeeHireDate`** (e.g. **0 days** on hire);
   **Scope:** a rule that resolves to **`ENTIGA-Pilot`** members (e.g. filter on a pilot attribute) for
   the pilot.
4. **Tasks:** keep template tasks such as **Enable user account**, **Send welcome email**, **Add user to
   groups**, and (optionally) **Request access package assignment** for `ENTIGA – Package – LOBApp – Prod`.
5. **Review + create.** Leave it enabled but scoped to the pilot only.

**7b — Leaver (offboarding)**
1. **+ Create a workflow → Choose template: Real-time employee termination** (on-demand) or
   **Post-offboarding / Scheduled leaver** keyed to `employeeLeaveDateTime`.
2. **Name:** `ENTIGA – Leaver – Offboarding`. **Scope:** `ENTIGA-Pilot`.
3. **Tasks:** **Remove user from all groups**, **Remove user from all Teams**, **Remove all access
   package assignments**, **Disable user account**, **Revoke all refresh tokens (sessions)**.
4. **Review + create.** For the pilot, run this **on-demand** against a test leaver rather than waiting
   for a real termination.

> **Mover pattern:** a **mover** workflow uses the same builder with a trigger on **attribute change**
> (e.g. department/manager change) and tasks that **remove stale group memberships** and **request the
> new role's package**. Build it with the same convention (`ENTIGA – Mover – DeptChange`) once joiner and
> leaver are validated.

## Step 8 — Validate the pilot (the gates)
Run **`ENTIGA-Validate.ps1`** and confirm on `ENTIGA-Pilot`:
- **G1 Request/approve/expire** — a pilot user requests `ENTIGA – Package – LOBApp – Prod` in **My
  Access**, the approver approves, access is granted **and shows an expiry**.
- **G2 Review/remove** — a review lists members; a **Deny** decision with **auto-apply** actually
  **removes** the access.
- **G3 Guest time-bound** — a guest requests via the guest policy, is approved by the internal sponsor,
  and receives access with the **shorter expiry**.
- **G4 Lifecycle** — the joiner workflow runs its tasks; the leaver workflow (on-demand) **disables** the
  test account and **revokes** sessions.

**Pass** = all four gates green. **Fail** = fix before expanding (see §6).

## Step 9 — Expand to production in waves
1. In each assignment policy, **broaden the requestor scope** from `ENTIGA-Pilot` to the intended
   audience (specific groups or **All members**), one package/audience at a time.
2. Add more **resources** to the catalog and publish additional **access packages** using the same
   convention.
3. **Broaden review scope** from the pilot group/app to the full set; switch don't-respond behavior to
   **Remove access** once trusted.
4. **Broaden workflow scope** from `ENTIGA-Pilot` to the full population and enable **scheduled**
   (attribute-driven) execution.
5. Re-run **`ENTIGA-Validate.ps1`** and **`ENTIGA-Report.ps1`** after each wave to capture evidence.

> **Rollback (any step):** disable or narrow the offending object rather than deleting it — set an
> **assignment policy** back to `ENTIGA-Pilot` only; set a review's don't-respond to **No change** or
> stop the review; **disable** a lifecycle workflow (**Workflows → (workflow) → Disable**). To restore
> an access removed by auto-apply, re-request/re-approve the package or re-add the membership.
> Lifecycle-workflow tasks that **disable accounts / revoke sessions** are high-impact — treat leaver
> changes under change control.

---
### Order of operations
`Assess (Discovery/GuestReview) → catalog + resources → access package → employee policy → guest policy
→ 3 access reviews → joiner + leaver workflows → validate the 4 gates → expand in waves`
