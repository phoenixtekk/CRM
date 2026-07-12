# 3. Implementation (Guided Labs) — Enablement Kit: Identity Modernization with Entra

This is the hands-on core of the kit. Work through the labs **in order**; each maps to a stage of the
deployment model (**Assess → Configure → Pilot → Validate → Expand**). Every object you create uses
the naming convention **`<Purpose> – <Scope> – <Stage>`** and is reused by name in later labs, the
testing guide, and the scripts. All labs are **pilot-scoped and non-destructive** — Conditional
Access is report-only, change scripts default to `-WhatIf`, and everything targets the pilot lab
group. **Do not enforce any policy against real users during the kit.**

Portal paths below are current at authoring time; Microsoft may relabel blades — *verify the current
navigation in your tenant.*

---

## Lab 0 — Set up the lab (Assess + safety)

**Goal:** create the pilot scope and confirm safety before touching any control.

1. Confirm two **break-glass** accounts exist and are excluded from broad policies (see global
   requirements G4). Never scope a lab policy to include them.
2. Open PowerShell and run the read-only assessment:
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser   # if not already installed
   .\EKIDMOD-Discovery.ps1
   ```
   Read the output: legacy authentication usage, per-user MFA vs Conditional Access state,
   authentication methods registered, and federated domains. This is your **baseline**.
3. Create the pilot group and sample users (preview first, then commit):
   ```powershell
   .\EKIDMOD-LabSetup.ps1               # -WhatIf preview by default: shows what it would create
   .\EKIDMOD-LabSetup.ps1 -Commit       # actually creates the group + sample users
   ```
   This creates the security group **`Identity Modernization – Pilot – Lab`** and sample cloud users
   (`labuser1…`), and adds the users to the group.
4. Validate the lab prerequisites:
   ```powershell
   .\EKIDMOD-Validate.ps1
   ```
   Confirm it reports: pilot group present, sample users present, Graph module OK, and detected
   licensing (P1/P2/Governance/GSA). Resolve any FAIL before continuing.

**Gate:** discovery baseline captured, pilot group + sample users exist, validation passes.

---

## Lab 1 — Conditional Access as the policy engine (report-only)

**Goal:** understand and build the first modern access policy without enforcing it.

*Concept recap:* CA replaces per-user MFA and legacy rules with signal-driven policy. In modernization
you always introduce CA in **Report-only** first, read the impact in sign-in logs, then enforce in
rings. Requires Entra ID P1 — *verify.*

1. Entra admin center → **Protection → Conditional Access → Policies → + New policy**.
2. Name it exactly: **`CA – Pilot – Require MFA (Report-only)`**.
3. **Users**: Include → **Select users and groups** → the group `Identity Modernization – Pilot – Lab`.
   Exclude your break-glass accounts.
4. **Target resources**: Include → **All cloud apps** (for the lab).
5. **Grant**: **Grant access** → check **Require multifactor authentication**.
6. **Enable policy**: set to **Report-only** (not On).
7. **Create**.
8. Build a second policy to teach legacy-auth blocking, also report-only:
   **`CA – Pilot – Block Legacy Auth (Report-only)`** → Users = pilot group → Conditions → **Client
   apps** → select **Exchange ActiveSync clients** and **Other clients** → Grant = **Block** →
   **Report-only** → **Create**.

**Gate:** two report-only policies exist, scoped only to the pilot group, break-glass excluded.
(Validate in the Testing guide via the What-If tool and the report-only sign-in workbook.)
For production rollout, hand off to **Zero Trust Conditional Access baseline (ENTZTCA)**.

---

## Lab 2 — Identity Protection as risk signal

**Goal:** see how risk becomes a Conditional Access signal. Requires Entra ID P2 — *verify.*

1. Entra → **Protection → Identity Protection → Overview**. Review **Risky users** and **Risky
   sign-ins** reports (these are read-only investigations).
2. Understand the two risk-based policy shapes (do **not** enable them against real users in the lab):
   - **Sign-in risk** → require MFA.
   - **User risk** → require secure password change.
3. Build a **report-only** risk-based CA policy to observe the pattern:
   Entra → **Protection → Conditional Access → + New policy** → name
   **`CA – Pilot – Sign-in Risk MFA (Report-only)`** → Users = pilot group (exclude break-glass) →
   Conditions → **Sign-in risk** → select **High, Medium** → Grant = **Require multifactor
   authentication** → **Report-only** → **Create**.
4. If P2 is not present, read this lab as concept only and note it in the runbook.

**Gate:** the risk-based report-only policy exists; the team can explain how Identity Protection risk
feeds CA. Production work → **Entra Identity Protection / Advanced Conditional Access** solution.

---

## Lab 3 — Passwordless & phishing-resistant authentication

**Goal:** enable a modern authentication method for the pilot group and register it.

*Concept recap:* the modernization endgame is phishing-resistant, passwordless sign-in (FIDO2
passkeys, Windows Hello for Business, certificate-based auth). You enable methods centrally and scope
them to the pilot group first.

1. Entra → **Protection → Authentication methods → Policies**.
2. Select **FIDO2 security key** (passkey) → **Enable** = Yes → **Target** = **Select groups** → add
   `Identity Modernization – Pilot – Lab` → **Save**. (Optionally also enable **Microsoft
   Authenticator** passkeys / passwordless for the same group.)
3. Have a pilot lab user register a passkey at **`https://aka.ms/mysecurityinfo`** (or Windows Hello
   for Business on a test device).
