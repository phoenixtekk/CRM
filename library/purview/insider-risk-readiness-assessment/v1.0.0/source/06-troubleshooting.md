# 6. Troubleshooting — Insider Risk Readiness Assessment (Microsoft Purview)

Symptom-first fixes for the failures you actually hit preparing IRM for deployment. Most problems are one of:
IRM not visible at all, a role-separation conflict, the Analytics scan or a policy showing nothing, a
connector not importing, audit logging off, or "why can't PowerShell do this?" — the answer to which is often
**because IRM is portal-configured**. Nothing here operates IRM against an individual.

---

## Visibility / licensing

**Insider Risk Management is not visible in the Purview portal (or Analytics is greyed out).**
- **Licensing.** IRM requires the appropriate plan (**E5 / E5 Compliance / an Insider Risk Management
  add-on**; A5 for education). Check the licensing signal with `IRMASSESS-Discovery.ps1` /
  `IRMASSESS-Validate.ps1 -Gate Licensing` and **verify in the M365 admin center**. Without the plan, IRM and
  the Analytics scan do not appear — **verify your licensing/tenant**.
- **Role.** Even licensed, you need an IRM role to *see* the workload — confirm you hold **Insider Risk
  Management Admins** (or the super-group) to configure. A missing role hides the node.

**The licensing script signal says "none matched" but I believe we are licensed.**
- The signal inspects subscribed-SKU **service plan names** for an insider-risk plan; plan names vary and
  evolve. Treat a non-match as *inconclusive*, not *unlicensed* — **verify in the admin center**. The script
  intentionally flags this as a signal, never an assertion.

## Roles & separation

**`IRMASSESS-Discovery.ps1` / `IRMASSESS-Validate.ps1` flags a separation conflict.**
- The same identity holds **conflicting** IRM roles (e.g. Analyst *and* Investigator) — separation of duties
  is broken. Remove the identity from one role in **Purview portal → Settings → Roles & scopes → Permissions**
  (or `Remove-RoleGroupMember`) so **Admins / Analysts / Investigators / Auditors** are held by **different**
  people.
- If the flag is the **super-group** (`Insider Risk Management`): that role grants everything. Reduce it to
  break-glass only.
- If HR/Legal appear as **Investigators**: by default they should be **escalation/reviewers**, not holders of
  the de-anonymizing Investigator role. Re-assign (Req 2.2/2.7).

**A role group isn't found by the script (`VERIFY-IN-PORTAL`).**
- IRM role-group names can vary by tenant/version. Confirm the actual role groups in **Settings → Roles &
  scopes → Permissions** and reconcile — do not assume a name; the script reports what `Get-RoleGroup`
  returns.

**`Get-RoleGroup` returns nothing / "cmdlet not recognized".**
- You are not connected to **Security & Compliance PowerShell**. Run `Connect-IPPSSession` with a modern-auth/
  MFA-capable admin holding a compliance role. `Get-RoleGroup` is an IPPSSession/Exchange cmdlet, not Graph.

## Privacy / anonymization

**Analysts can see real usernames when triaging.**
- **Anonymization is off.** Turn on **"Show anonymized versions of usernames"** in **Insider Risk Management →
  Settings → Privacy** *before* granting analyst access. This is a **portal setting** — there is no cmdlet;
  the scripts flag it as VERIFY-IN-PORTAL, they do not toggle it.
- De-anonymization is an **Investigator** action **inside an authorized case** — that is by design, not a
  privacy leak, and it is out of scope for a readiness assessment (no case is opened here).

**Too many indicators are enabled.**
- Data minimization: enable only what the intended template needs in **Settings → Policy indicators**. Excess
  indicators mean excess collection and more false signal — trim them.

## Connectors & signal

**The Analytics scan (or a template) shows little/no potential risk.**
- **Audit logging off?** Check `IRMASSESS-Validate.ps1 -Gate Audit`. With the unified audit log disabled, IRM
  has almost nothing to correlate — enable it and allow ingestion time.
