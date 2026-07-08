# 3. Diagnostic Playbook — Android Enterprise Enrollment (symptom → root cause → fix)

This is a **symptom-to-root-cause decision tree**. Start at **Step 0** to reproduce and route, then follow
the one **Playbook node** the routing table sends you to. Each node gives the **exact checks** (Intune admin
center, Microsoft Graph, device logs, endpoint reachability) and the **fix**, with a **pass/fail gate** and,
where the fix is high-impact, a **rollback**. Work **one variable at a time** and confirm each fix by
re-running the same reproduction before moving on.

> **Golden rules.** (1) **Reproduce before you change anything** — debug a fact, not a report. (2) **Binding
> sits above everything** — clear Playbook A before chasing anything else. (3) **Pilot first** — prove every
> fix on `Repro Device – Android – Test` and the `Enrollment Scope – Android – Pilot` group before the fleet.
> (4) **AMAPI / re-enrollment behavior is evolving** — where flagged, **verify against current Microsoft
> guidance / your tenant**; do not assume.

---

## Step 0 — Reproduce and route

**0.1 Reproduce on the test device.** Factory reset `Repro Device – Android – Test`, connect it to the
**same network** the failing fleet uses, and re-run the failing enrollment with the exact method the fleet
uses (BYOD work profile via Company Portal, or the device-owner QR/token/NFC/zero-touch path). Capture the
**exact on-device error text and screen**, the OS build, and whether the device has Google Mobile Services.

**0.2 Establish the tenant baseline (read-only, changes nothing).**
- `powershell -File .\ANDROIDDX-EnrollmentReadiness.ps1 -Days 14 -CsvPath .\android-readiness.csv` → record as `Enrollment Readiness – Android – Assessed`.
- `powershell -File .\ANDROIDDX-BindingHealth.ps1 -JsonPath .\binding.json` → record as `Binding Health – Android – Baseline`.
- `powershell -File .\ANDROIDDX-DiagnosticReport.ps1 -Symptom <symptom> -JsonPath .\prod-config.json` → record as `Diagnostic Report – Android – <symptom>`.

**0.3 Route by symptom.**

| Reported symptom | Start at | Also check |
|---|---|---|
| "Can't add a Google account" to Gmail/the device | **F** (account model) | **A** (binding), **D** (endpoints) |
| Web / account-driven enrollment works in DEV but fails in PROD | **B** (dev-vs-prod) | **D** (endpoints), **A** (binding) |
| Enrollment broke **after an AMAPI migration** | **E** (post-AMAPI) | **A** (binding) |
| Managed Google Play binding / connector error; apps won't deliver | **A** (binding) | — |
| Enrollment stalls / times out at a network step | **D** (endpoints) | **A** (binding) |
| Wrong/failed provisioning for a specific enrollment method | **C** (method path) | **A** (binding) |

> **If the binding baseline in 0.2 is not `bound` / not synced, do Playbook A first regardless of symptom** —
> a broken connector produces almost every downstream symptom.

---

## Playbook A — Managed Google Play binding / connector health

**Symptom:** binding/connector error, apps not delivering, or any symptom while `bindStatus ≠ bound`.

**Checks**
1. **Graph / tool:** `ANDROIDDX-BindingHealth.ps1` — read `BindStatus`, `OwnerUserPrincipalName`,
   `LastAppSyncStatus`, `LastAppSyncAgeHours`, and the enabled enrollment paths.
2. **Intune admin center:** **Devices > Android > Android enterprise** (Connection/Enrollment) — confirm the
   connection shows connected, note the **binding model** (account enterprise vs Google Workspace) and the
   **owner account**.
3. **Model check:** confirm exactly **one** model is in place. A tenant with Google Workspace must use the
   Workspace / third-party-EMM binding; a tenant without it uses the account-enterprise binding.

**Fix (decision)**
- `bindStatus = bound`, owner present, sync recent + `success` → **binding is healthy; return to your routed
  node.**
- `bindStatus ≠ bound` **or** no owner account → the connector is broken. **Repair / re-establish the managed
  Google Play connection** (Global Admin, one-time Google consent) per the connection setup process. This is
  **high-impact** — see rollback.
- Sync stale/failed → force a managed Google Play **sync** and re-check `LastAppSyncStatus`; if it stays
  non-`success`, treat as a broken connection.

**Pass/fail gate:** `ANDROIDDX-BindingHealth.ps1` reports `bound`, an owner account, and a recent `success`
sync. **Fail** → do not proceed; the binding must be healthy first.

**Rollback (high-impact):** before re-establishing a binding, record the current connection state and owner
account. Re-establishing or unbinding the connection **can affect existing enrolled devices** — **whether it
forces re-enrollment is version-dependent; verify against current Microsoft guidance / your tenant** — so do
it only in an approved change window with the connection-setup solution's rollback in hand.

---

## Playbook B — Web / account-driven enrollment works in DEV but fails in PROD

