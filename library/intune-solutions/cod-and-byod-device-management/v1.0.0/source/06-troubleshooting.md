# 6. Troubleshooting — Corporate-Owned (COD) & BYOD Device Management

Work top-down: confirm the **identity** (one account), then **ownership** (Corporate vs Personal),
then **targeting** (filters/assignments), then **access** (Conditional Access). Most issues are a
device tagged with the wrong ownership, a missing filter on an assignment, or a BYOD user not using a
managed app.

## A user's two devices show under different accounts
- **Duplicate identities.** Consolidate to one Entra account; the user must sign in with the same UPN
  on both devices (Requirements R1). Re-enroll/re-register the stray device under the correct account.

## A corporate device is tagged Personal (or vice-versa)
- **Wrong ownership.** Intune → **Devices → (device) → Properties → Device ownership** → set
  **Corporate**/**Personal**. For COD, add **corporate device identifiers** or use a corporate
  enrollment program so it tags Corporate automatically (R5).
- After fixing, the device picks up the correct filtered policies on next sync.

## Corporate policies are not applying to the corporate device
- **Filter mismatch.** The compliance/config assignment must **Include** the **Corporate Devices**
  filter and target the **user** group (Implementation §5–6). Verify the filter rule is
  `(device.deviceOwnership -eq "Corporate")`.
- **Device not compliant/enrolled.** Confirm the device is enrolled and checking in.

## App Protection isn't applying to the BYOD device
- **User not in scope.** App Protection assigns to the **user** group — confirm the pilot user is a
  member (Implementation §7).
- **App not managed/approved.** The user must use an **approved managed app** (Outlook, Edge, Teams).
  Built-in mail/browser apps are intentionally excluded.
- **No Intune/MAM license** on the user (R2).
- App Protection applies on **next app launch / token refresh** — close and reopen the managed app.

## BYOD user can't access corporate mail/data
- **By design in an unmanaged app.** They must use the managed app (e.g. Outlook), not the built-in
  one. Deploy and direct them to the approved apps (Implementation §8).
- **Conditional Access blocking.** If CA requires app protection, accessing from a non-managed app is
  blocked — expected. Check Entra → **Sign-in logs** for the CA result.

## One account works on the corporate device but not the personal one (or vice-versa)
- **CA grant too strict.** The Conditional Access policy must **require *one of*** compliant device
  **or** app protection — not **both** (Implementation §9). "Require all" blocks one of the two paths.
- **App protection not yet registered** on the personal device — open a managed app and complete the
  PIN setup.

## Personal device received corporate **device** policies (over-management)
- The personal device was **fully enrolled** and/or tagged **Corporate**. Confirm enrollment
  restrictions and ownership (R4–R5); for BYOD, prefer **App Protection without enrollment**. If
  personal MDM enrollment is intended, ensure it's tagged **Personal** so the Personal filter excludes
  corporate policies.

## Conditional Access has unexpected effects
- Keep the pilot policy in **report-only** and read Entra → **Sign-in logs → Conditional Access** to
  see exactly which control was/wasn't satisfied before turning it **On**.

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (ownership), **Compliance**, **Configuration**;
  Apps → **App protection policies → (policy) → Monitor** for per-user status; Tenant administration →
  **Filters**.
- **Entra:** **Sign-in logs → Conditional Access** tab for grant evaluation.
- **Scripts:** re-run `CODBYOD-Validation.ps1 -User <upn>` after each change to confirm the gate.
