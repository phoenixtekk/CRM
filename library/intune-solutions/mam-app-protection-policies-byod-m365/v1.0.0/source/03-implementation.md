# 3. Implementation Guide — MAM App Protection Policies for BYOD

Follow these steps in order. App Protection and App Configuration policies are in the Microsoft
Intune admin center (`https://intune.microsoft.com` → Apps). The Conditional Access grant is in
Microsoft Entra (`https://entra.microsoft.com` → Conditional Access).

> Model: Create iOS + Android App Protection Policies, add an App Configuration Policy, enforce with a
> Conditional Access "Require app protection policy" grant, validate on an unenrolled BYOD device,
> then pilot and expand.

Reuse these object names exactly: `MAM Users – BYOD – Pilot`, `MAM Users – BYOD – Production`,
`BYOD – App Protection – iOS`, `BYOD – App Protection – Android`, `BYOD – App Config – M365`,
`CA – Require APP – M365`.

## Step 1 — Create the scope groups
1. Entra → Groups → New group → Security → `MAM Users – BYOD – Pilot` (a few representative BYOD users). Create.
2. Create `MAM Users – BYOD – Production` (the rest of the BYOD population). Create.

## Step 2 — Create the iOS App Protection Policy
1. Intune → Apps → App protection policies → Create policy → iOS/iPadOS.
2. Name: `BYOD – App Protection – iOS`. Next.
3. Apps: Target policy to `Selected apps` (or `All Microsoft apps`). Add Outlook, Teams, SharePoint, OneDrive, and Edge. Next.
4. Data protection:
   - Backup org data to iTunes and iCloud backups: `Block`.
   - Send org data to other apps: `Policy managed apps` (limits "open in / share").
   - Receive data from other apps: `Policy managed apps`.
   - Restrict cut, copy, and paste between other apps: `Policy managed apps with paste in`.
   - Save copies of org data: `Block`, then allow only `OneDrive for Business` and `SharePoint` under `Allow user to save copies to selected services`.
   - Encrypt org data: `Require`.
5. Access requirements:
   - PIN for access: `Require`; PIN type and length per your policy; allow biometric as an alternative.
   - Recheck the access requirements after (minutes of inactivity): `30`.
   - Offline grace period: `720` minutes to block access; `90` days to wipe org data.
   - Next.
6. Conditional launch:
   - Jailbroken/rooted devices: `Block access`.
   - Min OS version and min app version: set per your standard (action `Warn` or `Block`).
   - Max PIN attempts: `5` → action `Reset PIN` (or `Wipe data`).
   - Next.
7. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 3 — Create the Android App Protection Policy
1. Intune → Apps → App protection policies → Create policy → Android.
2. Name: `BYOD – App Protection – Android`. Next.
3. Apps: add the same set — Outlook, Teams, SharePoint, OneDrive, and Edge. Next.
4. Data protection: match Step 2's settings (block backup, policy-managed transfer, block save-as except OneDrive/SharePoint, require encryption). Also set `Screen capture and Google Assistant` to `Block` if required. Next.
5. Access requirements: require an app PIN (allow biometric), recheck after `30` minutes, offline grace `720` minutes to block / `90` days to wipe. Next.
6. Conditional launch: rooted devices → `Block access`; set min OS / min app version and min patch level; max PIN attempts `5` → `Reset PIN`. Set `Device attestation` (SafetyNet / Play Integrity) to `Require` if your standard needs it. Next.
7. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 4 — Create the App Configuration Policy (managed apps)
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `BYOD – App Config – M365`. Next.
3. Public apps: select the same Microsoft 365 apps (iOS and Android). Next.
4. Settings: add managed-app configuration keys per your standard — for example, set the default save location to OneDrive/SharePoint, and configure the Edge managed browser (require org sign-in, restrict which sites open outside the managed browser). Next.
5. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 5 — Enforce with Conditional Access (require app protection policy)
1. Entra → Conditional Access → Create new policy.
2. Name: `CA – Require APP – M365`.
3. Users: Include `MAM Users – BYOD – Pilot`; Exclude the two break-glass accounts.
4. Target resources: Cloud apps → Office 365.
5. Conditions → Device platforms → Include `iOS` and `Android`.
6. Grant: Grant access → select `Require app protection policy` and `Require approved client app`; choose `Require one of the selected controls` (so either satisfies on platforms that support one).
7. Enable policy: `Report-only`. Create.

## Step 6 — Validate on an unenrolled BYOD device
1. On a personal (unenrolled) iPhone or Android, install the Microsoft 365 apps (and Company Portal on Android — for MAM brokering only; do not enroll).
2. Sign in to Outlook with the pilot work account. The app should apply the policy: prompt to set an app PIN and show the "managed by your organization" data-protection behavior.
3. Try to copy org text into a personal app — the paste should be blocked; try to save an attachment to a personal location — save-as should be blocked (OneDrive/SharePoint allowed).
4. Run `MAMAPP-Validation.ps1` to confirm the user's apps report a protection policy applied.

## Step 7 — Validate the pilot and enable enforcement
1. Run `MAMAPP-Report.ps1` to confirm coverage (which pilot users/apps have the policy) and the CA grant status.
2. In Entra → Sign-in logs, open a pilot sign-in → Report-only tab and confirm `CA – Require APP – M365` would apply and grant only from a protected app.
3. Complete the Testing Guide. When clean, edit `CA – Require APP – M365` → Enable policy → `On`.

## Step 8 — Expand to production
1. Add `MAM Users – BYOD – Production` to the Included groups of `BYOD – App Protection – iOS`, `BYOD – App Protection – Android`, `BYOD – App Config – M365`, and `CA – Require APP – M365`.
2. Roll out in waves; monitor sign-in logs and run `MAMAPP-Report.ps1` each wave.
3. Re-validate with `MAMAPP-Validation.ps1`; remediate gaps with `MAMAPP-Remediation.ps1`.

---
### Order of operations
`Scope groups → iOS APP → Android APP → App config → CA grant (Report-only) → Validate on BYOD → Enable → Expand`
