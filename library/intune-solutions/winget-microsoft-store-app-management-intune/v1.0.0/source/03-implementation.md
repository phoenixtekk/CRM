# 3. Implementation Guide — Winget & Microsoft Store App Management with Microsoft Intune

Follow these steps **in order**. Everything happens in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). **Exact console navigation, blade names, and the "Microsoft Store app
(new)" type label are verify-with-Microsoft** — the portal changes; confirm the current path against
Microsoft's documentation. Where a path is given, it is the current expected drill-down.

> **Model:** Add a Microsoft Store (winget-backed) app, assign it **Required** for a baseline app and
> **Available** (self-service) for a long-tail app, cover winget-only apps with a Win32 wrapper, confirm
> updates, assign to a **pilot** ring, validate, then expand to **broad**. The pilot ring is the gate.

## Named objects (reuse these names verbatim everywhere)
We use the `<Purpose> – <Platform> – <Stage/Type>` naming convention so every object is self-describing
and searchable. For the two worked example apps:

| Object | Name to create |
|---|---|
| Pilot user group | `Store & Winget Apps – Pilot – Ring 1` |
| Broad user group | `Store & Winget Apps – Broad – Ring 2` |
| Required Store app | `Adobe Acrobat Reader – Store – Required` |
| Available (self-service) app | `VLC media player – Winget – Available` |
| Winget-only Win32 wrapper (if needed) | `<App> – Winget – Win32 Wrapper` |

## Step 1 — Create the pilot and broad groups
1. Entra (`https://entra.microsoft.com`) → **Groups → New group** → **Group type: Security** → **Group
   name** = `Store & Winget Apps – Pilot – Ring 1` → add a few representative pilot **users** →
   **Create**. (Or run `WINGETSTORE-Set-Assignment.ps1`, which references existing groups.)
2. Repeat to create `Store & Winget Apps – Broad – Ring 2` (the rest of the fleet's users). **Create**.

## Step 2 — Add a Microsoft Store app (the Required baseline app)
1. Intune → **Apps → Windows → Add**.
2. **App type:** select **Microsoft Store app (new)**. **Select**.
   *(If the type name differs in your tenant, use the current winget-backed Store app type —
   verify-with-Microsoft.)*
3. **Search the Microsoft Store app** → type `Adobe Acrobat Reader` → in the results, confirm the
   **publisher is Adobe Inc.** (not a look-alike) → **Select**. Intune fills in the app's package
   identifier and metadata.
4. **App information:** confirm **Name** = `Adobe Acrobat Reader – Store – Required` (set the display
   name to this exact value), confirm publisher, add a short description. Set **Install behavior** to
   **System** for a device-wide baseline app (use **User** only if the app requires per-user install).
   **The available install-behavior options and their exact effect are verify-with-Microsoft.** **Next.**

## Step 3 — Assign the Store app as Required to the pilot ring
1. On the **Assignments** tab, under **Required**, **Add group** → select
   `Store & Winget Apps – Pilot – Ring 1`.
2. Do **not** add the broad ring yet — the pilot is the gate. **Next → Review + create → Create.**

## Step 4 — Add a winget long-tail app as Available (self-service)
1. Intune → **Apps → Windows → Add → Microsoft Store app (new) → Select**.
2. **Search** → type `VLC` → confirm the **publisher is VideoLAN** (disambiguate from re-packaged
   look-alikes) → **Select**.
3. **App information:** **Name** = `VLC media player – Winget – Available`; confirm publisher. **Next.**
4. On the **Assignments** tab, under **Available for enrolled devices**, **Add group** → select
   `Store & Winget Apps – Pilot – Ring 1`. This publishes the app in **Company Portal** for those users
   to install on demand. **Next → Review + create → Create.**

## Step 5 — (If the app is winget-community-only, not in the Store) wrap the winget command
Some apps exist in the **winget community catalog** but do not surface as a Microsoft Store app (new).
For those, deploy a **Win32 app** that runs the winget install command. **Whether a given app is
directly addable as a new-Store app is verify-with-Microsoft** — check the catalog first.
1. Create a Win32 app named `<App> – Winget – Win32 Wrapper` (packaging is covered by the sibling
   *Intune Win32 Application Packaging & Deployment* product — do not re-derive it here).
2. **Install command (example):**
   `winget install --id VideoLAN.VLC --silent --accept-package-agreements --accept-source-agreements --scope machine`
   **Uninstall command (example):** `winget uninstall --id VideoLAN.VLC --silent`
   The **exact package `--id`, the supported flags, and machine-scope behavior in system context are
   verify-with-winget/Microsoft** — confirm the current id and switches before deploying.
3. Author a detection rule (file/version or registry) and assign it Required or Available as above.

## Step 6 — Confirm the update path for each app
1. For **Microsoft Store app (new)** apps, updates are designed to be **service-managed** — the app
   moves to newer versions as the publisher ships them, without you re-uploading. **The exact update
   cadence, and whether any app is excluded, is verify-with-Microsoft.**
2. For a **winget-wrapped Win32 app**, updates happen when you deploy a new version (or run a scheduled
   winget upgrade). Plan which apps are auto-managed vs. version-controlled by you (see the Overview
   "Limitations").
3. Record, per app, whether updates are **auto** (Store/winget) or **managed by you** (Win32-pinned).

## Step 7 — Validate on a pilot device
1. On a pilot device, sync policy: **Settings → Accounts → Access work or school → (account) → Info →
   Sync**.
2. Confirm the **Required** app `Adobe Acrobat Reader – Store – Required` installs automatically.
3. Open **Company Portal**, find `VLC media player – Winget – Available`, and **Install** it
   on-demand (self-service).
4. Run `WINGETSTORE-Validate.ps1` (PASS/FAIL) and `WINGETSTORE-Test-Install.ps1` to confirm the pilot
   apps are deployed, assigned, self-service is configured, and installs detect. Complete the
   **Testing Guide**.
5. Run `WINGETSTORE-Report.ps1` to confirm Intune reports **Installed** for the pilot users/devices.

## Step 8 — Expand to the broad ring
1. Only after the pilot passes the Testing Guide gate, edit each app's **Assignments**:
   - `Adobe Acrobat Reader – Store – Required` → under **Required** → **Add group** →
     `Store & Winget Apps – Broad – Ring 2`.
   - `VLC media player – Winget – Available` → under **Available for enrolled devices** → **Add group** →
     `Store & Winget Apps – Broad – Ring 2`.
   **Save.**
2. Re-run `WINGETSTORE-Report.ps1` over the next cycle and chase any **Failed** or missing installs
   (cross-reference *Intune App Deployment Troubleshooting & Failure Remediation (Win32/LOB/Store)*).

---
### Order of operations
`Pilot/broad groups → add Store app (Required) → assign pilot → add winget app (Available) → assign
pilot → (winget-only? wrap as Win32) → confirm updates → validate → expand broad`
