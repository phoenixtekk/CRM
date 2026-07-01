# Netskope + Entra ID SSO & Identity-Based Policy Enforcement

> **Version 1.0.0** · Category: Network · Solution code: NSSSO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

**Network Solutions · SASE/SSE**

Network-security policy that is not tied to identity is blunt. You cannot write a rule that says
"this group may use this app and that group may not," admins juggle a separate login for the
security console, and users are provisioned and de-provisioned by hand — so access drifts out of
sync with who actually works here. This solution integrates Netskope with Microsoft Entra ID as the
identity provider: SAML single sign-on for the admin console and for users, SCIM user and group
provisioning into Netskope, and policy that steers and enforces by identity and group — so the right
controls follow the right people everywhere.

This is a complete, repeatable package for connecting Netskope to Entra ID for SSO and
identity-based policy, written for an administrator with no prior Netskope/IdP-integration
experience. Netskope console specifics are deferred to the official Netskope documentation; the
Entra ID side is documented click-by-click.

## What you get
- A plain-language Solution Overview of the IdP integration model — SAML SSO, SCIM provisioning,
  identity-based steering and policy — and how it complements (not duplicates) Entra Conditional Access.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: configure SAML SSO, enable SCIM provisioning,
  map groups, build identity-based policy, then pilot, validate, and expand.
- Five PowerShell scripts for SSO/SCIM-readiness discovery, sign-in and provisioning validation, an
  identity-policy coverage report, safe remediation of provisioning gaps, and an identity-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A single identity backbone for Netskope: one sign-in for admins and users via SAML, users and groups
kept in sync by SCIM, and policies that target by Entra group — proven on a pilot group before the
fleet, with a documented rollback path.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Netskope policy that follows the user — Entra ID single sign-on, SCIM-provisioned users and groups,
and identity-based steering and enforcement — so the right controls reach the right people
everywhere, validated on a pilot before you scale.


---


# 1. Solution Overview — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

## What this integration is
This solution makes Microsoft Entra ID the identity provider (IdP) for Netskope. Three things are
wired together, in order:

1. SAML single sign-on (SSO) between Entra ID and Netskope, so the Netskope admin console — and,
   where Netskope uses it, end-user authentication — is governed by Entra ID rather than a separate
   local account and password.
2. SCIM user and group provisioning from Entra ID into Netskope, so the users and groups Netskope
   sees are kept in sync automatically — created, updated, and de-provisioned as Entra ID changes.
3. Identity-based steering and policy in Netskope, written against the provisioned users and groups,
   so rules apply to "the right people" by group rather than by IP address or device alone.

The result is policy that follows the user: a user signs in once through Entra ID, is recognized in
Netskope by their Entra identity and group memberships, and gets exactly the Netskope controls those
groups are assigned — wherever they connect.

## How it works
1. An enterprise application registered in Entra ID represents Netskope. Its SAML single sign-on
   configuration establishes the trust (identifier/entity ID, reply/ACS URL, signing certificate,
   and claims) so Entra ID can issue assertions Netskope accepts.
2. The same enterprise application's provisioning is set to SCIM. Entra ID pushes users and groups
   that are in scope (assigned to the app) into Netskope on a recurring cycle, so Netskope's
   directory mirrors Entra ID without manual import.
3. Entra security groups are assigned to the application so only the intended users are provisioned
   and granted sign-in — this assignment is also what scopes the pilot.
4. In Netskope, real-time and steering policies are written to match by the provisioned identity and
   group, so a control (allow/block/inspect a category or app, a DLP rule, a ZTNA app) targets a
   group rather than a subnet.
5. Sign-in events and provisioning status are observable in Entra ID (the enterprise app's sign-in
   logs and provisioning logs); policy hits and identity attribution are observable in Netskope.

## What you can control
- Who can sign in to Netskope (admin console / users) via SAML — by Entra group assignment.
- Which users and groups exist in Netskope — automatically, via SCIM provisioning scope.
- Attribute and group mapping — what Entra attributes/claims flow to Netskope and how groups map.
- Identity-based Netskope policy — steering and real-time rules targeted by provisioned group.
- Lifecycle — joiners, movers, and leavers reflected in Netskope as Entra ID changes (de-provisioning).

## How this differs from Entra Conditional Access (complements, does not duplicate)
This is a common point of confusion, so be explicit. Entra Conditional Access decides whether a
sign-in to a resource is allowed at authentication time — based on signals such as user/group,
device state, location, risk, and MFA. It is an access gate at the front door.

