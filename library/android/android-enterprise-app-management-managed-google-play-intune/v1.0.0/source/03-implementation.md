# 3. Implementation Guide — Android Enterprise App Management via Managed Google Play (Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and the **managed Google Play** iframe surfaced inside it. Names in
`code` are the exact objects to create — keep them consistent so the scripts and reports find them.

> **Model:** approve → configure → protect → set track → **assign to `ANDROIDAPP-Pilot` first** →
> validate the four gates → expand in waves. Every production change has a rollback.

## Step 1 — Create the assignment groups
1. Entra → **Groups → New group** → Security → `ANDROIDAPP-Pilot` (**Assigned**); add one enrolled test
   device per enrollment model you will target. **Create**.
2. Create the production groups you need (e.g. `ANDROIDAPP-Prod-WorkProfile`,
   `ANDROIDAPP-Prod-FullyManaged`, `ANDROIDAPP-Prod-Dedicated`). Keep them **Assigned** for predictable
   app targeting.

## Step 2 — Baseline the current state
1. Run **`ANDROIDAPP-Scope.ps1`** — confirms the managed Google Play binding is connected and app sync is
   current (pass gate before you approve anything).
2. Run **`ANDROIDAPP-Discovery.ps1`** — records which managed Google Play apps are already approved and
   how they are assigned, so you know your starting posture.

## Step 3 — Approve a store app (managed Google Play)
1. Intune → **Apps > All apps > Add** → App type **Managed Google Play app** → **Select** (opens the
   managed Google Play iframe).
2. Search the app by its **exact package name / publisher** (from Requirement 2.3) — e.g. **Microsoft
   Outlook**, publisher **Microsoft Corporation**, package `com.microsoft.office.outlook`. Disambiguate
   from similarly named apps.
3. **Approve** → on **Approval settings**, choose how app **permission changes** are handled. A common
   safe choice is **"Keep approved when app requests new permissions"** so an app doesn't silently
   un-approve on an update (confirm the current option wording in the iframe). **Done → Sync**.
4. Back in Intune, wait for **Sync** to pull the approved app into **Apps > Android** (this is the
   `androidManagedStoreApp` object the scripts report on).

## Step 4 — (If used) publish and approve a private LOB or web app
1. **Private LOB app:** in the managed Google Play iframe → **Publish / Create a private app** (or
   Google Play Console developer account) → upload the `.apk`, name it, publish **privately** to your
   organization. **Approve** → **Sync**. *(The private-publishing surface evolves — follow current Google
   guidance; verify against your organization's publisher account.)*
2. **Web app:** iframe → **Web apps** → **Add** → enter title, URL, display mode, icon → **Create** →
   **Approve** → **Sync**. It appears in Intune as a managed Google Play (web) app you assign like any other.

## Step 5 — Assign the app to the pilot (choose intent + track)
1. Intune → **Apps > Android > (the app) > Properties > Assignments > Edit** (or **Add group** on the
   assignment blade).
2. Add `ANDROIDAPP-Pilot` under the **intent** that matches the model:
   - **Required** — silently installed (fully managed / corporate-owned work profile / dedicated).
   - **Available for enrolled devices** — user pulls it from the work Play Store (work-profile BYOD).
   - **Available with/without enrollment** — MAM-style availability (verify applicability to your model).
   - **Uninstall** — removes the app.
3. On the assignment's **settings** (managed Google Play app settings), set the **App update priority /
   auto-update mode** and, if you publish to a non-Production track, select the **track** (Production /
   Beta / your closed track). **Review + save**.
4. Prefer to stage this with **`ANDROIDAPP-AssignConfig.ps1 -WhatIf`** first — it prints the exact
   assignment (intent, group, track, auto-update mode) it *would* apply. **Note:** the Graph `assign`
   action **replaces all** of an app's assignments, so the helper reads the current set and only writes
   (behind `-Commit`) the full intended set — preventing accidental removal of other groups.

## Step 6 — Push managed app configuration (pre-configure the app)
1. Intune → **Apps > App configuration policies > Add > Managed devices**.
2. **Platform:** Android Enterprise. **Profile type:** the enrollment-model profile that applies
   (e.g. **Fully Managed, Dedicated, and Corporate-Owned Work Profile Only** vs **Personally-Owned Work
   Profile Only**). **Associated app:** select the app from Step 3/4.
3. On **Settings**, use the **configuration designer** to set the app's **managed configuration keys**
   (accounts, server URLs, feature flags). For **OEMConfig**, select the OEM app and set its schema keys
   (Samsung KSP / Zebra OEMConfig — keys per the OEM's documentation).
4. **Assignments →** `ANDROIDAPP-Pilot` → **Create**. The app now arrives pre-configured.
5. Stage/verify with **`ANDROIDAPP-AssignConfig.ps1 -WhatIf`** (it also reports whether an app-config
   policy is attached for the app's package).

## Step 7 — Apply an Android app protection policy (optional but recommended)
1. Intune → **Apps > App protection policies > Create policy > Android**.
2. **Public apps / Custom apps:** add the target app(s) by package name. Set **Data protection**
   (backup, transfer, copy/paste, save-as), **Access requirements** (PIN, credentials), and
   **Conditional launch** (min OS/patch, jailbreak/root block, offline grace) to your standard.
3. **Assignments →** `ANDROIDAPP-Pilot`. **Create**.
4. Stage/verify with **`ANDROIDAPP-AppProtection.ps1 -WhatIf`** (read mode lists existing Android APP
   policies and their assignments; `-Commit` creates the staged policy).

## Step 8 — Validate the pilot (the four gates)
Run **`ANDROIDAPP-Validation.ps1`** and confirm on a pilot device per model:
- **G1 Delivery** — Required apps install silently; Available apps appear in the work Play Store.
- **G2 Configuration** — the app opens **pre-configured** (accounts/URLs populated); OEM keys applied.
- **G3 Protection** — APP controls are in force (PIN prompt, copy/paste/save-as blocked as configured).
- **G4 Update track** — the app is on the **intended track** and honoring the auto-update mode.

**Pass** = all four gates green on every targeted model. **Fail** = fix before expanding (see §6).

## Step 9 — Expand to production in waves
1. Add the production groups (`ANDROIDAPP-Prod-*`) to each app's assignment under the matching intent,
   with the **Production** track for the general fleet (keep Beta on a smaller group if piloting updates).
2. Roll out **wave by wave**; re-run **`ANDROIDAPP-Validation.ps1`** after each wave.
3. Keep new apps flowing through the same approve → config → protect → assign pattern.

> **Rollback (any step):** **unassign** the app / config / protection from the affected group in Intune
> (or set the app's intent to **Uninstall** for a Required app), and **revert the track** to the prior
> stable track. `ANDROIDAPP-AssignConfig.ps1 -WhatIf` shows the current set before you change it, so you
> can restore it exactly. Connector/AMAPI-level changes are **high-impact** — treat separately under
> change control and verify re-enrollment behavior against current Microsoft guidance.

---
### Order of operations
`Groups → baseline (Scope/Discovery) → approve store app → (private/web) → assign to pilot (intent+track)
→ managed config → app protection → validate 4 gates → expand in waves`
