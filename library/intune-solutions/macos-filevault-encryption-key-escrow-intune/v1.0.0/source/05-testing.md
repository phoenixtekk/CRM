# 5. Testing Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Run after the pilot policy applies (Implementation Step 7) and after each production wave. Use
`MACFV-Validation.ps1` for a single Mac and `MACFV-Report.ps1` for the fleet.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Disk encryption →** `FileVault – Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded** (no Error/Conflict).

## Test 2 — FileVault is on and the volume is encrypted
**Do:** On a pilot Mac run `fdesetup status` (expect `FileVault is On`) and
`diskutil apfs list` (the data volume shows FileVault/encryption). Or run `MACFV-Validation.ps1 -DeviceName "MAC-001"`.
**Expected:** FileVault **On**; the internal volume is encrypted.

## Test 3 — SecureToken confirmed for the FileVault user
**Do:** On the pilot Mac run `sysadminctl -secureTokenStatus <username>`.
**Expected:** The user is **ENABLED** for SecureToken (and appears in `fdesetup list`).

## Test 4 — Personal recovery key escrowed to Intune
**Do:** Intune → **Devices → macOS → <device> → Recovery keys**; or run `MACFV-Validation.ps1`.
**Expected:** A **personal recovery key** is present for the device in Intune.

## Test 5 — Recovery-key retrieval works (Graph)
**Do:** Run **`MACFV-Report.ps1 -DeviceName "MAC-001"`** (retrieves the escrowed personal recovery key for that Mac through Microsoft Graph).
**Expected:** The personal recovery key is returned for an authorized admin.

## Test 6 — Recovery unlock + rotation
**Do:** At the pilot Mac's login/recovery screen, use the escrowed personal recovery key to unlock, reset the password, then re-check Intune → **Recovery keys**.
**Expected:** The key unlocks the volume; Intune **rotates** the key (a new key is escrowed, the used one retired).

## Test 7 — Compliance reflects encryption
**Do:** Intune → device → **Compliance** (with a "require encryption / FileVault" compliance rule for macOS).
**Expected:** The encrypted Mac is **Compliant** for the encryption requirement.

## Test 8 — Fleet report
**Do:** Run **`MACFV-Report.ps1`** (no `-DeviceName`).
**Expected:** A breakdown of encrypted / not-encrypted Macs and a flag for any encrypted Mac **without an escrowed key**.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for the pilot group (escrow confirmed and recovery/rotation verified for every device) |
| **Wave pass** | Tests 2, 4, 8 pass before the next wave (encrypted + escrowed, no unescrowed devices) |