This solution is about what Netskope does with the session after identity is established: it gives
Netskope the same identity and groups (via SCIM) and the same sign-in (via SAML) so Netskope's
inline controls — steering, web/app categorization, SSL inspection, DLP, ZTNA — can be written per
group and enforced continuously across traffic.

The two are layered, not redundant: Conditional Access governs the authentication event; this
integration governs the ongoing network-security policy Netskope applies to the user's traffic. Use
Conditional Access to gate the sign-in (including, optionally, the sign-in to the Netskope app
itself), and use this integration so Netskope can enforce identity-aware policy on everything that
flows after. Conditional Access design itself is out of scope here.

## Why identity-based policy (the case for this integration)
- Per-user and per-group rules. Without identity, Netskope policy is keyed to network location; with
  it, you write rules for "Finance" or "Contractors" that follow them anywhere.
- One sign-in. SAML SSO removes a separate admin/user credential and brings Netskope under the same
  authentication, MFA, and governance as the rest of the estate.
- Automatic, accurate membership. SCIM keeps users and groups current, so policy targets reflect who
  actually works here — including prompt de-provisioning when someone leaves.
- Auditability. Identity-attributed policy and sign-in/provisioning logs make access reviewable.

## Limitations (be honest with buyers)
- Netskope console specifics (exact screens, the SCIM endpoint/token location, where SAML metadata
  is entered) change over time and are deferred to the official Netskope documentation and your
  tenant. This solution names each step and the artifact; you confirm the precise control in Netskope.
- SCIM provisions only the users/groups in scope (assigned to the app); membership is only as good
  as your Entra group hygiene.
- This is identity integration and identity-based policy. It does not, by itself, design your full
  Netskope steering/inspection posture or your Conditional Access policies.
- Provisioning is cycle-based, not instantaneous; expect a short delay between an Entra change and
  its appearance in Netskope.

## The deployment model
> Register/confirm the Netskope enterprise app → configure SAML SSO → enable SCIM provisioning →
> assign and map groups → write identity-based policy → validate on a pilot group → expand to the
> fleet. The standard model: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-network.md`.

## Named artifacts (use these names verbatim everywhere)
Name every artifact `<Purpose> - <Scope> - <Stage>` and reuse the exact name in Entra ID, Netskope,
the scripts, and these docs:

- Enterprise application: `Netskope SSO - Corp - Prod` (the Entra enterprise app representing Netskope).
- SCIM provisioning config: `Netskope SCIM Provisioning - Corp - Prod` (provisioning on that app).
- Pilot group: `Netskope Identity - Pilot - Stage` (Entra security group; pilot scope for SSO + SCIM).
- Production group: `Netskope Identity - Corp - Prod` (Entra security group; full scope after pilot).
- Identity policy: `Identity Steering Policy - Corp - Prod` (the Netskope policy targeted by group).

## 2.1 Netskope tenant with SSO + SCIM support
**Description:** A licensed Netskope tenant whose modules support SAML SSO and SCIM provisioning.
**Why:** SSO and SCIM are the two integration surfaces this solution configures on the Netskope side.
**Verify:** Sign in to the Netskope admin console; confirm SAML SSO and SCIM provisioning are available in your edition (see Netskope documentation).
**Implement:** Engage your Netskope account team to enable the required SSO/SCIM capabilities.

## 2.2 Entra ID rights to register apps and configure provisioning
**Description:** An admin able to create/configure enterprise applications and their provisioning in Entra ID.
**Why:** Creating the SAML configuration and SCIM provisioning requires Application Administrator (or higher) rights.
**Verify:** `https://entra.microsoft.com` → Identity → Applications → Enterprise applications loads and you can create/edit an app; run `NSSSO-Discovery.ps1`.
**Implement:** Assign Application Administrator (or Cloud Application Administrator); reserve Global Administrator for tenant-wide changes.

## 2.3 The Netskope enterprise application in Entra ID
**Description:** An enterprise application `Netskope SSO - Corp - Prod` representing Netskope.
**Why:** It holds the SAML SSO configuration and the SCIM provisioning that connect Entra ID to Netskope.
**Verify:** Entra → Identity → Applications → Enterprise applications → search `Netskope SSO - Corp - Prod`; run `NSSSO-Discovery.ps1`.
**Implement:** Add Netskope from the Entra gallery (or create a non-gallery app) and name it `Netskope SSO - Corp - Prod` (Implementation Step 1).

