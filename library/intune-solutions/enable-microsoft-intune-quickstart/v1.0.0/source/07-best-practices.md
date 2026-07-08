# Best Practices — Enable Microsoft Intune (Quick-Start)

Keep the enablement clean and set yourself up to expand without rework.

## Pilot before you widen
- Start with the `INTUNE – QuickStart – Pilot` group and a handful of users. Confirm Windows and iOS both
  enroll and report compliant **before** you switch MDM user scope to **All** or broaden enrollment
  restrictions.
- Keep the pilot enrollment restriction (`Enrollment – QuickStart – Pilot`) until you are confident, then
  relax it deliberately.

## Name everything, consistently
- This guide uses `<Purpose> – <Platform> – <Stage>` (e.g. `Compliance – Windows – Baseline`,
  `INTUNE – QuickStart – Pilot`). Keep that convention as you add policies so you can find, audit, and
  clean up later. Reuse the exact names in scripts and documentation.

## Protect the Apple push certificate
- Use a **dedicated organizational Apple ID** (never a personal one) and store its credentials in your
  password vault.
- **Set a renewal reminder ~30 days before expiry.** Renew with the **same Apple ID** — a different Apple
  ID silently un-enrolls every Apple device. The certificate expiry is visible in the Apple MDM Push
  certificate blade and is reported by `ITSTART-Discovery.ps1`.

## License by group, not by hand (as you grow)
- One-off license assignment is fine for a pilot. For rollout, assign Intune licenses via a **group** so
  new users inherit entitlement automatically and enrollment "just works."

## Keep the baseline light — then layer
- The baseline here is deliberately minimal (one compliance policy per platform, one config profile). Do
  **not** pile on settings before devices reliably enroll. Add hardening incrementally, testing each
  layer against the pilot.

## Decide ownership early
- **BYOD (personal)** and **corporate** devices deserve different policy. This Quick-Start uses BYOD iOS to
  get you live fast; when you introduce company-owned iPhones via Apple Business Manager, keep their
  policies and enrollment profiles separate from BYOD.

## Verify with scripts, not assumptions
- Re-run `ITSTART-Validate.ps1` after any change to enrollment or baseline settings. It scores the
  enablement against the success criteria so drift is caught early.

## Know your next steps
Once Intune is functioning, the natural build-out (each a dedicated catalog solution):
- **Windows Autopilot** — zero-touch, ship-to-user Windows provisioning.
- **Apple Business Manager + ADE** — zero-touch corporate iPhones (see `04-enrollment-scenarios.md`).
- **Conditional Access** — require compliant devices before granting access to company data.
- **Compliance & configuration at scale**, **app deployment**, and **Defender for Endpoint** integration.

This free Quick-Start is the on-ramp; the catalog is the road.
