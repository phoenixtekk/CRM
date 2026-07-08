# Testing & Validation — Enable Microsoft Intune (Quick-Start)

Prove the enablement worked by enrolling one Windows PC and one iPhone, then confirming both check in and
report compliant. Use the included scripts to verify tenant state without clicking through every blade.

---

## Pre-check — confirm the tenant is ready
Run the Discovery script first (see the Scripts appendix / `scripts\` folder):

```
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"
.\ITSTART-Discovery.ps1
```

**Expect:** it reports the MDM authority = Intune, an Apple MDM push certificate present (with expiry),
Windows auto-enrollment scope configured, and your pilot group and baseline policies found. Fix any ❌
before enrolling devices.

---

## Test 1 — Enroll the Windows device (automatic)
1. On the test PC, ensure it is **not** already managed. Go to **Settings → Accounts → Access work or
   school**.
2. Click **Connect**, then **"Join this device to Microsoft Entra ID."**
3. Sign in as your pilot user (`pilot01@contoso.com`) and complete the join. Reboot if prompted.
4. Sign in to the PC with the pilot user. Automatic enrollment runs in the background.

**Validate:**
- On the PC: **Settings → Accounts → Access work or school → (your account) → Info**. Under **Device sync
  status**, click **Sync** and confirm areas report successfully.
- In the **Intune admin center → Devices → All devices**, the PC appears, **Managed by = Intune**, and
  after a check-in shows **Compliant** against `Compliance – Windows – Baseline`. Confirm the setting from
  `Config – Windows – Baseline` applied.

## Test 2 — Enroll the iPhone (personal / BYOD via Company Portal)
1. On the iPhone, install **Intune Company Portal** from the App Store.
2. Open it and **sign in** as your pilot user.
3. Follow the prompts: tap **Begin → Continue**, allow the **management profile** download, then go to
   **Settings → Profile Downloaded → Install** and confirm with the device passcode.
4. Return to Company Portal and finish; it confirms the device is now managed.

**Validate:**
- In **Company Portal**, the device shows **"Can access company resources"** / compliant.
- In **Intune admin center → Devices → All devices**, the iPhone appears, **Managed by = Intune**, and
  reports **Compliant** against `Compliance – iOS – Baseline` after check-in.

## Test 3 — Confirm reporting end to end
Run the reporting script for a clean summary of what enrolled and its compliance:

```
.\ITSTART-Report.ps1 -OutCsv .\quickstart-enrollment.csv
```

**Expect:** a table (and CSV) listing your two devices with platform, ownership, management state, and
compliance — proof that Intune is functioning for both Windows and iOS.

## Test 4 — Validate the enablement checklist
Run the validation script to score the enablement against the Quick-Start's success criteria:

```
.\ITSTART-Validate.ps1
```

**Expect:** all checks **PASS** — MDM authority set, Apple push certificate valid, Windows auto-enrollment
on, baseline compliance policies assigned, and at least one Windows + one iOS device enrolled and
compliant. Any **FAIL** points you to the exact step to revisit.

---

## Success criteria (you are done when all are true)
- ✅ MDM authority = **Microsoft Intune**.
- ✅ Apple MDM push certificate is **valid**.
- ✅ Windows automatic enrollment is **enabled** for the pilot scope.
- ✅ One **Windows** device is enrolled and **compliant**.
- ✅ One **iPhone** is enrolled and **compliant**.
- ✅ Baseline configuration and compliance policies are **assigned and evaluating**.

When these hold, you have a **functioning Intune** — ready to expand to more devices and layer on the
deeper catalog solutions.