## 2.4 User and group structure in Entra ID
**Description:** The users and Entra security groups that policy will target (e.g. departments, contractors).
**Why:** SCIM provisions these into Netskope and identity-based policy is written against them; without groups, policy stays generic.
**Verify:** Entra → Groups; the intended security groups exist with the right members; run `NSSSO-Report.ps1`.
**Implement:** Create the required security groups (Entra → Groups → New group → Security) or use `NSSSO-Set-IdentityScopeTargeting.ps1` to build the scope groups.

## 2.5 The Netskope client / steering deployed to endpoints
**Description:** The Netskope client (and steering configuration) on the target devices, delivered via Intune.
**Why:** Identity-based steering and inline policy apply to traffic that the client steers to Netskope under the signed-in identity.
**Verify:** On a managed device, confirm the Netskope client is installed and steering (see Netskope documentation); device is enrolled in Intune.
**Implement:** Deploy the Netskope client and steering config via Intune (deferred to your endpoint-management solution / Netskope deployment docs).

## 2.6 The pilot group (staged rollout)
**Description:** An Entra security group `Netskope Identity - Pilot - Stage` of pilot users for SSO + SCIM.
**Why:** Every rollout is piloted first; this group scopes the SSO assignment and SCIM provisioning during the pilot.
**Verify:** Entra → Groups; `Netskope Identity - Pilot - Stage` exists with a few representative members.
**Implement:** Entra → Groups → New group → Security → `Netskope Identity - Pilot - Stage`, or run `NSSSO-Set-IdentityScopeTargeting.ps1`.

## 2.7 Change control and rollback
**Description:** A change window and a documented rollback (revert SSO to local Netskope admin, pause SCIM, disable the identity policy).
**Why:** Changing how admins/users authenticate and how policy targets users affects live access and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling SSO enforcement / SCIM at scale.
**Implement:** Define the rollback (keep an emergency local Netskope admin, document how to pause provisioning and disable the policy) and a comms plan.

---
## Checklist
- [ ] Netskope tenant supports SAML SSO + SCIM
- [ ] Entra rights to register apps + configure provisioning — `NSSSO-Discovery.ps1`
- [ ] Enterprise app `Netskope SSO - Corp - Prod` present
- [ ] User/group structure in Entra (target groups) — `NSSSO-Report.ps1`
- [ ] Netskope client / steering deployed to endpoints
- [ ] Pilot group `Netskope Identity - Pilot - Stage` created
- [ ] Production group `Netskope Identity - Corp - Prod` created
- [ ] Change window + rollback approved


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Follow these steps **in order**. The Entra ID side is documented click-by-click in the Microsoft
Entra admin center (`https://entra.microsoft.com`). The Netskope side is named at the procedural
level and the exact console controls are deferred to the official Netskope documentation and your
tenant.

> **Model:** Configure SAML SSO, then SCIM provisioning, then identity-based policy — and prove the
> whole chain on `Netskope Identity - Pilot - Stage` before expanding to `Netskope Identity - Corp - Prod`.

> **Artifact names (use verbatim):** enterprise app `Netskope SSO - Corp - Prod`; provisioning
> `Netskope SCIM Provisioning - Corp - Prod`; pilot group `Netskope Identity - Pilot - Stage`;
> production group `Netskope Identity - Corp - Prod`; policy `Identity Steering Policy - Corp - Prod`.

## Step 1 — Create the scope groups and the enterprise application
1. Entra → Groups → New group → Security → `Netskope Identity - Pilot - Stage` (a few representative users). Create.
2. Entra → Groups → New group → Security → `Netskope Identity - Corp - Prod` (the full population). Create.
3. Entra → Identity → Applications → Enterprise applications → New application. Add Netskope from the gallery (or create a non-gallery application) and name it `Netskope SSO - Corp - Prod`. Create.

## Step 2 — Configure SAML single sign-on (Entra side)
1. Entra → Identity → Applications → Enterprise applications → open `Netskope SSO - Corp - Prod` → Single sign-on → select SAML.
2. In Basic SAML Configuration, enter the Identifier (Entity ID) and Reply URL (ACS URL) for your Netskope tenant. The exact values come from Netskope — see the Netskope documentation for its SAML/SSO settings (deferred).
3. Review Attributes and Claims so the user identifier and any group claim Netskope expects are issued (confirm the required claim format in the Netskope docs).
4. In the SAML Signing Certificate section, download the Base64 certificate and copy the Login URL / App Federation Metadata URL — these are handed to Netskope in Step 3.

