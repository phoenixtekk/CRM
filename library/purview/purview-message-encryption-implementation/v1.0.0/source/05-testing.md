# Testing & Validation — Purview Message Encryption (OME) in Microsoft Purview

Run these gates in order. Each has an explicit **pass/fail** signal. **Do not enforce broadly** (Phase
5 — flip rules from `Audit` to `Enforce` and widen scope) until every gate passes **and**
compliance/privacy have confirmed the condition→template mapping. Where a gate involves a real send,
use a **sanctioned pilot sender** in `SG-OME-Pilot` and **test recipients** (one internal Microsoft
365 mailbox, one external mailbox on a different provider) — do not test on production correspondence.

Use the scripts where noted; they are read-only or `-WhatIf`/Audit-mode and change nothing you don't
approve.

---

## Gate 1 — Licensing is in place (Basic vs Advanced)

**Why:** OME rides on Azure RMS/AIP; custom branding, revocation, and expiration are **Advanced-only**.
**How:** Confirm the AIP/Azure RMS entitlement for the pilot senders; confirm E5/E5 Compliance if you
rely on custom branding / revocation / expiration. Run `OME-Discovery.ps1`.
**Pass:** Senders are licensed for Basic OME; any Advanced feature you plan to use is licensed.
**Fail:** Senders unlicensed, or a design depends on an Advanced feature you don't have → acquire/assign,
or redesign to Basic (default branding, two templates) before proceeding.

## Gate 2 — Azure RMS is enabled and healthy

**Why:** No RMS, no encryption — every template, rule, and branding depends on it.
**How:** Exchange Online PowerShell — `Get-IRMConfiguration` (`AzureRMSLicensingEnabled : True`) and
`Test-IRMConfiguration -Sender <pilot> -Recipient <external>`. `OME-ScopeHealth.ps1` runs these.
**Pass:** `AzureRMSLicensingEnabled` is **True** and `Test-IRMConfiguration` returns **PASS** on all
checks (RMS online, templates retrieved, encrypt/decrypt round-trip).
**Fail:** RMS disabled or any `Test-IRMConfiguration` check fails → enable RMS
(`Set-IRMConfiguration -AzureRMSLicensingEnabled $true`) / activate Azure RMS, then re-test.

## Gate 3 — The protection templates are available

**Why:** The rules apply `Encrypt` / `Do Not Forward`; they must exist and be published.
**How:** Exchange Online PowerShell — `Get-RMSTemplate` lists the available templates.
`OME-Discovery.ps1` reports them.
**Pass:** The **`Encrypt`** and **`Do Not Forward`** templates are returned and enabled.
**Fail:** Templates missing → confirm RMS is active (Gate 2) and allow propagation; **verify template
availability in your tenant.**

## Gate 4 — Branding is configured and renders correctly

**Why:** The encryption portal/wrapper is recipient-facing and trust-critical; wrong or missing
branding looks like phishing.
**How:** `Get-OMEConfiguration` shows the branding you set (logo, colour, text). Then send a
sanctioned encrypted test to an internal and an external recipient and **view** the wrapper/portal.
**Pass:** `Get-OMEConfiguration` returns your intended values; the recipient sees your logo, colour,
and text (not default Microsoft branding, unless that is the deliberate choice).
**Fail:** Branding absent, broken (logo too large / wrong format), or wrong → re-run
`Set-OMEConfiguration` (Implementation Phase 2) and re-test; **verify current logo size/format limits.**

## Gate 5 — The rules are healthy, in AUDIT mode, scoped to the pilot

**Why:** A prematurely-enforcing or over-scoped rule encrypts (or DNFs) mail that must stay readable.
**How:** `Get-TransportRule`; `OME-Configure.ps1 -Action MailFlowRules -WhatIf` to re-print the plan;
`OME-Validate.ps1` to confirm mode/scope.
**Pass:** `OME-Encrypt-Outbound-Pilot` and `OME-DoNotForward-Confidential` are **enabled**, **`Mode =
Audit`**, scoped to **`SG-OME-Pilot`**, each with the correct condition and template.
**Fail:** A rule is already `Enforce`, over-scoped, disabled, or has the wrong condition/template →
correct before testing detections.

