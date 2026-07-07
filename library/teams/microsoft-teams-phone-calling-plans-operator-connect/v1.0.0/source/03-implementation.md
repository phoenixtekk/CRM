# 3. Implementation Guide — Teams Phone (Calling Plans & Operator Connect)

Follow these steps **in order**. Configuration is done in the **Teams admin center**
(`https://admin.teams.microsoft.com`) and the **MicrosoftTeams PowerShell module**; all write
automation runs **`-WhatIf` first** (the scripts default to a dry run). Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are **reused verbatim** in every
later step, test, and script.

> **Model:** Assess readiness and choose the PSTN path → design the policies/dial plan/emergency
> locations/voice apps → configure them → enable a small **pilot** ring → validate every gate
> (including a live emergency test) → expand under change control, with rollback at each step.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Connect first (every step that uses PowerShell):**
> `Connect-MicrosoftTeams` — modern auth / MFA. No stored credentials. Confirm with
> `Get-CsTenant | Select-Object DisplayName,TenantId`.

---

## Step 1 — Assess readiness and inventory (Assess)
1. Run **`TEAMSPHONE-Discovery.ps1`** (read-only) to capture the baseline: which users are already
   enterprise-voice-enabled, current number assignments, assigned voice policies, spare number
   inventory, and licensing signals. It writes the export `Number Inventory – Teams Phone – Discovery`.
2. In the Teams admin center, confirm your PSTN availability: `Voice → Calling plans` (Calling Plan
   availability for your country) and `Voice → Operators` (a participating Operator Connect operator).
   Record, per pilot user/number, the chosen path (**Calling Plan** or **Operator Connect**) — this
   drives the `-PhoneNumberType` used later.
3. Confirm Teams Phone licensing on the pilot users (Requirement 2.1). Do not proceed for a user whose
   license/plan is missing.

**Gate:** the inventory is captured, the PSTN path is decided per pilot number, and pilot users are
correctly licensed.

## Step 2 — Define the pilot scope (Design)
1. Create/confirm the pilot user group `Teams Phone Pilot – Voice – Pilot` (an Entra security group).
   Keep it small (e.g. 5–15 users across one site) and include at least one user who can safely
   participate in a coordinated **emergency test call**.
2. Run **`TEAMSPHONE-Scope.ps1`** (read-only) against the group to list members, their licensing, and
   current voice state — confirming everyone is ready to enable.

**Gate:** `Teams Phone Pilot – Voice – Pilot` exists, is populated, and every member is licensed.

## Step 3 — Acquire numbers (Design/Configure)
1. **Calling Plans:** Teams admin center → `Voice → Phone numbers → Get new numbers` (choose the
   **user (subscriber)** subtype for people, **service** subtype for auto attendants/queues), or submit
   a **port order** (`Voice → Phone numbers → Port`) to move existing numbers. Port orders are
   carrier-driven — **allow days to weeks**.
