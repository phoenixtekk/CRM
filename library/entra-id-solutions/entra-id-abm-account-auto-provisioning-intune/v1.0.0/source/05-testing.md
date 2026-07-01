# 5. Testing Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Run after provisioning is on for the pilot and one device per model is enrolled (Implementation
Steps 13–14), and again after each expansion wave. Use **`ABMPROV-Discovery.ps1`** /
**`ABMPROV-Validation.ps1`** / **`ABMPROV-Report.ps1`** to back each test with data.

## Test 1 — Federation is active for the domain
**Do:** Have a pilot user sign in to an Apple service with their work email; confirm the sign-in
redirects to **Entra** and accepts their Entra credentials (and MFA).
**Expected:** Authentication completes via Entra ID — no separate Apple password prompt.

## Test 2 — Existing-Apple-ID conflicts are clear for pilot users
**Do:** Re-check the ABM domain-capture / conflict report for the pilot users (deferred to Apple docs).
**Expected:** No conflicted personal Apple IDs remain for in-scope pilot users.

## Test 3 — Managed Apple IDs auto-provision (SCIM)
**Do:** Entra → `Apple Business Manager – Federation – Prod` → **Provisioning → Provisioning logs**;
run **`ABMPROV-Validation.ps1`** for the pilot users.
**Expected:** Pilot users have a **Managed Apple ID provisioned** (provisioning job healthy; logs show
success for the pilot group).

## Test 4 — Just-in-time backfill works
**Do:** With a scoped user who has no Managed Apple ID yet, have them sign in to an Apple service with
their federated credentials.
**Expected:** A Managed Apple ID is created on first federated sign-in (JIT) without a manual step.

## Test 5 — COD enrolls correctly
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot COD device; check Intune → **Devices**.
**Expected:** The phone is **supervised**, **has user affinity**, enrolled via **ADE**
(`iOS COD – ADE – Pilot`), in **`iOS COD – Devices – Pilot`**, compliant.

## Test 6 — BYOD enrolls correctly (privacy-preserving)
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot BYOD device; check Intune → **Devices**.
**Expected:** The phone shows **account-driven User Enrollment**, a **managed work partition**, user in
**`iOS BYOD – Users – Pilot`**; personal data is not managed.

## Test 7 — Shared enrolls correctly (no affinity)
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot shared device; check Intune → **Devices**.
**Expected:** The phone is **supervised**, **no primary user**, enrolled via `iOS Shared – ADE – Pilot`,
in **`iOS Shared – Devices – Pilot`**; staff sign in to the app/service with a Managed Apple ID.

## Test 8 — Apple connection readiness
**Do:** Run **`ABMPROV-Discovery.ps1`**.
**Expected:** APNs certificate **Active** (not near expiry), a valid **ADE token**, the provisioning job
**On/healthy**, and federation reachable.

## Test 9 — Fleet coverage + scenario breakdown
**Do:** Run **`ABMPROV-Report.ps1`**.
**Expected:** A clear provisioning-coverage figure and a COD / BYOD / Shared device breakdown; each
device appears in exactly one model.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Federation/provisioning pass** | Tests 1–4 pass for the pilot group |
| **Per-model pass** | Tests 5–7 pass (one device validated per model) |
| **Readiness pass** | Tests 8–9 pass before any expansion wave |
