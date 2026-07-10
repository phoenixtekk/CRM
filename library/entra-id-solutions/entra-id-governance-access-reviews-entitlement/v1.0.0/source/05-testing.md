# 5. Testing & Validation — Entra ID Governance: Access Reviews & Entitlement Management

Validate on the **pilot** (`ENTIGA-Pilot`) first. Each test has a **pass/fail** signal. Do not expand
until all four gates pass. Reference scripts are named in each row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Request** | A pilot user opens **My Access** (`https://myaccess.microsoft.com`) and requests `ENTIGA – Package – LOBApp – Prod` | Request is submitted and routed to the approver | Package not visible / not requestable |
| 2 | **G1 Approve** | The approver (Manager / named) approves in **My Access → Approvals** | Access is granted; the resource role is assigned | Approval never arrives / grant not applied |
| 3 | **G1 Expiry** | Inspect the assignment after approval | Assignment shows a **time-bound expiry** (e.g. 90 days) | Grant is permanent / no expiry |
| 4 | **G2 Review runs** | Start `ENTIGA – Review – PrivGroup – Quarterly`; reviewer opens **My Access → Access reviews** | Reviewer sees members + recommendations and can Approve/Deny | Review not started / reviewer sees nothing |
| 5 | **G2 Auto-apply removes** | Reviewer **Denies** a test member; auto-apply runs | The denied member is **removed** from the group | Access remains after a Deny decision |
| 6 | **G3 Guest time-bound** | A test guest requests via `ENTIGA – Policy – Guests – TimeBound`; internal sponsor approves | Guest gets access with the **shorter expiry** (e.g. 30 days) | Guest gets permanent access / no approver |
| 7 | **G4 Joiner** | Run `ENTIGA – Joiner – Onboarding` on-demand for a test user | Tasks run (account enabled, added to groups, welcome sent) | Workflow fails / tasks skipped |
| 8 | **G4 Leaver** | Run `ENTIGA – Leaver – Offboarding` on-demand for a test leaver | Account **disabled**, group/package assignments **removed**, sessions **revoked** | Access/sessions remain after run |

## Automated checks
- **`ENTIGA-Discovery.ps1`** — inventories catalogs, access packages + policies, access review
  definitions, and lifecycle workflows so you can confirm the named objects exist with the expected
  configuration.
- **`ENTIGA-Validate.ps1`** — checks each **named** object from §3 is present and correctly wired
  (package has an approval policy with an expiry; each review has auto-apply set; each workflow is
  enabled and scoped) and **flags gaps** — the automated form of the gate table.
- **`ENTIGA-Report.ps1`** — exports **audit/recertification evidence**: current access package
  assignments (who has what, granted/expiry dates) and recent access review decisions.
- **`ENTIGA-GuestReview.ps1`** — lists guests with **last sign-in** so you can confirm stale guests are
  being caught by the guest review.
- **`ENTIGA-Lifecycle.ps1`** — reports workflow **run history** and which in-scope users have the trigger
  attributes (`employeeHireDate` / `employeeLeaveDateTime`) populated.

## Evidence to capture (for audit / recertification)
- Screenshots: the package in **My Access**, an approval decision, an assignment showing **expiry**.
- A completed **access review** with decisions and the **auto-apply** result.
- `ENTIGA-Report.ps1` CSV of assignments + review decisions (the recertification artifact).
- Lifecycle workflow **run report** showing joiner/leaver task outcomes.

## Exit criteria (before Expand)
- [ ] G1 — request → approve → **time-bound** grant works end to end
- [ ] G2 — a Deny decision with **auto-apply** actually removes access
- [ ] G3 — guest access is granted with a **shorter expiry** via an internal sponsor
- [ ] G4 — joiner runs its tasks; leaver **disables + revokes + removes** assignments
- [ ] `ENTIGA-Validate.ps1` shows no gaps for the pilot objects
- [ ] `ENTIGA-Report.ps1` produces a clean assignment + decision evidence export
