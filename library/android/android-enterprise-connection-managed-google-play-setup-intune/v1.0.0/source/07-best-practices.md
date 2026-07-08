# 7. Best Practices — Android Enterprise Connection & Managed Google Play Setup

Operating principles for a clean, durable Android Enterprise foundation in Intune.

## Binding & ownership
- **Own the managed Google Play owner account.** Bind managed Google Play with an
  **organization-controlled** Google account, never a personal Gmail or an individual admin's account.
  Record the account identity (not its password) so it survives staff changes.
- **Commit to one binding model deliberately.** Account enterprise (no Google Workspace) and the Google
  Workspace ↔ Intune EMM are **mutually exclusive**. Decide with the identity owner and document the
  decision; switching later is disruptive.
- **Never disconnect the connection to "test."** Disconnecting managed Google Play **un-enrols** Android
  Enterprise devices. Treat disconnect as a change-controlled, last-resort action only.

## Enrollment restrictions
- **Restrict to the models you actually use.** Allow personally-owned work profile only where BYOD is
  intended; allow corporate-owned device-owner enrollment only where you issue company devices. Block
  everything else — restrictions are the gate that keeps the wrong model out.
- **Block legacy Android device administrator** unless a specific legacy requirement exists. Android
  Enterprise is the modern, supported model.
- **Scope before you enforce.** Assign a new/changed restriction to the **pilot group first**; restrictions
  apply at **enrollment time**, so validate on new enrollments before widening.

## Enrollment models
- **Match the model to ownership and privacy.** BYOD → personally-owned work profile (personal data stays
  private). Company single-user → fully managed or corporate-owned work profile. Company shared/kiosk →
  dedicated/COSU (no user affinity).
- **Corporate-owned models require a reset device.** Fully managed / COPE / COSU enrol at **first-run**;
  plan device staging (or zero-touch) accordingly.
- **Keep enrollment tokens/QRs controlled.** They enrol devices — treat them as sensitive, set sane
  expiries, and rotate rather than sharing broadly.

## Pilot, change control, and the AMAPI transition
- **Assess → Design → Configure → Pilot → Validate → Expand** — always. Prove every change on the pilot,
  with pass/fail gates and a documented rollback.
- **Treat connector / enrollment-model changes as high-impact.** They can affect which devices enrol and,
  where AMAPI is in play, potentially re-enrollment.
- **Do not assume re-enrollment behavior.** The **AMAPI transition**, web/account-driven enrollment, and
  whether a change triggers **re-enrollment** are **actively evolving** — **verify against current Microsoft
  guidance and test on your own tenant** before any production change. Re-validate after Microsoft-announced
  Android enrollment changes.

## OEM & third-party (pattern level)
- **Layer OEM controls on top, don't replace the foundation.** Samsung Knox, Zebra, and other rugged/kiosk
  vendors extend Android Enterprise; configure their specifics in the vendor console (deferred to their
  docs) **after** the base enrollment model is correct.

## Automation & security
- **Safe-by-default automation.** Run the read-only scripts (`ANDROIDENT-Discovery.ps1`,
  `ANDROIDENT-Report.ps1`) freely; the config scripts default to `-WhatIf` — preview, then `-Apply`.
- **Least privilege.** Global Administrator for the one-time binding only; Intune Administrator for
  ongoing restriction/profile work.
- **No secrets in code.** The scripts use interactive delegated Graph sign-in — never hardcode credentials,
  tokens, or the Google owner account password.
- **Document the estate.** Record the binding model, owner account identity, restriction plan, and the
  enrollment-profile names so the next operator can reason about the foundation.
