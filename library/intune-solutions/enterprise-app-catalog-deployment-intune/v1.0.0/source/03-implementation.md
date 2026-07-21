# 3. Implementation Guide — Enterprise App Catalog Deployment in Microsoft Intune

Follow these steps **in order** in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`; Government cloud: `https://endpoint.microsoft.us` — *verify the
correct portal for your national cloud against current Microsoft documentation*).

> **Model:** Confirm the app is in the catalog and select it → configure the supplied install
> behavior and assignment → enable update management → assign to a **pilot** ring → validate install,
> detection, and an update → expand to **broad**. The pilot ring is the gate — a bad rollout never
> reaches production.

> **Navigation note:** Enterprise App Catalog menu labels, blade names, and tab order in the Intune
> admin center change over time. The paths below reflect the current model; **verify each exact
> label against current Microsoft documentation** before relying on it. The *sequence* (add → select
> from catalog → install behavior → detection [prebuilt] → assignment → update management → pilot →
> expand) is stable.

## Named objects (reuse these names verbatim everywhere)
We use the `<Purpose> – <Scope> – <Stage>` naming convention so every object is self-describing and
searchable. For the worked example catalog app `Sample App`:

| Object | Name to create |
|---|---|
| Pilot ring group | `Catalog Apps – Pilot Devices – Ring 1` |
| Broad ring group | `Catalog Apps – Broad Devices – Ring 2` |
| The catalog app (as added in Intune) | `Catalog App – Sample App – Prod` |

*(`Sample App` is a placeholder for the actual catalog application you select — do not assume which
apps are in the catalog; confirm in Step 3.)*

## Step 1 — Create the ring groups
1. Go to **Entra** (`https://entra.microsoft.com`) → **Groups → New group**.
2. **Group type: Security**. **Group name:** `Catalog Apps – Pilot Devices – Ring 1`. Add a few
   representative devices (or members). **Create**.
3. Repeat: **New group → Security**, name `Catalog Apps – Broad Devices – Ring 2` (the rest of the
   fleet). **Create**.
   *(You may instead run `ENTAPPCAT-Set-Assignment.ps1` to create these; it defaults to `-WhatIf`.)*

## Step 2 — Start adding an Enterprise App Catalog app
1. In the Intune admin center, go to **Apps** → **All apps** → **Add**.
2. In **Select app type**, under the **Windows** category, choose **Enterprise App Catalog app**
   (exact label — *verify against current Microsoft documentation*). Click **Select**.

## Step 3 — Select the app from the catalog
1. On the catalog picker, **search for `Sample App`** and select it.
   *Which applications (and versions) are offered is Microsoft-defined and changes over time — if the
   app is not listed, it is not in the catalog; use hand-packaged Win32 or the winget/Store lane
   instead (see the sibling "Winget & Microsoft Store App Management" product).*
2. If the catalog offers a **version** choice, select the version you intend to pilot (or choose the
   option that tracks the latest, if you plan to rely on update management). **Select / Next.**
3. The prepackaged app now supplies the **install/uninstall logic** and the **detection rule** —
   **you do not author these.** Review the **App information** (name, publisher, description). Set the
   **Name** to `Catalog App – Sample App – Prod` so it is searchable. **Next.**

## Step 4 — Confirm install behavior (the supplied package settings)
On the **Program / install-behavior** step (exact tab name — *verify against current documentation*):
1. Confirm the **Install behavior** — **System** (per-device) unless the app must be per-user (see
   Requirement 2.4). The available options are supplied by the catalog package.
2. Leave the **install/uninstall commands** and **return codes** as supplied by Microsoft's package —
   do not override them unless you have a documented reason. **Next.**

## Step 5 — Verify the built-in detection rule
On the **Detection rules** step:
1. Confirm the rule type is set to **use the prebuilt/built-in detection** supplied by the catalog
   package (you do **not** manually author an MSI product code / file / registry rule for a catalog
   app — Microsoft's package provides it). The exact wording of this option is *verify-with-Microsoft*.
2. Do not replace it with a hand-authored rule unless you deliberately intend to; the built-in rule
   is what makes catalog reporting reliable. **Next.**

## Step 6 — Enable update management
On the **update management / supersedence** step (exact label — *verify against current
documentation*):
1. **Enable update management** for `Catalog App – Sample App – Prod` so the app is kept current as
   Microsoft publishes new versions.
   *The update cadence, whether you can pin a version, and exactly how updates are applied are
   Microsoft-defined — verify the current behavior and options against Microsoft documentation before
   relying on a specific guarantee.*
2. If you must stay on a fixed version, choose the **pin/version** option instead (if offered) and
   record that decision. **Next.**

## Step 7 — Assign to the pilot ring
1. On the **Assignments** step, under **Required**, click **Add group** and select
   `Catalog Apps – Pilot Devices – Ring 1`.
   *(Choose **Available for enrolled devices** instead if the app should be optional via Company
   Portal.)*
2. Do **not** assign `Catalog Apps – Broad Devices – Ring 2` yet — the pilot is the gate.
3. **Next → Review + create → Create.**

## Step 8 — Apply and validate on a pilot device
1. On a pilot device, sync policy: **Settings → Accounts → Access work or school → (account) → Info →
   Sync**.
2. Run `ENTAPPCAT-Test-Install.ps1` on the device to confirm the IME is healthy and the app's
   detection state (read-only).
3. Run `ENTAPPCAT-Validate.ps1` to confirm, PASS/FAIL: the app is deployed, assigned to the pilot
   group, detected as installed, and has update management enabled.
4. Run `ENTAPPCAT-Report.ps1` to confirm Intune reports **Installed** for the pilot devices and to
   capture install + update status.
5. Complete the **Testing Guide** — including confirming that an **update applies** via update
   management — before expanding.

## Step 9 — Expand to the broad ring
1. Only after the pilot passes the Testing Guide gate, open `Catalog App – Sample App – Prod` →
   **Properties → Assignments → Edit** → under **Required** → **Add group** →
   `Catalog Apps – Broad Devices – Ring 2`. **Review + save.**
2. Re-run `ENTAPPCAT-Report.ps1` over the next cycle and chase any **Failed** devices (see
   Troubleshooting; for deep break/fix use the "Intune App Deployment Troubleshooting & Failure
   Remediation" product).

---
### Order of operations
`Ring groups → Add app (Enterprise App Catalog) → Select from catalog → Confirm install behavior →
Verify built-in detection → Enable update management → Assign pilot → Validate (install + detection +
update) → Expand broad`
