# 6. Troubleshooting — Shared iPad for Frontline Teams

Symptom → cause → fix. Work top-down: the first entry is the cause of the overwhelming majority of
failures in this solution, and almost every other symptom in this section is a downstream consequence
of it.

---

## 1. "The next user still sees the prior user's mail" — **THE #1 CAUSE**

**Symptom:** User B signs in (or picks up the iPad) and sees User A's mailbox, Teams chat, photos, or
documents. Test 5 fails. This is the original problem, unchanged.

**Cause — in order of likelihood:**

### 1a. The device is not actually in Shared iPad mode *(the cause ~90% of the time)*

The iPad is a **single-user device being handed between people**. The OS has no per-user boundary, so
there is nothing to isolate. Everything you configured downstream is irrelevant — restrictions,
compliance, and app settings cannot create a session boundary that the OS does not have.

**Diagnose:**
1. **Look at the device.** After enrollment, does it present a **Shared iPad sign-in screen asking for
   a Managed Apple ID**? If it lands on a **normal iPad home screen**, it is **not** in Shared iPad
   mode. Stop here — this is your answer.
2. Intune → **Devices → All devices → (the iPad) → Properties**. Check:
   - **Supervised = `Yes`**? If `No`, the device did not go through ADE.
   - **Enrollment profile = `SHARED IPAD – ADE Profile – Shared`**?
   - **Enrollment type** — is it an Apple/ADE (DEP) enrollment type, or a manual/user enrollment?
3. Run `SHAREDIPAD-Validate.ps1`. Look specifically at **"Shared iPad ENABLED on that profile"**.
4. Run `SHAREDIPAD-Report.ps1` and check the device's **ProfileIsShared** and **SharedIPadReady**
   columns.

**Fix — depending on what you found:**

| What you found | What it means | Fix |
|---|---|---|
| The enrollment profile does **not** have Shared iPad enabled | The profile is wrong. Every device enrolled with it is single-user. | Fix the profile (Implementation §3 Step 7), **then wipe and re-enroll every affected device** (Step 12). Changing the profile does **not** convert already-enrolled devices. |
| The profile is correct but the device didn't get it | The serial was never assigned the profile. | Assign it on the token (Step 8), then **wipe and re-enroll** the device (Step 12). |
| **Supervised = `No`** / the device enrolled manually | The device never went through ADE. | **Wipe and re-enroll via ADE** (Step 12). There is no in-place conversion — you cannot make an enrolled iPad supervised or Shared without erasing it. |
| The serial isn't on the ADE token at all | The device is not in ABM. | See §6 below. This may be a procurement problem. |

> **The critical fact: you cannot convert a device into Shared iPad mode in place.** Shared iPad is
> established **at enrollment**. Fixing the profile and waiting for a policy sync does nothing. The
> device must be **erased and re-enrolled** through ADE. If you take one thing from this section, take
> this.

### 1b. The device *is* in Shared iPad mode, but users aren't signing out

**Diagnose:** Watch a real handover. Does the outgoing user use the **iPad's** sign-out (the user
picker → Sign Out), or do they just put the iPad down? Does the device show the sign-in screen when
it's on the rack, or someone's home screen?

**Fix:** Brief the field team on the shift-handover runbook (Testing §5) and put it on the rack. Shared
iPad gives a clean device **after** sign-out. A user who walks away leaves an open session — the one
gap the architecture does not close for you. Also confirm the handover point has good Wi-Fi (R17): a
sign-out attempted on a dead spot may not complete.

### 1c. It's one specific app leaking, not the device

**Diagnose:** Run the Test 5 checklist item by item. If Outlook, Teams, and Photos are clean and only
the **CMMS app** (or the viewer) leaks, Shared iPad is working — that app is not honouring the per-user
boundary.

**Fix:** This is a **vendor gap and you cannot configure around it**. Take the Test 5 results to the app
vendor as evidence and ask explicitly: *does this app support Apple Shared iPad?* Do not spend days in
Intune on it — there is no setting.

