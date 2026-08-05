# Troubleshooting — edge cases and gotchas

The **Diagnostic Runbook** (`03-implementation.md`) is the main symptom tree for a blocked call. This
file covers the harder edges: getting the **tooling and consent** to cooperate, and the three
preview-specific traps — **throttling storms**, **tenant-not-enabled flighting**, and
**undocumented-endpoint deprecation** — that masquerade as ordinary errors.

> Reminder: this is a **beta** surface. Any behavior below can change without notice; re-verify against
> current Microsoft documentation before treating a workaround as permanent.

---

## Tooling, sign-in, and consent

**`Connect-MgGraph` fails or the module is missing.**
- Install: `Install-Module Microsoft.Graph -Scope CurrentUser` (and `Microsoft.Graph.Beta` for beta
  cmdlet coverage). Confirm with `Get-Module Microsoft.Graph -ListAvailable`.
- An **old SDK** can lack newer environments or cmdlets — `Update-Module Microsoft.Graph`.

**The consent prompt says an administrator must approve.**
- The Copilot admin scopes require **admin consent**. Have a Global Administrator grant it once for
  **Microsoft Graph Command Line Tools** (appId `14d82eec-204b-4c2f-b7e8-296a70dad67c`) or your custom
  app. See Runbook **Branch D**.

**You consented, but the scope is still not in the token.**
- You may have consented in a **different cloud** or **different tenant**. Confirm
  `(Get-MgContext).Environment` and `.TenantId`. Reconnect explicitly:
  `Connect-MgGraph -Environment <cloud> -TenantId <id> -Scopes ...`.

**You are sure you have the permission but still get 403.**
- Nine times out of ten this is a **role** gap, not a scope gap (Runbook **Branch E**), or an
  **app-only token** where delegated is required (**Branch B**). Run `CPADMDX-Resolve-Scopes.ps1` — it
  separates the two.

**`jwt.ms` shows the scope but the call still 403s.**
- The scope is present but the **user lacks the admin role**, or the **feature is not flighted** to
  your tenant, or you are in a **Gov cloud** where the endpoint does not exist. Work Branches E → F →
  R8 in that order.

---

## Throttling storms (429)

**Every call suddenly 429s, not just heavy ones.**
- You (or another script/admin on the same tenant) tripped a **dynamic** throttle. Graph throttling
  varies by app, tenant, workload, endpoint, and time of day; a burst earlier can throttle you now.
- **Honor `Retry-After`** exactly. If absent, back off exponentially (5s→10s→20s→…, capped). Do **not**
  retry in a tight loop — it extends the penalty window.

**A batch job throttles where single calls do not.**
- Reduce concurrency and add pacing between requests; page with `$top`/`$filter` instead of pulling
  everything; cache results you will reuse. Preview endpoints have **less** burst headroom than GA —
  size the job accordingly.

**429s only in one cloud or one tenant.**
- Throttle budgets are per-tenant/per-app. A shared automation account across many tenants amplifies
  throttling — give each tenant its own pacing.

---

## Tenant-not-enabled (flighting) — the 403/404 that is not your fault

**The call is provably correct (path, version, scope, role, consent, cloud) and still 403s or 404s.**
- The preview feature has **not rolled out to your tenant**. This is Microsoft-side flighting; there is
  **no self-service switch**. Multiple tenants report exactly this on the package-catalog endpoint.
- **Confirm** by reproducing the same call in a tenant known to be enabled (or Graph Explorer with a
  consented admin). Success there + failure for you = flighting, not misconfiguration.
- **Cross-check the UI:** if the Microsoft 365 admin center **Agents / Agent Registry** surface is
  absent in your tenant, the mirroring API is likely not flighted either.
- **Action:** wait for the rollout, or open a Microsoft support case for eligibility; meanwhile use the
  supported fallbacks (Runbook Branch F/J). Record the `request-id` and date in `CPADMDX-Findings.json`.

**A 404 that is really "not enabled."**
- A `404` is not always a typo. If the path matches the current reference **character-for-character**
  on a version that hosts it, and it still 404s, suspect **flighting or cloud unavailability** rather
  than a wrong route (Runbook Branch H → F/R8).

---

## Undocumented-endpoint deprecation and drift

**A path that worked last month now 404s or returns a different shape.**
- Beta paths can be **renamed, moved to GA, or removed** without notice. Re-check the current reference
  page: the resource may now live on `/v1.0`, or a property may have been renamed/removed.
- Your wrapper should **tolerate missing/renamed fields** and fall back automatically (Best Practices
  §5). If you hard-coded the shape, that is the bug to fix — not the endpoint.

**A blog or internal snippet uses a path you cannot find in Microsoft Learn.**
- Treat an **undocumented** route as **not for third-party use**: it can vanish without notice and may
  violate the API terms. Do **not** build on it and do **not** fabricate its response shape. Use the
  supported path (GA endpoint, admin-center export, Purview audit) and file a feature request if the
  capability matters.

**The license/permission requirement changed under you.**
- The package-catalog endpoint moved from *"no additional license"* to *"requires Microsoft Agent
  365,"* and lists application permissions that are rejected at runtime. Always read licensing and
  permissions from the **current** reference page, not memory or an older doc. (**The customer has
  ruled out Agent 365 licensing as the blocker** — confirm and exclude via Runbook Branch G, then move
  on.)

---

## Policy-settings-specific responses (not failures)

If you are probing `copilot/admin/policySettings/{id}`, several non-200 responses are **by design**,
not bugs:
- **`200` with `value: null` (and/or `policyId: null`)** — the setting is not configured / no tenant
  policy exists. Expected.
- **`404` `unsupportedSetting`** — the setting **id** is not in the supported list. Fix the id, not the
  path.
- **`422` `groupScopedSettingNotSupported`** — the setting is configured at **group** level; this
  endpoint returns **tenant-level** only.
- **`502` `tooManyGroupPolicies`** — the tenant exceeds the supported number of group-level policies.
Read these from the error `innerError.code`, not just the status number.

---

## When the method itself stalls

- **You fixed a gate and it still fails.** You probably fixed a **later** gate while an **earlier** one
  is still failing. Return to Step 0, re-read scopes/roles/auth/cloud in gate order, and fix the
  **first** failing gate.
- **Results are intermittent across tenants or accounts.** Compare a working tenant/account's
  `CPADMDX-Findings.json` against the failing one — the difference (cloud, role, flighting, scope) is
  your cause.
- **Nothing supported returns the data.** Accept it as a genuine limitation (Runbook Branch J), record
  the source page and date, and set a re-check for when the API graduates to GA.
