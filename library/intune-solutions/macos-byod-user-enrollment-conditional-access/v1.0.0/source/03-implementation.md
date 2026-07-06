# 3. Implementation — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
the pilot group **`BYOD-Mac-Pilot`** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Microsoft Entra at `https://entra.microsoft.com` unless noted. Named objects you will create:

| Object | Name | Where |
|---|---|---|
| Pilot security group | **`BYOD-Mac-Pilot`** | Entra → Groups |
| Enrollment type | **account-driven user enrollment** (macOS) | Intune → Enrollment |
| Compliance policy | **`macOS BYOD Compliance - Pilot`** | Intune → Compliance policies |
| Conditional Access policy | **`CA - Require Compliant Mac - Pilot`** | Entra → Conditional Access |

---

## Phase 0 — Assess (confirm readiness)

### Step 1. Run the discovery script
1. On an admin workstation with the **Microsoft Graph PowerShell SDK**, run
   **`MACBYOD-Discovery.ps1`** (read-only).
2. Confirm: macOS enrollment **allowed**, an account-driven user-enrollment configuration present (or
   flagged as not yet enabled), a macOS **compliance policy**, and whether a **Conditional Access**
   policy already gates macOS. Resolve any FAIL before continuing.

### Step 2. Confirm the pilot group exists
1. Entra → **Groups**; confirm **`BYOD-Mac-Pilot`** exists with your pilot users (Requirements R7).
2. If missing: **Groups → New group → Security**, name it **`BYOD-Mac-Pilot`**, add pilot users.

---

## Phase 1 — Configure account-driven user enrollment

### Step 3. Allow macOS personally owned enrollment
1. Intune → **Devices → Enrollment → Enrollment device platform restrictions**.
2. Open the default (or a pilot-targeted) restriction → **macOS**.
3. Set **Personally owned devices = Allow**. Save.

### Step 4. Enable account-driven user enrollment for macOS
1. Intune → **Devices → Enrollment → Apple** → open the **macOS** enrollment area.
2. Select the **account-driven user enrollment** enrollment type (the identity-driven, lighter-footprint
   BYOD option — **not** device enrollment and **not** Automated Device Enrollment).
3. Configure it to target **`BYOD-Mac-Pilot`** so only pilot users get this experience first.
4. Save.

> **If your console does not surface account-driven *user* enrollment for macOS**, confirm your OS floor
> (Requirements R2) and your managed Apple Account path (R3) — both are prerequisites. **Flag it and
> confirm against Microsoft's current macOS enrollment documentation rather than forcing a different
> enrollment type.** Do not silently substitute device enrollment; that changes the footprint the buyer
> asked for.

### Step 5. Confirm the managed Apple Account path
1. Verify pilot users can obtain a **managed Apple Account** for the corporate scope (Requirements R3) —
   the user's **personal** Apple ID stays untouched.
2. If unclear, coordinate with whoever owns your Apple identity relationship **before** piloting.

---

## Phase 2 — Scope BYOD compliance

### Step 6. Create the BYOD compliance policy
1. Intune → **Devices → Compliance policies → Create policy**.
2. **Platform = macOS**; **Create**.
3. **Name:** **`macOS BYOD Compliance - Pilot`**.
4. **Compliance settings** — keep BYOD-appropriate and minimal (do not over-manage a personal Mac):
   - **Minimum OS version** = your confirmed account-driven-enrollment floor (Requirements R2).
   - **System Integrity Protection** required (where supported).
   - Disk-encryption / firewall settings **only** where they make sense for BYOD and match your policy.
5. **Actions for noncompliance** — start gentle: **Mark noncompliant** immediately; optionally email
   the user. (Avoid retire/wipe actions on personal Macs.)
6. **Assignments** → include **`BYOD-Mac-Pilot`**.
7. **Review + Create.**

> Prefer automation for scoping? Run **`MACBYOD-Set-ScopeTargeting.ps1`** to assign the compliance
> policy (and, later, the CA policy) to a target group. It **defaults to `-WhatIf`** and only writes
> when you pass `-Apply`.

---

## Phase 3 — Build the Conditional Access gate