## Step 3 — Complete SAML on the Netskope side (deferred to Netskope docs)
1. In the Netskope admin console, configure SAML SSO using the Entra Login URL, Entra identifier, and the signing certificate from Step 2 (the exact Netskope screen/fields are deferred to the official Netskope documentation).
2. Provide Netskope's Entity ID and ACS URL back into the Entra Basic SAML Configuration if they were not known in Step 2; save on both sides.

## Step 4 — Assign the pilot group to the application
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Users and groups → Add user/group.
2. Add `Netskope Identity - Pilot - Stage`. Assign. Only assigned users will get SSO and (in Step 5) be provisioned.

## Step 5 — Enable SCIM user/group provisioning (Entra side)
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Provisioning → Get started → set Provisioning Mode to Automatic.
2. Under Admin Credentials, enter the Netskope SCIM Tenant URL and Secret Token. These are issued by Netskope — generate/copy them in the Netskope console (the exact location is deferred to the Netskope documentation).
3. Test Connection; when it succeeds, treat this provisioning configuration as `Netskope SCIM Provisioning - Corp - Prod`.
4. Under Mappings, confirm the user and group attribute mappings (at minimum a stable user identifier and group membership) match what Netskope expects per the Netskope docs.
5. Under Settings, set Scope to "Sync only assigned users and groups," then Save.

## Step 6 — Start provisioning to the pilot scope
1. On the Provisioning page, set Provisioning Status to On.
2. Provisioning runs on a recurring cycle; the first cycle provisions the members of `Netskope Identity - Pilot - Stage` into Netskope. Monitor Provisioning logs for success.
3. Run `NSSSO-Validation.ps1` to confirm the app's SSO is configured and provisioning is enabled; run `NSSSO-Report.ps1` for SSO/SCIM/group coverage.

## Step 7 — Build the identity-based policy (Netskope side, deferred)
1. In Netskope, create `Identity Steering Policy - Corp - Prod` and target it by the provisioned group (the pilot group first), so steering/real-time controls apply by identity rather than by IP (exact Netskope policy screens deferred to the Netskope documentation).
2. Keep this distinct from Entra Conditional Access: this policy governs Netskope's inline controls on the user's traffic, not the authentication gate (see Overview).

## Step 8 — Validate the pilot
1. Have a pilot user sign in to Netskope via SSO; confirm the Entra-issued identity is recognized.
2. Confirm the pilot users/groups appear in Netskope (provisioned by SCIM); confirm `Identity Steering Policy - Corp - Prod` matches by group.
3. Run `NSSSO-Validation.ps1` (SSO + provisioning enabled) and `NSSSO-Report.ps1` (coverage). Complete the Testing Guide pilot gate before expanding.

## Step 9 — Expand to production
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Users and groups → add `Netskope Identity - Corp - Prod`. Assign — SSO and SCIM now cover the full population.
2. Confirm a provisioning cycle completes for the larger scope (Provisioning logs); re-run `NSSSO-Report.ps1`.
3. Extend `Identity Steering Policy - Corp - Prod` (and any per-group policies) to the production groups only after the pilot gate passes.

---
### Order of operations
`Scope groups + enterprise app -> SAML SSO (Entra) -> SAML SSO (Netskope) -> assign pilot -> SCIM provisioning -> start provisioning -> identity policy -> validate pilot -> expand`


---


# 5. Testing Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Run after the pilot is configured (Implementation Step 8) and again after expanding to production.
Artifacts referenced verbatim: `Netskope SSO - Corp - Prod`, `Netskope SCIM Provisioning - Corp - Prod`,
`Netskope Identity - Pilot - Stage`, `Netskope Identity - Corp - Prod`, `Identity Steering Policy - Corp - Prod`.

## Test 1 — SAML SSO configured
**Do:** Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Single sign-on; run `NSSSO-Validation.ps1`.
**Expected:** SSO mode is SAML with the identifier, reply URL, claims, and signing certificate set.

