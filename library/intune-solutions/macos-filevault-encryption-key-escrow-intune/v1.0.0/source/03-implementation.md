# 3. Implementation Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A macOS **FileVault** disk-encryption policy that enables FileVault, **escrows the
> personal recovery key to Intune**, **hides the key from the user**, and **rotates** it — assigned
> to a pilot group first, then expanded. FileVault depends on **SecureToken**, so confirm the
> bootstrap token first.

## Step 1 — Create the device groups
1. In the Intune admin center go to **Groups → New group** (this opens Microsoft Entra).
2. **Group type:** Security. **Group name:** `FileVault – Pilot Devices`. Add a small,
   representative set of pilot Macs. **Create**.
3. Repeat to create `FileVault – Production Devices` for the rest of the Mac fleet (populate it
   later, at Step 8).

## Step 2 — Confirm SecureToken / bootstrap token
1. For **ADE (Automated Device Enrollment)** Macs, the bootstrap token is generated and escrowed at
   setup. Confirm on a pilot Mac: `profiles status -type bootstraptoken` (should report the token
   escrowed to the server), and `sysadminctl -secureTokenStatus <username>` shows **ENABLED** for
   the account that will use FileVault.
2. Run **`MACFV-Discovery.ps1`** to confirm APNs, enrollment, and readiness at the tenant level.
3. **Gate:** Do not proceed until at least one account on each pilot Mac is SecureToken-enabled (see
   Requirements 2.5). Without SecureToken, FileVault will not enable.

## Step 3 — Create the FileVault disk-encryption policy
1. Intune → **Endpoint security → Disk encryption → Create policy**.
2. **Platform:** **macOS**. **Profile:** **FileVault**. **Create**.
3. **Name:** `FileVault – Pilot`. (Optional) Description: note the pilot scope. **Next**.

## Step 4 — Configure FileVault settings (escrow + hide + rotate)
On **Configuration settings**, set FileVault to enable, escrow the personal key, hide it from the
user, and rotate it:
1. **Enable FileVault** = **Yes**.
2. **Escrow location description of personal recovery key** = a short message the user sees, e.g.
   `Your recovery key is stored securely by IT. Contact the Help Desk if you are locked out.`
3. **Hide recovery key from user** = **Yes** (the personal recovery key is escrowed to Intune, not
   shown on screen).
4. **Personal recovery key rotation** = **Enabled** — set a rotation period (for example every
   **6 months**) so keys refresh over time.
5. **Number of times user can bypass** (deferral) = choose a small number (for example **3**) so
   enablement is enforced after a few logins rather than deferred indefinitely.
6. **Disable prompt at sign out** / defer-until-logout options = leave at the defaults unless you
   have a reason to change them. Click **Next**.

> **Note:** Intune's FileVault profile uses the **personal recovery key** model (per-device key
> escrowed to Intune). It does not configure an institutional key — that legacy model is out of
> scope by design (see Overview).

## Step 5 — Scope tags (optional) and Assign to the pilot
1. **Scope tags** — add if you use RBAC scoping. **Next**.
2. **Assignments → Add groups →** `FileVault – Pilot Devices`. **Next → Review + create → Create**.

## Step 6 — Apply on a pilot Mac
1. On a pilot Mac, sync policy (**System Settings → Privacy & Security → Profiles**, or force a
   check-in from Company Portal).
2. At the next **log out / log in**, the SecureToken-enabled user is prompted to enable FileVault
   (up to the bypass count you set). After the user signs in, **encryption begins**.

## Step 7 — Validate the pilot (escrow + recovery)
1. Run **`MACFV-Validation.ps1 -DeviceName "MAC-001"`** → confirms Intune sees the device as
   **encrypted** and that a **personal recovery key is escrowed**.
2. In Intune → **Devices → macOS → <device> → Recovery keys**, confirm the **personal recovery key
   is present**.
3. **Recovery workflow test:** on the pilot Mac, at the login screen choose the "reset password /
   recovery key" path, enter the escrowed personal recovery key retrieved from Intune (or via
   `MACFV-Report.ps1`), and confirm the volume unlocks. Then confirm Intune **rotates** the key
   (a new key appears; the used one is retired).
4. Run **`MACFV-Report.ps1`** → confirms encryption + escrow coverage across the pilot group.
   Complete the **Testing Guide** (document 5).

> **Pilot pass gate:** every pilot Mac is **encrypted**, has an **escrowed personal recovery key**,
> and the **recovery-key unlock + rotation** worked. Do not expand until this passes.

## Step 8 — Expand to production
1. Populate `FileVault – Production Devices` and add it to the `FileVault – Pilot` policy's
   **Assignments** (or clone the policy as `FileVault – Production`); roll out in waves.
2. For each wave, confirm **escrow for every device** — a Mac that encrypts without an escrowed key
   is a recovery risk. Use `MACFV-Report.ps1`.
3. If any Mac is encrypted but **not escrowed** or FileVault did not enable, run
   **`MACFV-Remediation.ps1`** (preview first; it defaults to `-WhatIf`).

---
### Order of operations
`Device groups → Confirm SecureToken/bootstrap token → FileVault policy (enable + escrow + hide +
rotate) → Assign to pilot → Apply at login → Validate encryption + escrow + recovery → Expand`