## Gate 6 — A matching message is detected in AUDIT (without being encrypted)

**Why:** Proves the condition matches the intended mail **before** anything encrypts.
**How:** From a pilot sender, send a message that matches `OME-Encrypt-Outbound-Pilot` (subject
`[encrypt]`, external recipient). Review **message trace** / the rule's Audit results.
**Pass:** Message trace / Audit shows the rule **matched** the test message; a **non-matching** control
message (no `[encrypt]`, internal only) did **not** match. The matching message is **not** encrypted
(Audit mode).
**Fail:** No match on the test, or a match on the control → fix the rule conditions/scope before
enforcing.

## Gate 7 — A real encrypted send is encrypted, branded, and readable

**Why:** Proves the end-to-end path in a controlled window before broad enforcement.
**How:** In a controlled test window, flip **only the pilot Encrypt rule** to `Enforce` (or use a
dedicated test rule), send a sanctioned message, and open it as **(a)** an internal Microsoft 365
recipient and **(b)** an external recipient (one-time passcode / OME portal — R7). Then return the rule
to `Audit` if broad enforcement isn't yet approved.
**Pass:** Both recipients can read the message; the external recipient completes the OTP/portal flow;
the branding renders. Message trace shows the message was encrypted by the rule.
**Fail:** Either recipient cannot read it, the OTP/portal flow fails, or the rule didn't encrypt →
check RMS health (Gate 2), recipient support (R7), and the rule action.

## Gate 8 — Do Not Forward actually restricts the recipient

**Why:** DNF's value is that the recipient **cannot** forward/print/copy — this must be proven, not
assumed.
**How:** Send a sanctioned message via the `Do Not Forward` path to an internal test recipient and
attempt to **forward**, **print**, and **copy** it.
**Pass:** Forward/print/copy are **blocked/greyed** for the DNF message; the same actions are allowed
on an ordinary (`Encrypt`-only) message.
**Fail:** The recipient can forward/print a DNF message → confirm the rule applied `Do Not Forward`
(not `Encrypt`), and that the recipient client honours RMS restrictions.

## Gate 9 — Reporting reconciles with message trace

**Why:** Leadership needs a defensible summary of what was encrypted, without over-collecting.
**How:** Run `OME-Report.ps1` (read-only) and compare its rollup to **message trace** (and, for
Advanced external mail, `Get-OMEMessageStatus`).
**Pass:** The rollup (encrypted-message counts by rule/template/time) reconciles with message trace;
no content or recipient data is exposed beyond what the report is authorized to show.
**Fail:** Rollup diverges materially from message trace → message trace is authoritative; reconcile
before reporting.

## Gate 10 — Compliance/privacy confirm the mapping before broad enforcement

**Why:** *What* must be encrypted and *what* triggers DNF are business determinations, not technical
defaults.
**How:** Walk the condition→template mapping with compliance/privacy: which conditions encrypt, which
apply DNF, and the recipient experience.
**Pass:** Compliance/privacy confirm the mapping and the recipient experience in writing.
**Fail:** Ambiguity about what should be encrypted, or the mapping isn't signed off → resolve **before**
flipping rules to `Enforce`.

---

### Exit criteria (all must be true before Expand/enforce)

- [ ] Licensing in place — Basic (and Advanced where relied on) (Gate 1)
- [ ] Azure RMS enabled and healthy; `Test-IRMConfiguration` passes (Gate 2)
- [ ] `Encrypt` and `Do Not Forward` templates available (Gate 3)
- [ ] Branding configured and renders correctly (Gate 4)
- [ ] Rules healthy, `Audit` mode, pilot-scoped (Gate 5)
- [ ] Matching message detected in Audit without being encrypted (Gate 6)
- [ ] Controlled real send: encrypted, branded, readable internally + externally (Gate 7)
- [ ] Do Not Forward restricts forward/print/copy (Gate 8)
- [ ] Reporting reconciles with message trace (Gate 9)
- [ ] Compliance/privacy confirmed the condition→template mapping (Gate 10)
