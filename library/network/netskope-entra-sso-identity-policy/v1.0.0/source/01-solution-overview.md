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
