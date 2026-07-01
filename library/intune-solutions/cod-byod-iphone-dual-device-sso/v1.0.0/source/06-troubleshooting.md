# 6. Troubleshooting — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Work top-down: confirm the **identity** (one account), then **ownership** (Corporate vs Personal),
then **targeting** (filters/assignments), then **SSO**, then **access** (Conditional Access). Most
issues are an iPhone tagged with the wrong ownership, a missing filter on an assignment, a BYOD user
not using a managed app, or Microsoft Authenticator not installed.

## A user's two iPhones show under different accounts
- **Duplicate identities.** Consolidate to one Entra account; the user must sign in with the same UPN
  on both iPhones (Requirements R1). Re-enroll/re-register the stray iPhone under the correct account.

## A corporate iPhone is tagged Personal (or vice-versa)
- **Wrong ownership.** Intune → **Devices → (device) → Properties → Device ownership** → set
  **Corporate**/**Personal**. For the corporate iPhone, enroll it via **ABM + ADE** so it tags
  Corporate (and supervised) automatically (R5/R12).
- After fixing, the iPhone picks up the correct filtered policies on next sync.

## Corporate policies are not applying to the corporate iPhone
- **Filter mismatch.** The compliance/config assignment must **Include** the **`iPhone – Corporate`**
  filter and target the **user** group (Implementation §§8–9). Verify the filter rule is
  `(device.deviceOwnership -eq "Corporate")`.
- **Device not compliant/enrolled.** Confirm the iPhone is enrolled (supervised, ADE) and checking in.

## App Protection isn't applying to the personal iPhone
- **User not in scope.** App Protection assigns to the **user** group — confirm the pilot user is a
  member (Implementation §10).
- **App not managed/approved.** The user must use an **approved managed app** (Outlook, Edge, Teams).
  The built-in Mail/Safari apps are intentionally excluded.
- **No Intune/MAM license** on the user (R2).
- App Protection applies on **next app launch / token refresh** — close and reopen the managed app.

## Personal iPhone user can't access corporate mail/data
- **By design in an unmanaged app.** They must use the managed app (e.g. Outlook), not the built-in
  one. Deploy and direct them to the approved apps (Implementation §11).
- **Conditional Access blocking.** If CA requires app protection, accessing from a non-managed app is
  blocked — expected. Check Entra → **Sign-in logs** for the CA result.

## Single sign-on keeps prompting for a password
- **Authenticator missing.** Microsoft Authenticator is the iOS identity broker — it must be installed
  on **both** iPhones (R6). On the personal iPhone, sign into one managed app first to register it.
- **Enterprise SSO extension not applied.** On the corporate iPhone, confirm the
  `iPhone – Enterprise SSO – COD – Pilot` profile shows **Succeeded** (Intune → Devices → (device) →
  Device configuration) and that Safari/the target app's bundle ID is listed (Implementation §12).
- **App not Entra-integrated.** Silent SSO applies to Entra-integrated apps; a non-Entra app will
  still prompt.

## One account works on the corporate iPhone but not the personal one (or vice-versa)
- **CA grant too strict.** The Conditional Access policy must **require *one of*** compliant device
  **or** app protection — not **both** (Implementation §15). "Require all" blocks one of the two paths.
- **App protection not yet registered** on the personal iPhone — open a managed app and complete the
  PIN setup.

## Personal iPhone received corporate **device** policies (over-management)
- The personal iPhone was **fully enrolled** and/or tagged **Corporate**. Confirm enrollment
  restrictions and ownership (R4–R5); for BYOD, prefer **App Protection without enrollment**. If
  Account-Driven User Enrollment is intended, ensure it's tagged **Personal** so the `iPhone – Personal`
  filter excludes corporate policies.

## Corporate iPhone won't enroll via ADE
- **APNs/ADE token lapsed.** Renew the **Apple MDM Push certificate** (R11) and the **ADE token** (R12)
  — an expired token blocks all iOS enrollment.
- **Serial not assigned.** Confirm the iPhone serial is in ABM and assigned to the `Intune – iPhone COD`
  MDM server, and the `iPhone ADE – COD – Pilot` profile is assigned (Implementation §§3, 7).

## Conditional Access has unexpected effects
- Keep the pilot policy in **report-only** and read Entra → **Sign-in logs → Conditional Access** to
  see exactly which control was/wasn't satisfied before turning it **On**.

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (ownership), **Compliance**, **Configuration**;
  Apps → **App protection policies → (policy) → Monitor** for per-user status; Tenant administration →
  **Filters**; Devices → Enrollment → Apple for APNs/ADE token status.
- **Entra:** **Sign-in logs → Conditional Access** tab for grant evaluation.
- **Scripts:** re-run `IOSDD-Validation.ps1 -User <upn>` after each change to confirm the gate.
