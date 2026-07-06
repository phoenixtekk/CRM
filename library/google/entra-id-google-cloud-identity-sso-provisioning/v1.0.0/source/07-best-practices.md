# 7. Best Practices — Entra↔Google SSO & Provisioning

- **Decide the source of truth first — one master per object.** Before touching a console, state which
  directory masters users and groups (Entra via SCIM, or AD via GCDS) and provision outward from it.
  **Never** let SCIM push and GCDS pull master the same objects — two sources of truth is the
  drift-and-conflict anti-pattern.
- **Provision before you enforce SSO.** SSO federates a sign-in into an account that must already
  exist. Provision (or verify accounts) first, then enforce federation — otherwise users authenticate
  successfully and land nowhere.
- **Match the identifier on both sides.** The SAML **NameID must be the user's email (user.mail)** and
  must equal the Google account's `primaryEmail` on a **verified custom domain**. A mismatched NameID —
  or a `*.onmicrosoft.com` UPN — is the number-one cause of "cannot sign in." Verify the domain in both
  Entra and Google.
- **Keep a break-glass Google super-admin outside SSO — always.** Set that account's SSO profile to
  **none** so a federation change can never lock admins out. Keep two cloud-only Entra emergency admins
  excluded from broad conditional-access policies too.
- **Pilot on a named OU/group, then expand in batches.** Assign the Google SSO profile and the
  provisioning scope to the pilot only; set everyone else to **none** until the gate passes. Expand OU
  by OU, not all at once.
- **Test the leaver path, not just the joiner path.** Provisioning that creates accounts but never
  removes them is worse than none. Prove that removing a user from scope (or disabling them) actually
  **de-provisions/suspends** them in Google — every cycle.
- **Treat JIT as convenience, never as lifecycle.** Just-in-time SSO creation is handy, but it does not
  de-provision leavers. Use SCIM push or GCDS for the real lifecycle.
- **Drive Google authorization from groups, not per-user admin.** Provision groups and memberships, and
  let Google OU/group membership decide access and admin roles — so entitlements follow directory
  membership and reviews, not hand-set per-user grants. (For privileged Google groups, consider Entra
  **PIM for groups** for just-in-time membership.)
- **Scope provisioning tightly and watch the quarantine channel.** Use assignment or an attribute
  scoping filter so only intended users flow; enable Entra provisioning **notification emails**,
  **accidental-deletion prevention**, and a **quarantine** address, and act on quarantine promptly.
- **Run GCDS off the domain controller and simulate before you sync.** Put GCDS on a separate host with
  LDAP access to AD; always run a **simulation** and review the proposed changes before a real sync.
- **Stage every identity change under change control.** Federation and provisioning changes are
  high-impact and can lock out or orphan users. Change-window them, keep the rollback ready (SSO profile
  → none; **Stop provisioning**), and confirm break-glass before each change.
- **Make coverage recurring, not one-time.** Re-run discovery, validation, and the coverage/exception
  report on a cadence so new users, new OUs, and any drift are caught and classified as they appear.
- **Maintain the identity reference doc.** Keep the source-of-truth statement, the domain/NameID
  mapping, the SSO-profile assignment plan, the provisioning scope, and the exception register current —
  it is the identity foundation's source of truth for coexistence and migration to build on.
