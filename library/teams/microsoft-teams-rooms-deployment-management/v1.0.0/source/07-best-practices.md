# 7. Best Practices — Microsoft Teams Rooms Deployment & Management

Durable practices for running a fleet of consistent, reliable, centrally managed Teams Rooms. These generalize the deployment model into standing operational discipline.

## Provisioning & accounts

- **One resource account per room, named to the convention.** Use `Room Account – <Room> – <Stage>` and reuse the exact name across the mailbox, licensing, policy grants, and scripts so the deployment is self-documenting and auditable.
- **Passwords never expire; store them in a vault.** A room signs in unattended and permanently — always set `DisablePasswordExpiration` and keep the password of record in a privileged secrets vault, never in a script or spreadsheet. Rotate on a controlled schedule, not on an expiry timer.
- **Set usage location before licensing.** License assignment fails without it; make it a standard step in the provisioning script.
- **Resolve SKU IDs at runtime.** Never hardcode a Teams Rooms `SkuId` — read it from `Get-MgSubscribedSku` because SKU part numbers and IDs vary by tenant and change over time.

## Calendar processing

- **Preserve subject and body.** Keep `AddOrganizerToSubject`, `DeleteSubject`, and `DeleteComments` at `$false` so the console shows the real subject and the Join button. This is the single most common cause of "the room has no Join button."
- **Process external meeting messages.** Set `ProcessExternalMeetingMessages = $true` so cross-org meetings appear on the console — increasingly common with hybrid work.
- **Match booking policy to the room.** Tune `AllowConflicts`, `BookingWindowInDays`, and `MaximumDurationInMinutes` to how the room is actually used; document the choice.

## Policy & licensing

- **Give rooms their own policies.** Apply dedicated `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` rather than letting rooms inherit an end-user policy — rooms have different needs (auto-admit, content, no chat noise).
- **Right-tier each room.** Use **Pro** for any room you want centrally managed, updated, and health-monitored; reserve **Basic** for the few low-touch rooms within the (verify-in-tenant) cap.
- **Treat plan-dependent features as such.** Advanced meeting experiences may require Teams Premium or specific hardware — verify entitlement before promising a feature, and flag it rather than assume it.

## Central management (Pro Management)

- **Enroll every Pro room.** A room that isn't in Pro Management is a room you'll be visiting in person. Enroll at sign-in as a standard step.
- **Ring your updates.** Keep a small **pilot** update ring ahead of the fleet so firmware/software updates prove out on a couple of rooms before reaching the rest.
- **Standardize with configuration profiles.** Apply one `Config Profile – Teams Rooms – Standard` fleet-wide so settings drift is caught and corrected centrally.
- **Watch health proactively.** Schedule `TEAMSROOMS-HealthReport.ps1` and act on unhealthy/offline rooms before users report them; a room is the most visible endpoint in the building.

## Hardware & peripherals

- **Certified only.** Use certified systems and certified peripherals end to end — it is the line between "supported" and "you're on your own."
- **Standardize models per room class.** Pick a small set of certified configurations (huddle / standard / boardroom) so spares, support, and training are simple.
- **Defer device internals to the OEM.** Firmware, on-device setup, and physical AV follow the vendor's documentation; keep that boundary clear in runbooks.

## Change discipline

- **Pilot-first, always.** Validate any new standard or policy change on the pilot room against the Section 5 gates before touching the fleet.
- **Keep a baseline and a rollback.** Capture room state (discovery output) before changes; every uniquely named object makes rollback exact and contained.
- **Automate read-only checks; gate writes.** Run discovery/validation freely; require an explicit `-Commit` for any change so a dry run is always the default.

## Documentation & audit

- **Maintain a room register.** Track each room's account UPN, license tier, policies, profile, ring, and certified hardware — the health report can seed it.
- **Record every named object.** Because names encode purpose/scope/stage, an up-to-date register plus the scripts is a complete, reproducible description of the fleet.
