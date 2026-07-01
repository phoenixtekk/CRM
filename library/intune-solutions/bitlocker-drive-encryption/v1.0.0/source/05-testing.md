# 5. Testing Guide — BitLocker Drive Encryption

Run after the pilot policy applies (Implementation Step 6) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Disk encryption →** `BitLocker - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded** (no Error).

## Test 2 — OS drive is encrypted
**Do:** On a pilot device run `BITLK-Validation.ps1` or `manage-bde -status`.
**Expected:** OS drive **Protection On**, **Percentage Encrypted = 100%**, **Encryption Method = XTS-AES 256**.

## Test 3 — Silent enablement (TPM devices)
**Do:** Observe a TPM device after policy sync — no user prompt.
**Expected:** Encryption begins automatically with no user interaction.

## Test 4 — Recovery key escrowed to Entra
**Do:** Intune → device → **Recovery keys** (or Entra → device → **BitLocker keys**).
**Expected:** A recovery key is present for the device.

## Test 5 — Recovery key retrieval works
**Do:** Run **`BITLK-Get-RecoveryKey.ps1 -DeviceName <name>`** (Graph).
**Expected:** The recovery password is returned for an authorized admin.

## Test 6 — Compliance reflects encryption
**Do:** Intune → device → **Compliance** (with a "require encryption" compliance rule).
**Expected:** The encrypted device is **Compliant** for the encryption requirement.

## Test 7 — Tenant report
**Do:** Run **`BITLK-TenantReport.ps1`**.
**Expected:** A breakdown of encrypted / encrypting / not-encrypted devices.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass for the pilot group (escrow confirmed for every device) |
| **Wave pass** | Tests 2, 4, 7 pass before the next wave |