- **Connector missing.** *Data theft by departing users* needs the **HR connector** (resignation/role-change
  signal) or the Entra account-deletion signal; security-violation indicators need **Defender for Endpoint**
  integration. Confirm the required connector exists and imported recently in **Data Connectors** — **verify
  in the portal**.
- **Dwell time.** IRM signals accrue over time; a tenant with fresh connectors/audit may simply have little
  history yet.

**The HR connector isn't importing.**
- Connector health is **portal-verified** (**Data Connectors** → the connector's last-import status). Check
  the CSV/API source, the schedule, and the field mapping per Microsoft docs. A silently stopped import
  degrades the departing-user signal without an obvious error — check it on a cadence.

## Scope & policy

**`IRMASSESS-Config.ps1` created the backing group, but I don't see a priority user group / policy.**
- **Correct — the script only creates the backing security group.** Binding it as a **priority user group**
  and creating the **policy** are **portal steps** (IRM exposes no policy cmdlet): **Settings → Priority user
  groups**, then **Policies → Create policy**, scoped to that group, **disabled/minimal**. The script does not
  (and should not) do this.

**The readiness scope group has real users in it.**
- Keep the readiness scope **test-accounts-only** until HR/privacy/legal approve deployment. Remove real users
  with `IRMASSESS-Set-Scope.ps1 -RemoveMember <upn> -Commit`.

**I want the script to enable the policy / turn IRM on.**
- **By design, no delivered script enables an IRM policy or enforcement.** Enablement is a deliberate portal/
  change-control action and an HR/privacy/legal **decision** — not something the assessment automates. The
  assessment proves *readiness*; it does not deploy.

## Tooling / PowerShell surface

**"Why can't PowerShell configure the analytics scan / connector / pseudonymization / policy?"**
- **Because IRM is largely portal-configured** — it exposes a limited PowerShell/Graph surface. This is a
  Microsoft platform reality, not a gap in the tooling. The scripts reliably handle **role groups, audit
  state, licensing signal, and the backing scope group (Graph)**, and **direct you to the portal** for the
  rest. We deliberately do **not** invent a cmdlet for a portal-only step.

**A Graph script fails with an authorization/scope error.**
- `IRMASSESS-Config.ps1` / `IRMASSESS-Set-Scope.ps1` need Graph scopes — reconnect with
  `Connect-MgGraph -Scopes Group.ReadWrite.All,User.Read.All`. Read-only checks need `Group.Read.All` /
  `Organization.Read.All`. Consent to the scopes with an admin.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`, and the only
  writes are **creating an empty backing group** or **adding/removing one scope member**. No script enables a
  policy. If a change landed, it was committed intentionally — remove the member / delete the empty group to
  revert; there is no operational IRM state to unwind.

---

### Fast triage table

| Symptom | First check |
|---|---|
| IRM not visible / Analytics greyed out | Licensing (E5/E5 Compliance/IRM add-on) + your IRM role — verify tenant |
| Separation conflict flagged | Same identity in conflicting roles / super-group / HR-Legal as Investigator — re-assign |
| Role group "not found" by script | Confirm actual role-group names in Settings > Roles & scopes |
| `Get-RoleGroup` not recognized | Not connected to S&C PowerShell — `Connect-IPPSSession` |
| Analysts see real usernames | Anonymization OFF — turn on in Settings > Privacy (portal) |
| Analytics/policy shows nothing | Audit logging off, connector missing, or dwell time — verify in portal |
| HR connector not importing | Data Connectors last-import status, source/schedule/mapping (portal) |
| No priority group/policy after Config | Expected — binding + policy are portal steps; Config makes only the backing group |
| Real users in readiness scope | Keep test-only — `IRMASSESS-Set-Scope.ps1 -RemoveMember -Commit` |
| "Script won't enable IRM" | By design — enablement is a portal/change-control + HR/privacy/legal decision |
| Graph script authorization error | Reconnect `Connect-MgGraph` with the needed scopes |
