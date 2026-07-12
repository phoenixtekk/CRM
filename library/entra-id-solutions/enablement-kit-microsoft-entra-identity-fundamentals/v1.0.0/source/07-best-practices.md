# 7. Best Practices — Enablement Kit: Microsoft Entra Identity Fundamentals

Keep-it-clean guidance for turning a fundamentals kit into a durable, safe operating habit — and
where to go next once the grounding is in place.

## Learn on a sandbox, never on production

- **Practice on cloud-only, clearly named test objects.** Prefix every lab object (`Lab-EntraFund-`,
  `Grp-EntraFund-`) and keep them in the `contoso.onmicrosoft.com` initial domain. A new admin should
  never learn "what does this button do" on a real user's account.
- **Read before you write.** Most identity mistakes are one irreversible change made without
  understanding. Open, read, and explain an object first (Labs 2, 4, 5 are read-only by design), then
  change only the sandbox copy.
- **Clean up when you are done.** Delete sandbox objects (or keep a labelled set for re-runs). Stale
  test users and half-configured apps are their own small risk.

## Treat the identity plane as high-risk

- **Guard Global Administrator.** It is all-powerful — keep the count tiny, prefer least-privilege
  roles (User Administrator, Helpdesk Administrator, Security Reader) for day-to-day work, and make
  elevation deliberate (PIM, where licensed).
- **Keep break-glass sacred.** Two cloud-only emergency accounts, excluded from Conditional Access,
  credentials stored securely. Teach the habit in the report-only CA lab so it is second nature before
  anyone builds an enforced policy.
- **Report-only before enforce, always.** The one CA policy this kit builds is **report-only** — it
  evaluates and logs but cannot block. Carry that discipline into every real policy you build later:
  report-only, validate, then enforce in waves.

## Build the right mental model

- **Tenant -> identities -> groups -> roles.** Hold the hierarchy in your head: the tenant is the
  boundary, identities are who signs in, groups are how you manage them in bulk, roles are who can
  administer what. Almost every task maps onto that model.
- **Registration is the definition; enterprise app is the instance.** The single most common
  fundamentals gap. An app registration defines an app; the enterprise application (service principal)
  is what users sign in to and what you assign and govern.
- **Target groups, not individuals.** Assign licenses, app access, and Conditional Access to security
  groups so the design is legible and scalable — never a pile of per-user assignments.

## Verify, don't assume

- **Verify licensing before you promise a feature.** Conditional Access needs **P1**; risk policies
  and PIM need **P2**; Governance, Global Secure Access, and Verified ID are further add-ons. Check
  **Billing -> Licenses** (or `EKIDFUND-Discovery.ps1`) — *bundles change and differ by cloud
  (Commercial vs GCC / GCC High)*.
- **Verify portal navigation and preview status.** Microsoft renames blades and ships features in
  preview. Treat the click-paths in this kit as current-at-writing and confirm against your tenant.

## Run it as a program, not a one-off class

- **Re-run for new hires.** The take-home runbook, glossary, and knowledge-check make onboarding a new
  admin repeatable — the sandbox and scripts are reusable.
- **Keep the runbook current.** As your tenant evolves (new domains, new roles, new apps), update the
  take-home runbook so it stays your team's fundamentals reference.

## Where to go next

With the fundamentals in place, the natural next steps in this catalog are:

- **Zero Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access Integration** — design
  and roll out a real, enforced CA baseline (this kit built only a report-only teaching policy).
- **Enablement Kit — MFA & Conditional Access (EKMFACA)** — go deeper on MFA methods, CA design
  patterns/personas, and safe report-only/What-If testing as a team-enablement follow-on.
- **Privileged Identity Management (ENTPIM)** — just-in-time, approval-gated admin elevation.
- **Passwordless & Passkey (ENTPASSKEY)** — deploy phishing-resistant MFA.
- **Identity Governance & Access Reviews (ENTIGA)** — periodic access certification and entitlement
  management.
- **Hybrid Identity** and **Enterprise-App & Service-Principal Governance** — extend the grounding to
  AD-to-Entra sync and the app estate.
