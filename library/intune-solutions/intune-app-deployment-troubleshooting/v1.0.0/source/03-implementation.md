# Diagnostic Playbook

This is the core of the solution: a **symptom-driven tree**. Start from what you observe, follow the
branch, run the exact checks, and you land on the one pipeline stage that owns the failure. Fix that
stage, then re-run the validation gates in `05-testing.md`.

**Golden rule:** the app pipeline is ordered — **Assign → Requirement → Dependency/Supersedence →
Download → Install → Detection → Report**. The **first** stage that fails is the root cause;
everything after it is a symptom. Never fix a later stage before confirming the earlier ones passed.

---

## Step 0 — Establish the facts (always do this first)

1. **Read the reported state in Intune.** Apps → **All apps** → the app → **Device install status**.
   Note the exact status text for the affected device: *Not applicable*, *Waiting for install
   status*, *Failed (0x…)*, *Installed but not detected*, or *Installed*.
2. **Read the state from Graph.** Run `INTAPPDX-Validation.ps1` for the device to get the app's
   `installState`, `installStateDetail`, and any error code in one place — this is faster and more
   precise than the console for triage across several apps.
3. **Open the device logs.** On the device, open
   `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and
   `AppWorkload.log`. Search for the app's **name** or its **application id**. The log tells you, in
   order, the requirement result, the download, the install command line, the returned exit code,
   and the detection result. Match that against the pipeline to see where it stopped.

Now pick the branch that matches your symptom.

---

## Branch A — "Not applicable" (Requirement not met)

**Symptom:** The device shows **Not applicable**, or the log says the app is *not applicable* and it
never attempts to download or install.

**Owner stage:** Requirement check.

**Checks:**

1. **Confirm the device is even in scope.** Run `INTAPPDX-Discovery.ps1` and confirm the device's
   user or the device is in a group the app is **assigned** to (Required or Available). If not in
   scope, the correct status *is* Not applicable — fix the assignment, not the requirement.
2. **Read each requirement rule.** In Intune, open the app → **Properties → Requirements**. Compare
   every rule against the device's real state:
   - **Operating system architecture** — 32-bit vs 64-bit. A 64-bit-only requirement makes the app
     Not applicable on 32-bit OS.
   - **Minimum operating system** — the device build must be equal or higher.
   - **Disk space / physical memory / logical processors** — read the device's Hardware in Intune.
   - **Registry / file / script requirement rules** — the custom check must return the value the
     rule expects. In the log, find the requirement evaluation line and read the actual value the
     device returned.
3. **Find the exact rule that failed in the log.** `IntuneManagementExtension.log` /
   `AppWorkload.log` logs the requirement evaluation, including which rule returned false and the
   value it saw. That line names the wrong rule directly.

**Fix:** Correct the requirement rule (loosen the OS/architecture rule, or fix the registry/file/
script check to match reality), or fix the assignment so the device is in scope. Bump nothing else.

---

## Branch B — "Installed but shows Failed / not detected" (Detection wrong)

**Symptom:** The app is clearly installed on the device, but Intune reports **Failed** or keeps
**re-installing** it every cycle. The install log shows a **success** exit code, then a detection
line that does not match.

**Owner stage:** Detection.

**Checks:**

1. **Read the detection rule.** App → **Properties → Detection rules**. Detection can be **MSI**,
   **File**, **Registry**, or a **custom detection script**.
2. **Verify the rule against the installed app on the device:**
   - **MSI product code** — run `Get-WmiObject Win32_Product` (or check
     `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`) and confirm the product code the
     rule expects is actually the one the installer registered. Repackaged or updated MSIs often
     ship a new product code.
   - **File** — confirm the exact **path**, **file name**, **version** operator, and **32-bit vs
     64-bit** program-files location. A file-version rule fails if the shipped version differs from
     the rule by even a build number, or if the rule points at `Program Files` on a 32-bit app that
     installed to `Program Files (x86)`.
   - **Registry** — confirm the key, value name, data, and the **32-bit registry view** checkbox.
   - **Custom script** — the script must **write a value to STDOUT and exit 0** to signal detected.
     Run it manually on the device as SYSTEM (via `PsExec -s` or a scheduled task) and confirm it
     prints on success and prints nothing on failure.
3. **Confirm in the log.** The detection result is logged right after the install exit code. If the
   exit code is success and detection is false, the detection rule — not the installer — is wrong.

**Fix:** Correct the detection rule so it matches what the installer actually leaves behind. Then
force a sync and confirm the state moves to **Installed / Detected**.

---

## Branch C — Blocked or looping install (Dependency / Supersedence)

**Symptom:** The app never starts, installs in the wrong order, or an older app keeps coming back /
being removed unexpectedly. The log mentions a **dependency** app or a **superseded** app id.

**Owner stage:** Dependency / supersedence resolution.

**Checks:**

1. **List the relationships.** `INTAPPDX-Discovery.ps1` reports each app's **dependencies** and
   **supersedence** links. Confirm they are what you intend.
2. **Dependency checks:**
   - Every **dependency** app must itself be **assigned** (or set to **auto-install**) and must
     succeed first. A dependency that is Not applicable or Failed on the device blocks the dependent
     app. Diagnose the dependency using Branch A/D/E/F as its own case.
   - Watch for **circular dependencies** (A depends on B, B depends on A) — the log shows the chain
     failing to resolve.
3. **Supersedence checks:**
   - Confirm the supersedence mode: **Update** (replace in place) vs **Uninstall previous version**.
   - A **too-deep supersedence chain** (more than one hop) is not supported and stalls resolution —
     flatten it.
   - Confirm the superseded app's **uninstall command line** actually works; if uninstall fails,
     the new app cannot proceed.

**Fix:** Assign the missing dependency, break the circular link, flatten the chain to a single hop,
or correct the uninstall command. Re-validate the whole pipeline for both apps.

---

## Branch D — Stuck downloading / "Waiting for install status" (Download failure)

**Symptom:** The app sits at **Waiting for install status** for a long time; the log shows the
Management Extension **downloading** content, retrying, or failing to decrypt/extract.

**Owner stage:** Download.

**Checks:**

1. **Read the download lines in the log.** In `IntuneManagementExtension.log`, find the content
   download for the app id. Look for HTTP errors, timeouts, hash/decryption failures, or repeated
   retries.
2. **Disk space.** Confirm the system drive has room for the encrypted download **and** the
   extracted payload under
   `C:\Program Files (x86)\Microsoft Intune Management Extension\Content`.
3. **Network / proxy.** The Management Extension must reach the Intune content delivery endpoints.
   Confirm the device can reach the Microsoft cloud endpoints (see global requirement G7); a proxy
   that blocks the content CDN causes silent, repeated download failures.
4. **Content integrity.** A decryption/hash-mismatch error usually means the `.intunewin` needs to
   be **re-uploaded** (repackage from source and replace the content).

**Fix:** Free disk space, open the required endpoints through the proxy, or re-upload the package.
Then re-sync and watch the download complete in the log.

---

## Branch E — Failed with a raw error code (Exit-code decode)

**Symptom:** The app shows **Failed (0x…)** or a decimal error; the log shows the install command
line ran and the installer **returned a non-success exit code**.

**Owner stage:** Install (exit-code mapping).

**Checks:**

1. **Find the exit code in the log.** `AppWorkload.log` logs the exact **install command line** and
   the **returned exit code** for the app. That code is the installer's, not Intune's.
2. **Decode the code:**
   - **0** = success; **1707** = success; **3010** = success, soft reboot required; **1641** =
     success, hard reboot initiated; **1618** = another install is in progress (retry); **1603** =
     fatal MSI error (the most common real failure).
   - For **1603** and other MSI failures, re-run the install manually on the device with verbose
     MSI logging (`msiexec /i package.msi /l*v install.log`) and read the failing action.
   - For non-MSI installers, look up the vendor's documented exit codes.
3. **Check the app's Return codes table.** App → **Properties → Return codes**. If the installer
   returns a code that Intune treats as **Failure** but the vendor documents it as success (or as
   "reboot required"), map it correctly in the table.

**Fix:** Resolve the installer's real error (from the verbose log), or correct the Return codes
mapping so a benign code is not treated as failure. Re-run and confirm success + detection.

---

## Branch F — User stuck on the Enrollment Status Page (ESP block)

**Symptom:** During Autopilot / first sign-in, the device is stuck on the **ESP** with an app error,
or the ESP times out.

**Owner stage:** ESP (which is exposing an underlying pipeline failure).

**Checks:**

1. **Identify the blocking app.** Intune → **Devices → Enrollment → Enrollment Status Page** →
   your ESP profile → the **"Block device use until these required apps are installed"** list.
   Whichever listed app is failing is the blocker.
2. **Diagnose that app** using Branches A–E — the ESP does not create a new failure; it makes an
   existing requirement/download/install/detection failure fatal at enrollment. Read the same
   Management Extension logs on the device (they exist during ESP).
3. **Check the ESP settings themselves:**
   - **Timeout** — too short a timeout fails a legitimately slow install.
   - **App selection** — an app in the block list that is **Not applicable** to that hardware will
     block forever; only list apps that apply to every enrolling device.
   - **Assignment** — the ESP profile and every blocking app must be **assigned** to the enrolling
     device's group.
4. **"Show error when installation takes longer than…"** — read the on-screen error and correlate it
   to the log.

**Fix:** Resolve the underlying app failure, remove non-universal apps from the block list, extend
the timeout if the install is legitimately long, and confirm every blocking app is assigned to the
enrollment group. Re-image a test device to confirm the ESP completes.

---

## After any fix — re-validate the whole pipeline

Do not stop at the stage you fixed. Force a sync (**Settings → Accounts → Access work or school →
Info → Sync**, or `INTAPPDX-Remediation.ps1`), then re-run `INTAPPDX-Validation.ps1` and confirm the
app reaches **Installed / Detected** — proving every downstream stage now passes too. Use the gates
in `05-testing.md`.
