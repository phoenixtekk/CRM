# 7. Best Practices — CASB & Cloud App Control with Netskope

- Discover before you decide. Build the app risk register — All cloud apps – Discovery stage first;
  you cannot make a sound sanctioned/unsanctioned call on apps you cannot see.
- Govern without blocking. Prefer restrict and coach over block — coach users toward the sanctioned
  alternative instead of slamming the door, which only drives workarounds.
- Reserve block for the highest-risk apps. Use a hard block only for apps whose risk score and
  disposition on the register genuinely warrant it.
- Pilot every control. Scope every new policy to `CASB Pilot – Pilot users – Pilot` first; expand to
  `CASB Broad – All users – Expand` only after the pilot pass gate.
- Start API policies in monitor mode. Watch the API connections — Sanctioned apps – Configure surface
  findings before turning on automated response, so you don't quarantine legitimate sharing.
- Control activities, not just apps. The real leverage is the activity controls — Inline – Configure
  profile (upload, share, download), plus data-movement controls for sensitive content — not blanket
  app blocking.
- Scope to identity. Apply controls by Entra group, not by IP, so policy follows the user across
  devices and networks.
- Keep the register current. Re-run discovery each cycle; new shadow-IT apps appear constantly —
  score and dispose of them on the same register.
- Keep a rollback ready. Before enabling any block, confirm the scope-out / monitor-only / disable
  path so live traffic can be restored fast.
- Document dispositions. Record why each app is sanctioned, restricted, coached, or blocked — for
  audits, repeatability, and consistent decisions as the catalog grows.
