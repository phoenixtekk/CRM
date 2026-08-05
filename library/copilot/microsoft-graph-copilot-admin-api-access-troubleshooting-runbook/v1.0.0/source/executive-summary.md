# Executive Summary

**The problem.** Your team tried to call a Microsoft Graph **Copilot admin (beta)** endpoint — most
often `GET /beta/copilot/admin/catalog/packages/{id}` to read the agent catalog — and the request was
**blocked**. The error (a 401, 403, 404, or 429) looks the same for a dozen unrelated causes, and the
preview documentation does not reliably tell them apart. Time is lost guessing between a missing
permission, a missing admin role, an app-vs-user token problem, an ungranted consent, a preview that
has not reached your tenant, a cloud where the feature does not exist, a license prerequisite, a
wrong path, or a capability that simply is not there yet.

**The solution.** This is a **branch-based troubleshooting runbook** for the entire
`/beta/copilot/admin/*` surface. It starts with a Step-0 fact-finding pass, then routes your exact HTTP
status and error text to **one named root cause** (Branches A–J), each with how to *confirm* it, the
*fix or supported workaround*, and how to *re-validate*. Five read-only PowerShell scripts do the
diagnosis for you: they report your token scopes and admin roles, probe the endpoint and decode the
real error, resolve *have-vs-need*, try the supported fallbacks, and write a single findings file you
can attach to a Microsoft support case.

**Why it is trustworthy.** Every endpoint path, permission scope, admin role, error meaning, license
requirement, and cloud-availability fact was **verified against Microsoft Learn on the build date** —
the Package Management API reference, the policy-settings reference, the Copilot APIs overview and
security pages, and the Graph permissions, throttling, and national-cloud references. Because this is a
**preview** surface that changes without notice, every volatile claim is explicitly flagged *"verify
against current Microsoft documentation."* The runbook never invents an endpoint, scope, role, or
response shape — where the honest answer is *"the data is not exposed"* or *"do not depend on this,"* it
says so and points you to the supported path.

**Key facts your team will act on immediately:**
- These admin endpoints require a **signed-in user (delegated)**; **application-only tokens are
  rejected** with *"User context is required"* — a leading cause of the 403 people cannot explain.
- **Scope and admin role are separate gates.** A token with `CopilotPackages.Read.All` but a user
  without **AI Administrator / Global Administrator** still gets 403.
- The endpoints are **Global-only** today — **not available in GCC High, DoD, or 21Vianet** — so in a
  Government tenant the fallback is the primary path.
- Microsoft's current docs state the package catalog now **requires a Microsoft Agent 365 license** (a
  change from the original announcement). **Your team has already ruled this out** as the blocker; the
  runbook confirms and excludes it, then moves to the real cause.
- **Beta is "not supported for production."** The runbook's decision guidance keeps you on GA
  (`/v1.0`), admin-center export, or Purview audit for anything you depend on.

**The outcome.** A blocked Graph Copilot admin call turned into a single named cause and fixed — or,
where the beta surface cannot be relied on, a proven, supported alternative delivering the data you
need. A repeatable method and scripts your team keeps and reuses on the next preview-API investigation.