**Symptom:** the same web / account-driven (AMAPI) enrollment succeeds in a dev tenant and fails in prod.

**Checks**
1. **Config diff:** export a snapshot from each tenant with `ANDROIDDX-DiagnosticReport.ps1 -JsonPath` and
   diff them: `ANDROIDDX-EndpointReachability.ps1 -CompareConfig -DevJson .\dev-config.json -ProdJson .\prod-config.json`.
   Record the differing settings as `Config Baseline – Android – Dev` vs `Config Baseline – Android – Prod`.
2. **Endpoint egress:** run `ANDROIDDX-EndpointReachability.ps1` **from the prod device network** and again
   from the dev network — an endpoint reachable in dev but **Blocked** in prod is the answer (go to **D**).
3. **Enrollment restriction / Conditional Access:** Intune **Devices > Enrollment > Enrollment restrictions**
   and Entra **Conditional Access** — compare the policies that apply to the prod enrolling user/device vs
   dev (platform blocked, personally-owned blocked, a CA grant requiring compliance/MFA that the fresh device
   can't satisfy).
4. **Binding model / consent:** confirm prod's managed Google Play binding is fully consented and `bound`
   (Playbook A) — a dev tenant is often bound while prod's binding is partial.
5. **Web/account-driven specifics:** the account-driven enrollment method is **evolving** — confirm the prod
   tenant meets the **current** prerequisites for it (**verify against current Microsoft guidance**), since
   dev may have been configured under different/newer settings.

**Fix**
- Reconcile the specific setting the diff surfaced (bring prod to match the known-good dev value **only after
  confirming that value is correct for prod**).
- Allowlist the endpoint that is blocked in prod (Playbook D).
- Relax/scope the prod enrollment restriction or CA rule that blocks the fresh device, under change control.

**Pass/fail gate:** the prod reproduction device now completes web/account-driven enrollment. **Fail** → the
remaining diff items or an endpoint block are still in play; continue isolating one variable at a time.

**Rollback:** enrollment-restriction and CA changes are reversible — record the prior policy state before
editing so you can restore it.

---

## Playbook C — Enrollment-method path (wrong/failed provisioning for a method)

**Symptom:** provisioning fails or lands in the wrong state for a **specific** enrollment method.

**Checks (per method)**
- **Personally-owned work profile (BYOD):** enrollment is via **Company Portal**; the work profile is
  created and a **managed** Google account is added by the profile. Confirm Company Portal is current and the
  user is licensed/allowed.
- **Fully managed / dedicated (COSU) / corporate-owned work profile:** these use a **device-owner** path
  (QR code, token, NFC, or zero-touch) from a **fresh/factory-reset** device. Confirm an
  **`androidDeviceOwnerEnrollmentProfile`** exists (readiness tool reports the count) and the QR/token is
  current and not expired.
- **Intune admin center:** **Devices > Enrollment > Android** — confirm the profile for the method exists and
  is assigned to `Enrollment Scope – Android – Pilot`.
- **Device logs:** capture the on-device provisioning error; a device-owner path started on a
  **non-factory-reset** device is a common, self-inflicted failure.

**Fix**
- Match the method to its path: device-owner methods require a **factory-reset** device and a valid
  profile/token; BYOD requires Company Portal. Regenerate an expired QR/token. Assign the profile to the
  pilot scope with `ANDROIDDX-Set-ScopeTargeting.ps1`.

**Pass/fail gate:** the device provisions into the **intended** method state (work profile vs fully managed
vs dedicated). **Fail** → re-check the profile assignment and the device's factory-reset state.

**Rollback:** regenerating a token invalidates the prior one — record it first; profile assignment changes
are reversible via the scope group.

---

## Playbook D — Network / endpoint / proxy blocks

**Symptom:** enrollment stalls at a network step, or "can't add a Google account" with the binding healthy.

**Checks**
1. **Reachability from the device network:** `ANDROIDDX-EndpointReachability.ps1 -CsvPath .\endpoints.csv` —
   record as `Endpoint Allowlist – Android – Verified`. Any **Blocked** host is a root cause.
2. **TLS/SSL inspection:** confirm whether the proxy performs **TLS interception** on Google/Microsoft hosts
   — intercepted TLS to `accounts.google.com` / `*.googleapis.com` breaks token/sign-in even when the host is
   "reachable."
3. **Authoritative lists:** the tool ships a **documented core** endpoint set — cross-check against the
   **current** Microsoft (Intune network endpoints) and Google (Android Enterprise network requirements)
   published lists for your region/tenant; **verify these lists are current** before allowlisting.
4. **Device basics:** confirm device **date/time** is correct and **Google Play services** are present and
   current (non-GMS/China-market devices behave differently — see **F**).

**Fix**
- **Allowlist** the blocked Google/Microsoft endpoints on the proxy/firewall and **exempt** Google/Microsoft
  hosts from **TLS inspection**. Correct device date/time. Update Google Play services where applicable.

**Pass/fail gate:** every required endpoint reports **Reachable**, TLS is not intercepted on Google hosts,
and the reproduction device now adds the account / completes enrollment. **Fail** → an endpoint or inspection
rule is still blocking; re-run the reachability tool after each network change.

**Rollback:** allowlist/exemption changes are network-team changes — record the prior rule so they can be
reverted if they conflict with security policy.

---

## Playbook E — Failure after an AMAPI migration

**Symptom:** enrollment (or management) broke **after** an Android Management API (AMAPI) migration.

> **This node is the most version-sensitive in the tree.** The AMAPI transition and **whether a migration
> forces device re-enrollment** are **actively evolving — verify every point below against current Microsoft
> guidance and your tenant**; do not assert the behavior from memory.

**Checks**
1. **Re-enrollment requirement (verify):** confirm whether the specific AMAPI change in your tenant requires
   affected devices to **re-enroll** — **verify against current Microsoft guidance / your tenant.** If it
   does, the "failure" may be expected until re-enrollment.
2. **Token / profile regeneration:** check whether the migration **regenerated** enrollment profiles or
   tokens (Playbook C) — an old QR/token distributed before the migration will now fail.
3. **Binding / app re-sync:** run `ANDROIDDX-BindingHealth.ps1`; force a managed Google Play sync. Migration
   can leave app approvals/config needing a re-sync (Playbook A).
4. **Diagnostic report:** `ANDROIDDX-DiagnosticReport.ps1 -Symptom AfterAmapiMigration` for the ranked
   candidates.

**Fix**
- If re-enrollment is required (**verified**), **re-enroll the reproduction device**, confirm success, then
  roll re-enrollment out via the pilot scope under change control.
- Redistribute **regenerated** QR/tokens; retire the old ones.
- Force the post-migration **app/config re-sync** and confirm `LastAppSyncStatus = success`.

**Pass/fail gate:** the reproduction device enrolls and is managed under the post-AMAPI path, and app sync is
`success`. **Fail** → re-check the re-enrollment requirement and token freshness.

**Rollback (high-impact):** an AMAPI migration is not casually reversible — treat forward-fix (re-enroll /
re-sync) as the path, keep the change window, and escalate to Microsoft support if the documented behavior
does not match your tenant.

---

## Playbook F — Identity / account model mismatch ("can't add a Google account")

**Symptom:** the device or Gmail won't add a Google account, or the added account is rejected.

**Checks**
1. **Account model:** determine which model applies. On a **work profile**, the Google account used for
   managed Google Play is a **managed account added by the profile** — it is **not** a consumer Gmail login,
   and **manually adding a personal Google account inside the work profile is expected to fail/absent**.
   Confirm the user is trying the **right** flow for the enrollment method.
2. **Binding provisioning:** if the managed account never provisions, the binding is likely the cause →
   Playbook A (`bindStatus`, owner account, sync).
3. **Endpoints / TLS:** `ANDROIDDX-EndpointReachability.ps1` — a blocked `accounts.google.com` /
   `*.googleapis.com` / `play.google.com` or intercepted TLS blocks the account add → Playbook D.
4. **Device / GMS:** confirm **Google Play services** are present and current and the **date/time** is
   correct. On **non-GMS / China-market** hardware the standard Google-account add path may not exist —
   this is a device/OEM constraint, not a tenant fault (pattern-level; defer to the vendor).
5. **Workspace identity match (Workspace-bound tenants):** if the tenant uses the Google Workspace binding,
   confirm the user's identity is correctly represented in **Cloud Identity / Workspace** so the managed
   account can be issued.

**Fix**
- Use the **correct account flow** for the method (managed account via the profile/enrollment, not a manual
  consumer Gmail add). Repair the binding (A) if the managed account never provisions. Clear the endpoint/TLS
  block (D). Update Google Play services / fix date-time. For non-GMS devices, follow the OEM's documented
  path or choose a supported device.

**Pass/fail gate:** the reproduction device successfully adds the **managed** Google account and managed
Google Play is usable. **Fail** → step back to A (binding) or D (endpoints) — those two produce most
account-add failures.

**Rollback:** account-flow and device fixes are non-destructive; binding and network fixes carry their own
rollbacks (A, D).

---

## Expand — from fixed device to fixed fleet
Once the reproduction device passes the routed node's gate:
1. Apply the same fix to the **`Enrollment Scope – Android – Pilot`** group (build/refresh it with
   `ANDROIDDX-Set-ScopeTargeting.ps1 -WhatIf` then apply).
2. Re-run the reproduction on **two or three** pilot devices; confirm the gate passes for all.
3. Promote to **`Enrollment Scope – Android – Expanded`** and roll out under change control.
4. Re-run `ANDROIDDX-EnrollmentReadiness.ps1` and confirm the ticket class stops recurring.

> Follow the house model throughout: **Assess → Design → Configure → Pilot → Validate → Expand**, one
> variable at a time, with the pass/fail gate and rollback at each node.
