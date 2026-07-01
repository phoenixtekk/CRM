# 3. Implementation Guide — Remote Help

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Enable Remote Help → deploy the app → assign RBAC → configure security → pilot a session → expand.

## Step 1 — Create the pilot groups
1. Entra → **Groups → New group** → Security → `RemoteHelp-Helpers` (add help-desk staff). **Create**.
2. Create `RemoteHelp-Sharers` (add pilot end-user devices/users). **Create**.

## Step 2 — Enable Remote Help
1. Intune → **Tenant administration → Remote Help**.
2. Set **Enable Remote Help** to **Enabled**. Review and accept the terms.
3. Configure options:
   - **Allow Remote Help to unenrolled devices** = your policy (default **No** for tighter control).
   - **Allow remote control** = **Yes** (or view-only if preferred).
   - **Disable chat** = as preferred.
4. **Save**.

## Step 3 — Deploy the Remote Help app
1. Intune → **Apps → Windows → Add**.
2. Add **Remote Help** (Microsoft Store app / Win32 per your packaging).
3. **Assignments → Required →** `RemoteHelp-Helpers` and `RemoteHelp-Sharers`. **Create**.

## Step 4 — Assign RBAC roles
1. Intune → **Tenant administration → Roles → Help Desk Operator** (or a custom role with Remote Help permissions).
2. **Assignments → Assign →** scope to `RemoteHelp-Helpers`; set the member/scope groups. **Save**.
3. Confirm the role grants the Remote Help capabilities you intend (view vs full control, elevation).

## Step 5 — Verify app delivery on pilot devices
1. On a pilot helper and a pilot sharer device, confirm the **Remote Help** app installed (Step 3) — run **`RHELP-Validation.ps1`**.

## Step 6 — Run a pilot session
1. On the **sharer** device, open **Remote Help → Get help** (or the helper sends a request).
2. On the **helper** device, open **Remote Help → Give help**, sign in with Entra, enter the session.
3. Confirm the helper sees the device **compliance** state, the sharer **consents**, and (if enabled) control works.

## Step 7 — Validate
1. Run **`RHELP-SettingsCheck.ps1`** → confirms Remote Help is enabled with the chosen options.
2. Run **`RHELP-SessionReport.ps1`** → confirms the pilot session appears in the audit/usage data.
3. Complete the **Testing Guide** (Section 5).

## Step 8 — Expand to production
1. Add production helper and sharer groups to the app assignment and RBAC scope.
2. Roll out in waves; confirm app delivery and a successful session per wave.
3. Re-validate with **`RHELP-Validation.ps1`** / **`RHELP-SessionReport.ps1`**.

---
### Order of operations
`Pilot groups → Enable Remote Help → Deploy app → Assign RBAC → Verify app → Pilot session → Validate → Expand`
