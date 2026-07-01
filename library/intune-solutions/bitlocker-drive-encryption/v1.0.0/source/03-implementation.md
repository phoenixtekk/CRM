# 3. Implementation Guide — BitLocker Drive Encryption

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A disk encryption policy requiring XTS-AES 256, Entra key escrow, and silent
> enablement, assigned to a pilot group.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `BitLocker-Pilot` → add pilot devices/users. **Create**.

## Step 2 — Create the disk encryption policy
1. Intune → **Endpoint security → Disk encryption → Create policy**.
2. **Platform:** Windows. **Profile:** **BitLocker**. **Create**.
3. **Name:** `BitLocker - Pilot`. **Next**.

## Step 3 — Configure BitLocker settings
On **Configuration settings**:
1. **BitLocker – Base Settings**
   - **Enable full disk encryption for OS and fixed data drives** = **Yes**.
   - **Require storage cards to be encrypted (mobile only)** = not applicable.
   - **Hide prompt about third-party encryption** = **Yes**.
   - **Allow standard users to enable encryption during Autopilot** = **Yes**.
   - **Configure client-driven recovery password rotation** = **Enabled for Microsoft Entra joined devices**.
2. **BitLocker – Fixed Drive Settings**
   - **Fixed drive recovery** = **Configure** → **Save BitLocker recovery information to Microsoft Entra ID** = **Yes**; **Store recovery information before enabling** = **Yes**.
   - **Block write access to fixed drives not protected by BitLocker** = optional.
3. **BitLocker – OS Drive Settings**
   - **Encryption for OS drives** = **Require**.
   - **BitLocker with non-compatible TPM chip** = block (or allow PIN if you support non-TPM).
   - **OS drive recovery** = **Configure** → **Save BitLocker recovery information to Microsoft Entra ID** = **Yes**; **Store recovery information before enabling** = **Yes**; **Hide recovery options during BitLocker setup** = **Yes**.
   - **Encryption method** = **XTS-AES 256-bit**.
4. **BitLocker – Removable Drive Settings** = as required. Click **Next**.

## Step 4 — Assign to the pilot group
1. **Assignments → Add groups →** `BitLocker-Pilot`. **Next → Create**.

## Step 5 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. On TPM devices encryption begins **silently**; otherwise the user is prompted for a startup PIN.

## Step 6 — Validate the pilot
1. Run **`BITLK-Validation.ps1`** → confirms the OS drive is encrypting/encrypted with the right method and a recovery protector exists.
2. In Intune → device → **Recovery keys**, confirm the **recovery key is escrowed**.
3. Run **`BITLK-TenantReport.ps1`** → confirms encryption status across the pilot group. Complete the **Testing Guide**.

## Step 7 — Expand to production
1. Add a production group to the policy **Assignments**; roll out in waves.
2. Confirm key escrow for each wave (a device that encrypts without an escrowed key is a recovery risk).
3. Re-validate with **`BITLK-Validation.ps1`** / **`BITLK-TenantReport.ps1`**.

---
### Order of operations
`Pilot group → Disk encryption policy → Base/Fixed/OS settings (XTS-AES 256 + Entra escrow + silent) → Assign → Apply → Validate encryption + escrow → Expand`
