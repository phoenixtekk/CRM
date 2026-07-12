# 5. Testing & Validation — Self-Deploy: Multi-Factor Authentication & Conditional Access

Validate the kit against explicit **pass/fail gates** — both that the **lab is set up safely** and
that the **skills** landed. Run the scripts and walk the manual checks. The automated gates are
produced by **`EKMFACA-Validate.ps1`**; readiness comes from **`EKMFACA-Discovery.ps1`**, the
CA-evaluation/troubleshooting labs from **`EKMFACA-Labs.kql`**, and impact + cohort evidence from
**`EKMFACA-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — CA is available and the MFA/CA picture is captured

- **What good looks like:** The Entra admin center loads; `EKMFACA-Discovery.ps1` returns enabled MFA
  methods, registration coverage, existing CA policies and states, and the P1/P2 tier.
- **How to test:** Run `EKMFACA-Discovery.ps1`; confirm it prints the methods, CA inventory, and
  licensing without error.
- **If it fails:** Confirm P1 (**R1**), the Graph SDK is installed and consented (**R6**), and the
  account holds a read role (**R2**). If no P1, Labs 2–6 are a read-only tour; the MFA-methods lab
  still runs.

## Gate 2 — Cohort, persona groups, and break-glass exclusion exist

- **What good looks like:** `Grp-MfaCa-Cohort`, the three `Grp-MfaCa-Persona-*-Pilot` groups, and
  `Grp-MfaCa-Excl-BreakGlass` (containing the two break-glass accounts) all exist.
- **How to test:** Entra -> **Groups**, or run `EKMFACA-Validate.ps1`, which lists each group and the
  break-glass membership.
- **If it fails:** Create the missing groups (Step 0.2 / 1.1) or run `EKMFACA-LabPolicy.ps1`, which
  creates the persona/exclusion groups if absent.

## Gate 3 — The report-only lab policies exist and are report-only

- **What good looks like:** `CALab001`, `CALab002`, and `CALab003` exist, each with **Enable policy =
  Report-only** (`enabledForReportingButNotEnforced`), scoped to the correct persona.
- **How to test:** Run `EKMFACA-Validate.ps1`; confirm each lab policy is present, report-only, and
  correctly scoped. *If no P1, mark N/A and confirm the read-only CA tour instead.*
- **If it fails:** Set any drifted policy back to **Report-only** immediately (it must never enforce in
  this kit); re-scope to the correct persona group (Lab 4).

## Gate 4 — Break-glass is excluded from every lab policy

- **What good looks like:** `Grp-MfaCa-Excl-BreakGlass` (or the break-glass users) is excluded from
  `CALab001`, `CALab002`, and `CALab003`.
- **How to test:** `EKMFACA-Validate.ps1 -BreakGlassUpn ...` reports each policy's exclusions and flags
  any missing the break-glass exclusion in red. Or check **Assignments -> Users -> Exclude** per
  policy.
- **If it fails:** Add `Grp-MfaCa-Excl-BreakGlass` to the policy's exclusions (**R4/G4**). This is the
  anti-lockout habit the kit exists to teach.

## Gate 5 — What-If matches the persona design

- **What good looks like:** In **Conditional Access -> What If**, a test internal user hits `CALab001`,
  a test admin hits `CALab002`, and a break-glass account hits **no** policy.
- **How to test:** Run What-If for one representative user per persona and for a break-glass account;
  confirm the applied policies match the design.
- **If it fails:** Fix the include/exclude scope until What-If matches (Lab 5); a break-glass account
  applying to any policy means the exclusion is missing (Gate 4).

## Gate 6 — Learners can read a sign-in and explain the CA decision

- **What good looks like:** Given a sign-in in the logs, a learner can state which CA policies applied,
  their result (including report-only "would have"), which MFA method satisfied the requirement, and
  what a failed user must do.
- **How to test:** Observe the capstone; have the learner open a sign-in (or run an `EKMFACA-Labs.kql`
  query) and narrate the CA evaluation and any failure reason.
- **If it fails:** Re-run Lab 6 (troubleshooting); reinforce the difference between a real failure and
  a report-only result.

## Gate 7 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-MfaCa-Pilot` (MFA method strength, CA anatomy,
  personas, report-only vs enforce, What-If, break-glass, reading a sign-in result).
- **How to test:** Run `EKMFACA-Validate.ps1`; it prints the knowledge-check answer key mapped to the
  lab that teaches each item, for the instructor to score.
- **If it fails:** Revisit the mapped lab for any question a learner missed; the check tests
  **concepts**, not tenant-specific values.

## Gate 8 — Report-only-only posture held; roles least-privilege

- **What good looks like:** No lab policy was ever enforced; learners held read roles and only the
  instructor created policies; break-glass was excluded from every policy throughout.
- **How to test:** `EKMFACA-Validate.ps1` confirms every lab policy is still report-only; review
  **Roles and administrators** (R2).
- **If it fails:** Set any enforced policy back to report-only immediately; tighten role assignments;
  reaffirm the report-only posture.

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | CA available + picture captured | `EKMFACA-Discovery.ps1` returns methods + CA + licensing |
| 2 | Cohort + personas + break-glass group | All groups present; break-glass in the exclusion group |
| 3 | Lab policies exist + report-only | `CALab001–003` present, all report-only, correctly scoped |
| 4 | Break-glass excluded everywhere | Every lab policy excludes the break-glass group |
| 5 | What-If matches design | Each persona hits its policy; break-glass hits none |
| 6 | Read a sign-in + explain CA | Capstone: CA decision + method + failure reason narrated |
| 7 | Knowledge-check passes | `Check-MfaCa-Pilot` scored to threshold |
| 8 | Report-only-only + least-privilege | No policy enforced; roles scoped |

All gates pass ⇒ the cohort can design, test, and troubleshoot MFA/CA safely; proceed to **Expand**
(the enforced-baseline solutions). Any fail ⇒ reinforce the mapped lab and re-check.