## Test 2 — Pilot user can sign in via SSO
**Do:** As a member of `Netskope Identity - Pilot - Stage`, sign in to Netskope through Entra ID.
**Expected:** Sign-in succeeds and is recorded in the app's Entra sign-in logs; the Entra identity is recognized in Netskope.

## Test 3 — SCIM provisioning enabled and healthy
**Do:** Entra → `Netskope SSO - Corp - Prod` → Provisioning (status On); review Provisioning logs; run `NSSSO-Validation.ps1`.
**Expected:** Provisioning is On (`Netskope SCIM Provisioning - Corp - Prod`), the last cycle succeeded, and scope is "assigned users and groups."

## Test 4 — Pilot users/groups present in Netskope
**Do:** Confirm members of `Netskope Identity - Pilot - Stage` and the group appear in Netskope; run `NSSSO-Report.ps1`.
**Expected:** The pilot users and group are provisioned in Netskope, mirroring Entra ID.

## Test 5 — Identity-based policy targets by group
**Do:** Confirm `Identity Steering Policy - Corp - Prod` matches by the provisioned group and a pilot user's traffic is governed by it (Netskope policy/logs, deferred).
**Expected:** The control applies to the group's members by identity, not by IP/subnet.

## Test 6 — De-provisioning (leaver) reflected
**Do:** Remove a test user from `Netskope Identity - Pilot - Stage`; after a provisioning cycle, run `NSSSO-Report.ps1`.
**Expected:** The user is de-provisioned/disabled in Netskope, so policy no longer applies to them.

## Test 7 — Coverage report
**Do:** Run `NSSSO-Report.ps1`.
**Expected:** A clear view of the enterprise app's SSO mode, provisioning status, and assigned/target groups.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass on `Netskope Identity - Pilot - Stage` and a leaver de-provisions (Test 6) |
| **Production pass** | Tests 1, 3, 4, 7 pass for `Netskope Identity - Corp - Prod` after expansion |


---


# 6. Troubleshooting Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Use `NSSSO-Validation.ps1` / `NSSSO-Discovery.ps1` for the app's SSO + provisioning state,
`NSSSO-Report.ps1` for coverage, and `NSSSO-Remediation.ps1` (default `-WhatIf`) for safe fixes to
the Entra ID scope/assignment. Netskope-side issues are deferred to the Netskope documentation.

## A. SSO sign-in fails
| Symptom | Cause | Remediation |
|---|---|---|
| User can't sign in to Netskope via Entra | User not assigned to `Netskope SSO - Corp - Prod` | Entra → app → Users and groups → add the user's group; or run `NSSSO-Remediation.ps1` |
| "Sign-in but not recognized" | SAML claim mismatch (identifier/format Netskope expects) | Re-check Attributes and Claims against the Netskope SAML requirements (Netskope docs) |
| Certificate/trust error | Wrong or expired signing certificate / metadata | Re-download the Entra signing certificate and re-enter it on the Netskope side |

## B. Locked out of the Netskope admin console
- If SAML is misconfigured after switching the admin console to SSO, use the emergency local/break-glass Netskope admin (see Best Practices) to sign in and correct the SAML config; never enable SSO-only without a verified local admin.

## C. SCIM provisioning not working
| Symptom | Cause | Remediation |
|---|---|---|
| Provisioning Test Connection fails | Wrong SCIM Tenant URL or Secret Token | Re-generate/copy the SCIM endpoint and token in Netskope (deferred) and re-enter under Admin Credentials |
| Users/groups missing in Netskope | Scope is "assigned only" and user/group not assigned | Assign the group to the app; run `NSSSO-Report.ps1`; or run `NSSSO-Remediation.ps1` |
| Provisioning logs show errors | Attribute mapping mismatch | Re-check Mappings against Netskope's required attributes (Netskope docs) |
| Change not appearing | Provisioning is cycle-based | Wait for the next cycle; check Provisioning logs for the last run |

## D. Leaver still has access
- SCIM de-provisions on a cycle; confirm the user was removed from the assigned group and that a provisioning cycle has run. Run `NSSSO-Report.ps1` to confirm the user is disabled/removed in Netskope.

## E. Identity-based policy not matching
- Confirm the group is provisioned into Netskope (`NSSSO-Report.ps1`) and that `Identity Steering Policy - Corp - Prod` targets the provisioned group; group-based policy can only match groups SCIM has delivered. Netskope policy specifics are deferred to the Netskope documentation.

