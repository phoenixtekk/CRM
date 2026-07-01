# 7. Best Practices — Azure Virtual Desktop Remote Access

- **Pilot before you scale.** A small `AVD – Users – Pilot` group on a single host pool catches image, profile, and Conditional Access issues before they reach the whole audience — the single most important practice.
- **Assign by group, never by user.** Grant access through `AVD – Users – Pilot` / `AVD – Users – Production` so adding a person is one group membership, not a portal change to the application group.
- **Choose the host pool type deliberately.** Use pooled multi-session for cost efficiency where users share a standard desktop; use personal only when a user genuinely needs a dedicated, persistent host.
- **Get FSLogix right first.** Size the `AVD – FSLogix Share – Core` for performance and high availability; an undersized or slow share is the top cause of slow logons and corrupt profiles.
- **Govern the front door.** Keep `AVD – Conditional Access – MFA` enforcing MFA (and, where possible, compliant-device or trusted-location conditions), and always exclude a break-glass account.
- **Name everything consistently.** Reuse the `<Purpose> – <Scope> – <Stage>` names and the `avdsh-` host prefix so the environment is self-documenting and scriptable.
- **Validate both clients every cycle.** Confirm the Windows and macOS clients each connect after image or policy changes — the two platforms can diverge.
- **Control idle cost.** Enable autoscale / start-on-connect so session hosts run only when users are working.
- **Keep images current.** Patch and rebuild the session-host image on a cadence; pin a known-good image version in a compute gallery for repeatable host creation.
- **Watch usage.** Track sessions and assignment with `AVD-Report.ps1` (and the AVD Insights workbook) to right-size capacity and chase unused assignments.
