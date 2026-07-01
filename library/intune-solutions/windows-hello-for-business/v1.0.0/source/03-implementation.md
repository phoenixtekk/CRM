# 3. Implementation Guide — Windows Hello for Business

Follow these steps **in order**. Each step must be complete before the next. All navigation is
in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** Microsoft Entra–joined devices, Intune-managed, Cloud Kerberos Trust.
> **Approach:** We leave the tenant-wide enrollment setting **off** and deploy WHfB as a
> **targeted Account protection policy** to a pilot group. This gives you precise control and a
> clean pilot → production path.

---

## Step 1 — Turn the tenant-wide WHfB enrollment setting to "Not configured"
This prevents an uncontrolled, everyone-at-once rollout so your targeted policy governs the pilot.

1. Go to **Devices → Windows → Windows enrollment**.
2. Click **Windows Hello for Business**.
3. Set **Configure Windows Hello for Business** to **Not configured**.
4. Click **Save**.

## Step 2 — Create the pilot security group
1. Open `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `WHfB-Pilot`.
3. Add 3–5 pilot users (or devices) as **Members**.
4. Click **Create**.

## Step 3 — (Hybrid only) Enable Microsoft Entra Kerberos
Skip if you are cloud-only.

1. On an admin workstation with the on-premises AD module, run **`Enable-EntraKerberos.ps1`** (in this package), signing in with a Domain Administrator and a Global/Cloud Device Administrator.
2. Confirm the script reports the **Azure AD Kerberos server object** was created for your domain.

## Step 4 — Create the WHfB Account protection policy
1. Go to **Endpoint security → Account protection**.
2. Click **+ Create Policy**.
3. **Platform:** Windows. **Profile:** **Account protection** (Windows Hello for Business).
4. Click **Create**.
5. **Name:** `WHfB - Pilot - Entra Joined`. Click **Next**.

## Step 5 — Configure the WHfB settings
On the **Configuration settings** page, set:

1. **Configure Windows Hello for Business:** **Enabled**.
2. **Use a Trusted Platform Module (TPM):** **Yes** (required — blocks weak software keys).
3. **Minimum PIN length:** **6**.
4. **Maximum PIN length:** **127** (or your standard).
5. **Lowercase letters in PIN / Uppercase letters in PIN / Special characters:** **Not allowed** (PIN stays simple unless you require complexity).
6. **Enable enhanced anti-spoofing for facial features:** **Yes**.
7. **Use Windows Hello for Business certificates / Use security keys for sign-in:** leave **Not configured** (Cloud Kerberos Trust needs neither).
8. **Use cloud trust for on-premises authentication (Cloud Kerberos Trust):** **Enabled**.
9. Click **Next**.

## Step 6 — Configure scope tags (optional)
1. On **Scope tags**, add tags if your org uses them, else click **Next**.

## Step 7 — Assign to the pilot group
1. On **Assignments**, under **Included groups**, click **Add groups**.
2. Select **`WHfB-Pilot`**. Click **Select**.
3. Click **Next**.

## Step 8 — Review and create
1. On **Review + create**, confirm every setting.
2. Click **Create**.

## Step 9 — Configure PIN/biometric experience (already set above)
PIN policy and anti-spoofing were set in Step 5. No separate profile is needed for the base solution.
(If you require additional biometric controls, add a **Settings catalog** profile under
**Devices → Configuration → Create → Settings catalog** and search **"Windows Hello"**.)

## Step 10 — Sync and provision a pilot device
1. On a pilot device, open **Settings → Accounts → Access work or school**, select the account, click **Info**, then **Sync**.
2. Sign the user out and back in. At sign-in Windows prompts **"Set up a PIN"** — complete the WHfB enrollment.
3. (Biometric hardware) **Settings → Accounts → Sign-in options → Facial recognition / Fingerprint → Set up**.

## Step 11 — Validate the pilot
1. Run **`WHfB-Validation.ps1`** on the pilot device → confirm the WHfB credential is provisioned.
2. Run **`WHfB-TenantReport.ps1`** → confirm the pilot users show registered WHfB methods in the tenant.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 12 — Expand to production
1. Once the pilot passes, edit the **`WHfB-Pilot`** group membership or create **`WHfB-Production`** and add it to the policy **Assignments**.
2. Roll out in waves (e.g. by department). Re-validate each wave with **`WHfB-Validation.ps1`** / **`WHfB-TenantReport.ps1`**.
3. Keep the tenant-wide enrollment setting **Not configured**; the targeted policy remains the single source of truth.

---
### Order of operations (summary)
`Tenant setting off → Pilot group → (Hybrid: Entra Kerberos) → Create policy → Settings → Assign → Provision device → Validate → Expand`
