# Troubleshooting — Exchange Online DLP

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"the policy isn't working" reports trace back to condition matching, recipient scope, simulation-vs-
enforce confusion, or a conflicting transport rule — not the rule itself.** Where a portal path or
cmdlet parameter is named, **verify it against your tenant** — the Purview portal and DLP
condition/action options evolve.

---

## 1. A test message doesn't match at all

**Symptoms:** Send a message you expect to match and **nothing** appears in the DLP simulation
results / Activity explorer; the policy never fires.

**Likely causes & fixes**
- **Content doesn't carry the SIT/label.** The test message must actually contain the **sensitive
  information type** (a valid pattern that meets the SIT's checksum/format) or carry the **sensitivity
  label** the rule keys on. Seed a known-good match and retry. `DLPEXO-Discovery.ps1
  -IncludeSensitiveTypes` lists the SITs available.
- **Instance count below threshold.** A rule that requires ≥ N instances will not fire on fewer. Check
  the count you set (`DLPEXO-Rule-Ext-Block` high, `-Ext-Notify` low) versus the test content.
- **Recipient scope mismatch.** An "external" rule (`-SentToScope NotInOrganization`) will not match a
  message sent **internally** (and vice-versa). Confirm you sent to the right recipient type.
- **Sender out of pilot scope.** During the pilot the rules are scoped to `SG-DLPEXO-Pilot`
  (`-FromMemberOf`). A sender not in that group is not evaluated. `DLPEXO-ScopeHealth.ps1` shows each
  rule's sender scope; `DLPEXO-Validate.ps1` gate **A4** confirms it.
- **Propagation delay.** New/changed policies take time to reach the transport pipeline. Wait, then
  retest.

---

## 2. Policy tips don't appear in Outlook

**Symptoms:** The rule matches (visible in simulation results) but the sender never sees a **policy
tip**.

**Likely causes & fixes**
- **Policy in a silent test mode.** `TestWithoutNotifications` simulates **without** showing tips. Use
  `TestWithNotifications` if you want tips during the pilot. `DLPEXO-Validate.ps1` gate **A3** shows the
  mode.
- **NotifyUser not configured.** The rule must notify the sender for a tip to show. Confirm the rule's
  user-notification / policy-tip action is set.
- **Client support varies.** Policy-tip rendering differs across Outlook desktop / web / mobile. **Verify
  tip behavior per client in your tenant** — a tip missing on one client is not proof the rule is broken.
- **Latency.** Tip configuration changes take time to propagate to clients. Wait and retest.

---

## 3. The rule fires on the wrong things (false positives)

**Symptoms:** Legitimate business mail is flagged/blocked — a sanctioned partner flow, an internal
message, a low-risk email.

**Likely causes & fixes**
- **Missing/stale trusted-partner exception.** Add the recipient domain to the exception
  (`-ExceptIfRecipientDomainIs`) on the external rules and confirm it is referenced.
  `DLPEXO-Validate.ps1` gate **A7** checks the exception is present.
- **SIT count/confidence too loose.** Raise the **instance count** or **confidence level** so ordinary
  mail with an incidental match doesn't trip the rule, then re-test.
- **Condition too broad.** A rule keyed on "all mail" instead of a **SIT/label** matches everything.
  Tighten the condition (R3). `DLPEXO-Validate.ps1` gate **A6** flags rules with no readable content
  condition.
- **Tune in simulation** — never tune by loosening an already-enforcing block in production.

---

## 4. Simulation looks fine but enforcement doesn't block/encrypt

**Symptoms:** In simulation the match is recorded; after "turning it on" the block/encrypt still
doesn't happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block or encrypt. To enforce,
  move the policy out of simulation: portal → turn the policy **On**; PowerShell →
  `Set-DlpCompliancePolicy -Identity DLPEXO-Pilot -Mode Enable`. `DLPEXO-Validate.ps1` gate **A3** shows
  the current mode.
- **Enforcing action not set on the rule.** Simulation configures conditions; the **Block** /
  **Encrypt** action must be present on the rule for enforcement to act. Confirm the rule's action
  matches the R5 matrix (`DLPEXO-Configure.ps1` deliberately leaves enforcing actions off — you set
  them in Phase 4).
- **Sender/recipient out of scope.** Enforcement only applies within the rule's sender/recipient scope.
  Confirm with `DLPEXO-ScopeHealth.ps1` / gate **A4**.
- **Propagation delay.** Mode/action changes take time to reach transport. Wait, then retest.

---

## 5. The encrypt action doesn't apply (or errors)

**Symptoms:** The labeled-mail-to-external rule (`DLPEXO-Rule-Label-Encrypt`) matches but the message
is not encrypted, or configuring the encrypt action errors.

**Likely causes & fixes**
- **Message encryption not enabled.** The DLP encrypt action depends on **Purview Message Encryption /
  Azure Rights Management** being enabled in the tenant (R1). `DLPEXO-ScopeHealth.ps1` flags IRM/OME
  readiness; if not enabled, enable it before relying on the encrypt action.
- **Wrong action parameter/name.** The DLP encryption action parameter/name **evolves** and differs
  across tenants. **Build the encrypt rule in the portal first**, then read it back with
  `DLPEXO-Discovery.ps1` to learn the exact shape, rather than guessing the parameter.
- **A transport rule is also stamping encryption.** Two controls encrypting the same mail causes
  confusing double-actions — reconcile per §7 / R7.

---

## 6. `New-DlpComplianceRule` fails on a condition/action parameter

**Symptoms:** `DLPEXO-Configure.ps1 -Commit` (or manual scripting) errors on a parameter such as
`-SentToScope`, `-ExceptIfRecipientDomainIs`, `-FromMemberOf`, or the sensitive-information condition.

**Fix**
- **Verify the exact parameter names/values for your tenant.** These parameter names and permitted
  values **evolve**. Run `Get-Help New-DlpComplianceRule -Full` and check current Microsoft docs, then
  adjust. `DLPEXO-Configure.ps1` deliberately **prints the plan** and wraps each write in try/catch so a
  differing parameter **warns** rather than aborting the whole run.
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPEXO-Discovery.ps1` to learn the exact shape in your tenant.

---

## 7. DLP and an Exchange transport (mail-flow) rule conflict

**Symptoms:** A message is double-acted on (e.g. encrypted twice, or blocked with an unexpected
message), or DLP "never fires" because a transport rule already deleted/redirected the mail first.

**Likely causes & fixes**
- **Overlapping controls.** DLP and transport rules **coexist** and both act in transport. Review
  transport rules that block/encrypt/delete/redirect on content or recipient
  (`Get-TransportRule`, or `DLPEXO-Discovery.ps1` / `DLPEXO-ScopeHealth.ps1` flag them) and **decide
  which control owns each behavior** (R7). Remove or adjust the duplicate.
- **Pre-emption.** A transport rule that **deletes or redirects** a message *before* DLP evaluates it
  makes DLP look broken. Reorder or narrow the transport rule so DLP can evaluate.

---

## 8. Multiple DLP policies overlap / precedence confusion

**Symptoms:** A rule you expect to act doesn't, or a different policy's action takes effect.

**Fix**
- **Check policy precedence.** When several DLP policies cover Exchange, **priority order** determines
  which acts. `DLPEXO-ScopeHealth.ps1` lists Exchange-location policies by **Priority** — review for
  overlap/shadowing and adjust priority so the intended policy/rule wins.

---

## 9. Activity report is empty or export fails

**Symptoms:** `DLPEXO-Report.ps1` returns no activity, or the Activity Explorer export warns and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only** rather than failing. Fall back to **Purview → Data loss
  prevention (Policy / Activity explorer)** in the portal.
- **Quiet pilot window.** A small pilot may simply have no activity in the window — widen `-Days` or
  perform the sanctioned test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer / DLP reports.

---

## 10. "It blocked an exec / broke a business flow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**:
  `Set-DlpCompliancePolicy -Identity DLPEXO-Pilot -Mode TestWithNotifications` (simulation) or
  `-Mode Disable` (off). Either **stops enforcement at once.**
- Or add the affected recipient domain to the **trusted-partner exception** on the offending rule.
- Then work the relevant section above (usually §3 false positives, §7 transport conflict, or §4
  scope), fix **in simulation**, re-validate with `DLPEXO-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / privacy / legal (see `global-requirements-purview.md` §5):

- *Should* this scenario be **blocked/encrypted** or only **audited**? → the **R5** decision owners.
- Is *this content* actually sensitive / in scope? → **compliance / data owners**.
- Is a recipient **domain trusted**? → **compliance / security** (R4).
- Is a user's message a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPEXO-Report.ps1`, Activity explorer, the validation output) — not a
verdict.
