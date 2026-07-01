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
