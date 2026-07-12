# 7. Best Practices — Migrate & Protect Applications with Entra

## Migration planning
- **Prioritize by real usage.** Drive the plan from the **AD FS application activity** report, not a stale
  spreadsheet — migrate the apps people actually use first, and retire dormant relying parties outright.
- **One app of each type first.** Prove the pattern on one AD FS app, one App Proxy app, and one SCIM app
  against `ENTAPPMIG-Pilot` before you scale. Waves after that are repeats of a proven recipe.
- **Reproduce claims deliberately.** Map each AD FS **claim rule** to Entra **claims mapping** and compare
  the actual token — silent claim drift is the top cause of "it authenticated but the app rejected me."

## AD FS cutover safety
- **Keep AD FS live until validated.** Never delete a relying party at cutover — **disable** it so it is an
  instant rollback, and only remove it after a clean soak period.
- **Cut over in a change window** with the app owner on hand, and preview first with
  `ENTAPPMIG-Cutover.ps1` (report-only). Repointing federation is a real change to live sign-in.
- **Have the rollback written down** per app: the exact endpoint/metadata to revert to AD FS. A rollback you
  have to improvise at 2 a.m. is not a rollback.

## Publishing on-prem apps
- **Pre-authenticate in Entra.** Always set App Proxy **pre-authentication = Microsoft Entra ID** so
  Conditional Access applies **before** the app is reached — passthrough publishing throws that away.
- **Two connectors per group.** Run App Proxy connectors in pairs in a **connector group** for HA, with
  clean internal DNS/route to the app.
- **Pick the right publishing path.** **Application Proxy** is for **web** apps with browser SSO; for
  **non-web/TCP** apps or full network ZTNA, publish via **GSA Private Access** (the *Entra Global Secure
  Access* solution) instead. Don't force a TCP app through a web proxy.

## Provisioning (SCIM)
- **Prove it on demand first.** Use **provision on demand** for one pilot user to confirm create/update
  before enabling the full job — then scope the job to **assigned users/groups only**.
- **Deprovisioning is the point.** Confirm that removing a user from scope **disables/deprovisions** them in
  the app — an SCIM job that only creates accounts leaves the classic leaver gap open.
- **Keep the token in the app, not in code.** The SCIM secret lives only in the provisioning config — never
  in scripts, source, or docs.

## Protection & governance
- **Conditional Access on every migrated app.** As you migrate an app, add it to
  `ENTAPPMIG – CA – MigratedApps – *` — an app off AD FS but with no CA is only half-protected.
- **Report-only, then enforce.** Ship CA policies as report-only, read the Insights, then turn them on.
  Always **exclude break-glass**.
- **Recertify with access reviews.** Fold every migrated app into
  `ENTAPPMIG – Review – MigratedApps – Quarterly` so assignments are re-justified over time.

## Change safety & hygiene
- **Pilot-first, always** — prove the four gates on `ENTAPPMIG-Pilot` before cutover or expansion.
- **Least privilege for operators** — run day-to-day work as **Application Administrator**; reserve Global
  Administrator for the one-time federation/cutover changes.
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` with least read
  scopes; write actions are gated behind an explicit `-Commit` with a `-WhatIf` preview — never embed tokens.

## Where to go next (adjacent catalog areas)
- **Cloud Identity as Enterprise IdP — SAML App Integration Factory** — the complementary solution for
  **SSO onboarding at scale** (integrating many SaaS SAML/OIDC apps). Use it once AD FS is retired and you
  are onboarding new apps as a factory; use **this** solution to get **off AD FS** and **publish on-prem**.
- **Entra Global Secure Access** — publish **non-web/TCP** apps and deliver network ZTNA via **Private
  Access**, the alternative to Application Proxy for those cases.
- **Zero Trust — Conditional Access Baseline** — the full CA policy set the migrated apps plug into.
- **Entra ID Governance — Access Reviews & Entitlement Management** — govern app entitlement at scale.
