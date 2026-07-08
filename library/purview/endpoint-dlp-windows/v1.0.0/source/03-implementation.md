# Implementation Guide — Endpoint DLP for Windows in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce)** — with every
object **named**, an explicit **pass/fail gate** at each phase, and a **rollback** for each change.
Do **not** skip the simulation phase; endpoint block actions are high-impact.

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| DLP policy | `EDLP-Windows-Pilot` |
| USB / removable-media rule | `EDLP-Rule-USB` |
| Print rule | `EDLP-Rule-Print` |
| Clipboard rule | `EDLP-Rule-Clipboard` |
| Network-share rule | `EDLP-Rule-NetworkShare` |
| Cloud-egress (browser) rule | `EDLP-Rule-CloudEgress` |
| Pilot device group | `DG-EDLP-Pilot` |
| Pilot user group | `SG-EDLP-Pilot` |
| Corporate removable-media device group | `USBG-Corporate` |
| Sanctioned printer group | `PRNG-Corporate` |
| In-scope network-share group | `NSG-Corporate` |

> **Tooling note.** Endpoint **device onboarding** and the **Endpoint DLP settings** (device/printer/
> share groups, browsers, domains) are configured in the **Purview portal** — there is no supported
> Security & Compliance PowerShell cmdlet to *onboard* a device. The **policy and rules** can be
> authored in the portal **or** with `New-/Set-DlpCompliancePolicy` and `New-/Set-DlpComplianceRule`;
> the provided `DLPWIN-Configure.ps1` builds them in **simulation** with `-WhatIf` by default.
> **Verify every portal path and cmdlet parameter against your tenant** — the portal and the
> endpoint-restriction parameter names evolve.

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R9. Do **not** proceed until licensing,
   roles, supported devices, an onboarding method, in-scope sensitive content, the endpoint global
   settings plan, the browser extension plan, the per-channel action decision, and a pilot group are
   all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\DLPWIN-Discovery.ps1` to inventory existing DLP
   policies/rules, the **Devices** coverage, sensitivity labels, and SITs, and to surface what is
   already in place. Keep the CSV as your baseline.
3. **Confirm onboarding readiness.** `.\DLPWIN-ScopeHealth.ps1` reports managed-device signals
   (Graph) and prompts you to confirm, **in Purview → Settings → Device onboarding**, that the pilot
   devices are onboarded.

**Gate 0 (pass/fail):** All of R1–R9 satisfied, Discovery baseline captured, pilot devices onboarded
and visible in **Purview → Devices**. **Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Onboard the pilot Windows devices

1. In **Purview portal → Settings → Device onboarding** (verify path), review the supported
   onboarding methods and download the package for your chosen method (Intune / Group Policy / local
   script / Configuration Manager).
   - *Local script* is fine for a **handful of pilot machines**; use **Intune or GPO** for scale.
   - If devices are already **onboarded to Microsoft Defender for Endpoint**, they may already be
     onboarded here — confirm they appear under **Devices**.
2. Onboard **only the pilot devices** (`DG-EDLP-Pilot`) first.
3. Deploy the **Microsoft Purview browser extension** to **Chrome/Firefox** on the pilot devices
   (R7) if cloud-egress/clipboard-to-web coverage in those browsers is in scope. **Edge** needs no
   extension.

**Gate 1:** Pilot devices show as **onboarded** in **Purview → Devices**; a test activity (e.g. copy
a benign file to a USB stick) appears in **Activity explorer** (Devices) within the expected latency.
**Fail → rollback:** offboard the device via your onboarding tool's offboarding package; re-check the
device prerequisites (R3) before retrying. **No policy is configured yet, so there is nothing to
enforce-rollback at this stage.**

---

## Phase 2 — Configure the Endpoint DLP global settings

In **Purview → Data Loss Prevention → Endpoint DLP settings** (verify path), define the vocabulary
the rules will reference. Name each object per the table above.

1. **Removable storage device groups** — create `USBG-Corporate` listing the corporate-issued/allowed
   USB devices (by device ID / vendor as your standard allows). This lets a USB rule **block
   everything except** approved media.
2. **Printer groups** — create `PRNG-Corporate` for sanctioned printers, so the print rule can allow
   corporate printing and control the rest.
3. **Network-share coverage / groups** — define `NSG-Corporate` (the shares in scope) and any
   exclusions.
4. **Browser and domain restrictions** — set **unallowed browsers** (browsers with no extension
   coverage that should be blocked from egress), **service domains** (sanctioned upload targets) and
   **sensitive service domains**, and **unallowed cloud service domains**. These drive the
   cloud-egress rule.
5. **Restricted apps / app groups**, **file-path exclusions**, and (if used) **VPN settings** and
   **business-justification** prompt text.

**Gate 2:** Each group/list above exists and is populated; `DLPWIN-Discovery.ps1` re-run reports them
as readable (or you have confirmed them in-portal where a setting is not exposed to PowerShell).
**Fail → rollback:** remove/blank the offending group; groups are inert until a rule references them,
so there is no user impact yet.

---

## Phase 3 — Author the policy and the five rules in SIMULATION

Create **one** DLP policy, `EDLP-Windows-Pilot`, scoped to the **Devices** location and the **pilot
scope only**, in **simulation/test mode** (nothing is blocked). Then add the five rules. Author in
the portal or run `.\DLPWIN-Configure.ps1 -WhatIf` first, then `.\DLPWIN-Configure.ps1` (still
simulation) to create the objects.

1. **Create the policy** (simulation, Devices location, pilot scope):
   - Location: **Devices** only, scoped to `DG-EDLP-Pilot` / `SG-EDLP-Pilot`.
   - Mode: **simulation/test** (portal: *"Run the policy in simulation mode"*; PowerShell: a **Test**
     mode — `TestWithoutNotifications` for a silent pilot, or `TestWithNotifications` to also show
     policy tips). **Verify the exact mode value in your tenant.**
2. **Add the five rules**, each with a **condition** on your sensitive content (a sensitivity-label
   condition such as *Confidential*, and/or a sensitive-info-type condition) **and** the matching
   **endpoint restriction**:

   | Rule | Endpoint activity | Starting action | Allow-list group |
   |---|---|---|---|
   | `EDLP-Rule-USB` | Copy to a removable USB device | **Audit** (simulation) | except `USBG-Corporate` |
   | `EDLP-Rule-Print` | Print | **Audit** (simulation) | except `PRNG-Corporate` |
   | `EDLP-Rule-Clipboard` | Copy to clipboard (paste to app/browser) | **Audit** (simulation) | — |
   | `EDLP-Rule-NetworkShare` | Copy to a network share | **Audit** (simulation) | scope `NSG-Corporate` |
   | `EDLP-Rule-CloudEgress` | Upload to / access from unallowed browser or non-sanctioned service domain | **Audit** (simulation) | except sanctioned service domains |

   - Set actions **per the R8 decision matrix**, but keep everything **Audit** while the policy is in
     simulation — the *enforce* action (Warn/Block) is applied in Phase 5, not now.
   - The endpoint restrictions are set on the rule (in the portal under the **Devices** activities,
     or in PowerShell via the rule's endpoint-restriction parameter). **Verify the exact restriction
     setting names and permitted values (`Audit` / `Warn` / `Block` / `Ignore`) against
     `Get-Help New-DlpComplianceRule -Full` in your tenant** before scripting them.
3. **Save.** The policy is now evaluating on the pilot devices **without blocking anyone.**

**Gate 3:** `EDLP-Windows-Pilot` exists, is in **simulation/test**, scoped to **Devices + pilot
only**, with all five rules present and conditioned on sensitive content. `DLPWIN-Validate.ps1`
reports **PASS** for policy-exists, mode-is-simulation, scope-is-pilot, and five-rules-present.
**Fail → rollback:** `Set-DlpCompliancePolicy -Identity EDLP-Windows-Pilot -Mode Disable` (or delete
the policy with `Remove-DlpCompliancePolicy`); simulation blocks nothing, so impact is limited to
telemetry.

---

## Phase 4 — Pilot & validate in simulation

1. Let the policy run in simulation on `DG-EDLP-Pilot` for the agreed observation window.
2. Perform the **sanctioned test actions** in `05-testing.md` on a pilot device (copy a test-labeled
   file to USB, print it, copy to clipboard into a browser, copy to an out-of-scope share, upload to
   a personal cloud domain in each in-scope browser).
3. Review **Activity explorer** (Devices) and the policy's **simulation results**; run
   `.\DLPWIN-Report.ps1` to roll up the configuration and (where available) the endpoint activity via
   **Activity explorer export**.
4. **Tune:** adjust conditions/allow-lists to remove false positives (e.g. add a legitimate corporate
   USB to `USBG-Corporate`) and confirm every intended channel is **seen**.

**Gate 4:** Every one of the five channels registered the sanctioned test action in simulation
(policy *would* act), false positives triaged, and the **R8 action matrix** confirmed **in writing**.
**Fail → do not enforce**; keep tuning in simulation. Rollback is unchanged from Phase 3 (disable/
delete the policy).

---

## Phase 5 — Enforce, then expand

**Only after Gate 4 passes.**

1. **Apply the enforce actions.** Update each rule to its **R8** action — **Warn (override)** or
   **Block** — for the channels that require it; leave **Audit** where the decision is audit-only.
2. **Move the policy out of simulation** to **enforce** (portal: turn the policy **On**; PowerShell:
   `Set-DlpCompliancePolicy -Identity EDLP-Windows-Pilot -Mode Enable`). Do this **still scoped to the
   pilot** first.
3. **Re-run the sanctioned tests** (`05-testing.md`) and confirm the blocked/warned channels now
   **actually** block/warn on the pilot, with the expected policy tip and (if configured) business
   justification.
4. **Expand scope in rings.** Widen the **Devices** scope (add the next device group), re-validate,
   and repeat. Consider renaming/cloning to a production policy (`EDLP-Windows`) as you exit pilot,
   per your naming standard.

**Gate 5:** On the pilot, each **block/warn** channel enforces as designed and each **audit** channel
records without blocking; expansion rings each pass the same gate before widening.
**Fail → rollback:** immediately return the policy to **simulation/test** (`Set-DlpCompliancePolicy
-Mode TestWithoutNotifications`) or **Disable** it — this stops enforcement at once — then diagnose
per `06-troubleshooting.md` before re-enforcing.

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| A rule blocks legitimate work | Set that rule's action back to **Audit**, or set the policy to **simulation/test**, then tune the allow-list/conditions. |
| The whole policy misbehaves | `Set-DlpCompliancePolicy -Identity EDLP-Windows-Pilot -Mode Disable` (stops all enforcement) or `-Mode TestWithoutNotifications` (back to simulation). |
| A device should not be in scope | Remove it from the scoped device/user group, or **offboard** it via your onboarding tool's offboarding package. |
| Start over cleanly | `Remove-DlpComplianceRule` for each rule, then `Remove-DlpCompliancePolicy -Identity EDLP-Windows-Pilot`. |

> Enforcement changes are **high-impact** — make them under change control, keep the pilot ring
> small, and never move all channels to **Block** at once without validating each in simulation
> first.