### Step 7. Confirm break-glass exclusions exist
1. Entra → **Users**; confirm your two **break-glass** emergency accounts exist (Requirements R6).
2. You will exclude them from the CA policy in the next step. **Never skip this.**

### Step 8. Create the named Conditional Access policy (report-only first)
1. Entra → **Protection → Conditional Access → Create new policy**.
2. **Name:** **`CA - Require Compliant Mac - Pilot`**.
3. **Users:**
   - **Include** → **`BYOD-Mac-Pilot`**.
   - **Exclude** → your two **break-glass** accounts.
4. **Target resources:** **Cloud apps → Include → Office 365** (or the specific apps you are gating).
5. **Conditions → Device platforms:** **Include → macOS** (so this policy targets Macs only).
6. **Grant:** **Grant access → Require device to be marked as compliant** (this is the compliance gate).
   Optionally also require **Microsoft Entra hybrid joined / device to be enrolled** per your model; for
   BYOD user enrollment, **require compliant** is the primary control.
7. **Enable policy = Report-only.**
8. **Create.**

> Automating the CA build? **`MACBYOD-Remediation.ps1`** can create/repair this policy and **always
> re-asserts break-glass exclusions**; it **defaults to `-WhatIf`** and only writes with `-Apply`.

---

## Phase 4 — Pilot

### Step 9. Onboard a pilot Mac (user-initiated)
1. As a **pilot user on their own Mac**, open **System Settings**.
2. Add the **Work or School account** (the account-driven user-enrollment sign-in), authenticating with
   the user's **Entra ID**.
3. macOS provisions the **managed Apple Account** and the **separate managed volume**; the corporate
   scope is applied. Personal apps, data, and Apple ID are untouched.
4. Wait for Intune policy to sync; the Mac appears in **Intune → Devices → macOS** as a
   **personally owned**, user-enrolled device.

### Step 10. Confirm the compliance signal
1. Intune → **Devices → macOS → (the pilot device) → Compliance**; confirm it evaluates against
   **`macOS BYOD Compliance - Pilot`** and reports **Compliant**.
2. Or run **`MACBYOD-Validation.ps1 -Serial the-device-serial`** for a per-device PASS/FAIL.

---

## Phase 5 — Validate

### Step 11. Validate the end-to-end posture
1. Run **`MACBYOD-Validation.ps1`** against the pilot Mac: enrolled (**account-driven user
   enrollment**), **personally owned**, **compliant**, and Entra-registered.
2. Review **`CA - Require Compliant Mac - Pilot`** in **report-only**: Entra → **Sign-in logs** → filter
   to the pilot user/macOS → confirm the policy would have **allowed** the compliant Mac and **blocked**
   a non-compliant/unenrolled one (test from an unmanaged Mac to see the block *predicted*).
3. Run **`MACBYOD-Report.ps1`** for the BYOD access-posture snapshot (enrolled vs unmanaged, compliant
   vs not, which Macs the CA policy would gate).

### Step 12. Turn the gate on for the pilot
1. Once report-only shows the intended outcome with **no surprise blocks** for legitimate users, edit
   **`CA - Require Compliant Mac - Pilot`** → **Enable policy = On**.
2. Re-test with a pilot user: a **compliant** enrolled Mac gets in; a **non-compliant/unenrolled** Mac
   is **blocked**. Break-glass accounts remain excluded.

---

## Phase 6 — Expand

### Step 13. Widen scope in waves
1. Create a production group (e.g. **`BYOD-Mac-Users`**) and add the next wave of users.
2. Use **`MACBYOD-Set-ScopeTargeting.ps1`** (preview with `-WhatIf`, then `-Apply`) to assign the
   **compliance policy** and the **CA policy** to the production group — or clone the pilot CA policy to
   a production-named policy (e.g. **`CA - Require Compliant Mac - Production`**) and expand its scope.
3. Keep break-glass exclusions on **every** CA policy.
4. Validate each wave with **`MACBYOD-Validation.ps1`** / **`MACBYOD-Report.ps1`** before widening
   further. Roll out in waves, never all at once.
