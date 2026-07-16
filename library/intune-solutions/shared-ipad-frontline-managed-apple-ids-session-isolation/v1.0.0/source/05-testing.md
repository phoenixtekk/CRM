# 5. Testing & Validation — Shared iPad for Frontline Teams

This section is the point of the whole project. Everything in Implementation §3 exists so that
**Test 5 — the session-isolation A/B test** passes. Run it with two real humans on a real pilot iPad
before a single production device is staged.

Each test has an explicit **PASS / FAIL** gate. A FAIL is not a warning — it is a stop.

---

## Test 1 — Tenant and Apple readiness

**Procedure:** Run `SHAREDIPAD-Discovery.ps1`.

**PASS:** The Apple MDM Push certificate is **Active** with a future expiry; an **ADE token** is
present with a future expiry; an enrollment profile **`SHARED IPAD – ADE Profile – Shared`** exists and
**Shared iPad is enabled** on it; **`SHARED IPAD – FMD – Pilot`** and **`SHARED IPAD – FMD –
Production`** exist; **`SHARED IPAD – Restrictions – Field Lockdown`** and **`SHARED IPAD – Compliance
– iPadOS`** exist; the allowlist apps are present.

**FAIL:** Any item missing → resolve it before piloting (Requirements §2, Implementation §3).

## Test 2 — Enrollment-time grouping owner

**Procedure:** Entra → **Groups → `SHARED IPAD – FMD – Pilot` → Owners**. Repeat for
**`SHARED IPAD – FMD – Production`**.

