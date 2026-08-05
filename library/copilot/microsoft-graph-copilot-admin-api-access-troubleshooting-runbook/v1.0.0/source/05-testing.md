# Testing & Validation

These gates prove two things: (1) the previously-blocked Graph Copilot admin call **now succeeds**, and
(2) the harder question — whether the **data you need is actually exposed** by the endpoint, or whether
you must use a supported fallback. Run them after applying a fix in `03-implementation.md`. Each gate
has an explicit **PASS / FAIL** criterion; record the result in
**`CPADMDX-Diagnostics\CPADMDX-Findings.json`**.

> Run every test as the **delegated admin** you intend to use in production of the automation, in the
> **cloud** you actually target. Testing as a Global Administrator in Global and then running as a
> lesser account in GCC High invalidates the result.

---

## Gate T1 — The call authenticates and authorizes (200, not 4xx)

**Procedure:**
1. `.\CPADMDX-Preflight.ps1 -Environment <cloud>` — confirm `AuthType = Delegated`, the required scope
   is listed, and an admin role (AI Administrator / Global Administrator) is present.
2. `.\CPADMDX-Probe-Endpoint.ps1 -Environment <cloud> -Path 'copilot/admin/catalog/packages' -ApiVersion beta`

**PASS:** HTTP **200 OK**. For a policy-setting probe, a **200 with `value: null`** also passes — it is
the documented response for an unconfigured setting, not an error.

**FAIL:** Any `401/403/404/429`. Return to the branch the probe names and fix the **first** failing
gate. Do not proceed to T2 until T1 passes.

---

## Gate T2 — The response contains the data you actually need

A 200 is necessary but not sufficient — the endpoint may return an object that **omits the field or
relationship** you came for.

**Procedure:**
1. For the package list: confirm the collection is non-empty and each item carries the properties you
   need (`id`, `displayName`, `type`, `publisher`, `isBlocked`, `supportedHosts`, `availableTo`,
   `deployedTo`, `elementTypes`).
2. For a specific package: `.\CPADMDX-Probe-Endpoint.ps1 -Path 'copilot/admin/catalog/packages/{id}'`
   and confirm the detail object includes the fields you require (e.g. `elementDetails`,
   `allowedUsersAndGroups`).
3. If the field you need is **absent from every documented response**, that is a **product limitation**
   (Branch J), not a fix-it-later item.

**PASS:** The 200 payload contains the specific data your use case needs.

**FAIL / LIMITATION:** The call succeeds but the needed data is not present in the documented schema →
record it as **Branch J** and proceed to T4 (prove the fallback).

---

## Gate T3 — The result is repeatable and correctly scoped to your cloud

**Procedure:**
1. Run the probe **three times**; confirm consistent 200s (a flaky mix of 200/403 suggests
   intermittent flighting or throttling, not a stable capability).
2. Confirm `(Get-MgContext).Environment` and the script's printed **GraphHost** match your intended
   cloud (`graph.microsoft.com`, `graph.microsoft.us`, or `dod-graph.microsoft.us`).
3. In a **Gov** tenant, confirm you are **not** silently succeeding against a Global endpoint with a
   mismatched token.

**PASS:** Three consistent 200s against the correct cloud host.

**FAIL:** Inconsistent results → treat as flighting/throttling (Branch F/R8/I); do not build a
dependency until stable.

---

## Gate T4 — A supported fallback returns the data (proves the exit path)

Whether or not the beta call succeeded, prove that a **supported** path can deliver the data — this is
your production-safe option and your Gov-cloud option.

**Procedure:**
1. `.\CPADMDX-Test-Fallbacks.ps1 -Environment <cloud>`.
2. Confirm at least one supported path returns the data you need:
   - **GA usage reports** (`/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail`) returns rows
     for adoption/usage; **or**
   - **GA package catalog** (`/v1.0/copilot/admin/catalog/packages`) returns the inventory where
     offered; **or**
   - the **Microsoft 365 admin center → Agents** export / **Purview audit** path yields the equivalent
     data (manual confirmation).

**PASS:** A supported fallback demonstrably returns the needed data in your cloud.

**FAIL:** No supported path returns it → the capability genuinely does not exist for you yet; document
it, cite the source page and date, and set a re-check reminder for when the API graduates.

---

## Gate T5 — Evidence is captured

**Procedure:** `.\CPADMDX-Report-Findings.ps1` and confirm
`CPADMDX-Diagnostics\CPADMDX-Findings.json` and `CPADMDX-Findings.txt` exist and record the failing
call, the resolved branch, and the recommended action.

**PASS:** Both findings files exist and name a resolved branch.

**FAIL:** Re-run the diagnostic scripts so their JSON outputs exist, then re-run the report.

---

## Exit criteria

You are done when **T1 passes** (the call works) **and** either **T2 passes** (the beta endpoint gives
you the data) **or** **T4 passes** (a supported fallback does), **T3** confirms stability in the correct
cloud, and **T5** has captured the evidence. If only T4 passes, your production path is the fallback —
apply the dependency guidance in `07-best-practices.md`.
