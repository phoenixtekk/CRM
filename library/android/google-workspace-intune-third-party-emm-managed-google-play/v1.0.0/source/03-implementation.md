# 3. Implementation Guide — Google Workspace ↔ Intune Third-Party EMM Integration

Follow these steps **in order**. Work happens in three places: the **Intune admin center**
(`https://intune.microsoft.com`), the **Google Admin console** (`https://admin.google.com`), and
**Microsoft Graph PowerShell**. Every script defaults to **read-only or `-WhatIf`** — nothing changes
until you deliberately re-run the one scope helper with `-Commit`. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the current binding and devices, design the identity/account model, configure the
> Google Admin console third-party EMM and the Intune side, **pilot** and **assess re-enrollment /
> end-user impact**, validate account add + app delivery, then expand under change control with a
> rollback ready. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Re-enrollment is not asserted anywhere in this guide.** Where a step touches enrollment impact, it
> tells you to **observe** the result on the pilot and **verify it against current Microsoft/Google
> guidance and your tenant** — never to assume a device will or will not re-enrol.

---

## Step 1 — Confirm this is the right model (Assess)
1. Confirm your organization has a **Google Workspace / Cloud Identity** managed domain (Requirement
   2.1). If you have **no** Google managed domain, stop and use the account-enterprise solution
   (`ANDROIDENT`) instead — the two models are mutually exclusive (GR 2).
2. In Intune, open **Devices → Android → Android enterprise (Enrollment)** and note the current managed
   Google Play connection status and the account it is bound to.
3. Identify the **Google super-admin** who will act in the Google Admin console (Requirement 2.2) and the
   **Intune Administrator / Global Administrator** who will act in Intune (Requirement 2.3).

## Step 2 — Capture the current-state baseline (Assess)
1. Run `ANDROIDGW-Discovery.ps1` (read-only) to record the managed Google Play connection state —
   bind status, owning account/organization, last app sync — into `Binding Posture – Workspace+Intune –
   Discovery`. The script flags whether the current binding looks like an **account enterprise** or a
   **managed-domain / Workspace** binding so you know your starting point.
2. Run `ANDROIDGW-DeviceImpact.ps1` (read-only) to inventory every existing Android device — enrollment
   type, ownership, management state, last check-in — into `Device Impact – Android – Assess`. This is
   the **blast-radius baseline** the pilot is measured against.
3. Keep both exports. They are the reference for answering the re-enrollment question later.

## Step 3 — Confirm the identity/account model (Design)
1. Run `ANDROIDGW-Readiness.ps1` (read-only) to print the integration readiness + identity checklist
   into `Integration Readiness – Workspace+Intune – Assess`: Intune-side prerequisites, the pilot
   users' presence/licensing, and the **Google identity ↔ Entra identity** mapping to confirm
   (Requirement 2.5).
2. Confirm the domains used for Entra UPNs and Google primary emails line up for the pilot users, and
   document the account each user will sign in with on their device.
3. Confirm managed Google Play / Google sign-in endpoints are reachable on the pilot network
   (Requirement 2.7).

## Step 4 — Build and scope the pilot (Design)
1. Run `ANDROIDGW-Set-Scope.ps1` in its default **`-WhatIf`** mode to preview creating/populating the
   pilot group `MGP Pilot – Android – Stage1`. Review the preview — no change is made.
2. Re-run `ANDROIDGW-Set-Scope.ps1 -Commit` to create/populate the pilot group. Include a
   **representative** device for each enrollment model you actually use (work profile BYOD, fully
   managed, corporate-owned work profile, dedicated/COSU) so the impact assessment covers them all.
3. Scope the pilot's app assignments and any enrollment restrictions to `MGP Pilot – Android – Stage1`
   so the change is contained.

## Step 5 — Enable the third-party Android EMM in the Google Admin console (Configure — Google side)
1. The **Google super-admin** signs in to `https://admin.google.com`.
2. Navigate to the **mobile device management → third-party integrations / Android EMM** area and
   **enable a third-party Android EMM provider**, delegating managed Google Play management to Intune.
   > ⚠️ **Verify the current menu path against Google's live guidance.** Google relocates these settings
   > (they have lived under *Devices → Mobile & endpoints → Settings → Third-party integrations* and
   > under an *Android EMM* setting). Do **not** rely on a remembered path — follow Google's current
   > documentation for *managed Google Play with a third-party EMM* / *bind a managed Google domain to
   > an EMM*, and capture any token/identifier the console generates for the Intune side.
