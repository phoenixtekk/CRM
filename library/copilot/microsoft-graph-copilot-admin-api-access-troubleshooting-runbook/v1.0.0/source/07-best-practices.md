# Best Practices — when to depend on beta vs wait for GA

The hardest decision this runbook leaves you with is not *"how do I make the call work"* but *"should I
build on it."* These practices answer that.

## 1. Treat `/beta/copilot/admin/*` as interim, not production

Microsoft's own notice on every beta page is unambiguous: *"APIs under the `/beta` version are subject
to change. Use of these APIs in production applications is not supported."* That is not boilerplate —
the Copilot admin surface has already changed its **license requirement** (from *"no additional
license"* to *"requires Microsoft Agent 365"*) and its **documented-vs-enforced permission model**
(application permissions listed but rejected at runtime) during preview. Build on beta only for
**diagnostics, one-off pulls, or interim automation you can afford to have break**.

## 2. Prefer GA (`/v1.0`) or the admin center for anything you depend on

Before you wire a beta call into a scheduled job, check for a supported equivalent:
- a **GA (`/v1.0`) path** for the same resource (the package catalog and usage reports both have GA
  paths);
- the **Microsoft 365 admin center → Agents** export;
- **Microsoft Purview** audit data.
If a GA or admin-center path delivers the data, use it — even if the beta call is momentarily more
convenient.

## 3. Use delegated auth with a least-privilege admin role

These endpoints require a **signed-in user** (application-only tokens are rejected). Sign in as an
account holding **AI Administrator** — the least-privilege role for Copilot/agent administration —
rather than Global Administrator. Reserve Global Administrator for genuine tenant-wide changes, and use
**PIM** to activate the role only when running the diagnostic.

## 4. Request only the scopes you need, and name them exactly

Ask for `CopilotPackages.Read.All` (read) rather than `ReadWrite` unless you must write; use
`CopilotPolicySettings.Read` for policy reads. Never request `ReadWrite`/write scopes "just in case" —
they widen consent and audit exposure. Get the scope names character-exact from the current reference.

## 5. Wrap every beta dependency so it fails safe

If you must depend on a beta call, isolate it behind one function that:
- checks the **HTTP status** and never assumes a shape — parse defensively, tolerate new/removed fields;
- treats a `404`/`403` as *"capability unavailable"* and falls back to the supported path automatically;
- logs the **`request-id`** on every failure for support cases;
- carries a **doc-reference + last-verified date** so you know when to re-check.
A single wrapper means a Microsoft-side change touches one place, not your whole codebase.

## 6. Pace your calls and honor throttling

Cache results, page with `$top`/`$filter`, and avoid tight retry loops. On `429`, **honor
`Retry-After`**; if absent, use exponential backoff. Preview endpoints have tighter, less predictable
burst capacity than GA — assume less headroom, not more.

## 7. Plan for Government and sovereign clouds explicitly

The Copilot admin beta endpoints are **Global-only** today (not GCC High / DoD / 21Vianet). If any of
your tenants are sovereign, design the **fallback as the primary** path there from day one — do not
assume parity, and re-verify the per-endpoint national-cloud table before each release. *(Beta — cloud
availability can expand; verify against current Microsoft documentation.)*

## 8. Re-verify on a schedule, and record what you excluded

Preview behavior drifts. Keep a short register of every Copilot admin endpoint you use, its version,
its scope/role/license requirement, its cloud availability, and the **date you last verified** it
against Microsoft Learn. When you exclude an endpoint as a genuine limitation (Branch J), record the
source and date so you re-check when it graduates to GA.

## 9. Keep the diagnostic evidence

Retain `CPADMDX-Findings.json` from each investigation. It is your fastest way to reopen a Microsoft
support case with the exact `request-id`, and your record of what the endpoint did (and did not) return
on a given date — invaluable when the beta shape changes underneath you.

## 10. Don't reverse-engineer undocumented routes

If the only path that returns what you want is **not on any current Microsoft Learn reference page**,
treat it as **not for third-party use** and do not build on it. An undocumented route can be removed
without notice and may violate the API terms of use. Use the supported fallback and, if the capability
matters to you, file the feature request.
