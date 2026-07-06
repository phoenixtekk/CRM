# 7. Best Practices — Enterprise Integration Patterns

- **Standardize on the catalog — one way to connect.** Every new integration picks a pattern (P1–P7),
  it does not invent one. Reuse is the whole point; a named pattern applied consistently beats seven
  clever one-offs.
- **One source of truth per object.** Master each user, group, and app account in exactly one directory
  and synchronize outward (SCIM push P2 **or** GCDS pull P3, never both). Two masters is the drift-and-conflict anti-pattern.
- **Federate authentication everywhere.** Prefer SAML/OIDC SSO to the enterprise IdP for every app that
  supports it (P1/P5). Local app passwords are snowflakes and credential-sprawl risk — design them out.
- **Drive authorization from groups and claims.** Carry roles in the assertion/token and map groups →
  app roles, so entitlements follow directory membership and reviews, not per-user local admin.
- **Least privilege on API and data access.** Use OAuth client-credentials / workload identity
  federation with scoped access (P7); never grant `*.ReadWrite.All`-style scopes "to be safe," and
  prefer read-only where the integration only reads.
- **Kill credential sprawl.** No shared service accounts, no long-lived secrets, no passwords in
  scripts. Prefer short-lived, federated credentials and give every service identity a named owner.
- **Automate the full lifecycle — including de-provisioning.** Provisioning that creates accounts but
  never removes leavers is worse than none; test the remove path (P2/P3/P6), not just the add path.
- **Verify third-party app capabilities in the vendor's docs and your tenant.** Whether an app supports
  SCIM from a given IdP, only SAML, or only a legacy connector changes over time — confirm it, don't
  assume it. The catalog names the pattern; the app decides what it supports.
- **Document coexistence with a cutover order.** During M365↔Google overlap, name the IdP owner per
  workload and the order (identity → SSO → provisioning → mail/data) under change control.
- **Stage and preview every change.** Federation, provisioning, and remediation changes can break a
  live integration — pilot on a scoped app set, run remediation in `-WhatIf` first, confirm with the
  owner, then apply to the reviewed integration only.
- **Keep a break-glass path outside SSO.** Always retain cloud-only emergency admins (Entra) and a
  Google super-admin that can sign in outside federation, so an SSO change can never lock you out.
- **Make conformance recurring, not one-time.** New integrations appear constantly; re-run discovery
  and the coverage/exception report on a cadence so snowflakes are caught and classified as they emerge.
- **Maintain the Integration-Patterns reference doc.** Keep the catalog, the IdP-direction table, the
  capability matrix, and the exception register current — it is the estate's source of truth.
