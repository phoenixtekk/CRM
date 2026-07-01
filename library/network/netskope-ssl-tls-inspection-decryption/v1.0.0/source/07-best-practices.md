# 7. Best Practices — SSL/TLS Inspection & Decryption Rollout (Netskope)

- Trust before decrypt, always. Deploy and verify the inspection certificate root on devices before
  enabling decryption for them — trust must lead, never trail, or users get certificate warnings.
- Pilot first. Decryption affects live traffic; validate apps, do-not-decrypt bypasses, and user
  experience on a small pilot group before any broad enforcement. This is the single most important
  practice.
- Bypass what you must. Always do-not-decrypt banking, health, and other sensitive personal
  categories, and certificate-pinned applications — decrypting them breaks apps or creates
  privacy/compliance exposure.
- One named bypass list, reused everywhere. Maintain a single do-not-decrypt list
  (`Do-Not-Decrypt – Sensitive & Pinned – All Stages`) and apply it to both the pilot and production
  decryption policies so exclusions stay consistent as you expand.
- Order the rules correctly. Ensure the do-not-decrypt bypass is evaluated before the decrypt rule so
  sensitive/pinned traffic is never decrypted by accident.
- Treat decryption as a governed change. Document what is decrypted vs. bypassed, get privacy/legal
  (and works-council/HR where required) sign-off, and notify users per policy.
- Keep certificate trust deployment ahead of scope. Expand the trusted-certificate profile to a group
  before expanding the decryption policy to it.
- Keep a rollback ready. Be able to disable the decryption policy (or pull pilot members) instantly
  if an app or user impact appears; pre-write the comms.
- Watch coverage. Track certificate-trust and decryption-readiness with `NSSSL-Report.ps1` and chase
  devices missing the inspection root before they hit decryption.
- Document the configuration. Record the named profiles, policy, bypass list, and groups for audits
  and repeatability — assign once, repeat everywhere.
- Defer console specifics to vendor docs. Netskope console screens change; confirm the exact control
  in the official Netskope documentation and your tenant rather than guessing.
