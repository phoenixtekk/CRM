# Implementation Guide — Exchange Online DLP in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce)** — with every
object **named**, an explicit **pass/fail gate** at each phase, and a **rollback** for each change.
Do **not** skip the simulation phase; DLP block/encrypt actions are high-impact.

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| DLP policy (pilot) | `DLPEXO-Pilot` |
| DLP policy (production, post-pilot) | `DLPEXO-Exchange` |
| Sensitive → external, high volume rule | `DLPEXO-Rule-Ext-Block` |
| Sensitive → external, low volume rule | `DLPEXO-Rule-Ext-Notify` |
| Labeled mail → external rule | `DLPEXO-Rule-Label-Encrypt` |
| Sensitive → internal rule | `DLPEXO-Rule-Internal-Audit` |
| High-risk escalation rule | `DLPEXO-Rule-Ext-Escalate` |
| Pilot sender group (mail-enabled) | `SG-DLPEXO-Pilot` |
| Compliance notification mailbox | `dlp-alerts@contoso.com` |
| Trusted-partner domain (exception) | `partner.contoso.com` |
| Sensitivity label keyed on | `Confidential` |
| Example SITs keyed on | `Credit Card Number`, `U.S. Social Security Number (SSN)` |

> **Tooling note.** The **policy and rules** can be authored in the **Purview portal** *or* with
> `New-/Set-DlpCompliancePolicy` and `New-/Set-DlpComplianceRule` via `Connect-IPPSSession`. The
> provided `DLPEXO-Configure.ps1` builds them in **simulation** — it **previews with `-WhatIf` and
> writes nothing unless you pass `-Commit`**, and it **never enforces** (never sets `Enable`/`Block`).
> **Verify every portal path and cmdlet parameter against your tenant** — condition/action parameter
> names (e.g. `-SentToScope`, `-NotifyAllowOverride`, the encryption action) and the exact simulation
> mode values evolve.

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R8. Do **not** proceed until licensing
   (incl. message encryption if you will encrypt), roles, in-scope sensitive content (SITs/labels),
   the recipient-scope decision, the per-scenario action matrix, the policy-tip plan, the
   transport-rule review, and a pilot sender group are all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\DLPEXO-Discovery.ps1 -IncludeSensitiveTypes` to
   inventory existing DLP policies/rules scoped to **Exchange**, their **modes**, the SITs and labels
   available, and the transport rules that may interact. Keep the CSV as your baseline.
3. **Review transport-rule interaction (R7).** Reconcile any existing mail-flow rule that already
   blocks/encrypts/redirects on content or recipient, so DLP and transport rules do not conflict.

**Gate 0 (pass/fail):** All of R1–R8 satisfied, Discovery baseline captured, transport-rule overlaps
reconciled. **Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Design (name every object, agree every action)

1. **Confirm the content conditions (R3).** Fix the SITs (e.g. `Credit Card Number`,
   `U.S. Social Security Number (SSN)`) with their **instance-count / confidence** thresholds, and the
   sensitivity label (`Confidential`) you will key on.
2. **Confirm the recipient scope + partner exception (R4).** External is the primary scope; list the
   trusted-partner domains (`partner.contoso.com`) to add as **exceptions**.
3. **Confirm the per-scenario action matrix (R5):**

   | Rule | Condition | Enforce action (per decision) |
   |---|---|---|
   | `DLPEXO-Rule-Ext-Block` | SITs to **external**, **high** count (e.g. ≥ 10 instances), **except** partner domains | **Block** + policy tip + incident report |
   | `DLPEXO-Rule-Ext-Notify` | SITs to **external**, **low** count (e.g. 1–9), **except** partner domains | **Policy tip / notify**, allow **override with justification** |
   | `DLPEXO-Rule-Label-Encrypt` | `Confidential` label to **external** | **Encrypt** (Purview Message Encryption) |
   | `DLPEXO-Rule-Internal-Audit` | SITs to **internal** recipients | **Notify / incident report** only (no block) |
   | `DLPEXO-Rule-Ext-Escalate` | SITs to **external** at a **very high** count (e.g. ≥ 50) | **Block** + **escalate** incident report to `dlp-alerts@contoso.com` |

4. **Confirm the policy-tip and notification plan (R6):** the tip text, override options, and the
   notification / incident-report recipients (`dlp-alerts@contoso.com`).
5. **Confirm the pilot sender scope (R8):** `SG-DLPEXO-Pilot`.

**Gate 1:** Every object is named, every action is agreed **in writing**, the partner exception and
pilot group exist. **Fail → do not configure**; close the design decision first.

---

## Phase 2 — Configure the policy and rules in SIMULATION

Create **one** DLP policy, `DLPEXO-Pilot`, scoped to the **Exchange** location, in **simulation/test
mode** (`TestWithNotifications` to also show policy tips, or `TestWithoutNotifications` for a silent
pilot). Author in the portal, or run `.\DLPEXO-Configure.ps1 -WhatIf` to preview, then
`.\DLPEXO-Configure.ps1 -Commit` (still simulation) to create the objects.

1. **Create the policy** (simulation, Exchange location):
   - Location: **Exchange email**.
   - Mode: **`TestWithNotifications`** (simulate *and* surface policy tips so the pilot senders see
     them) — **verify the exact mode value in your tenant**.
2. **Add the five rules**, each with its **condition(s)** and the matching **action(s)**, keeping
   **enforcing actions OFF while in simulation** (the block/encrypt take effect only when the policy
   Mode becomes `Enable` in Phase 4):

   - **`DLPEXO-Rule-Ext-Block`** — condition: content **contains** the SITs at the **high** count
     **AND** recipient **is external** (`-SentToScope NotInOrganization` — *verify*), **except** the
     trusted-partner domains (`-ExceptIfRecipientDomainIs partner.contoso.com` — *verify*). Configure
     the **block** action, **notify user (policy tip)**, and **generate incident report** — but these
     do not *act* until the policy is enabled.
   - **`DLPEXO-Rule-Ext-Notify`** — same content/recipient at the **low** count; action: **notify
     user (policy tip)** with **allow override / business justification**
     (`-NotifyAllowOverride WithJustification` — *verify*). No block.
   - **`DLPEXO-Rule-Label-Encrypt`** — condition: message/attachment carries the `Confidential`
     **sensitivity label** AND recipient is **external**; action: **encrypt** (the DLP encryption
     action — **verify the exact parameter/name for your tenant**, and confirm Purview Message
     Encryption is enabled, R1).
   - **`DLPEXO-Rule-Internal-Audit`** — condition: SITs AND recipient **is internal**
     (`-SentToScope InOrganization` — *verify*); action: **notify / generate incident report** only
     (visibility, no block).
   - **`DLPEXO-Rule-Ext-Escalate`** — condition: SITs to external at a **very high** count; action:
     **block** + incident report escalated to `dlp-alerts@contoso.com`.

3. **Scope the rules to the pilot senders.** Add a sender condition on `SG-DLPEXO-Pilot`
   (`-FromMemberOf` — *verify*) so simulation only evaluates pilot senders' mail; widen this in
   Phase 5.
4. **Save.** The policy is now evaluating in simulation **without blocking or encrypting anyone.**

**Gate 2:** `DLPEXO-Pilot` exists, is in a **Test/simulation** mode, on the **Exchange** location, with
all five rules present, each conditioned on sensitive content/recipient scope and scoped to the pilot
senders. `DLPEXO-Validate.ps1` reports **PASS** for policy-exists, Exchange-location,
mode-is-simulation, five-rules-present, and content-condition. **Fail → rollback:**
`Set-DlpCompliancePolicy -Identity DLPEXO-Pilot -Mode Disable` (or `Remove-DlpCompliancePolicy`);
simulation blocks nothing, so impact is limited to telemetry.

---

## Phase 3 — Pilot & validate in simulation

1. Let the policy run in simulation on `SG-DLPEXO-Pilot` for the agreed observation window.
2. Perform the **sanctioned test actions** in `05-testing.md` from a pilot mailbox — send benign
   test messages that match each scenario (a seeded SIT to an external test address at low and high
   counts, a `Confidential`-labeled message externally, a SIT to an internal recipient, and a message
   to a partner-domain address to confirm the exception).
3. Review the policy's **simulation results** and **Activity explorer**; run `.\DLPEXO-Report.ps1` to
   roll up rule matches, policy-tip, and (in a Test-with-notifications pilot) tip events.
4. **Tune:** adjust SIT count/confidence thresholds and the partner-domain exception to remove false
   positives, and confirm every intended scenario is **matched**.

**Gate 3:** Every one of the five scenarios registered its sanctioned test action in simulation (the
rule *would* act), the **partner-domain exception** did **not** match, false positives triaged, and the
**R5 action matrix** confirmed **in writing**. **Fail → do not enforce**; keep tuning in simulation.
Rollback is unchanged from Phase 2 (disable/delete the policy).

---

## Phase 4 — Enforce, then expand

**Only after Gate 3 passes.**

1. **Confirm each rule's enforce action** matches the **R5** matrix — **block** for
   `DLPEXO-Rule-Ext-Block` / `-Ext-Escalate`, **encrypt** for `-Label-Encrypt`, **notify/override**
   for `-Ext-Notify`, **audit/notify** for `-Internal-Audit`.
2. **Move the policy out of simulation to enforce** (portal: turn the policy **On**; PowerShell:
   `Set-DlpCompliancePolicy -Identity DLPEXO-Pilot -Mode Enable`). Do this **still scoped to the pilot
   senders** first.
3. **Re-run the sanctioned tests** (`05-testing.md`) and confirm the blocked/encrypted scenarios now
   **actually** block/encrypt, the policy tip appears, override-with-justification works, and the
   partner-domain exception is still **not** blocked.
4. **Expand scope in rings.** Widen the rules' sender scope (add the next group, or remove the
   `-FromMemberOf` pilot condition to cover **All** senders), re-validate, and repeat. Consider
   cloning/renaming to the production policy (`DLPEXO-Exchange`) as you exit pilot, per your naming
   standard.

**Gate 4:** On the pilot, each **block/encrypt** scenario enforces as designed, each **notify/audit**
scenario records without blocking, override-with-justification is logged, and the partner exception
holds; expansion rings each pass the same gate before widening.
**Fail → rollback:** immediately return the policy to **simulation/test**
(`Set-DlpCompliancePolicy -Mode TestWithNotifications`) or **Disable** it — this stops enforcement at
once — then diagnose per `06-troubleshooting.md` before re-enforcing.

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| A rule blocks/encrypts legitimate mail | Set the policy to **simulation/test** (`Set-DlpCompliancePolicy -Mode TestWithNotifications`), then tune the SIT thresholds / add the recipient domain to the partner exception. |
| The whole policy misbehaves | `Set-DlpCompliancePolicy -Identity DLPEXO-Pilot -Mode Disable` (stops all enforcement) or `-Mode TestWithNotifications` (back to simulation). |
| A sender should not be in scope | Remove them from `SG-DLPEXO-Pilot`, or narrow the rule's `-FromMemberOf` condition. |
| A partner flow is being blocked | Add the recipient domain to the trusted-partner **exception** on the affected rule(s), re-validate in simulation. |
| Start over cleanly | `Remove-DlpComplianceRule` for each rule, then `Remove-DlpCompliancePolicy -Identity DLPEXO-Pilot`. |

> Enforcement changes are **high-impact** — make them under change control, keep the pilot ring small,
> and never move all scenarios to **Block/Encrypt** at once without validating each in simulation
> first. Where the encrypt action or a condition parameter name is uncertain, **build that rule in the
> portal first, then read it back with `DLPEXO-Discovery.ps1`** to learn the exact shape in your
> tenant.
