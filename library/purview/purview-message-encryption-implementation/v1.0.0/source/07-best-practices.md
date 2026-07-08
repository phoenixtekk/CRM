# Best Practices — Purview Message Encryption (OME) in Microsoft Purview

Field-tested guidance for running OME well. It follows the same order the solution is built: get the
**RMS foundation and branding** right, then let **rules** apply encryption — piloted in `Audit` mode,
proportionate to sensitivity, and defensible.

## 1. Enable and prove the RMS foundation before anything else

- OME is only as healthy as **Azure RMS** underneath it. Confirm `AzureRMSLicensingEnabled : True` and
  a clean `Test-IRMConfiguration` **before** you build branding or rules — most "encryption isn't
  working" tickets trace back to an RMS/IRM problem, not the rule.
- Treat RMS enablement as a **tenant-wide, change-controlled** action; it affects all message
  encryption, not just your pilot.

## 2. Brand the experience — an unbranded portal reads as phishing

- Recipients (especially external ones) are asked to click a link and, often, complete a one-time
  passcode. If the wrapper and portal carry **default Microsoft branding or no branding**, people
  distrust it. Set your **logo, colour, and text** on the default OME configuration so the experience
  is unmistakably yours.
- Keep the disclaimer and "read the message" text **clear and reassuring** — tell recipients why they
  received an encrypted message and what to do. Follow Microsoft's current **logo size/format** limits
  (verify them; oversized logos fail to render).

## 3. Always pilot rules in AUDIT mode, scoped to a group

- A mail flow rule with `-Mode Audit` **matches and logs but does not encrypt** — this is your
  simulation. Build every OME rule in `Audit` first, scoped to **`SG-OME-Pilot`**, and confirm the
  match in **message trace** before flipping to `Enforce`.
- Expand **group-by-group** (or by loosening `-SentToScope` / conditions deliberately), never
  tenant-wide in one move. Re-run the Testing gates after each expansion.

## 4. Pick the template that fits the flow — Encrypt vs Do Not Forward

- **`Encrypt`** protects the message but lets the recipient **reply and forward** — right when the
  recipient needs to work with the content or route it onward within their own controls.
- **`Do Not Forward`** additionally blocks **forward/print/copy** — reserve it for the most sensitive
  one-to-one / one-to-few sends where onward sharing must be prevented. DNF *everything* creates
  friction and drives workarounds; use it deliberately.

## 5. Prefer classification-driven triggers over fragile keywords

- A subject keyword like `[encrypt]` is a fine **starting** trigger, but it depends on users
  remembering it. As labeling matures, drive encryption from a **sensitivity label** (a `Confidential`
  / `Highly Confidential` label can apply protection itself or serve as a rule condition) so the
  strongest protection follows the **classification**, not a typed string.
- Keep the condition→template mapping **narrow and explicit**; over-broad conditions (e.g. "encrypt all
  external mail") break automated flows and recipient usability.

## 6. Set recipient expectations to cut support load

- Document the **recipient experience** for both internal (inline) and external (OTP / OME portal)
  correspondents, and give the help desk a short runbook. Most "the encrypted email is broken" tickets
  are unfamiliarity, not failure.
- Test the **external** experience to your real correspondent domains during the pilot — the OTP/portal
  flow varies by provider (Outlook.com, Gmail, etc.).

## 7. Use Advanced features only where licensed — and know their limits

- **Custom branding templates**, **message revocation** (`Set-OMEMessageRevocation`), and **expiration**
  require **Advanced Message Encryption** (E5 / E5 Compliance). Don't design around them on a Basic OME
  tenant — plan on the **default** branding and the two templates.
- Revocation/expiration apply to mail read via the **OME portal** (typically external recipients);
  they don't retroactively control a message a Microsoft 365 recipient already opened inline. **Verify
  current behaviour and licensing in your tenant.**

## 8. Don't over-encrypt the plumbing

- Encrypting mail that flows to **systems** (ticketing, journaling, archiving, downstream automation)
  that can't process OME will **break** those flows. Exclude or narrowly scope rules away from
  service/system mailboxes, and confirm journaling/archiving still capture what compliance needs.

## 9. Keep the evidence trail — message trace and reporting

- **Message trace** (and, for Advanced, `Get-OMEMessageStatus`) is the authoritative record of what was
  encrypted. Report **counts by rule/template/time** (`OME-Report.ps1`) for leadership; don't rebuild
  a shadow log of message contents.
- Retention/disposition of mail-flow and encryption evidence is a **records/legal determination** — do
  not delete it to "clean up."

## 10. Separate the technical control from the sensitivity decision

- OME **enforces** a policy; it does not **decide** what is sensitive. Keep the condition→template
  mapping owned by **compliance/privacy**, reviewed as classification and regulation evolve. The
  administrator operates the control; the business owns the determination
  (`global-requirements-purview.md` §5).

## 11. Verify against your tenant — the surfaces evolve

- OME templates, the `*-OMEConfiguration` properties, transport-rule parameters (e.g. the custom-branding
  parameter name), and Advanced-feature availability are **licensing-dependent** and the Exchange/Purview
  portals **change**. Confirm exact paths, parameters, and capability availability **against your
  licensing/tenant** rather than assuming; treat anything in preview as such.
