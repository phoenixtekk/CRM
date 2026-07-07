# Best Practices

Durable practices for running the SAML app-integration factory as a program, not a series of
one-off projects.

## Standardize the pattern, then never deviate silently

- Onboard **every** app through `SSO Onboarding Pattern – SaaS – v1`. If an app genuinely needs a
  deviation (unusual NameID, SP-init only, no provisioning), record the deviation **in the catalog** —
  the exception is documented, not invisible.
- Keep the pattern versioned. When you improve it (`v2`), migrate apps deliberately, not by drift.

## Assign by group, never by user

- Turn apps ON for `Assignment Group – <App> – Users` only. **Never** assign to "All users" or a broad
  OU as a shortcut — that severs the link between directory lifecycle and app access and is the #1
  finding the guardrail check catches.
- Keep assignment groups **governed by the source of truth** (Global Requirement 4). A hand-edited group
  is an ungoverned access grant.
- One group per app (or per access role within an app) keeps access reviews legible.

## Make provisioning follow assignment

- Scope auto-provisioning / SCIM to the **same** `Assignment Group – <App> – Users` that grants access,
  so "in the group" means both *can sign in* and *has an account*. Divergence creates orphaned accounts.
- Always test **deprovisioning** (Test 5), not just creation. Offboarding is where orphaned SaaS accounts
  and license waste hide.
- For apps without provisioning, record **manual/JIT** in the catalog and put their offboarding on the
  leaver checklist explicitly.

## Treat the catalog as the system of record

- `App Catalog – Federated SaaS – v1` is the audit surface: type, attribute map, group, provisioning
  method, owner, cert expiry, status. Update it as part of "done" for every app — a live app not in the
  catalog does not exist for governance.
- Use the catalog to drive access reviews and offboarding verification, and to answer "which apps does a
  leaver still have?" from group membership.

## Manage certificates proactively

- Record Google's **IdP signing-certificate expiry per app** and rotate **before** expiry, in a planned
  window — an expired cert breaks every app that pinned it. Rehearse rotation (Test 8) at least once.
- Prefer metadata-URL exchange over pasted certs where the app supports it, so rotation propagates
  automatically.

## Least privilege for admins and automation

- Grant app-management via a **custom admin role** (Web and mobile apps privilege) rather than blanket
  super-admin.
- Run the tools with **read-only ADC** or a service account with **domain-wide delegation limited to the
  read-only Directory scopes** they need. **Never** commit a service-account key; never hardcode secrets.
  Keep write actions (the config helper's file writes) `--dry-run` by default.

## Pilot-first, with a real rollback

- Every app is validated against `Pilot Cohort – SSO Factory – Pilot` before full turn-on. Keep the
  app's prior sign-in method available until it passes Gate 3, so rollback is real, not theoretical.
- Turn apps on for their full audience only inside an approved change window.

## Design security controls to your edition — and verify

- Session length, re-authentication, and **context-aware access** (BeyondCorp Enterprise) on app sign-in
  depend on your Cloud Identity / Workspace edition and may be add-on or preview features. **Verify
  availability in your tenant** before you commit to them in the pattern; don't assume a control exists.

## Keep security and compliance in the loop

- Have security review `SSO Onboarding Pattern – SaaS – v1` and sign off on regulated-data apps before
  onboarding (Global Requirement 6). Legal/records determinations stay with those functions; you supply
  the technical method and the catalog as evidence.