4. Note: FIDO2 / passkey capabilities and platform support evolve and some options are in preview —
   *verify current availability in your tenant.*

**Gate:** a phishing-resistant method is enabled and scoped to the pilot group, and at least one lab
user has registered it. Production rollout → **Entra Passwordless / FIDO2 passkey rollout (ENTPASSKEY)**.

---

## Lab 4 — Identity governance (least privilege & lifecycle)

**Goal:** rehearse access reviews, an access package, and PIM at pilot scope. Governance features
require **Entra ID P2 / Entra ID Governance** — *verify.*

1. **Access review (lab):** Entra → **Identity governance → Access reviews → + New access review** →
   name **`Access Review – Pilot – Lab`** → review membership of the group
   `Identity Modernization – Pilot – Lab` → reviewer = yourself → duration a few days → set decisions
   to **manual** (no auto-apply in the lab) → **Create**.
2. **Access package (lab):** Entra → **Identity governance → Entitlement management → Access
   packages → + New access package** → name **`Access Package – Pilot Apps – Lab`** → add a resource
   the pilot group can request (for example a test group or app) → policy: who can request = the
   pilot group → **Create**. Have a lab user request it to see the request/approval flow.
3. **PIM (lab):** Entra → **Identity governance → Privileged Identity Management → Microsoft Entra
   roles → Assignments**. Inspect an existing eligible assignment and the activation experience
   (read-only exploration). Do **not** change production role assignments in the lab.

**Gate:** an access review and an access package exist at pilot scope; the team can explain
eligible-vs-active roles in PIM. Production work → **Entra ID Governance — PIM & Access Reviews /
Entitlement (ENTPIM / ENTIGA)**.

---

## Lab 5 — Global Secure Access (extend Zero Trust to the network)

**Goal:** understand identity-centric network access. GSA licensing/capabilities are evolving — *verify
availability in your tenant; treat as concept-only if not licensed.*

1. Entra → **Global Secure Access**. Review **Get started** and the two pillars: **Internet access**
   (Secure Web Gateway) and **Private access** (Zero Trust Network Access to internal apps).
2. If enabled in your tenant, create a lab traffic-forwarding profile named **`GSA – Pilot – Lab`**
   and observe how Conditional Access can now apply to network traffic (do not enforce for real users).
3. If not enabled, read the concept and record in the runbook where GSA fits (after CA + Identity
   Protection are established).

**Gate:** the team can explain how GSA extends Conditional Access to network access. Production work →
the **Global Secure Access** solution.

---

## Lab 6 — Migration & coexistence patterns (AD FS / hybrid → cloud)

**Goal:** learn the safe order to retire legacy without breaking sign-in. Read-only inspection only.

1. Inspect domain authentication types: Entra → **Identity → Settings → Domain names**. Note any
   **Federated** domains (AD FS) vs **Managed** (cloud-authenticated). `EKIDMOD-Discovery.ps1` also
   lists federated domains.
2. Learn the coexistence sequence (do not execute against production here):
   - Ensure **hybrid sync** is healthy (cross-reference the **Hybrid Identity Enablement Kit —
     EKHYBID** and **HYBID** implementation solution).
   - Move authentication from **federation → cloud auth** (Password Hash Sync / Pass-through Auth)
     using **staged rollout** to a pilot group before converting the domain.
   - Convert the domain from **Federated → Managed** only after staged rollout validates.
   - Retire the AD FS farm once no reliance remains.
3. Record the customer-specific coexistence plan in the take-home runbook (see the Testing guide).

**Gate:** the team can sequence a federation-to-cloud migration and name the safe rollback points.

---

## Lab 7 — Score and report the modernization posture

**Goal:** turn discovery into a shareable scorecard and (optionally) analyze sign-in signals.

1. Generate the scorecard:
   ```powershell
   .\EKIDMOD-Report.ps1 -OutputPath .\EKIDMOD-Scorecard
   ```
   This writes a CSV and an HTML summary scoring the estate across the building blocks (legacy auth,
   MFA/passwordless coverage, CA posture, governance, federated domains).
2. (Optional) If Log Analytics / Sentinel is available, open **Logs** and run queries from
   **`EKIDMOD-Signals.kql`** — legacy-auth sign-ins, risky sign-ins, CA gaps, passwordless adoption.

**Gate:** a scorecard is produced; the team can read it and prioritize the next real modernization step.

---

## Wrap-up
- Complete the **knowledge-check** and finalize the **take-home runbook** (both in `05-testing.md`).
- Optionally tear down lab objects: re-run `EKIDMOD-LabSetup.ps1 -Remove` (preview first) to delete
  the pilot group and sample users you created.
