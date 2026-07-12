# 5. Testing & Validation — Enablement Kit: Microsoft Entra Identity Fundamentals

Validate the kit against explicit **pass/fail gates** — both that the **lab sandbox** is set up
correctly and that the **skills** landed. Run the scripts and walk the manual checks. The automated
gates are produced by **`EKIDFUND-Validate.ps1`**; readiness comes from **`EKIDFUND-Discovery.ps1`**,
the sign-in labs from **`EKIDFUND-Labs.kql`**, and cohort evidence from **`EKIDFUND-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — The tenant is reachable and the fundamentals picture is captured

- **What good looks like:** The Entra admin center loads; `EKIDFUND-Discovery.ps1` returns the tenant
  fundamentals (users, groups, roles, apps, licensing).
- **How to test:** Run `EKIDFUND-Discovery.ps1`; confirm it prints user/group/role/app counts, the
  detected P1/P2 tier, and any existing CA policies without error.
- **If it fails:** Confirm portal access (**R1**), the Graph SDK is installed and consented (**R6**),
  and the account holds at least a read role (**R2**).

## Gate 2 — The learner cohort exists

- **What good looks like:** `Grp-EntraFund-Cohort` exists with the learners as members; learners hold
  read roles.
- **How to test:** Entra -> **Groups**; confirm the cohort group and membership. `EKIDFUND-Discovery.ps1`
  lists the cohort group where present.
- **If it fails:** Create the cohort (Step 0.2) and assign read roles (**R2**).

## Gate 3 — The cloud-only lab sandbox exists and is correctly named

- **What good looks like:** `Grp-EntraFund-LabTeam-Pilot`, `Grp-EntraFund-DynamicDept-Pilot`,
  `Lab-EntraFund-User1`, and `App-EntraFund-LabApp-Pilot` all exist, are **cloud-only**, and carry the
  agreed prefixes.
- **How to test:** Run `EKIDFUND-Validate.ps1`; confirm it lists each sandbox object as present and
  cloud-only. Or check them by name in the portal.
- **If it fails:** Create them with `EKIDFUND-LabSetup.ps1 -WhatIf:$false`, or by hand in Labs 3 and 5.
  If any is synchronized from on-prem, recreate it cloud-only (**R3**).

## Gate 4 — Learners can read a user, group, role, and app unaided

- **What good looks like:** In the capstone, learners open a user and read its UPN/object ID, target a
  group, name a least-privilege role, and explain the registration vs enterprise-app split — without
  help.
- **How to test:** Observe the capstone; confirm the learner performs Labs 2–5 actions on the sandbox
  unaided and explains each.
- **If it fails:** Re-run the specific lab (Labs 2–5) the learner struggled with before repeating the
  capstone.

## Gate 5 — The sign-in labs run and the CA lab policy is report-only

- **What good looks like:** The learner can open a sign-in and read its Conditional Access and
  authentication-method details; `CAFund-RequireMFA-LabTeam-ReportOnly` exists in **report-only**,
  scoped to `Grp-EntraFund-LabTeam-Pilot`, with break-glass excluded.
- **How to test:** Review a sign-in in **Monitoring -> Sign-in logs**; run a `EKIDFUND-Labs.kql`
  query; run `EKIDFUND-Validate.ps1`, which confirms the CA policy state is report-only and lists its
  scope and exclusions. *If the tenant has no P1, mark the policy build N/A and confirm the CA blade
  tour instead.*
- **If it fails:** Set the policy state back to **Report-only** if it drifted; add the break-glass
  exclusion if missing; re-scope to the lab team only (Lab 6).

## Gate 6 — Break-glass is excluded from the CA lab policy

- **What good looks like:** The two break-glass accounts are **excluded** from
  `CAFund-RequireMFA-LabTeam-ReportOnly` — teaching the anti-lockout habit even in report-only.
- **How to test:** `EKIDFUND-Validate.ps1` reports the policy's user exclusions; confirm break-glass
  is listed. Or check **Assignments -> Users -> Exclude** in the portal.
- **If it fails:** Add the break-glass accounts (or their exclusion group) to the policy's exclusions
  (**R4/G4**).

## Gate 7 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-EntraFund-Pilot` (tenant, users vs guests vs
  service principals, groups & membership, least-privilege roles, registration vs enterprise app,
  sign-in/MFA/CA basics, licensing).
- **How to test:** Run `EKIDFUND-Validate.ps1`; it prints the knowledge-check answer key mapped to the
  lab that teaches each item, for the instructor to score.
- **If it fails:** Revisit the mapped lab for any question a learner missed; the knowledge-check tests
  **concepts**, not tenant-specific values.

## Gate 8 — Read-only-first posture held; roles least-privilege

- **What good looks like:** No production identity was changed during the kit; learners held read
  roles and only the instructor created sandbox objects; the CA lab never left report-only.
- **How to test:** Review **Roles and administrators** (R2) and the audit log; confirm learner
  activity was read/sandbox-only.
- **If it fails:** Tighten role assignments; reaffirm the sandbox posture (**R3**) and re-run affected
  labs on sandbox objects only.

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Tenant reachable + fundamentals captured | `EKIDFUND-Discovery.ps1` returns the picture |
| 2 | Cohort exists | `Grp-EntraFund-Cohort` present with members |
| 3 | Lab sandbox exists, cloud-only | All four sandbox objects present and correctly named |
| 4 | Read user/group/role/app unaided | Capstone Labs 2–5 performed without help |
| 5 | Sign-in labs + CA lab report-only | Sign-in read; `CAFund-RequireMFA-LabTeam-ReportOnly` is report-only |
| 6 | Break-glass excluded | Break-glass excluded from the CA lab policy |
| 7 | Knowledge-check passes | `Check-EntraFund-Pilot` scored to threshold |
| 8 | Read-only-first + least-privilege | No production change; roles scoped |

All gates pass ⇒ the cohort is grounded; proceed to **Expand** (operate with confidence; progress to
the advanced solutions). Any fail ⇒ reinforce the mapped lab and re-check.
