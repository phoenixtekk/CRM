# Testing & Validation — Device Compliance Policies (Government / GCC High edition)

Validation proves the compliance policy **evaluates correctly** and the Conditional Access
gate **enforces** it — on the sovereign cloud, using the sovereign portals. Work through each
test, record **PASS/FAIL**, and only advance a stage when its gate passes.

Run the read-only scripts (`-Environment USGov`) alongside the manual checks so you have
machine-verifiable evidence, not just screenshots.

---

## Test 1 — You are on the GCC High tenant (not Commercial)

**Goal:** Confirm the whole exercise is happening in the government cloud.

| Step | Expected (PASS) |
| --- | --- |
| Admin center URL in the browser | `intune.microsoft.us` (not `.com`) |
| Sign-in redirects to | `login.microsoftonline.us` |
| `DCPG-Validation.ps1` output | Reports `Environment: USGov` and a Government Graph host |

**FAIL if** any URL is a `.com` Commercial host — stop and switch to the sovereign portals.

---

## Test 2 — The named objects exist and are pilot-scoped

**Goal:** Confirm Configure produced exactly the intended objects.

Run `DCPG-Validation.ps1`. It should report:

- `CP-Win-Baseline-GovHigh` **exists**.
- It is assigned to **`SG-Compliance-Pilot`** and **not** to All devices/All users.
- `MT-Compliance-Noncompliant-GovHigh` is attached as a noncompliance action.

**PASS:** all three true. **FAIL:** any missing or the policy is fleet-wide before pilot.

---

## Test 3 — A healthy device evaluates as Compliant

**Goal:** A well-configured pilot device is marked compliant.

1. Pick a pilot device that has BitLocker on, Firewall on, Defender on, TPM present.
2. Sync it (`intune.microsoft.us` → Devices → the device → **Sync**), then **reboot** (needed
   for any boot-time / DHA-measured settings). [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
3. `intune.microsoft.us` → **Devices → Compliance** → the device → per-setting results.

**PASS:** device shows **Compliant** and each configured setting shows **Compliant**.
**FAIL:** device stuck **In progress** for hours, or an expected setting shows **Error**.

---

## Test 4 — DHA behavior on GCC High (the parity check)

**Goal:** Resolve, for **your** tenant, whether the DHA-dependent Device Health settings work
— because Microsoft's docs disagree. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
[[MS-WIN-COMPL]](gcc-high-parity-notes.md)

1. On the pilot device, inspect the results for **Require BitLocker**, **Require Secure
   Boot**, and **Require code integrity**.

| Result | Meaning | Action |
| --- | --- | --- |
| Real **Compliant / Not compliant** | DHA is working in your GCC High tenant | Keep the three settings |
| Perpetual **Not applicable / Error / no result** | DHA appears unavailable here | Set the three to **Not configured**; rely on **Encryption of data storage** + **TPM** instead |

**Record the outcome** in your deployment notes — it determines the supported baseline for
this tenant.

---

## Test 5 — A noncompliant device is caught

**Goal:** The policy correctly flags a device that violates a rule.

1. On a **spare** pilot device (never a production machine), disable a required control —
   e.g. turn **Windows Firewall off** (a non-destructive, easily reversible violation).
2. Sync the device.
3. Confirm `intune.microsoft.us` → **Devices → Compliance** shows the device **Not compliant**
   with the **Firewall** setting failing.
4. Re-enable the firewall, sync, and confirm it returns to **Compliant**.

**PASS:** device flips to Not compliant on violation and back to Compliant on remediation.

---

## Test 6 — The noncompliance action fires

**Goal:** The email notification reaches the user.

1. With a device noncompliant past the scheduled delay, confirm the user receives the
   `MT-Compliance-Noncompliant-GovHigh` email.
2. Confirm the email contains **no Commercial `*.com` remediation links** (Company Portal on
   GCC High is `portal.manage.microsoft.us`).

**PASS:** email received, sovereign links only.

---

## Test 7 — Conditional Access enforces the label

**Goal:** The compliant/noncompliant label actually gates access.

1. With `CA-Require-Compliant-GovHigh` set to **On** and scoped to `SG-Compliance-Pilot`:
   - From a **compliant** pilot device, open the test app (e.g. SharePoint Online) → **access
     granted**.
   - From a **noncompliant** pilot device, attempt the same → **access blocked**.
2. Verify both outcomes in **`entra.microsoft.us` → Sign-in logs** (the Conditional Access
   tab of each sign-in shows the policy result).
3. Confirm the **break-glass** account is excluded and still able to sign in.

**PASS:** compliant allowed, noncompliant blocked, break-glass unaffected.

---

## Validation summary gate

| # | Test | PASS/FAIL |
| --- | --- | --- |
| 1 | On GCC High tenant | |
| 2 | Named objects exist, pilot-scoped | |
| 3 | Healthy device = Compliant | |
| 4 | DHA behavior recorded | |
| 5 | Noncompliant device caught | |
| 6 | Noncompliance email fires | |
| 7 | Conditional Access enforces | |

Do not begin **Expand** until Tests 1–7 pass on the pilot. Re-run `DCPG-Validation.ps1` and
`DCPG-Report.ps1` after each expansion wave to keep the evidence current.