---

## 2. Managed Apple ID sign-in fails

**Symptom:** A user cannot sign in at the Shared iPad sign-in screen.

| Symptom detail | Cause | Fix |
|---|---|---|
| The account is not recognised / rejected | **The user has no Managed Apple ID.** Usually because their address is still conflicted by a personal Apple ID (R14). | Confirm in ABM → **Users** that the Managed Apple ID exists. If not, resolve the conflict (§3 below / Implementation Step 3). **This is a gate — pick a clear user for the pilot rather than fighting it mid-test.** |
| Sign-in hangs or times out | Network. Apple's endpoints are unreachable, or the Wi-Fi at this location is poor (R16/R17). | Test from the same spot: reach `https://login.microsoftonline.com`. Confirm Apple's published enterprise endpoints are allowed through the proxy. **VERIFY WITH APPLE** — use Apple's current published network requirements list, not an older allowlist. Retry at a known-good location to isolate it. |
| "Device is full" / sign-in refused for space | Storage (R11). See §7 below. | §7. |
| The wrong sign-in page appears, or none | Federation is not configured or not active for the domain. | §4 below. |
| Password rejected but the account exists | If **not** federated, the Managed Apple ID has its own separate password — the user is typing their work password. | Either federate (R13, Implementation Step 4) or issue the Managed Apple ID password. **Federate.** A second password on a shared frontline device ends up written on the rack. |

---

## 3. ABM says "address already in use" / the Managed Apple ID cannot be created

**Symptom:** ABM will not issue a Managed Apple ID at a staff member's work address.

**Cause:** **A personal Apple ID is already using that address.** ABM cannot issue a Managed Apple ID at
an address in use by a personal Apple ID. This is expected, it is Requirement R14, and it is the single
largest blocker in this project.

**Fix:**
1. Run `SHAREDIPAD-AppleIDConflict.ps1` to build the **candidate** worklist from Entra ID.
   **Remember what this list is and is not:** it tells you who *would need* a Managed Apple ID and at
   which address. **It cannot query Apple and cannot tell you which addresses actually conflict.**
2. **Get the authoritative conflict list from Apple Business Manager.** ABM is the only source that
   knows. Reconcile it into the CSV's `ABMConflict` column.
