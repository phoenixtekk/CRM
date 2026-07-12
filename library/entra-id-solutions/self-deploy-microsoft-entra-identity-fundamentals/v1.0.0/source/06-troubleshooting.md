# 6. Troubleshooting — Self-Deploy: Microsoft Entra Identity Fundamentals

The common failure modes, each as **symptom → cause → fix**. Most kit issues are a missing role, a
sandbox object created the wrong way, dynamic-membership lag, or a licensing surprise — not a broken
tenant. Use `EKIDFUND-Discovery.ps1` for the read-only picture and `EKIDFUND-Validate.ps1` for the
gate checks.

---

## 1. A learner cannot open a blade / everything is greyed out

- **Symptom:** The Users, Groups, or Roles blade is missing or read-only actions are unavailable.
- **Cause:** The learner has no directory role, or too low a one.
- **Fix:** Assign at least **Global Reader** (or **Directory Readers**) so learners can explore
  read-only (**R2**). Only the instructor needs create/change roles. Confirm portal reachability
  (**R1/G8**).

## 2. `Connect-MgGraph` fails or a script returns 403

- **Symptom:** A helper cannot connect, or a call is forbidden.
- **Cause:** The Graph SDK is not installed, scopes were not consented, the wrong cloud endpoint was
  used, or the account lacks the role.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and consent the read scopes in
  the script header; for Government cloud pass the matching `-Environment`; confirm the account holds
  a read role (**R6/R2**). *Verify the correct endpoints for your cloud.*

## 3. The lab sandbox setup won't create objects

- **Symptom:** `EKIDFUND-LabSetup.ps1 -WhatIf:$false` fails to create a group, user, or app.
- **Cause:** The account lacks the create role (**User Administrator** / **Groups Administrator** /
  **Application Administrator**), or the initial domain name is different in your tenant.
- **Fix:** Run the setup as the **instructor** with the create roles; if your initial domain is not
  `contoso.onmicrosoft.com`, pass your real `*.onmicrosoft.com` domain via the script's `-Domain`
  parameter so the test UPN is valid.

## 4. A lab test user cannot be edited (it's synced)

- **Symptom:** Fields on a user are read-only in Entra ("managed on-premises").
- **Cause:** The object is **synchronized from Active Directory**, not cloud-only — synced attributes
  are managed on-prem.
- **Fix:** Do labs on **cloud-only** sandbox users (`Lab-EntraFund-User1`), never on synced accounts
  (**R3**). Create a fresh cloud-only user if needed.

## 5. Dynamic-group membership didn't update

- **Symptom:** After setting `Lab-EntraFund-User1`'s department to `LabDept`, it isn't in
  `Grp-EntraFund-DynamicDept-Pilot` yet.
- **Cause:** Dynamic membership is evaluated **asynchronously** — it can take minutes (longer in large
  tenants), and the rule must match exactly.
- **Fix:** Wait and refresh; confirm the rule (`user.department -eq "LabDept"`) matches the attribute
  value exactly (case and spelling); check the group's **Membership processing status**.

## 6. The Conditional Access lab policy isn't report-only (or can't be built)

- **Symptom:** `CAFund-RequireMFA-LabTeam-ReportOnly` shows as On/Off instead of Report-only, or the
  CA blade is unavailable.
- **Cause:** The state was changed, or the tenant has no **Entra ID P1** (Conditional Access is a P1
  feature).
- **Fix:** Set **Enable policy = Report-only** (Lab 6); it must never be On for this kit. If there is
  no P1, make Lab 6 a **read-only tour** of the CA blade instead of a policy build, and note the gap
  (**R5**). *Verify licensing.*

## 7. Break-glass is not excluded from the CA lab policy

- **Symptom:** `EKIDFUND-Validate.ps1` flags the CA lab policy as missing the break-glass exclusion.
- **Cause:** The exclusion was not added when the policy was created.
- **Fix:** Add the two break-glass accounts (or their exclusion group) under **Assignments -> Users ->
  Exclude** (**R4/G4**). Teaching this habit is a core point of the lab even though the policy is
  report-only.

## 8. Sign-in logs show nothing / the KQL lab returns no rows

- **Symptom:** A `EKIDFUND-Labs.kql` query returns 0 rows, or Sign-in logs look empty.
- **Cause:** The time window is too tight, the sandbox user hasn't signed in yet, or (for the
  Log-Analytics variant) sign-in logs aren't being exported to a workspace.
- **Fix:** Widen the window (`ago(7d)`); have `Lab-EntraFund-User1` sign in once to generate a
  sign-in; use the **Entra -> Monitoring -> Sign-in logs** portal view if no Log Analytics export
  exists. *Sign-in-log retention and export are P1/P2 and workspace-dependent — verify in your
  tenant.*

## 9. "Which license do I have?" confusion

- **Symptom:** A feature the kit mentions (risk policies, PIM, Governance) isn't visible.
- **Cause:** Those need **Entra ID P2** or an add-on the tenant may not have.
- **Fix:** Run `EKIDFUND-Discovery.ps1` (licensing section) or check **Billing -> Licenses**; the kit
  flags P2/add-on features as *verify availability*. Everything in the core labs runs on P1; note any
  gap and move on.

## 10. App registration vs enterprise application confusion

- **Symptom:** A learner can't find the app in the expected blade, or edits the wrong object.
- **Cause:** The **registration** (definition, under **App registrations**) and the **enterprise
  application** (instance/service principal, under **Enterprise applications**) are two different
  blades for the same app.
- **Fix:** Re-do Lab 5: open `App-EntraFund-LabApp-Pilot` under **App registrations** for its
  identity/permissions, then find the matching service principal under **Enterprise applications** for
  assignment/consent. They are linked but distinct.
