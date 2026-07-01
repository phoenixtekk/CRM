# 5. Testing & Validation — Certificate-Based VPN Authentication for Cisco ISE with Intune

Run these tests in order. Each has an explicit **pass/fail gate**. Do not advance past a failed gate
— a failure here prevents a lockout in production. The three gates that matter most: **cert present,
chain valid, ISE EAP-TLS auth success.**

> Object names referenced: `Cisco VPN – Trusted Root`, `Cisco VPN – SCEP Device Cert` /
> `Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`, `PILOT – Cisco Cert VPN Users`.

---

## Test 1 — Profiles exist and are assigned (readiness)
**How:** Run **`CISECERT-Discovery.ps1`**. Confirm the certificate connector is present/active and
that `Cisco VPN – Trusted Root` and your SCEP/PKCS profile appear with the pilot group assigned.
Alternatively, in **Intune → Devices → Manage devices → Configuration → Policies**, confirm both
profiles and their assignments.
**PASS:** Connector active; Trusted Root + SCEP/PKCS profiles exist and are assigned to
`PILOT – Cisco Cert VPN Users`.
**FAIL:** Missing connector or profile → Troubleshooting **A**; revisit Implementation Steps 2–3.

---

## Test 2 — The trust chain is present on the device
**How:** On a pilot device, run **`CISECERT-Validation.ps1 -IssuingCaName "your-issuing-ca-name"`**
(elevated). Check the **root trusted** result. Or open `certlm.msc` → **Trusted Root Certification
Authorities** (and **Intermediate** if applicable) and confirm the CA is present.
**PASS:** The root (and intermediate) CA certificate is present in the device trust store.
**FAIL:** Chain incomplete → Troubleshooting **B**. Do not proceed — the leaf cannot chain.

---

## Test 3 — The leaf certificate is issued and valid (cert present)
**How:** On the pilot device, from the same `CISECERT-Validation.ps1` run, check: **leaf present**,
**issued by your CA**, **chain valid**, **Client Authentication EKU present**, **within validity**.
Or `certlm.msc` → **Personal → Certificates** and inspect the leaf's **Issuer**, **EKU** (Client
Authentication), and **valid-to** date.
**PASS:** A leaf certificate issued by your CA is present, chains to the trusted root, carries the
**Client Authentication** EKU (`1.3.6.1.5.5.7.3.2`), and is unexpired.
**FAIL:** No cert / wrong EKU / broken chain → Troubleshooting **A** (no cert) or **B** (chain).

---

## Test 4 — Subject/SAN matches what ISE keys on (identity)
**How:** Inspect the leaf's **Subject** and **Subject Alternative Name** (`certlm.msc` → cert →
Details, or the Subject line printed by `CISECERT-Validation.ps1`). Compare to the identity attribute
your ISE **Certificate Authentication Profile** reads (e.g. SAN **UPN**).
**PASS:** The issued Subject/SAN exactly matches the attribute ISE is configured to key on.
**FAIL:** Mismatch → fix the SCEP/PKCS **Subject name / SAN** (Implementation Step 3) or align the
ISE Certificate Authentication Profile (Cisco docs). This is the classic silent failure.

---

## Test 5 — ISE accepts the EAP-TLS handshake (auth success)
**How:** Connect the VPN from the pilot device using the certificate (no password). Confirm success
in **ISE RADIUS Live Logs** (*Cisco docs*): the authentication method is **EAP-TLS** and the result
is **Access-Accept**.
**PASS:** ISE Live Logs show **EAP-TLS → Access-Accept** for the pilot identity and the VPN session
establishes **without a password**.
**FAIL:** ISE rejects → Troubleshooting **C**. Common causes: ISE does not trust the CA, the
Certificate Authentication Profile keys on a different attribute, revocation check fails, or the
head-end is not passing EAP-TLS.

---

## Test 6 — Renewal works before expiry
**How:** Confirm the profile's **renewal threshold** is set (e.g. 20%). For a fast check, review a
pilot device near threshold, force a sync, and re-run `CISECERT-Validation.ps1` to confirm a fresh
`NotAfter`. Use **`CISECERT-Report.ps1`** to watch for devices trending toward expiry.
**PASS:** Certificates renew automatically before expiry; no device drops to an expired leaf.
**FAIL:** Renewal not firing → Troubleshooting **D** (renewal failures).

---

## Test 7 — Fleet coverage before expansion
**How:** Run **`CISECERT-Report.ps1`** (optionally `-CsvPath`). Review Succeeded / Error / Pending
counts for the certificate profile.
**PASS:** Pilot (then each expansion wave) shows the expected Succeeded count with no unresolved
Error/Pending.
**FAIL:** Laggards present → run **`CISECERT-Remediation.ps1`** (default `-WhatIf`, then `-Apply`) to
trigger re-evaluation, re-check, then expand.

---

## Exit criteria (all must pass before broad rollout)
- Test 1 (readiness), Test 2 (**chain valid**), Test 3 (**cert present**), Test 4 (identity),
  Test 5 (**ISE EAP-TLS auth success**), Test 6 (renewal), Test 7 (coverage) all **PASS** on the
  pilot.
- A rollback step is documented and the password/legacy VPN auth path remains available until broad
  certificate auth is proven.
