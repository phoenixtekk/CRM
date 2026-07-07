# 3. Implementation — Microsoft Teams Rooms Deployment & Management

This is the ordered, runnable procedure. It follows the deployment model **Assess → Design → Configure → Pilot → Validate → Expand**, provisions the **pilot room first**, names every object with the `<Purpose> – <Scope> – <Stage>` convention from Section 1, and defines explicit **pass/fail gates** and a **rollback**. Portal paths and cmdlets are current Microsoft public-documentation detail; plan-/cloud-dependent items are flagged **verify in your tenant**.

Throughout, the canonical pilot objects are:

- Resource account: `Room Account – Boardroom-A – Pilot` → UPN `room-boardroom-a@contoso.com`
- Meeting policy: `Meeting Policy – Teams Rooms – Prod`
- Calling policy: `Calling Policy – Teams Rooms – Prod`
- Pro Management profile: `Config Profile – Teams Rooms – Standard`
- Pro Management update ring: `Update Ring – Teams Rooms – Pilot`

> **Connections used below.** Exchange Online (`Connect-ExchangeOnline`), Microsoft Graph (`Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All"`), and Microsoft Teams (`Connect-MicrosoftTeams`) — all modern-auth, no stored credentials.

---

## Phase 1 — Assess (read-only)

Establish the baseline before changing anything.

1. **Inventory existing rooms and mailboxes.** In Exchange Online PowerShell:
   ```powershell
   Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited |
     Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
   ```
   Run `TEAMSROOMS-Discovery.ps1` (read-only) to capture room mailboxes, their calendar processing, license assignment, and current Teams policy grants in one pass.
2. **Confirm licensing entitlements (R1).** `Get-MgSubscribedSku | Select-Object SkuPartNumber, @{N='Available';E={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}` and confirm Teams Rooms Pro/Basic seats are available. **Verify the Basic room cap for your tenant.**
3. **Confirm admin roles and network readiness (R2, R3, R5, R6).** Verify you hold the least-privilege roles and that the pilot room's subnet meets Teams media guidance.
4. **Record the baseline.** Save the discovery output; it is the reference for the rollback and for validating that only intended objects changed.

**Gate A (exit Assess):** you have a confirmed pilot room, available Teams Rooms licensing, the required roles, and a saved baseline. Do not proceed until all are true.

---

## Phase 2 — Design

Finalize the standard (write it down; do not configure yet).

1. **Naming.** Confirm the Section 1 naming table for the pilot and for production rooms.
2. **Licensing tier per room.** Decide **Pro** (centrally managed) vs **Basic** per room. The pilot room should be **Pro** so you validate the Pro Management path.
3. **Calendar-processing standard** (the Teams Rooms recommended values, applied in Phase 3):
   | Setting | Value | Reason |
   | --- | --- | --- |
   | `AutomateProcessing` | `AutoAccept` | Room auto-accepts valid invitations |
   | `AddOrganizerToSubject` | `$false` | Keep the real subject on the console |
   | `DeleteSubject` | `$false` | Preserve the meeting subject |
   | `DeleteComments` | `$false` | Preserve the invite body (holds the Join link) |
   | `RemovePrivateProperty` | `$false` | Keep private-flag handling intact |
   | `AddAdditionalResponse` | `$true` | Send a helpful auto-reply |
   | `ProcessExternalMeetingMessages` | `$true` | Show external-org invites on the console |
   | `AllowConflicts` | `$false` | Prevent double-booking (adjust to policy) |
   | `BookingWindowInDays` / `MaximumDurationInMinutes` | per policy | Booking horizon / max length |
4. **Room policies.** Define `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` values (auto-admit, content sharing, IP video, etc.) with the governance stakeholders.
5. **Pro Management profile and update ring.** Define `Config Profile – Teams Rooms – Standard` and the pilot update ring `Update Ring – Teams Rooms – Pilot`.
6. **Peripheral standard.** Record the certified camera, microphone/soundbar, and front-of-room display models.

**Gate B (exit Design):** the standard is documented and approved under change control.

---

## Phase 3 — Configure (pilot room only)

Apply the standard to the **pilot room only**. Every write below defaults to a dry run; the helper scripts require an explicit `-Commit` to make changes.

### 3.1 Create the resource account (room mailbox)

Exchange Online PowerShell:
```powershell
New-Mailbox -Name "Room Account - Boardroom-A - Pilot" `
  -Alias "room-boardroom-a" `
  -MicrosoftOnlineServicesID "room-boardroom-a@contoso.com" `
  -Room