3. Resolve the conflicts via Apple's supported path, which is built around **verifying your domain** in
   ABM; affected personal Apple IDs must then be changed to a personal email address (or are otherwise
   handled by Apple's process).

> **VERIFY WITH APPLE.** The exact flow name, where it lives in ABM, what ABM reports, the notification
> Apple sends the affected user, the **grace period**, and **what happens to a user who does not act**
> are **all Apple's and all change**. **Get every one of these from current Apple Business Manager
> documentation before you plan a date or write user communications.** A wrong timeline here is a broken
> promise to staff.

> **Before you act on any of this:** whether to require staff to rename or surrender a personal Apple ID
> tied to their work address is an **identity, HR, legal, and communications decision** — it reaches
> their personal iPhone, personal Mac, iCloud photo library, and App Store purchases. **Present the
> options and their impact to the customer's HR, legal, and identity owners and let them decide**
> (Implementation Step 3c). Do not make the call. Do not send a staff notification without executive
> sponsorship and an agreed comms plan and grace period (R18).

**Tactical workarounds while the campaign runs:**
- **For the pilot:** pick two `PILOT – Shared iPad Users` who are **clear of conflict**. Do not burn the
  pilot on a blocked user — you will end up debugging a configuration that is fine.
- **Worth raising early:** issuing Managed Apple IDs on a **verified subdomain** the staff have never
  used personally (e.g. `staff.contoso.com`) may sidestep many conflicts entirely. **VERIFY WITH APPLE**
  that this fits your ABM and federation configuration before proposing it — but raise it *before* the
  campaign starts, because switching to it later is expensive.

---

## 4. Federation sign-in loop, or the Microsoft sign-in page never appears

**Symptom:** Signing in with a Managed Apple ID loops between Apple and Microsoft, returns to the
sign-in screen repeatedly, or never presents the Microsoft page at all.

**Cause / fix:**

| Cause | Fix |
|---|---|
| Federation is not active for that domain | In ABM, confirm federated authentication is configured **and active** for the exact domain of the address being used (e.g. `contoso.com`). |
| The address is on a domain you never federated | Users on a second domain or a subdomain need that domain verified and federated too. Check the exact address the user is typing. |
| The Entra account is disabled, blocked, or has no licence | Entra → **Users → (the user)**: account enabled, and licensed (R1/R2). A disabled account cannot complete federated sign-in. |
| Conditional Access is blocking the sign-in | Entra → **Sign-in logs**, filter to the user, and read the **Conditional Access** tab. A CA policy requiring a compliant device can block the sign-in that is *establishing* the session on that device. Move the offending policy to **report-only** to confirm, then fix the policy — do not leave it off. |
| The Microsoft consent was never completed | Re-run the ABM federation setup and complete the Microsoft-side consent as a **Global Administrator** (Implementation Step 4). |
| The user still has an unresolved personal Apple ID at that address | Federation does not resolve conflicts. §3 above. |

> **VERIFY WITH APPLE AND MICROSOFT.** The ABM federation flow, its navigation, the exact Microsoft
> permissions requested, how ABM behaves for a domain with unresolved personal Apple IDs, and the
> handling of pre-existing accounts are **Apple's and Microsoft's and they change**. Follow Apple's
> **current** ABM federation documentation rather than a remembered flow.

---

## 5. Restrictions not applying / the App Store is still there

**Symptom:** `SHARED IPAD – Restrictions – Field Lockdown` shows as assigned, but the device still has
the App Store, still allows adding accounts, or still allows app removal.

| Cause | Diagnose | Fix |
|---|---|---|
| **The device is not supervised** *(the usual cause)* | Intune → **Devices → (device) → Properties → Supervised**. | Most of these restrictions **only apply to supervised devices** and are **silently ignored** on an unsupervised one. **Wipe and re-enroll via ADE** with Supervised enabled (Steps 7, 12). No in-place fix exists. |
| The device isn't in the group | Intune → **Devices → (device) → Group membership**; or run `SHAREDIPAD-Validate.ps1`. | If the group is **empty**, go to §8 — the Provisioning Client owner is missing. |
| The profile isn't assigned to *this* group | `SHAREDIPAD-Validate.ps1` reports assignment per group. Common at Expand: assigned to Pilot, forgotten for Production. | Add the assignment (Step 14), or run `SHAREDIPAD-Set-Restrictions.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Production' -WhatIf:$false`. |
| Not synced yet | Intune → **Devices → (device) → Sync**; check the profile's **Device status**. | Allow time and re-check. Policy delivery is not instant. |
| Profile shows **Error** or **Conflict** | Open the profile → **Device status** → the device → read the per-setting result. | A **Conflict** means another profile sets the same setting differently. Find the other profile and resolve it — the device does not pick a winner for you. |
| Camera/Safari blocked and the workload broke | The lockdown is too tight. | Loosen the specific setting (Step 9), **then re-run Test 5** — loosening a restriction can reopen a leak. |

---

## 6. The device won't ADE-enroll / the serial isn't on the token

**Symptom:** Setup Assistant never shows **Remote Management**; the iPad comes up as a normal personal
device; or the serial does not appear under the ADE token in Intune.

| Cause | Diagnose | Fix |
|---|---|---|
| **The device is not in Apple Business Manager** *(the most common, and the most expensive)* | ABM → **Devices** → search the serial. No result = not in ABM. | **A device not in ABM cannot be ADE-enrolled and therefore CANNOT run Shared iPad** (R6). There is no Intune setting that fixes this. Either bring it into ABM by an Apple-supported route, or replace it with an iPad purchased through an ABM-linked reseller. **VERIFY WITH APPLE** — the routes for adding already-owned devices, the eligibility rules, and any provisional window are Apple's and change. **Establish this across the whole fleet in the Assess phase** — it decides whether this is a configuration project or a hardware purchase. |
| The serial isn't assigned to the MDM server | ABM → **Devices** → check the serial's assigned MDM server. | Assign it to **`Intune – Shared iPad`**, then **Sync** in Intune (Step 8). |
| Assigned in ABM but not visible in Intune | Intune → token → **Devices** → **Sync**. | Apple **rate-limits** this sync. Wait several minutes. **Do not click Sync repeatedly** — it will not go faster. |
| The serial has no enrollment profile assigned | Intune → token → **Devices** → check the **Profile status** column. | Select the serials → **Assign profile** → `SHARED IPAD – ADE Profile – Shared` (Step 8). |
| The device was already set up | It went past Setup Assistant. | **Erase All Content and Settings** (Step 12) so it returns to Setup Assistant. |
| The ADE token has expired | `SHAREDIPAD-Discovery.ps1` reports the expiry. | **The token expires annually.** Renew it in ABM and re-upload (Step 6). An expired token stops all new enrollments. Calendar it. |
| The APNs certificate has expired | `SHAREDIPAD-Discovery.ps1` reports the expiry. | Renew it **with the same company Apple ID** you originally used (Step 5). A new Apple ID means re-enrolling every managed device in the tenant. |
| Enrollment restrictions block iOS/iPadOS | Intune → **Devices → Enrollment → Enrollment device platform restrictions**. | Allow iOS/iPadOS for the target scope. |

**The Shared iPad option is missing from the enrollment profile:** confirm you are creating an
**iOS/iPadOS** profile, and that you drilled into the **ADE token** first (**Devices → Enrollment →
Apple → Enrollment program tokens → (open the token) → Profiles → Create profile → iOS/iPadOS**). The
Profiles tab does not exist anywhere else in the console, and Shared iPad appears under the
**user-affinity** choice on the Management settings page — it is a multi-user model, so it is not under
"enroll without user affinity". **VERIFY WITH APPLE AND MICROSOFT** — the console layout for this page
changes.

---

## 7. Storage full / a user can't sign in for lack of space

**Symptom:** A user cannot sign in and the device reports it is full; or users' data is being evicted
and they have to re-download everything each shift; or later users in a shift cycle fail while early
ones succeed.

**Cause:** **Each resident user consumes storage on the device.** The device is either undersized, or
the enrollment profile's **maximum cached users** is set higher than the hardware can carry. This is
the constraint teams underestimate, and it typically appears at wave 3, not at the pilot.

**Diagnose:**
1. Intune → **Devices → (device) → Hardware** — total and free storage.
2. Run `SHAREDIPAD-Report.ps1` and review the `StorageGB` / `FreeGB` / `FreePercent` columns across the
   fleet. Look for a pattern, not a single device.
3. Check the **maximum cached users** on `SHARED IPAD – ADE Profile – Shared` (Step 7).

**Fix:**
- **Reduce the maximum cached users** to what the hardware can genuinely carry, and re-enroll the
  affected devices for the new value to take effect at enrollment.
- **Or re-size the hardware.** Under-specced iPads are a procurement problem, not a configuration one.
- **VERIFY WITH APPLE** — Apple publishes the **current minimum and recommended storage** for Shared
  iPad and the **maximum number of resident users**, and both have changed across iPadOS releases. **Get
  the figures from Apple's current Shared iPad documentation.** Do not use a number from an older
  deployment; do not use a number from this document — it deliberately does not give you one.
- **Run Test 9 at the pilot**, with three or four users on one device. Finding this at device 4 of 40 is
  a conversation. Finding it at device 34 is a re-procurement.

---

## 8. The device group is empty after enrollment / nothing deploys

**Symptom:** iPads enroll successfully, but `SHARED IPAD – FMD – Pilot` (or `– Production`) is empty.
No restrictions, no compliance, no apps arrive. Everything in the console looks correctly configured.

**Cause:** **The Intune Provisioning Client service principal is not an Owner of the group**, or the
group is **Dynamic** instead of Assigned.

Enrollment-time device grouping works by that first-party principal **owning** the Assigned group.
Without the owner, nothing is ever added to the group — and because every policy is assigned to the
group, nothing deploys. **This failure looks exactly like a policy problem and is not one.**

**Diagnose:**
1. Entra → **Groups → `SHARED IPAD – FMD – Pilot` → Owners**.
2. Run `SHAREDIPAD-Validate.ps1` — it checks this explicitly and matches by AppId.

**Fix:**
1. Confirm the group's membership type is **Assigned**, **not Dynamic**. If it is Dynamic, this
   mechanism does not apply at all — recreate it as Assigned (Step 2).
2. Entra → **Groups → (the group) → Owners → Add owners**, and search by **AppId
   `f1346770-5b25-470b-88bd-d5744ab7952c`**.
   - **Search by the AppId, not the display name.** The display name varies by tenant — many show
     **`Intune Autopilot ConfidentialClient`**, others show something else. Matching on the display name
     is how people conclude the principal "isn't there" when it is.
   - **If the principal genuinely isn't present:** open `https://intune.microsoft.com` once as a
     **Global Administrator** to provision it into the tenant, then add it as owner.
3. **Verify the owner on `SHARED IPAD – FMD – Production` too**, before the first expansion wave. Do not
   assume it carried over from the pilot group — it does not.
4. Re-enroll a test device to confirm it now lands in the group.

**Verify this before every pilot and every wave.** It is one click to check and a lost afternoon to
diagnose.

---

## 9. An app isn't available or misbehaves under Shared iPad

**Symptom:** An app in `SHARED IPAD – Apps – Field Allowlist` doesn't install, doesn't appear, or
behaves oddly — won't stay signed in, loses data between sessions, or leaks between users.

| Symptom | Cause | Fix |
|---|---|---|
| App never installs | Not assigned **Required** to the device's group; or not synced. | Confirm the Required assignment to the correct group (Step 11a) and sync. `SHAREDIPAD-Validate.ps1` checks this. |
| App installs but isn't on the home screen | It's not in the **allowlist** (`SHARED IPAD – Apps – Field Allowlist`, Step 11b) — the allowlist hides everything it doesn't name. | Add the app's **bundle ID** to the allowlist. |
| **The wrong app** installed | Selected by name from App Store search. Search returns near-identical results. | Remove it and re-add by the **exact publisher string and bundle ID** (Step 11a). Get the CMMS/viewer publisher and bundle ID **from the vendor, in writing**. |
| App won't install on a Shared iPad specifically | A store app may depend on an App Store identity that a Shared iPad does not have. | Re-add it as a **volume purchased (VPP/ABM)** app and license it **by device**. This is the preferred model for a fleet. |
| App loses the user's data between their own sessions | The app isn't storing data in the per-user space. | Vendor issue. Raise it with the vendor. |
| **The app leaks data between users** | **The app is not honouring the Shared iPad user boundary.** | **Vendor gap — you cannot configure around it.** Take the Test 5 evidence to the vendor and ask explicitly whether the app supports **Apple Shared iPad**. Do not burn days in Intune. |
| A Microsoft app behaves unexpectedly | Possible, and unexpected if Shared iPad is working. | Re-verify Test 3 first. Then raise a Microsoft support case. **Do not reach for Shared Device Mode as a patch** until you understand why — layering B on a broken A hides the real fault. |

> **If you are layering Option B (Microsoft 365 Shared Device Mode):** it requires the **Microsoft
> Authenticator** broker and per-app configuration, and it affects **only apps that participate in
> SDM**. **The set of Microsoft apps supporting shared device mode on iOS/iPadOS changes over time —
> verify the current supported-app list against Microsoft's documentation before designing around it.**
> This solution does not assert that list, and neither should you. An app that does not participate is
> simply unaffected by SDM — that is not a bug, and no amount of configuration will change it.

---

## 10. Compliance shows Not evaluated / the device is Not compliant

| Symptom | Cause | Fix |
|---|---|---|
| **Not evaluated** | The device isn't in the group the policy is assigned to. | §8, then confirm the assignment (Step 10). |
| **Not compliant — minimum OS** | iPadOS is below the floor set in `SHARED IPAD – Compliance – iPadOS`. | Update iPadOS (R10). If the floor itself is wrong, **VERIFY WITH APPLE** the current Shared iPad minimum and correct the policy — don't lower the floor to make a red dashboard green. |
| **Not compliant — jailbreak** | Detected or falsely detected. | Investigate. On a supervised, ADE-enrolled, locked-down field iPad, a genuine jailbreak is a serious finding — treat it as one. |
| **Not compliant — passcode** | The policy requires a passcode the shared-use model doesn't set. | Discuss with the customer's security owner. Under Shared iPad each user authenticates at sign-in; decide the device-passcode requirement deliberately (Step 10) rather than by default. |
| Compliance grace period masking failures | The policy's noncompliance action is delayed. | Set **Mark device noncompliant → Immediately** for a field fleet so you see reality. |

---

## 11. The scripts

| Symptom | Cause | Fix |
|---|---|---|
| `Connect-MgGraph` fails or scopes are refused | The signed-in account lacks the rights, or admin consent hasn't been granted for the scope. | Sign in as **Intune Administrator** (or Global Administrator). Each script's header lists its exact **Required Graph scopes** — grant those, no more. |
| **"Group not found"** / **"profile not found"** for an object you can see in the portal | **The scripts match on EXACT display name, and the object names use an en dash (–), not a hyphen (-).** They look nearly identical and are different characters. | Copy the name **verbatim** from this guide, or pass it with the `-DeviceGroupName` / `-ProfileName` parameter. Do not retype the dash. This is the single most common script failure. |
| "Found N objects named X" | A duplicate object exists. | Resolve the duplicate in the portal. The scripts deliberately refuse to guess which one you meant. |
| `SHAREDIPAD-Set-Restrictions.ps1` reports what it would do but changes nothing | **Working as designed — it defaults to `-WhatIf`.** | Read the dry-run output, then re-run with **`-WhatIf:$false`** to apply. That explicit step is the point. |
| `SHAREDIPAD-Validate.ps1` says PASS but Test 5 still fails | **Expected and important.** A PASS proves the **architecture** is configured. It cannot prove sessions are isolated. | Go to §1. The session-isolation A/B test (Testing §5) is the only real gate. Never sign a project off on the script alone. |
| `SHAREDIPAD-AppleIDConflict.ps1` shows every user as "UNKNOWN" conflict | **Working as designed. The script cannot query Apple.** | It builds the **candidate** list from Entra. **The authoritative conflict list comes from Apple Business Manager.** Fill the `ABMConflict` column from ABM. Never present the script's output to a customer as a conflict list. |
| "Specify a scope" error from `SHAREDIPAD-AppleIDConflict.ps1` | Deliberate — it refuses to run unscoped across a whole tenant. | Pass `-GroupName 'PILOT – Shared iPad Users'` or `-Domain 'contoso.com'`. An unscoped worklist is one nobody can action. |
| Shared iPad state reports "unknown" / a property looks absent | The Graph property naming for Shared iPad on the ADE enrollment profile has varied across API versions. The scripts check the known variants. | **Verify the true state in the portal**: Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles → `SHARED IPAD – ADE Profile – Shared`**. The portal is authoritative; treat a script "unknown" as *check by hand*, not as a failure. |
| Device counts don't match the portal | Graph paging, or a stale sync. | The scripts follow `@odata.nextLink` and page fully. If the numbers still differ, force a device sync and re-run. |
| Nothing returned for iPads | The filter looks for `operatingSystem eq 'iOS'` and a model containing "iPad" — correct for iPadOS, which Graph still reports as iOS. | If genuinely empty, no iPads are enrolled yet. Check Intune → **Devices → All devices**. |