3. Record exactly what was enabled, when, and by whom, in the change record (Requirement 2.8) — this is
   the action you will reverse if you roll back.

## Step 6 — Complete the connection on the Intune side (Configure — Microsoft side)
1. In Intune, complete/confirm the **Android Enterprise** connection so managed Google Play is delegated
   to Intune for your domain, following Intune's current in-portal flow for connecting to managed Google
   Play.
   > ⚠️ **Verify the current Intune flow against Microsoft's live guidance.** The connection UX and the
   > interplay with the Google Admin console step evolve (including the **AMAPI** transition). Follow
   > Microsoft's current documentation for connecting Intune to managed Google Play for Google Workspace
   > / Cloud Identity organizations.
2. Re-run `ANDROIDGW-Discovery.ps1` and confirm the binding posture now shows a **bound** state and a
   recent **successful app sync**. If app sync has not completed, trigger/allow a sync and re-check.

## Step 7 — Assess re-enrollment / end-user impact on the pilot (Pilot — the critical gate)
1. On the pilot devices only, **observe** what actually happens after the binding is in place:
   - Do already-managed devices keep checking in and stay compliant, or do they prompt to re-add an
     account / re-enrol?
   - What does the end user see (any account prompt, work-profile change, app re-provisioning)?
2. Re-run `ANDROIDGW-DeviceImpact.ps1` and **diff it against the Step 2 baseline** (`Device Impact –
   Android – Assess`): compare enrollment type, management state, and enrolled/last-check-in dates per
   device to detect any device that re-enrolled or fell out of management.
   > ⚠️ **Do not assume — verify.** Whether any change is expected is **state- and version-dependent**.
   > Confirm the observed behavior against **current Microsoft/Google guidance and your tenant** before
   > drawing a conclusion, and record it in the pilot notes.
3. **Pass/fail gate:** proceed **only** if the pilot devices behave as your verified expectation
   requires (e.g. no unexpected re-enrollment, users retain access, apps still deliver). If not, invoke
   rollback (Step 10) and reassess.

## Step 8 — Validate account add + app delivery on the pilot (Validate)
1. On a fresh/representative pilot device, confirm a pilot user can **add the managed Google account**
   and complete enrollment for the target enrollment model.
2. Assign a known managed Google Play app to `MGP Pilot – Android – Stage1` and confirm it **installs**
   on the pilot devices.
3. Run `ANDROIDGW-Validation.ps1` (read-only) to produce `Account Add + App Delivery – Pilot –
   Validation`: it reports app-sync health, the pilot's assigned managed Google Play apps, and the pilot
   devices' install/compliance state. Complete the **Testing Guide (05)** before expanding.

## Step 9 — Expand to the fleet (Expand)
1. Only after the pilot passes both gates (Step 7 impact, Step 8 validation), broaden scope to
   `MGP Broad – Android – Stage2` in stages (e.g. by enrollment model or business unit), re-observing
   device state at each stage.
2. Re-run `ANDROIDGW-Validation.ps1` to refresh `MGP Sync Health – Android – Report` and confirm the
   connection stays healthy and apps deliver as scope widens.
3. Keep the change record and rollback current until the full fleet is confirmed stable.

## Step 10 — Rollback (if a gate fails)
1. If the pilot shows unacceptable impact, **stop expanding** and follow the documented rollback
   (Requirement 2.8): the Google super-admin reverses the third-party EMM enablement in the Google Admin
   console and the Intune side is reverted per Microsoft's current guidance.
   > ⚠️ Rollback of a managed Google Play / third-party EMM binding is itself **high-impact** and may
   > affect devices. **Verify the current, supported rollback procedure against Microsoft/Google
   > guidance** before executing, and treat it as its own change-controlled action.
2. Re-run `ANDROIDGW-DeviceImpact.ps1` and confirm devices return to the baseline state; reassess the
   plan before attempting the cutover again.

---
### Order of operations
`Confirm model → baseline binding + devices → confirm identity model → build pilot scope → Google Admin
console third-party EMM → Intune side → assess re-enrollment impact (gate) → validate account add + app
delivery (gate) → expand in stages → rollback ready throughout.`

### Pass/fail gates
- **Gate A (impact):** pilot devices behave as your *verified* expectation requires — no unexpected
  re-enrollment or loss of management; users retain access.
- **Gate B (validation):** pilot users can add the managed Google account and assigned managed Google
  Play apps install; connection/app sync is healthy.
- **Rollback trigger:** either gate fails → stop, revert the Google Admin console + Intune change per
  current guidance, return to baseline, reassess.