**PASS:** The Intune Provisioning Client service principal — matched by **AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`**, not by display name — is listed as an **Owner** of **both**
groups, and both groups are **Assigned** (not Dynamic).

**FAIL:** Missing owner, or a Dynamic group → Implementation §3 Step 2b. **The group will stay empty at
enrollment and nothing will deploy.** Verify this before every wave.

## Test 3 — The pilot iPad is actually in Shared iPad mode

**This is the test that predicts Test 5.** If this fails, Test 5 will fail, and you will waste an hour
looking at Outlook.

**Procedure:**
1. On the enrolled pilot iPad, observe the screen it lands on after Setup Assistant.
2. In Intune → **Devices → All devices → (the pilot iPad) → Properties**.
3. Run `SHAREDIPAD-Validate.ps1`.

**PASS:** The device presents a **Shared iPad sign-in screen requesting a Managed Apple ID** — *not* a
normal iPad home screen. In Intune, **Supervised = `Yes`**, the enrollment profile is
**`SHARED IPAD – ADE Profile – Shared`**, and the device is enrolled via **ADE**. The device is a member
of **`SHARED IPAD – FMD – Pilot`**.

**FAIL:** The device shows a normal home screen, or **Supervised = `No`**, or the device did not enroll
via ADE → **the device is not in Shared iPad mode**. Go to Troubleshooting §6 — this is the #1 cause of
the session leak, and no amount of app configuration will fix it. The device must be wiped and
re-enrolled once the enrollment profile is correct.

## Test 4 — Managed Apple ID sign-in works

**Procedure:** On the pilot iPad's Shared iPad sign-in screen, have **User A** (a member of
`PILOT – Shared iPad Users`) sign in with their **Managed Apple ID**.

**PASS:** User A signs in. With federation (Requirement R13) they are prompted by the **Microsoft**
sign-in page and use their normal work credentials. The device sets up their data space and lands on the
home screen showing **only** the `SHARED IPAD – Apps – Field Allowlist` apps.

**FAIL:** Sign-in is rejected → the Managed Apple ID does not exist, or the address is still conflicted
by a personal Apple ID (Requirement R14 / Implementation §3 Step 3). Sign-in hangs → check network
(R16) and Wi-Fi at this location (R17). Sign-in reports the device is full → storage (R11). See
Troubleshooting §6.

---

## Test 5 — **THE SESSION-ISOLATION A/B TEST** *(the acceptance gate)*

**This is the test the customer is buying. It is the reason the project exists.** Run it with **two
real people**, on a **real pilot iPad**, in the **field Wi-Fi environment**. Do not simulate it, do not
run it with one person signing in twice, and do not sign the assessment off without it.

**You need:** the pilot iPad (Test 3 PASSED), **User A** and **User B** — two different members of
`PILOT – Shared iPad Users`, both with working mailboxes (Requirement R2) and Managed Apple IDs
(Test 4 PASSED).

### Part 1 — User A creates a session with real data

1. **User A** signs in to the iPad with their **Managed Apple ID**.
2. Open **Microsoft Outlook**. Sign in if prompted. Wait for the mailbox to sync.
3. **Send an email** from User A to themselves with the subject **`ISOLATION TEST A`**. Confirm it
   arrives in their inbox. *(Now there is unmistakable, identifiable data on the device.)*
4. Open **Microsoft Teams**. Sign in if prompted. **Send a chat message** to a colleague containing the
   text **`ISOLATION TEST A`**. Confirm it appears in the chat list.
5. Open the **Camera** and **take a photo** of something identifiable. Confirm it appears in Photos.
6. Open the **CMMS app**. Sign in and open any work order. *(This is your real workload — test it.)*
7. Open the **schematics / document viewer** and open a drawing.
8. **User A signs out of the Shared iPad session** — use the Shared iPad sign-out control (the user
   picker / Sign Out), **not** the app-level sign-out inside Outlook. *(App-level sign-out is exactly
   the thing that does not work. Test the real mechanism.)*
9. Confirm the device returns to the **Shared iPad sign-in screen**.

### Part 2 — User B signs in on the SAME device

**User B now signs in on the same physical iPad and must observe *nothing* of User A's.**

Check each of the following. **Every single one must pass.**

| # | Check | **PASS** | **FAIL** |
|---|---|---|---|
| 5.1 | **Outlook mailbox** — open Outlook | Outlook prompts for sign-in, **or** opens **User B's** mailbox. There is **no** mailbox belonging to User A. | User A's mailbox is present. |
| 5.2 | **Cached mail** — search for `ISOLATION TEST A` in Outlook | **Zero results.** The message does not exist on this device for User B. | The message is visible or cached. |
| 5.3 | **Teams chat** — open Teams | Teams prompts for sign-in, **or** opens **User B's** chats. `ISOLATION TEST A` is **not** present. | User A's chat history is visible. |
| 5.4 | **Photos** — open Photos / Camera roll | **Empty**, or contains only User B's own photos. User A's photo is **not** present. | User A's photo is visible. |
| 5.5 | **Identity autofill** — open Outlook / Teams / the CMMS sign-in and tap the username field | No suggestion of **User A's** address. The field is empty or offers only User B's. | User A's address is offered by autofill or is pre-filled. |
| 5.6 | **Signed-in state** — check every app in the allowlist, including the **CMMS app** and the **viewer** | **Nothing** is silently signed in as User A. Each app is signed out or signed in as User B. | Any app opens already signed in as User A. |
| 5.7 | **Files / documents** — open the viewer's recent documents and the Files app | No document User A opened is present or accessible to User B. | User A's documents are listed or openable. |
| 5.8 | **Safari** *(only if Safari is allowed in your build)* — open it and check history and autofill | No history or saved identity from User A's session. | User A's browsing state persists. |

### The verdict

- **PASS = every one of 5.1 through 5.8 passes.** Not most. Every one. A single leak means the
  architecture is not delivering isolation, and one leaked mailbox is the whole problem you were
  hired to fix.
- **Now reverse it.** Sign User B out, sign **User A** back in, and confirm A gets **their own** data
  back (their mail, their photo) and **none** of B's. Isolation must work in both directions —
  a device that gives everyone a blank slate but loses each user's own data is also broken.

### What a FAIL means — read this before you debug

**A FAIL is almost never an app problem.** Diagnose in this order:

| Symptom | Which architecture step is wrong | Fix |
|---|---|---|
| **Everything leaks** — mail, photos, chat, all of it | **The device is not in Shared iPad mode.** It is a single-user iPad being handed between people — the original problem, unchanged. This is the #1 cause. | Re-run **Test 3**. Check the device is **ADE-enrolled**, **Supervised = Yes**, and the enrollment profile is `SHARED IPAD – ADE Profile – Shared` **with Shared iPad enabled** (Implementation §3 Step 7). Wipe and re-enroll (Step 12). |
| **The device never asked for a Managed Apple ID** — it went to a home screen | Same as above — Shared iPad was never enabled, or the device did not enroll via ADE. | Implementation §3 Steps 7–8, then Step 12. Confirm the serial is in ABM (R6). |
| **Photos leak but mail is clean** | The device **is** in Shared iPad mode, but something outside the per-user data space is being written — or you are looking at an app that stores outside it. | Confirm iCloud Photo Library is **Blocked** (Step 9) and re-test. Escalate to the app vendor if it persists. |
| **Only the CMMS app leaks** — Microsoft apps are clean | **The CMMS app is not honouring the Shared iPad user boundary.** Shared iPad is working; that one app is not designed for it. | Take it to the vendor with this test as evidence. Ask explicitly whether the app supports **Apple Shared iPad**. This is a vendor gap, not a configuration gap — and you cannot configure around it. |
| **Only Microsoft apps leak** — photos and files are clean | Shared iPad is working at the OS layer. This is unexpected and is worth a support case. | Re-verify Test 3, then raise it with Microsoft. Do **not** reach for Shared Device Mode as a patch until you understand why — layering B on a broken A hides the real fault. |
| **User B sees a sign-in prompt but User A's address is pre-filled** | Keyboard/autofill state, not session state. Minor but real — it is a data disclosure. | Confirm **predictive keyboard / auto-fill** is **Blocked** in `SHARED IPAD – Restrictions – Field Lockdown` (Step 9) and re-test. |

---

## Test 6 — Field lockdown is enforced

**Procedure:** As User B, on the pilot iPad, attempt each of the following.

**PASS:** The **App Store** is not present and cannot be reached. Apps **cannot** be installed or
removed. **Adding an account** (personal Apple ID, personal mail) is **blocked**. **Erase All Content
and Settings** is unavailable. **AirDrop** is unavailable. Only the `SHARED IPAD – Apps – Field
Allowlist` apps appear on the home screen. **Camera works** (the field team needs it).

**FAIL:** Any restriction not enforced → confirm **Supervised = `Yes`** (Test 3 — unsupervised devices
silently ignore most of these), confirm the profile assignment to `SHARED IPAD – FMD – Pilot`, and
force a sync. See Troubleshooting §6.

## Test 7 — Compliance reports correctly

**Procedure:** Intune → **Devices → Compliance → `SHARED IPAD – Compliance – iPadOS` → Device status**.

**PASS:** The pilot iPad reports **Compliant** against the policy.

**FAIL:** Not evaluated → the device is not in `SHARED IPAD – FMD – Pilot` (Test 2). Non-compliant →
read the reason; a minimum-OS failure means the device needs an iPadOS update (R10).

## Test 8 — The field workload actually works

**Procedure:** As User B, complete a genuine shift task end-to-end: open a work order in the **CMMS
app**, open a **schematic** in the viewer, **take a photo** and attach it to the work order, and send a
**Teams** message about it.

**PASS:** The complete workload succeeds on a locked-down Shared iPad.

**FAIL:** A step is blocked → a restriction in `SHARED IPAD – Restrictions – Field Lockdown` is too
tight (Safari and Bluetooth are the usual culprits), or an app is missing from
`SHARED IPAD – Apps – Field Allowlist`. Fix and re-test — **and then re-run Test 5**, because loosening
a restriction can reopen a leak.

## Test 9 — Storage holds under multiple resident users

**Procedure:** Sign three or four different pilot users into the same iPad in sequence, each doing a
short real task. Then check Intune → **Devices → (device) → Hardware** for free storage, and run
`SHAREDIPAD-Report.ps1`.

**PASS:** All users sign in successfully and free storage remains healthy against Apple's current
guidance for your resident-user count.

**FAIL:** A sign-in fails for lack of space, or users are being evicted → the hardware is undersized
(Requirement R11) or the cached-user setting exceeds what the device can carry (Implementation §3 Step
7). **VERIFY WITH APPLE** — check the current storage and maximum-user guidance in Apple's Shared iPad
documentation. **Find this out at the pilot, not at device 30 of 40.**

---

## Acceptance gate

**Do not stage a single production device until:**

- Tests **1, 2, 3, 4** PASS *(the architecture is real)*
- Test **5** PASSES **completely — all of 5.1 to 5.8, in both directions** *(the leak is fixed — this
  is the gate)*
- Tests **6, 7, 8, 9** PASS *(the device is locked down, healthy, usable, and sized)*

If Test 5 fails, **nothing else matters**. Fix the architecture and re-run it.

---

## Shift-handover runbook — for the field team

Print this. Put it on the iPad rack. Brief the team before their devices are staged.

**Shared iPad gives you a clean device — but only after you sign out.** A user who walks away without
signing out leaves their session open on the rack for the next person to walk into.

### At the END of your shift
1. **Close what you are working on.** Save and submit any open work order in the CMMS app.
2. **Sign out of the iPad session.** Tap your name / user picker → **Sign Out**.
   - **This is not the same as signing out of Outlook.** Signing out of an app does not end your
     session. Use the **iPad's** sign-out.
3. **Wait for the sign-in screen to appear** before you put the iPad down. Sign-out has work to do —
   walking away mid-way can leave your session open.
4. **Return the iPad to the rack and put it on charge.** A dead iPad is an iPad the next shift cannot
   use.

### At the START of your shift
1. **Take any iPad from the rack.** They are interchangeable — you will get your own environment.
2. **Check the sign-in screen is showing.** If you see **someone else's** home screen or name, the
   previous user did not sign out — sign them out via the user picker, or report it. **Do not use the
   device inside their session.**
3. **Sign in with your work account** (your Managed Apple ID). You will get your own mail, your own
   photos, and your own work orders.
4. **Stand where the Wi-Fi is good** when you sign in. Sign-in needs the network.

### Report it if
- You sign in and see **anyone else's** mail, messages, photos, or work orders. **Report it
  immediately** — that is exactly what this system exists to prevent, and it means something is
  broken.
- The iPad says it is full, or will not let you sign in.
- Your own mail or photos are missing after you sign in.
