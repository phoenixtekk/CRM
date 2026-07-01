# 3. Implementation Guide — Cloud-First Autopilot Zero-Touch Provisioning

Follow these steps in order. All navigation is in the Microsoft Intune admin center
(`https://intune.microsoft.com`) unless stated otherwise.

> Model: user-driven, Microsoft Entra joined Autopilot, assigned to a dynamic Autopilot device group,
> with an Enrollment Status Page and provisioning-time apps/policy. Default to cloud-first; add domain
> join later only for a named on-prem dependency (Step 9).

Named artifacts (reuse verbatim — these match the Requirements Guide):
- Autopilot group: `Autopilot Devices – All Cloud-First – Provisioning`
- Deployment profile: `Autopilot Profile – Entra Join – Provisioning`
- Enrollment Status Page: `ESP – Cloud-First – Provisioning`
- Provisioning app set: `App Assignments – Core Apps – Provisioning`
- Baseline: `Security Baseline – Cloud-First – Provisioning`

## Step 1 — Enable automatic MDM enrollment
1. Go to Devices → Enrollment → Automatic Enrollment.
2. Set MDM user scope to All (or your pilot group). Click Save.

## Step 2 — Register the pilot device(s)
1. On each pilot device (in OOBE or already running), run `CFAP-Discovery.ps1` to confirm readiness and
   to export the hardware hash CSV, or use the built-in
   `Get-WindowsAutopilotInfo` from the `WindowsAutopilotIntune` / `Get-WindowsAutopilotInfo` script.
2. Go to Devices → Enrollment → Windows → Windows Autopilot → Devices → Import, then upload the CSV.
3. Click Sync and wait for the device to appear under Windows Autopilot → Devices.
   (At scale, have the OEM/reseller register devices at purchase so this step is unnecessary.)

## Step 3 — Create the dynamic Autopilot device group
1. Open `https://entra.microsoft.com` → Groups → New group.
2. Group type: Security. Name: `Autopilot Devices – All Cloud-First – Provisioning`.
3. Membership type: Dynamic Device.
4. Add the dynamic membership rule: `(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))`. Save.
5. Click Create. Registered Autopilot devices join this group automatically.

## Step 4 — Configure company branding (optional but recommended)
1. Open `https://entra.microsoft.com` → Company branding → Customize (or Add).
2. Add your logo, background, and sign-in text so the OOBE shows your brand. Save.

## Step 5 — Create the Autopilot deployment profile (Entra join)
1. Go to Devices → Enrollment → Windows → Windows Autopilot → Deployment profiles → Create profile →
   Windows PC.
2. Name: `Autopilot Profile – Entra Join – Provisioning`. Click Next.
3. On Out-of-box experience (OOBE):
   - Deployment mode: User-driven.
   - Join to Microsoft Entra ID as: Microsoft Entra joined. (This is the cloud-first choice — not
     Microsoft Entra hybrid joined.)
   - Microsoft Software License Terms: Hide.
   - Privacy settings: Hide.
   - Hide change account options: Yes.
   - User account type: Standard.
   - Allow pre-provisioned deployment: No (keep the pilot simple).
   - Apply device name template: optionally set a naming template (for example `CF-%SERIAL%`).
4. Click Next → Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`.
5. Click Next → Create.

## Step 6 — Assign the provisioning-time apps
1. Go to Apps → Windows → Add and add each core app the device must arrive with (for example the
   Microsoft 365 Apps, the company VPN/agent, and any line-of-business app). Name this set, in your
   notes, `App Assignments – Core Apps – Provisioning`.
2. For each app: Assignments → Required → Add group →
   `Autopilot Devices – All Cloud-First – Provisioning`. Save.
3. Keep the blocking set lean — large apps extend the Enrollment Status Page wait.

## Step 7 — Assign a security baseline
1. Go to Endpoint security → Security baselines → choose the Windows baseline → Create profile.
2. Name: `Security Baseline – Cloud-First – Provisioning`. Accept or tune the defaults. Next.
3. Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`. Create.

## Step 8 — Create the Enrollment Status Page (ESP)
1. Go to Devices → Enrollment → Windows → Enrollment Status Page → Create.
2. Name: `ESP – Cloud-First – Provisioning`. Next.
3. Settings:
   - Show app and profile configuration progress: Yes.
   - Block device use until all apps and profiles are installed: Yes.
   - Allow users to reset device if installation error occurs: Yes.
   - Show error when installation takes longer than (minutes): set a sensible limit (for example 60).
   - Block device use until these required apps are installed: select only the must-have apps from
     `App Assignments – Core Apps – Provisioning`.
4. Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`. Create.

## Step 9 — Provision a pilot device (the zero-touch flow)
1. Power on a reset/new registered pilot device and connect it to the internet at OOBE.
2. Your company branding appears; the user signs in once with their work account.
3. The device Microsoft Entra joins, auto-enrolls in Intune, and the ESP runs — installing the
   provisioning apps and baseline — until the device is ready.
4. The user reaches a fully configured desktop. Technician touch: power-on only.

## Step 10 — Validate the pilot
1. Run `CFAP-Validation.ps1` → confirms the device is Autopilot-registered, Microsoft Entra joined,
   Intune-enrolled, and that the assigned apps/baseline are present.
2. Run `CFAP-Report.ps1` → confirms provisioning success and the technician-touch summary across pilot
   devices.
3. Complete the Testing Guide (Section 5) before expanding.

## Step 11 — Decision path: add domain join LATER, only if required
Default to cloud-first. Add domain join only for a device that has a named, verified on-prem dependency.
Use these criteria in order:
1. Does any required app authenticate only via Kerberos/NTLM to on-prem Active Directory (no modern
   auth, no Entra app)? Does the device need an on-prem-only file share or print server?
   - If No → stay Entra joined. Done.
   - If Yes → continue.
2. Can the on-prem resource be reached without changing the join type? Prefer Microsoft Entra Kerberos
   / Cloud Kerberos Trust (for SMB/Kerberos resource access from an Entra-joined device). If that meets
   the need → stay Entra joined and enable Cloud Kerberos Trust. Done.
3. Only if neither cloud option works, adopt the exception: Microsoft Entra hybrid join for that device
   class. This requires line-of-sight to a domain controller and the on-prem Intune Connector for
   Active Directory. Create a separate hybrid Autopilot deployment profile (Join type: Microsoft Entra
   hybrid joined) and a separate device group; do not change the default cloud-first profile. Document
   the named dependency that justified the exception.

## Step 12 — Expand to production
1. Register production devices (OEM/reseller registration at purchase is ideal at scale).
2. They join `Autopilot Devices – All Cloud-First – Provisioning` automatically (dynamic group) and
   inherit the profile, ESP, apps, and baseline.
3. Re-validate each wave with `CFAP-Validation.ps1` and `CFAP-Report.ps1`; track the technician-touch
   rate trending toward zero.

---
### Order of operations
`Auto-enrollment → Register devices → Dynamic group → Branding → Deployment profile (Entra join) → Provisioning apps → Baseline → ESP → Provision → Validate → (Domain-join exception only if required) → Expand`
