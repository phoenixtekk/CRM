# 5. Testing Guide — Windows Hello for Business

Run these validations after the pilot is provisioned (Implementation Step 11) and again after
each production wave. Each test states **what to do** and the **expected result**. Do not expand
the rollout until every test passes for the pilot group.

## Test 1 — WHfB is enabled on the device
**Do:** On a pilot device run `dsregcmd /status`. Review the **NgcSet** value under SSO State.
**Expected:** `NgcSet : YES` (the Next Generation Credential — the WHfB key — is set).

## Test 2 — The policy applied
**Do:** Intune admin center → **Endpoint security → Account protection →** `WHfB - Pilot - Entra Joined` **→ Device/User check-in status**.
**Expected:** Pilot devices/users show **Succeeded**. No **Error** or **Conflict**.

## Test 3 — PIN enrollment works
**Do:** Sign out and sign in as a pilot user. When prompted, complete **Set up a PIN**.
**Expected:** The PIN is accepted (min length 6), and subsequent sign-ins accept the PIN with no password.

## Test 4 — Biometric enrollment works (if hardware present)
**Do:** **Settings → Accounts → Sign-in options → Facial recognition / Fingerprint → Set up.**
**Expected:** Enrollment completes; signing out and back in succeeds with face/fingerprint.

## Test 5 — Authentication succeeds (cloud)
**Do:** Lock the device (Win+L) and unlock with the PIN/biometric. Open a browser to `https://myapps.microsoft.com`.
**Expected:** Unlock succeeds and Microsoft 365 apps authenticate with no password prompt.

## Test 6 — On-premises resource access (hybrid only)
**Do:** From a WHfB-signed-in hybrid device, open a mapped **file share** and a **print queue** on-premises.
**Expected:** Access is granted without a credential prompt (Microsoft Entra Kerberos issued the ticket). Confirm with `klist` showing a TGT.

## Test 7 — Compliance remains intact
**Do:** Intune → **Devices → Compliance**; review the pilot devices after WHfB provisioning.
**Expected:** Devices remain **Compliant**; no new compliance failures were introduced.

## Test 8 — Tenant-wide registration report
**Do:** Run **`WHfB-TenantReport.ps1`** (Microsoft Graph).
**Expected:** Pilot users appear with **Windows Hello for Business** listed among their registered authentication methods.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 (and 6 if hybrid, 7–8) all pass for **100%** of the pilot group |
| **Wave pass** | Tests 1–3, 5, 7 pass for the wave before starting the next |

Record results in your change log. If any test fails, use the **Troubleshooting Guide** (Section 6)
and the **`WHfB-Remediation.ps1`** script before proceeding.
