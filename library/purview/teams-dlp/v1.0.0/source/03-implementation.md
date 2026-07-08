# Implementation Guide — Teams Chat & Channel DLP in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce)** — with every
object **named**, an explicit **pass/fail gate** at each phase, and a **rollback** for each change.
Do **not** skip the simulation phase; Teams-message and file block actions are high-impact.

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| DLP policy | `DLP-Teams-Pilot` |
| Teams-message rule | `DLP-Rule-TeamsMessages` |
| Shared-files rule (SharePoint + OneDrive) | `DLP-Rule-TeamsFiles` |
| Pilot user/security group | `SG-TeamsDLP-Pilot` |

**Locations this policy spans (R5):** **Teams chat and channel messages** (message text),
**SharePoint** (channel-shared files), **OneDrive** (chat-shared files).

> **Tooling note.** The **policy and rules** can be authored in the **Purview portal** **or** with
> `New-/Set-DlpCompliancePolicy` and `New-/Set-DlpComplianceRule`; the provided `DLPTEAMS-Configure.ps1`
> builds them in **simulation** with `-WhatIf` by default. The Teams-messages location is set via the
> policy's Teams location parameter (e.g. `-TeamsLocation`), and files via `-SharePointLocation` /
> `-OneDriveLocation`. **Verify every portal path and cmdlet parameter against your tenant** — the
> portal and the Teams DLP scope evolve.

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R8. Do **not** proceed until message-DLP
   licensing, roles, the in-scope Teams surfaces, in-scope sensitive content, the three-location
   understanding, the action + internal/external decision, a pilot group, and the policy-tip content
   are all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\DLPTEAMS-Discovery.ps1` to inventory existing DLP
   policies/rules, which locations they cover (Teams / SharePoint / OneDrive), sensitivity labels, and
   SITs. Keep the CSV as your baseline. (A **default Teams DLP policy** may already exist — note it.)
3. **Confirm pilot scope.** `.\DLPTEAMS-ScopeHealth.ps1` reports the pilot group membership (Graph)
   and the current scope of any existing Teams policy.

**Gate 0 (pass/fail):** All of R1–R8 satisfied, Discovery baseline captured, pilot group defined.
**Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Design the policy (locations, rules, actions)

1. **Confirm the three locations** the policy will span (R5): Teams messages + SharePoint + OneDrive,
   scoped to the **pilot group** only (`SG-TeamsDLP-Pilot`).
2. **Confirm the content condition** (R4): the sensitivity label(s) and/or SIT(s) each rule keys on.
3. **Confirm the action matrix** (R6): message action (block + policy tip), internal-vs-external
   logic (e.g. audit internal / block external), and the file action — **in writing**.

**Gate 1:** The location set, content condition, and action matrix are documented and approved.
**Fail → stop**; the R6 decision is a determination owner's call, not the administrator's.

---

## Phase 2 — Author the policy + rules in SIMULATION

Create **one** DLP policy, `DLP-Teams-Pilot`, spanning the three locations and scoped to the pilot
group, in **simulation/test mode** (nothing is blocked). Then add the two rules. Author in the portal
or run `.\DLPTEAMS-Configure.ps1 -WhatIf` first, then `.\DLPTEAMS-Configure.ps1 -Commit` (still
simulation) to create the objects.

1. **Create the policy** (simulation, three locations, pilot scope):
   - Locations: **Teams chat and channel messages**, **SharePoint**, **OneDrive**, each scoped to
     `SG-TeamsDLP-Pilot`.
   - Mode: **simulation/test** (portal: *"Run the policy in simulation mode"*; PowerShell: a **Test**
     mode — `TestWithoutNotifications` for a silent pilot, or `TestWithNotifications` to also show
     policy tips). **Verify the exact mode value in your tenant.**
2. **Add the two rules**, each conditioned on your sensitive content:

   | Rule | Location(s) | Condition | Starting action | Notes |
   |---|---|---|---|---|
   | `DLP-Rule-TeamsMessages` | Teams messages | Sensitive label/SIT match | **Audit** (simulation); block-on-external per R6 in enforce | Differentiate internal vs external recipients per R6 |
   | `DLP-Rule-TeamsFiles` | SharePoint + OneDrive | Sensitive label/SIT match | **Audit** (simulation); block external share per R6 in enforce | Covers files shared in channels (SharePoint) and chats (OneDrive) |

   - Keep everything **Audit / notify-only** while the policy is in simulation — the *enforce* action
     (block / block-external) is applied in Phase 4, not now.
   - Set the **internal vs external** condition on the message rule per R6 (e.g. a *recipient is
     external* / *content is shared with people outside the org* condition). **Verify the exact
     condition and action parameter names against `Get-Help New-DlpComplianceRule -Full` in your
     tenant** before scripting them.
3. **Save.** The policy is now evaluating on the pilot users **without blocking anyone.**

**Gate 2:** `DLP-Teams-Pilot` exists, is in **simulation/test**, spans **Teams + SharePoint +
OneDrive**, scoped to the pilot, with both rules present and conditioned on sensitive content.
`DLPTEAMS-Validate.ps1` reports **PASS** for policy-exists, three-locations, mode-is-simulation,
scope-is-pilot, and two-rules-present.
**Fail → rollback:** `Set-DlpCompliancePolicy -Identity DLP-Teams-Pilot -Mode Disable` (or delete with
`Remove-DlpCompliancePolicy`); simulation blocks nothing, so impact is limited to telemetry.

---

## Phase 3 — Pilot & validate in simulation

1. Let the policy run in simulation on `SG-TeamsDLP-Pilot` for the agreed observation window.
2. Perform the **sanctioned test actions** in `05-testing.md` as a pilot user (post a matching test
   string in a 1:1 chat and a channel, share a matching test file in a chat and a channel, and repeat
   with an **external** recipient where in scope).
3. Review **Activity explorer** and the policy's **simulation results**; run `.\DLPTEAMS-Report.ps1`
   to roll up policy modes and (where available) DLP activity.
4. **Tune:** adjust conditions to remove false positives and confirm both message and file activity is
   **seen**, and that the internal-vs-external logic behaves as designed.

**Gate 3:** The message rule and the file rule both registered the sanctioned test actions in
simulation (would act), the internal-vs-external differentiation is observed, false positives triaged,
and the **R6 action matrix** confirmed **in writing**. **Fail → do not enforce**; keep tuning in
simulation. Rollback is unchanged from Phase 2 (disable/delete the policy).

---

## Phase 4 — Enforce, then expand

**Only after Gate 3 passes.**

1. **Apply the enforce actions.** Update each rule to its **R6** action — block the message (with the
   approved **policy tip**, R8), block-on-external, and the file action — leaving **Audit** where the
   decision is audit-only.
2. **Move the policy out of simulation** to **enforce** (portal: turn the policy **On**; PowerShell:
   `Set-DlpCompliancePolicy -Identity DLP-Teams-Pilot -Mode Enable`). Do this **still scoped to the
   pilot** first.
3. **Re-run the sanctioned tests** (`05-testing.md`) and confirm the message is now actually blocked
   (with the policy tip) and the file share is handled as designed on the pilot.
4. **Expand scope in rings.** Widen the location scope (add the next user group), re-validate, and
   repeat. Consider renaming/cloning to a production policy (`DLP-Teams`) as you exit pilot.

**Gate 4:** On the pilot, the enforced message block/policy-tip and file action behave as designed,
and audit-only paths record without blocking; expansion rings each pass the same gate before widening.
**Fail → rollback:** immediately return the policy to **simulation/test** (`Set-DlpCompliancePolicy
-Mode TestWithoutNotifications`) or **Disable** it — this stops enforcement at once — then diagnose per
`06-troubleshooting.md` before re-enforcing.

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| A rule blocks legitimate messages/files | Set that rule's action back to **Audit**, or set the policy to **simulation/test**, then tune conditions. |
| The whole policy misbehaves | `Set-DlpCompliancePolicy -Identity DLP-Teams-Pilot -Mode Disable` (stops all enforcement) or `-Mode TestWithoutNotifications` (back to simulation). |
| A user should not be in scope | Remove them from `SG-TeamsDLP-Pilot` (or the scoped location membership). |
| Files covered but messages over-blocking (or vice-versa) | Disable the single offending rule (`Set-DlpComplianceRule -Identity <rule> -Disabled $true`) while leaving the other. |
| Start over cleanly | `Remove-DlpComplianceRule` for each rule, then `Remove-DlpCompliancePolicy -Identity DLP-Teams-Pilot`. |

> Enforcement changes are **high-impact** — make them under change control, keep the pilot ring small,
> and never move both message and file rules to **Block** at once without validating each in
> simulation first.
