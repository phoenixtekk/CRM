# 1. Solution Overview — Android Enterprise Enrollment Troubleshooting (Managed Google Play, Web Enrollment & "Can't Add a Google Account")

## What this solution is
Android Enterprise enrollment fails in maddening, hard-to-narrow ways: a device won't **add a Google
account** to Gmail or to the device, **web / account-driven enrollment** works cleanly in a dev tenant
but stalls in production, enrollment breaks **after an Android Management API (AMAPI) migration**, or the
managed Google Play **binding/connector** throws errors and apps never deliver. The cause is almost never
where the error appears — it lives one or two layers down, in the binding, the enrollment-method path,
the network endpoints, or the account model.

This solution is a **layered enrollment diagnostic playbook**: a symptom-to-root-cause decision tree that
walks the moving parts in the order that isolates a fault fastest — managed Google Play binding health,
the enrollment-method path, network/endpoint reachability, the identity / account-add flow, dev-vs-prod
configuration differences, and post-AMAPI-migration issues — with the exact check and the exact fix at
each node. It gets devices enrolling and Google accounts adding, and it turns a recurring class of tickets
into a repeatable 20-minute triage.

> **A note on what's stable and what's evolving.** The Intune admin center, Microsoft Graph, managed
> Google Play, and the Google Admin console steps here are authored from Microsoft's and Google's public
> documentation. The **AMAPI transition** (Intune's move off the legacy Play EMM API), **web / account-driven
> enrollment**, and **whether a given change forces device re-enrollment** are **actively evolving** — every
> such point is flagged **"verify against current Microsoft guidance / your tenant"** rather than asserted.

## The enrollment moving parts (what the tree walks)
1. **Managed Google Play binding** — Intune's connection to managed Google Play, in one of two mutually
   exclusive models: a **managed Google Play account enterprise** (tenants without Google Workspace) or the
   **Google Workspace / Cloud Identity ↔ Intune third-party EMM** integration (tenants with Workspace). A
   broken, unbound, or unsynced binding is the single most common upstream cause.
2. **Enrollment-method path** — **personally-owned work profile (BYOD)**, **fully managed**,
   **corporate-owned work profile**, or **dedicated / COSU (kiosk)**. Each has a different provisioning path
   (managed account add vs QR/token/NFC/zero-touch device-owner) and therefore a different failure surface.
3. **Network / endpoint reachability** — the device's path to the Google (managed Google Play, Android) and
   Microsoft (Intune, Entra) endpoints. A proxy, firewall, or TLS-inspection rule that blocks one host is a
   classic "can't add a Google account" root cause.
4. **Identity / account-add flow** — on a work profile the Google account is a **managed** account added by
   the profile, not a consumer Gmail login; mismatching that model produces confusing "can't add account"
   symptoms.
5. **Dev-vs-prod configuration** — the setting, endpoint egress, Conditional Access rule, or binding model
   that differs between a working dev tenant and a failing prod tenant.
6. **AMAPI vs legacy** — the state of the AMAPI transition and whether a migration regenerated a token,
   changed the management path, or (verify) required re-enrollment.

## The diagnostic method
Three words drive every investigation: **Reproduce. Isolate. Resolve.**
- **Reproduce** the failure on a known **reproduction device** so you are debugging a fact, not a report.
- **Isolate** by walking the tree top-down — binding first (it sits above everything), then the enrollment
  path, then endpoints, then the account model — changing one variable at a time.
- **Resolve** at the node the tree lands on, then re-run the same reproduction to confirm the fix, and only
  then expand back to the fleet.

## The named artifacts (use these names everywhere)
Name each working artifact with the pattern `<Purpose> – <Scope> – <Stage>` and reuse the names verbatim
across every document, script, and group:
- `Binding Health – Android – Baseline` — the managed Google Play connector state (from `ANDROIDDX-BindingHealth.ps1`).
- `Enrollment Readiness – Android – Assessed` — the per-tenant readiness table (from `ANDROIDDX-EnrollmentReadiness.ps1`).
- `Endpoint Allowlist – Android – Verified` — the reachability result from the device network.
- `Config Baseline – Android – Dev` / `Config Baseline – Android – Prod` — the two snapshots diffed for dev-vs-prod drift.
- `Diagnostic Report – Android – <symptom>` — the symptom-to-cause report for the failure under investigation.
- `Repro Device – Android – Test` — the dedicated wipe-and-retry reproduction device.
- `Enrollment Scope – Android – Pilot` / `Enrollment Scope – Android – Expanded` — the Entra ID groups that bound each pass.

## What you can control
- Which symptom you are triaging (the tree has a dedicated entry per reported failure).
- The reproduction scope (the pilot group and the reproduction device).
- Which binding model the tenant uses (account enterprise vs Google Workspace) — chosen deliberately, changed only under change control.
- The endpoint allowlist and TLS-inspection exemptions on the device network.
- The enrollment method(s) in scope, and the change window for any high-impact change.

## Benefits
- **Faster triage** — a repeatable tree replaces guesswork; most failures root-cause in one short session.
- **Fewer tickets** — the same playbook prevents the recurring "can't add a Google account" and
  "dev works, prod fails" tickets from recurring.
- **Safer changes** — binding, connector, and AMAPI-migration changes are treated as high-impact, with a
  pilot gate and a rollback before they touch the fleet.
- **Auditability** — named artifacts (binding health, readiness, endpoint allowlist, diagnostic report)
  make every finding and fix traceable.

## Limitations (be honest with buyers)
- This is a **diagnostic** solution. It root-causes and fixes enrollment failures; it does not stand up the
  binding from scratch or design a greenfield enrollment program (those are separate solutions in the line).
- **AMAPI transition and re-enrollment behavior are evolving.** Where a step depends on the current AMAPI
  state or on whether a change forces re-enrollment, the solution flags it to **verify against current
  Microsoft guidance and your tenant** — it does not assert a behavior that Microsoft may change.
- **OEM and non-GMS specifics are pattern-level.** Samsung Knox, Zebra, and other rugged/kiosk devices, and
  devices without Google Mobile Services (e.g. some China-market hardware), are covered at the pattern level;
  their consoles and firmware behaviors are deferred to the vendor's documentation.
- **On-device and network actions happen off-tenant.** Endpoint allowlisting, TLS-inspection exemptions, and
  reading on-device logs happen on the network and device; the PowerShell tools cover the Intune/Graph side
  and the reachability probe.
- The **authoritative endpoint lists** are Microsoft's and Google's — the tool ships a documented core set
  and tells you to verify against the current published lists for your region/tenant.

## The standard deployment model
> Assess the binding and readiness, design the isolation path for the reported symptom, configure the fix on
> a reproduction device / pilot scope, validate that the device enrolls and the account adds, then expand the
> fix to the fleet.
> The repeatable way: Assess to Design to Configure to Pilot to Validate to Expand.
