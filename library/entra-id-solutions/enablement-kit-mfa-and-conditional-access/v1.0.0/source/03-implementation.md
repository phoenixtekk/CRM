# 3. Implementation Guide — Enablement Kit: Multi-Factor Authentication & Conditional Access

This is the exact, ordered guide — a sequence of **guided hands-on labs**. Every object you create is
**named** with a consistent convention — `<Purpose> - <Scope> - <Stage>` for groups and `CALab0nn
<Purpose> - <Persona> - ReportOnly` for policies — and the same name is reused in later labs, the
knowledge-check, and the scripts. **Every lab Conditional Access policy is created in report-only and
can never enforce**, break-glass is excluded from every policy from the first save, and the lab scope
is a handful of cloud-only test users. No policy in this kit is ever enforced — enforcing a real
baseline is the ENTZTCA / Conditional Access Integration solutions.

> **Before you start:** confirm CA licensing (**R1**, P1), the cohort and least-privilege roles
> (**R2**), the lab persona groups (**R3**), break-glass and the exclusion group (**R4**, **G4**), the
> methods/sign-in-log access (**R5**), and the toolchain (**R6**). This guide **designs and tests** in
> report-only; it does not enforce.

**Object naming convention (used everywhere below and in the scripts).** Create these once and reuse
the exact names in testing, troubleshooting, and scripts:

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MfaCa-Cohort` | Entra security group of kit learners |
| Break-glass exclusion group | `Grp-MfaCa-Excl-BreakGlass` | Holds the two break-glass accounts; excluded from every policy |
| Admins persona (lab) | `Grp-MfaCa-Persona-Admins-Pilot` | Cloud-only test admins |
| Internals persona (lab) | `Grp-MfaCa-Persona-Internals-Pilot` | Cloud-only test staff |
| Guests persona (lab) | `Grp-MfaCa-Persona-Guests-Pilot` | Cloud-only test guests |
| Knowledge-check | `Check-MfaCa-Pilot` | The scored end-of-kit knowledge-check |

Report-only lab policies (each created **report-only**, never enforced):

| # | Policy | Persona | Control | License |
| --- | --- | --- | --- | --- |
| CALab001 | `CALab001 Require MFA - Internals - ReportOnly` | Internals | Require MFA | P1 |
| CALab002 | `CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly` | Admins | Auth strength: phishing-resistant | P1 |
| CALab003 | `CALab003 Block Legacy Authentication - AllUsers - ReportOnly` | All (break-glass excluded) | Block legacy clients | P1 |

> Every one is **report-only** and excludes `Grp-MfaCa-Excl-BreakGlass`. If the tenant has no P1,
> Labs 2–6 are a **read-only tour** instead of a policy build (**R1**). The runnable CA-evaluation and
> troubleshooting queries live in the delivered **`EKMFACA-Labs.kql`** pack.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to the **Microsoft Entra admin center** -> `https://entra.microsoft.com`.
2. From PowerShell, take a read-only picture:

   ```
   pwsh -File .\EKMFACA-Discovery.ps1
   ```

   It reports, read-only: enabled MFA methods and registration coverage, existing Conditional Access
   policies and their states, which policies exclude break-glass (and flags any "all users, no
   exclusions" lock-out risk), detected legacy-auth sign-ins, and the licensing tier (P1/P2). **Nothing
   is modified.** Save the output — your before picture and a teaching prop.

### Step 0.2 — Create the cohort

1. Entra -> **Groups -> New group** -> Security -> `Grp-MfaCa-Cohort`; add the learners.
2. Confirm learners hold read roles and the instructor holds `Conditional Access Administrator`
   (**R2**).

---

## Phase 1 — Configure (persona groups + break-glass exclusion)

### Step 1.1 — Create the lab persona and exclusion groups

1. Entra -> **Groups** -> create `Grp-MfaCa-Excl-BreakGlass` and add the two break-glass accounts
   (**R4/G4**).
2. Create the cloud-only persona groups `Grp-MfaCa-Persona-Admins-Pilot`,
   `Grp-MfaCa-Persona-Internals-Pilot`, `Grp-MfaCa-Persona-Guests-Pilot` and add a few disposable
   test users to each.
3. Or preview and create them with `EKMFACA-LabPolicy.ps1` (it creates the persona/exclusion groups
   if absent before previewing the report-only policies).

---

## Phase 2 — Pilot (the guided labs, all report-only)

Run each lab with the cohort. Each lab states the **concept**, the **task**, and the **check**.

### Lab 1 — MFA methods and registration

- **Concept.** MFA methods differ in strength: SMS/voice (weak, phishable) < authenticator with number
  matching < **phishing-resistant** (FIDO2/passkey, Windows Hello for Business, certificate-based).
  The **authentication-methods policy** controls what is enabled and drives registration.
- **Task.** Open **Protection -> Authentication methods -> Policies**; read which methods are enabled
  and for whom. Open **Authentication methods -> Activity / Registration** and read the registration
  coverage (or run `EKMFACA-Discovery.ps1`'s methods section). Discuss which methods your org should
  prefer. *Read-only — do not change the tenant methods policy in the lab.*
- **Check.** You can rank the MFA methods by strength, explain phishing-resistant, and find where
  methods and registration are configured.

### Lab 2 — Anatomy of a Conditional Access policy

- **Concept.** A CA policy is if-then: **assignments/conditions** (users/groups + exclusions, target
  resources, device/location/client/risk) -> **grant controls** (require MFA / auth strength /
  compliant device / block) and/or **session controls** (sign-in frequency, persistent browser,
  app-enforced restrictions).
- **Task.** Open **Protection -> Conditional Access -> Policies**; open an existing policy (or start a
  New policy without saving) and walk each section: Users (include/exclude), Target resources,
  Conditions, Grant, Session, and the **Enable policy** toggle (On / Off / **Report-only**). *Do not
  save an enforced policy.*
- **Check.** You can name every section of a CA policy and explain what report-only does.

### Lab 3 — Design patterns and personas

- **Concept.** Design CA by **persona**, not one mega-policy: **admins** (phishing-resistant MFA,
  tight session), **internals** (MFA + compliant/hybrid device), **guests** (MFA + app-enforced
  restrictions), **service accounts** (non-interactive — scoped out, governed separately). Personas
  map to groups; policies target groups.
- **Task.** Map your org's users onto the four personas on paper; match each to your lab persona group
  (`Grp-MfaCa-Persona-*-Pilot`). Sketch which control each persona needs. Discuss the common baseline
  patterns (MFA everywhere, phishing-resistant for admins, block legacy auth).
- **Check.** You can assign a user to the right persona and name the control that persona needs.

### Lab 4 — Build the report-only policies (no lockouts)

- **Concept.** Every policy is created in **report-only** and excludes break-glass — it evaluates and
  logs but cannot block anyone.
- **Task.** Preview the report-only lab policies (changes nothing):

  ```
  pwsh -File .\EKMFACA-LabPolicy.ps1
  ```

  Review, then create them (still report-only):

  ```
  pwsh -File .\EKMFACA-LabPolicy.ps1 -WhatIf:$false
  ```

  This creates `CALab001` (Require MFA - Internals), `CALab002` (Phishing-Resistant MFA - Admins), and
  `CALab003` (Block Legacy - All Users) — all **report-only**, all scoped to the persona groups, all
  excluding `Grp-MfaCa-Excl-BreakGlass`. *You can also build each by hand in the portal: New policy ->
  name it exactly `CALab00n ... - ReportOnly`, set the persona include, the break-glass exclude, the
  grant control, and **Enable policy = Report-only**.* If no P1, do this as a read-only tour (**R1**).
- **Check.** The three lab policies exist, are **report-only**, scoped to the right persona, and each
  excludes break-glass.

### Lab 5 — Test with What-If (simulate before enforce)

- **Concept.** **What-If** simulates a sign-in and shows exactly which policies would apply and which
  controls would fire — with no real sign-in and no risk.
- **Task.** Open **Conditional Access -> What If**. Run it for: a test **internal** user (expect
  `CALab001` to apply), a test **admin** (expect `CALab002`), and a **break-glass** account (expect
  **no** policy to apply — the exclusion works). Adjust scope/exclusions until What-If matches the
  design.
- **Check.** What-If shows each persona hitting its intended policy and break-glass hitting **none**.

### Lab 6 — Troubleshoot sign-in failures and CA evaluation

- **Concept.** Every sign-in logs **why** each CA policy applied or did not (success / failure /
  reportOnlySuccess / reportOnlyFailure / notApplied) and which MFA method satisfied the requirement.
  Most "MFA is broken" tickets are a policy doing exactly what it was told.
- **Task.** Open **Monitoring -> Sign-in logs**; open a sign-in and read its **Conditional Access**
  tab (which policies applied and their result, including the report-only labs), **Authentication
  Details** (which method satisfied MFA), and the failure reason for any failed sign-in. Run the
  `EKMFACA-Labs.kql` queries (CA-evaluation and failure-reason sections) to summarize would-apply
  results and top failure reasons.
- **Check.** Given a sign-in, you can state which policy applied, why, and what the user must do — and
  distinguish a real failure from a report-only "would have."

---

## Phase 3 — Validate (capstone + knowledge-check)

1. **Capstone.** Each learner, unaided: designs a report-only policy for a chosen persona (or explains
   one of `CALab001–003`), proves it with **What-If** for that persona **and** for break-glass (must
   apply to the persona, must **not** apply to break-glass), then reads a sign-in log to explain the
   result. *Everything stays report-only.*
2. **Knowledge-check.** Score `Check-MfaCa-Pilot`:

   ```
   pwsh -File .\EKMFACA-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
   ```

   It walks the pass/fail gates in `05-testing.md` — lab policies exist and are **report-only**,
   break-glass is excluded from every one, personas are scoped correctly — and prints the
   knowledge-check answer key for the instructor to score.
3. **Impact + cohort report.** Summarize what the report-only policies *would* have done and cohort
   progress:

   ```
   pwsh -File .\EKMFACA-Report.ps1 -OutputCsv .\ekmfaca-cohort.csv
   ```

---

## Phase 4 — Expand (take the capability to production)

1. **Move to the enforced baseline solutions.** With the team able to design, test, and troubleshoot
   MFA/CA, the natural next step is the **Zero Trust Conditional Access Baseline (ENTZTCA)** and
   **Conditional Access Integration** — design and roll out a real, **enforced** baseline (report-only
   -> pilot -> enforce, wave by wave). This kit built the skill; those products build the production
   system.
2. **Deploy phishing-resistant methods.** Feed the MFA-methods understanding into the **Passwordless &
   Passkey (ENTPASSKEY)** rollout so `CALab002`-style phishing-resistant requirements have a method to
   satisfy them.
3. **Adopt the runbook.** Move the take-home runbook into standing operations documentation so the
   MFA/CA design-test-troubleshoot method is reused, not re-explained.
4. **Tear down or keep the lab.** Remove the report-only lab policies and persona groups if the kit
   was one-off, or keep them for re-runs.

---

## Rollback / safe-off

- **Concept/observation labs (1, 2, 3, 5, 6):** read-only — nothing to roll back.
- **Report-only lab policies (Lab 4):** they are **report-only** and cannot enforce; set each to
  `Off` or delete `CALab001–003` (`EKMFACA-LabPolicy.ps1 -Remove -WhatIf:$false` after previewing).
  Break-glass is excluded throughout, so there is no lock-out risk at any point.
- **Persona/exclusion groups:** delete the `Grp-MfaCa-*` groups if the kit was one-off; keep them if
  operationalizing into the ENTZTCA baseline.
