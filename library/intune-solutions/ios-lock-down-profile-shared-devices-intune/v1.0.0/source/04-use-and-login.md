# 4. Use & Login Guide — for staff using a shared phone and users with a corporate phone

This is the **end-user** guide. It covers the practical, day-to-day experience for **both** device
models: how staff pick up, sign in to, use, and hand back a **shared** phone, and how a user provisions
and signs in to their own **corporate** phone. Hand the relevant section to the people who use the
phones — no admin knowledge required.

---

## Part A — Using a SHARED phone (anyone on shift)

A shared phone has **no owner**. It is locked down to what the job needs, and you sign into the **apps**
(not the device) with a **shared account** where one is needed. Treat it as a tool you borrow and
return clean.

### A1. Pick it up
1. Take the phone from its charging/storage location.
2. Wake it. There is **no personal sign-in to the device** — it goes straight to the locked-down home
   screen, or directly into the **single app** if it's in kiosk mode.
3. You will only see the apps the job needs. The App Store, Safari, settings changes, and "erase
   device" are intentionally blocked — that's expected, not a fault.

### A2. Sign in to the app(s) (only if prompted)
1. If an app asks who you are, sign in with the **shared/managed account** your team was given
   (display name `iOS Shared – App Sign-in`). The credentials live in your team's password manager or
   are posted per your local process — **not** your personal account.
2. If the app shows a previous session, you can usually keep using it; sign out and back in only if your
   process requires per-shift identity.
3. Where the app supports it, sign-in may be pre-filled — just confirm.

### A3. Do the job
- Use the phone for its intended task: calls, the role app, scanning, etc.
- If something you need is missing or blocked, it's by design — report it to your admin rather than
  trying to work around the lock-down.

### A4. Hand it back (important)
1. **Sign out of any app** that holds your personal or shift-specific session, if your process says to
   (e.g. a messaging or queue app). For a generic shared account, you can usually leave it signed in.
2. Close out of any task screens so the next person starts clean.
3. Return the phone to its charging/storage location.
4. **Do not** attempt to remove management, change Wi-Fi, or reset the phone — these are locked, and the
   next person relies on the phone being in the same state you found it.

> **Hand-back expectation:** the next person should pick up the phone and find it exactly as a fresh
> shared device — locked down, on the right home screen/app, with no leftover personal data. The
> restrictions enforce most of this automatically; signing out of personal app sessions is the part
> that's up to you.

### A5. If the shared phone misbehaves
- App won't open / stuck: lock and wake the phone; if kiosk-locked and frozen, hold the side button to
  re-launch (the kiosk re-pins the app).
- Can't sign in to the app: confirm you're using the **shared account**, not your own; check with your
  admin if the password changed.
- Anything else: hand it to your admin — do not try to factory-reset it (that's blocked anyway).

---

## Part B — Provisioning and using a CORPORATE phone (your own assigned phone)

A corporate phone is **assigned to you**. You sign in with **your own work identity**, and you get a
managed but normal-feeling work phone. You set it up once.

### B1. First-time setup (provisioning)
1. Power on the new (or freshly erased) iPhone. Choose **language** and **region**, and connect to
   **Wi-Fi** (or insert the SIM/eSIM for cellular).
2. The phone reaches a **Remote Management** screen that names **your organization**. This is expected
   — it means the phone is being set up as a managed corporate device. Tap **Continue**.
3. When prompted, **sign in with your own work account** (your Entra ID — the same
   `you@yourcompany.com` email and password you use for Microsoft 365), and complete **multi-factor
   authentication** if asked.
4. Let Setup Assistant finish. The phone enrolls **assigned to you**, applies the corporate baseline,
   and begins installing your **approved work apps** automatically (this can take a few minutes).

### B2. Finish app sign-in
1. Open the **Company Portal** app if prompted (it confirms the phone is registered and compliant).
2. Open your work apps (Outlook, Teams, etc.) and sign in **with your own work account** — the same one
   from setup. They may sign in automatically via single sign-on.
3. If an app requires an app PIN (app protection), set it when prompted.

### B3. Day-to-day use
- Use the phone as your normal work phone: it is **not** locked to a single app. You can use the App
  Store and personal-style apps within your organization's policy.
- Your work data is protected by the baseline and (if configured) app-protection policies — for
  example, you may be blocked from copying work data into personal apps.
- The phone stays **compliant** as long as it's updated and you keep your passcode set; non-compliance
  can block access to work apps until fixed.

### B4. Everyday tips
- **Keep iOS updated** — compliance and Conditional Access can require a minimum iOS version.
- **Keep your passcode set** — corporate phones require one.
- If you get **a new phone**, repeat B1 on the new device; tell your admin so the old one can be
  retired/wiped.

### B5. If your corporate phone has trouble
- Can't access work apps: open **Company Portal → Devices → (this device) → Check compliance**, then
  update iOS / set a passcode as prompted.
- Sign-in loops: confirm you're using **your own** work account (not a shared one) and that MFA
  completes.
- Lost/stolen: contact your admin immediately so the phone can be remotely wiped.

---

## Quick comparison for users

| | Shared phone | Corporate phone |
|---|---|---|
| Who signs in | A **shared account** at the **app** level (if prompted) | **You**, with your own work account, at setup |
| Device sign-in | None — straight to the locked home screen / app | Your work account during Setup Assistant |
| What you can do | Only the job's app(s); App Store/Safari blocked | Normal work phone within policy |
| At the end of use | Sign out of personal app sessions, hand it back clean | Keep it — it's yours to use |
| Reset / unenroll | Blocked — leave it alone | Don't reset; contact admin if replacing |