```
`-Room` creates the mailbox as a **room mailbox** with a disabled, system-generated password. (`TEAMSROOMS-Set-ResourceAccount.ps1 -Commit` wraps this step plus 3.2–3.4.)

### 3.2 Enable the account, set usage location, and stop password expiry

The room mailbox's Entra account must be **enabled**, have a **usage location** (required before licensing), and have its password set to **not expire** (a room signs in unattended). Set a strong password of record, then via Microsoft Graph:
```powershell
$u = Get-MgUser -UserId "room-boardroom-a@contoso.com"
Update-MgUser -UserId $u.Id -AccountEnabled:$true -UsageLocation "US"
# Stop the password expiring (a room's sign-in is permanent):
Update-MgUser -UserId $u.Id -PasswordPolicies "DisablePasswordExpiration"
```
> Set `UsageLocation` to the room's country. Store the account password in your privileged secrets vault, not in scripts.

### 3.3 Assign the Teams Rooms license

Assign **Teams Rooms Pro** (for the pilot) to the account. Confirm the SkuId from `Get-MgSubscribedSku`, then:
```powershell
$sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "Microsoft_Teams_Rooms_Pro" }
Set-MgUserLicense -UserId $u.Id -AddLicenses @{ SkuId = $sku.SkuId } -RemoveLicenses @()
```
> **Verify the exact `SkuPartNumber`** in your tenant — Teams Rooms SKU part numbers vary and change over time. Do not hardcode a SkuId; resolve it from `Get-MgSubscribedSku`.

### 3.4 Configure calendar processing

Apply the Phase 2 calendar-processing standard (Exchange Online):
```powershell
Set-CalendarProcessing -Identity "room-boardroom-a@contoso.com" `
  -AutomateProcessing AutoAccept `
  -AddOrganizerToSubject $false -DeleteSubject $false -DeleteComments $false `
  -RemovePrivateProperty $false `
  -AddAdditionalResponse $true `
  -AdditionalResponse "This room is a Microsoft Teams Room. Add it to your Teams meeting to enable one-touch join." `
  -ProcessExternalMeetingMessages $true `
  -AllowConflicts $false
```
Verify with `Get-CalendarProcessing -Identity "room-boardroom-a@contoso.com"`. (`TEAMSROOMS-Set-RoomPolicy.ps1` applies this and 3.5 with `-WhatIf`/`-Commit`.)

### 3.5 Grant the room Teams meeting and calling policies

Create the room policies in the Teams admin center (**Meetings → Meeting policies** and **Voice → Calling policies**), named `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod`, then grant them to the room account:
```powershell
Grant-CsTeamsMeetingPolicy -Identity "room-boardroom-a@contoso.com" `
  -PolicyName "Meeting Policy - Teams Rooms - Prod"
Grant-CsTeamsCallingPolicy -Identity "room-boardroom-a@contoso.com" `
  -PolicyName "Calling Policy - Teams Rooms - Prod"
```
> Policy availability and specific settings can be **plan-dependent** (some advanced meeting features require Teams Premium) — verify which settings your licensing exposes.

### 3.6 Sign the device in and onboard to Pro Management

1. On the certified device console, complete the OEM setup, then **sign in** with `room-boardroom-a@contoso.com` and its password of record. (Device-side setup is the OEM's documentation.)
2. In the **Teams admin center → Teams Rooms** (or **Teams devices**), confirm the room appears and is **online**.
3. In the **Teams Rooms Pro Management** portal (`portal.rooms.microsoft.com` — **verify the URL for your cloud**), confirm the room is enrolled; assign it the `Config Profile – Teams Rooms – Standard` and add it to the `Update Ring – Teams Rooms – Pilot`.

**Gate C (exit Configure):** the pilot room mailbox exists, is licensed, has the standard calendar processing and room policies, the device is signed in and online, and it is enrolled in Pro Management.

---

## Phase 4 — Pilot

Use the room for real meetings for an agreed window (for example one week).

1. **Book it.** Invite `Room Account – Boardroom-A – Pilot` to Teams meetings (internal and one external-org meeting); confirm each auto-accepts and shows on the console with subject and Join button.
2. **Join from the room.** Press **Join** on the console; confirm audio, video, and content sharing.
3. **Exercise Pro Management.** Confirm health telemetry appears and that the update ring is applied.
4. **Log issues** against Section 6 (Troubleshooting) and resolve before validation.

---

## Phase 5 — Validate (pass/fail gates)

Run `TEAMSROOMS-Validation.ps1` and the manual checks in Section 5. The pilot passes only when **all** gates are green:

- **Gate V1 — Provisioned:** mailbox is `RoomMailbox`, account enabled, password non-expiring, usage location set.
- **Gate V2 — Licensed:** a Teams Rooms (Pro for the pilot) license is assigned.
- **Gate V3 — Calendar:** calendar processing matches the standard (auto-accept, subject/body preserved).
- **Gate V4 — Policy:** the room account has `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod`.
- **Gate V5 — Joins reliably:** the room books, shows the agenda, and one-touch-joins with working audio/video/content.
- **Gate V6 — Managed & healthy:** the room is enrolled in Pro Management with **healthy** status and an assigned update ring.

If any gate fails, fix it (Section 6) and re-validate before expanding.

---

## Phase 6 — Expand

Repeat Phases 3–5 for each additional room, changing only `<Scope>` in the object names (for example `Room Account – Huddle-3 – Prod`). Reuse the **same** policies and Pro Management profile so every room is identical. Add production rooms to a broader `Update Ring – Teams Rooms – Prod` (kept behind the pilot ring so updates are proven on the pilot first). Monitor the fleet with `TEAMSROOMS-HealthReport.ps1` on a schedule.

---

## Rollback

Because you configure pilot-first, a problem is contained to one room. To roll back the pilot:

1. **Policies:** re-grant the tenant default policy — `Grant-CsTeamsMeetingPolicy -Identity room-boardroom-a@contoso.com -PolicyName $null` (and the calling policy) to remove the room-specific grant.
2. **Calendar processing:** restore the prior values captured in the Phase 1 baseline with `Set-CalendarProcessing`.
3. **License:** remove the Teams Rooms license with `Set-MgUserLicense -RemoveLicenses @($sku.SkuId) -AddLicenses @{}` if the account is being decommissioned.
4. **Pro Management:** unenroll the room from the portal and remove it from the update ring.
5. **Account:** if the room is being removed entirely, `Remove-Mailbox` the room mailbox under change control.

Because every object is uniquely named, rollback targets exactly the pilot objects and never affects users or other rooms.