2. **Operator Connect:** request numbers from the operator (via the operator's portal / `Voice →
   Operators`); they appear under `Phone numbers` once provisioned into the tenant.
3. Re-run **`TEAMSPHONE-Discovery.ps1`** to confirm the new numbers show as **Unassigned** and of the
   expected type/capability.

**Gate:** enough user numbers for the pilot and any service numbers for voice apps are present and
unassigned.

## Step 4 — Register emergency addresses and dynamic locations (Configure — do this BEFORE assigning numbers)
1. In `Locations → Emergency addresses`, register and validate the site's civic address as
   `Emergency Address – HQ` (or via `New-CsOnlineLisCivicAddress`). Address validation is
   country-dependent — **verify in your tenant**.
2. Create the place(s) within it as `Emergency Location – HQ-Floor1` (`New-CsOnlineLisLocation`).
3. Map network identifiers to that location so location is **dynamic**: subnets
   (`Set-CsOnlineLisSubnet`), Wi-Fi access points (`Set-CsOnlineLisWirelessAccessPoint`), and — for
   wired — switches/ports (`Set-CsOnlineLisSwitch`, `Set-CsOnlineLisPort`).
4. **The choice of which addresses are legally required and validated is deferred to
   facilities/EHS/compliance** (Requirement 2.4) — you implement what they specify.

**Gate:** `Emergency Address – HQ` is validated and `Emergency Location – HQ-Floor1` is mapped to the
site's network identifiers.

## Step 5 — Build the calling policy, dial plan, and emergency calling policy (Configure)
1. **Calling policy** — create `Calling Policy – Standard – Prod`
   (`New-CsTeamsCallingPolicy -Identity "Calling Policy - Standard - Prod" ...`) with the calling
   features the org allows (call forwarding, delegation, call park, busy-on-busy, etc.). *(PowerShell
   identities cannot contain the en-dash; use the ASCII form `Calling Policy - Standard - Prod` in
   cmdlets and the display name `Calling Policy – Standard – Prod` in the admin center — treat them as
   the same artifact.)*
2. **Tenant dial plan** — create `Dial Plan - US - Prod`
   (`New-CsTenantDialPlan`) and add normalization rules (`New-CsVoiceNormalizationRule`) so extension
   and local-format dialing normalize to E.164. *(The Tenant Dial Plan applies to all PSTN paths; the
   **Online Voice Routing Policy** is Direct-Routing-only and is NOT created here.)*
3. **Emergency calling policy** — create `Emergency Calling Policy - HQ - Prod`
   (`New-CsTeamsEmergencyCallingPolicy`) to define **security-desk notification** (who is notified when
   an emergency call is placed, and the notification mode). *(Do NOT create an Emergency Call **Routing**
   Policy — that is a Direct-Routing control; for Calling Plans/Operator Connect, routing to the PSAP is
   handled by Microsoft/the operator, Requirement 2.5.)*

**Gate:** the three artifacts exist with agreed settings and correct names.

## Step 6 — Dry-run the pilot enablement (Pilot — no changes yet)
1. Run **`TEAMSPHONE-Set-NumbersAndPolicy.ps1 -WhatIf`** (the default) with the pilot group, the
   number-to-user mapping, the chosen `-PhoneNumberType`, and the policy/dial-plan/emergency-location
   names. With `-WhatIf` it makes **no changes** — it prints, per user, exactly which number it would
   assign, which policies it would grant, and which emergency location it would attach.
2. Read every line. Confirm each user, number, `PhoneNumberType`, dial plan, calling policy, emergency
   calling policy, and location is correct and that no production/non-pilot user appears.

**Gate:** the dry run shows exactly the intended changes for pilot users only, with no errors.

## Step 7 — Enable the pilot (Pilot)
1. Re-run **`TEAMSPHONE-Set-NumbersAndPolicy.ps1 -Execute`** for `Teams Phone Pilot – Voice – Pilot`.
   For each user it:
   - assigns the number and location with
     `Set-CsPhoneNumberAssignment -Identity <upn> -PhoneNumber <+E164> -PhoneNumberType <CallingPlan|OperatorConnect> -LocationId <id>` (this also enables enterprise voice),
   - grants `Grant-CsTenantDialPlan`, `Grant-CsTeamsCallingPolicy`, and
     `Grant-CsTeamsEmergencyCallingPolicy` with the named artifacts.
2. Allow policy propagation (assignments can take time to fully apply) before testing.

**Gate:** every pilot user is enterprise-voice-enabled with the correct number and named policies.

## Step 8 — Build auto attendants and call queues (Configure/Pilot)
1. Create resource accounts `Resource Account – AA-MainLine` and `Resource Account – CQ-Support`
   (`New-CsOnlineApplicationInstance`), license them with a **Teams Phone Resource Account** license
   (Requirement 2.1), then assign each a **service number** with
   `Set-CsPhoneNumberAssignment -Identity <resourceaccount> -PhoneNumber <+E164> -PhoneNumberType <path>`.
2. Run **`TEAMSPHONE-Set-VoiceApps.ps1 -WhatIf`** to preview creation of:
   - `Call Queue – Support – Prod` (`New-CsCallQueue`) — agents, routing method, overflow/timeout,
     backed by `Resource Account – CQ-Support`.
   - `Auto Attendant – MainLine – Prod` (`New-CsAutoAttendant`) — business-hours/holiday schedule
     (`New-CsOnlineTimeRange`, `New-CsOnlineSchedule`), menu and options
     (`New-CsAutoAttendantMenu`, `New-CsAutoAttendantMenuOption`, `New-CsAutoAttendantCallableEntity`)
     routing to the call queue, backed by `Resource Account – AA-MainLine`.
3. Re-run with `-Execute` to create them, then associate each resource account to its app
   (`New-CsOnlineApplicationInstanceAssociation`).

**Gate:** calling the auto attendant's number reaches the menu; the menu routes to the call queue,
which rings the agents.

## Step 9 — Validate the pilot (Validate)
1. Run **`TEAMSPHONE-Validation.ps1`** to produce `Voice Validation – Teams Phone – Report` — confirm,
   per pilot user: enterprise-voice enabled, correct `LineURI`/number, correct dial plan and calling
   policy, and emergency location attached.
2. Perform the live call tests in the **Testing Guide** (§5): outbound PSTN, inbound PSTN, and a
   **coordinated emergency test call** (Requirement 2.5) confirming the security-desk notification
   fires and the presented location is correct.

**Gate:** every test in §5 passes, including the emergency test. Do not expand until this gate is met.

## Step 10 — Expand under change control (Expand)
1. Add the next wave of users to a broader scope, repeat Steps 6–7 with `-WhatIf` then `-Execute`,
   reusing the same named policies and dial plan.
2. Re-run **`TEAMSPHONE-Validation.ps1`** after each wave to refresh `Voice Validation – Teams Phone –
   Report` and catch any user that did not fully enable.
3. Register additional sites' emergency addresses/locations (Step 4) **before** enabling users at each
   new site.

---

### Rollback (any step)
Voice changes are reversible. To back a user out:
`Remove-CsPhoneNumberAssignment -Identity <upn> -PhoneNumber <+E164> -PhoneNumberType <path>`
(unassigns the number and disables enterprise voice), and re-grant the prior/global policies
(`Grant-CsTeamsCallingPolicy -Identity <upn> -PolicyName $null`, likewise dial plan and emergency
calling policy → global). For voice apps, remove the association
(`Remove-CsOnlineApplicationInstanceAssociation`) and unassign the service number.
**`TEAMSPHONE-Set-NumbersAndPolicy.ps1 -Rollback -WhatIf`** previews the exact reversal per user before
you apply it.

### Order of operations
`Assess/inventory → pilot scope → acquire numbers → emergency addresses/locations → policies + dial plan → dry-run → enable pilot → auto attendants/queues → validate (incl. emergency test) → expand`