## F. Confusion with Entra Conditional Access
- If a sign-in is blocked at authentication, that is a Conditional Access decision, not this integration. This integration controls Netskope's inline policy after authentication. Review Conditional Access separately (out of scope here); see the Overview for the distinction.

## G. Diagnostics quick reference
```powershell
# Read-only checks (Microsoft Graph side)
.\NSSSO-Discovery.ps1     # app, SAML SSO config, SCIM provisioning status, groups
.\NSSSO-Validation.ps1    # SSO configured + provisioning enabled
.\NSSSO-Report.ps1        # SSO mode, provisioning status, assigned/target groups
```
In Entra: the enterprise app's Sign-in logs (SSO) and Provisioning logs (SCIM) are the primary
evidence. In Netskope: policy hit logs and the provisioned user/group list (deferred to Netskope docs).

## H. When to escalate
If SSO is correctly configured (Test 1), the user is assigned, claims match, provisioning is On and
its last cycle succeeded, but Netskope still does not recognize the identity or apply group policy,
collect the Entra sign-in and provisioning log entries and open a Netskope support case (the
remaining surface is Netskope-side configuration, which is deferred to the Netskope documentation).


---


# 7. Best Practices — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

- **Pilot first, always.** Prove SSO, SCIM, and identity policy on `Netskope Identity - Pilot - Stage` before assigning `Netskope Identity - Corp - Prod` — the single most important practice.
- **Keep an emergency local admin.** Before switching the Netskope admin console to SAML, confirm a working local/break-glass Netskope admin so an IdP outage can't lock you out.
- **Scope provisioning to assigned users and groups.** Set SCIM scope to "sync only assigned users and groups" so Netskope mirrors exactly the population you intend — no accidental fleet-wide provisioning.
- **Provision groups, target policy by group.** Let SCIM carry Entra groups into Netskope and write `Identity Steering Policy - Corp - Prod` against those groups, not individuals — assign once, repeat everywhere.
- **Mind the lifecycle.** SCIM is the mechanism that de-provisions leavers; test a leaver explicitly so access actually follows HR reality.
- **Name everything consistently.** Use `<Purpose> - <Scope> - <Stage>` for the enterprise app, provisioning, groups, and policy, and reuse the names verbatim — it makes audits and the scripts line up.
- **Don't duplicate Conditional Access.** This integration governs Netskope's inline policy on the user's traffic; Conditional Access governs the authentication gate. Layer them; don't try to re-implement one in the other.
- **Confirm claims and mappings early.** Mismatched SAML claims or SCIM attribute mappings are the usual cause of "signed in but not recognized" — verify them against the Netskope documentation before piloting.
- **Watch the logs.** Track the enterprise app's Entra sign-in logs and provisioning logs, plus Netskope policy hits, with `NSSSO-Report.ps1`, and chase failures.
- **Document the rollback.** Record how to revert SSO to local admin, pause provisioning, and disable the identity policy, so any change is reversible within the change window.


---


# 8. Deliverables Summary — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The IdP integration model: SAML SSO, SCIM provisioning, identity-based policy, and how it complements Entra Conditional Access |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, and the named artifacts |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (SAML SSO, SCIM provisioning, identity policy); Entra click-by-click, Netskope deferred |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSSSO-Discovery.ps1` | Reports the Netskope enterprise app, its SAML SSO config, SCIM provisioning status, and group structure (read-only, Microsoft Graph) |
| `NSSSO-Validation.ps1` | Confirms SSO is configured and SCIM provisioning is enabled on the app (read-only, Microsoft Graph) |
| `NSSSO-Report.ps1` | SSO mode, provisioning status, and assigned/target groups coverage report (read-only, Microsoft Graph) |
| `NSSSO-Remediation.ps1` | Safe remediation of provisioning gaps (default `-WhatIf`); ensures the scope groups are assigned to the app (Microsoft Graph) |
| `NSSSO-Set-IdentityScopeTargeting.ps1` | Creates/ensures the pilot and production identity scope groups and their membership (Microsoft Graph) |

> Netskope-side SSO/SCIM specifics (the Netskope SAML screen, the SCIM tenant URL/secret token, and
> Netskope policy) are flagged and deferred to the official Netskope documentation; the scripts act
> on the Entra ID / Microsoft Graph side only.

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Netskope policy that follows the user — Entra ID single sign-on, SCIM-provisioned users and groups,
and identity-based steering and enforcement — proven on a pilot before the fleet.
