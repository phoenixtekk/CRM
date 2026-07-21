# 3. Implementation — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The design is: **author an idempotent detection script
and a minimal, preview-first remediation script → package them as a named Intune remediation → scope
to a pilot ring → schedule → read status/output → wave to production behind guardrails → register the
proven pair in a governed library.** Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`

> **Navigation flag.** The exact **Remediations** location and blade names in Intune change over
> time and differ by cloud (Commercial vs. GCC / GCC High / DoD). This guide uses the common path
> **Reports → Endpoint analytics → Remediations** (some tenants also surface it under **Devices →
> Remediations**). **Verify the current path against Microsoft's documentation for your tenant**
> before creating objects.

> **Worked example used throughout.** So every step is concrete, this guide builds one real pair: a
> **service-health** remediation that ensures the **Windows Time service (`w32time`)** is set to
> **Automatic** and **Running** — a common recurring drift. Reuse the *pattern* (and the included
> templates) for your own conditions; the object names below are the ones to reuse verbatim.

---

## Phase 1 — Author the pair (safety first)

### Step 1. Author the detection script (idempotent, read-only, exit-code contract)
1. In your `Remediations Pack Library` location (Requirements §R10), create a file **named
   `Detect-ServiceHealth-w32time.ps1`**. Use the included **`PROREM-Detect-Template.ps1`** as the
   starting point.
2. The detection must do **three things and nothing else**:
   - **Observe only** — read the state (here: query the `w32time` service start type and status).
     It must **never change** the device. Detection is read-only by contract.
   - **Reach the same verdict every run** (idempotent) — given the same device state, it always
     returns the same result.
   - **Report via exit code only** — `exit 0` = **healthy** (do nothing); `exit 1` = **issue found**
     (run the remediation). Write a short human-readable line to output for the console, but the
     **exit code is the contract**.
3. Example logic (conceptual): if the service is `Automatic` **and** `Running` → `Write-Output
   "w32time healthy"; exit 0`. Otherwise → `Write-Output "w32time not Automatic/Running"; exit 1`.
4. Save it. **Do not** put any fix logic in the detection script — a detection that "fixes while it
   checks" breaks the model and hides what remediation actually did.

### Step 2. Author the remediation script (minimal, preview-first, logged)
1. In the same library location, create a file **named `Remediate-ServiceHealth-w32time.ps1`**. Use
   the included **`PROREM-Remediate-Template.ps1`** as the starting point — **it defaults to a
   preview (dry-run)**.
2. The remediation must:
   - **Default to preview** — on first authoring and first pilot, it **logs exactly what it would
     change without changing it**. You only remove the preview gate once you have proven, from the
     log, that it would do the right and minimal thing. (The template's `-WhatIf`-style
     `$DryRun = $true` default enforces this.)
   - **Change the smallest possible thing** — set the `w32time` start type to `Automatic` and start
     the service if stopped. Nothing else. No "while I'm here" extras.
   - **Be idempotent** — running it on an already-fixed device makes no further change and still
     `exit 0`.
   - **Log to a predictable path** — write a timestamped line to a log (e.g. under
     `C:\ProgramData\Remediations\`) so you have on-device evidence of every action.
   - **Report success via `exit 0`** — a remediation that completes its fix exits `0`; if it cannot
     fix (e.g. insufficient rights, target absent), it writes the reason and `exit 1`.
3. **Prove it in preview first:** run the remediation locally (or on one pilot device) with the
   dry-run default and read the log — confirm it *would* make exactly the intended minimal change.
   Only then produce the "acting" version by setting the dry-run switch off for deployment.

### Step 3. Match the run context to what the pair touches
1. Decide the **run context** for this pair. The `w32time` service is **machine-wide**, so this pair
   runs as **system** (no signed-in user required). A pair that edited `HKCU`/the user profile would
   instead run in the **logged-on user's context** (Requirements §R6).
2. Record the chosen context in the pack's header/changelog so reviewers see it. A mismatch here is
   the classic "runs but changes nothing" failure.

---

## Phase 2 — Package and scope

### Step 4. Create the pilot and production groups
1. Entra → **Groups → New group → Security**; **name it `PILOT – Remediations – Devices`** and add a
   small set of representative Windows devices.
2. Entra → **Groups → New group → Security**; **name it `Remediations – Windows – Production`** (it
   may start empty; you fill it in waves during Expand).

### Step 5. Create the remediation (package the pair) — name it
1. In Intune, go to **Reports → Endpoint analytics → Remediations → Create script package**
   (*verify the current path per the navigation flag above*).
2. **Basics:** **name it `PROREM – Service Health – w32time – Pilot`**; add a clear description and
   the **publisher** (your team name — white-label; do not brand it).
3. **Settings:**
   - **Detection script file:** upload `Detect-ServiceHealth-w32time.ps1` (Step 1).
   - **Remediation script file:** upload `Remediate-ServiceHealth-w32time.ps1` (Step 2) — for the
     **pilot**, upload the **preview/dry-run** version first so the pilot proves behavior without
     changing devices.
   - **Run this script using the logged-on credentials:** set to **No** for this system-context pair
     (set **Yes** only for user-context pairs — Step 3).
   - **Enforce script signature check** and **Run script in 64-bit PowerShell:** set per your
     signing posture (Requirements §R5) and the target's needs — a script touching 64-bit locations
     must run 64-bit. (**Verify current option names/behavior against Microsoft's documentation.**)
4. **Review + create.**

### Step 6. Assign to the pilot ring and schedule
1. Open **`PROREM – Service Health – w32time – Pilot`** → **Assignments → Select groups to include**
   → choose **`PILOT – Remediations – Devices`**.
2. Set the **schedule** for the assignment. Start with **Once** (or **Daily**) for the pilot so you
   see a clean first result quickly. (Available cadences — Once / Hourly / Daily — and their exact
   behavior should be **verified against current Microsoft documentation**.)
3. **Save.** Detection now runs on the pilot devices on that schedule; because the pilot uses the
   **preview** remediation, no device is changed yet — you are validating detection accuracy and the
   remediation's *intended* behavior from its log.

---

## Phase 3 — Read results and validate

### Step 7. Read detection and remediation status + output
1. Open **`PROREM – Service Health – w32time – Pilot`** → the **Overview / Device status** view.
2. Read the columns Endpoint Analytics reports (names may vary — **verify current column labels**):
   - **Detection status** — e.g. *With issue* / *Without issue* / *Detection failed*.
   - **Remediation status** — e.g. *Issue remediated* / *Issue not remediated* / *Remediation
     failed* (in preview, the remediation reports what it *would* have done via its output/log).
   - **Pre-remediation** and **post-remediation** detection output — the human-readable lines your
     scripts wrote.
3. Confirm the detection correctly split the pilot into *With issue* vs *Without issue*, and that the
   *With issue* devices' remediation **preview log** shows the correct minimal intended change.
4. Run the included **`PROREM-Discovery.ps1`** and **`PROREM-Validate.ps1`** for a tenant-side view
   (the package exists, is assigned, is running, and is reporting).

### Step 8. Flip the pilot remediation from preview to acting, and re-detect
1. Once the preview logs prove correctness, update the remediation script to its **acting** version
   (dry-run off) and re-upload it to **`PROREM – Service Health – w32time – Pilot`** (**Properties →
   Settings → Remediation script file → replace**).
2. Let the schedule run again. Now the *With issue* pilot devices are actually remediated.
3. On the **next** detection cycle, confirm those devices flip to **Without issue** — this
   **re-detection is your proof the fix worked and held**. Use `PROREM-Report.ps1` to export the
   detection/remediation success-fail trend to CSV for evidence.

---

## Phase 4 — Expand to production behind guardrails

### Step 9. Wave to production
1. Only after the pilot passes (detection accurate, remediation minimal and effective, re-detection
   clean), create the production assignment. Recommended: **clone** the pilot package to a
   production copy **named `PROREM – Service Health – w32time – Production`** (or re-assign the same
   package to the production group — keep pilot and production distinguishable).
2. Assign **`PROREM – Service Health – w32time – Production`** to **`Remediations – Windows –
   Production`**, and fill that group in **waves** (a first wave, validate, then widen) rather than
   the whole fleet at once.
3. Keep the schedule conservative to start (Daily), watch the trend, and widen only when each wave
   stays clean.

### Step 10. Guardrails for production
- **Never widen unproven** — a package only reaches production after a clean pilot.
- **Watch for a remediation loop** — if *Issue remediated* keeps recurring on the same devices every
  cycle, the fix isn't holding or detection is over-firing; pause the assignment and investigate
  (Troubleshooting) before it churns the fleet.
- **Keep the ability to reverse** — you can **unassign** a package instantly to stop it; for changes
  that need active rollback, author a paired "revert" remediation before you deploy the forward one.
- **Change the smallest blast radius** — widen group membership in waves; never assign a new or
  edited remediation straight to the whole production group.

---

## Phase 5 — Govern the library

### Step 11. Register the proven pair in the governed script-pack library
1. Store the final, proven `Detect-ServiceHealth-w32time.ps1` and
   `Remediate-ServiceHealth-w32time.ps1` in the **`Remediations Pack Library`** (Requirements §R10)
   with a **version** (e.g. `v1.0.0`) and a short **changelog**.
2. **Naming convention** — name every pack and its console package the same way so it is identifiable
   at a glance: **`PROREM – <Area> – <Target> – <Stage>`** (e.g. `PROREM – Service Health – w32time –
   Pilot`, `PROREM – Cert Hygiene – ClientAuth – Pilot`). Reuse the exact name across the library,
   the console package, the assignment, testing, and troubleshooting.
3. **Review & approval** — require a **second admin** to review the detection and remediation source
   and to confirm it was proven in **preview + pilot** before the remediation is **approved to act**
   in production. Record the reviewer and approval date in the changelog.
4. **Reuse** — when the next recurring issue appears, start from an existing proven pack, adapt the
   detected condition and minimal fix, and run it through the same pilot-first flow. The library is
   how the practice compounds instead of restarting each time.
