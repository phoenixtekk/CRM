# Troubleshooting — Teams Chat & Channel DLP

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"Teams DLP isn't working" reports trace back to a location not enabled, message-DLP licensing,
condition matching, the internal-vs-external logic, or simulation-vs-enforce confusion — not the rule
itself.** Where a portal path or cmdlet parameter is named, **verify it against your tenant** — the
Purview portal and the Teams DLP scope evolve.

---

## 1. Messages are covered but shared FILES are not (the classic gap)

**Symptoms:** A sensitive **message** is caught, but a sensitive **file** shared in a chat or channel
is not.

**Fix**
- **Enable the file locations.** Teams-shared files live in **SharePoint** (channel files) and
  **OneDrive** (chat files) — they are governed by those DLP locations, **not** the Teams-messages
  location. Add **SharePoint** and **OneDrive** to the policy. `DLPTEAMS-Validate.ps1` gate **A3** and
  `DLPTEAMS-Discovery.ps1` both flag this gap.
- Confirm the file rule (`DLP-Rule-TeamsFiles`) is present and enabled.

---

## 2. The Teams-messages location isn't available, or message DLP never fires

**Symptoms:** You cannot add the **Teams chat and channel messages** location, or message posts never
generate a DLP match even in simulation.

**Likely causes & fixes**
- **Licensing.** Message-level Teams DLP is a premium, plan-gated capability with its own requirement
  (typically E5-tier / equivalent). **Verify against the Microsoft Purview service description for
  your tenant** (R1). Without the entitlement, the messages location / message actions are unavailable.
- **Surface not in scope.** Coverage of **private / shared channels** varies — verify which Teams
  surfaces your licensing/tenant covers (R3). A message posted in an unsupported surface won't match.
- **Propagation delay.** After creating/scoping the policy, allow time before message telemetry
  surfaces — it is **not** instant. Wait and retry.

---

## 3. The rule fires on the wrong things (false positives)

**Symptoms:** Legitimate messages/files are flagged/blocked.

**Likely causes & fixes**
- **Condition too broad.** If a rule keys on "all content" instead of a **sensitivity label / SIT**,
  it matches everything. Tighten the condition (R4). `DLPTEAMS-Validate.ps1` gate **A7** flags rules
  with no readable content condition.
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- **Internal traffic blocked when it should be allowed.** If the R6 intent was audit-internal /
  block-external, check the internal-vs-external condition on the message rule — an over-broad rule
  will block internal chats too.
- Tune **in simulation** — never tune by loosening an already-enforcing block in production.

---

## 4. The rule doesn't fire on content it should

**Symptoms:** A message/file you expect to match generates no DLP match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test message/file must actually carry the **sensitivity
  label** or contain the **sensitive information type** the rule keys on. Seed a known match.
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPTEAMS-Discovery.ps1`
  inventories both.
- **Rule disabled.** `DLPTEAMS-Validate.ps1` gate **A6b** flags disabled rules.
- **Wrong location.** A file shared in a channel is a **SharePoint** match, not a Teams-messages match
  — make sure you are looking at the right location's activity.

---

## 5. The internal-vs-external logic behaves unexpectedly

**Symptoms:** External sharing isn't blocked, or internal messages are blocked when they shouldn't be.

**Likely causes & fixes**
- **Recipient condition mis-set.** Confirm the message rule's *recipient is external / shared with
  people outside the org* condition matches the R6 intent. **Verify the exact condition parameter name
  for your tenant** (`Get-Help New-DlpComplianceRule -Full`).
- **Federation/guest settings.** Whether external participants are even possible depends on Teams
  external-access/federation settings — confirm with the Teams admin (R3).
- Re-test **in simulation** with a genuine external/guest participant before enforcing.

---

## 6. Simulation looks fine but enforcement doesn't block

**Symptoms:** In simulation the activity is recorded; after "turning it on" the block still doesn't
happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the
  policy out of simulation: portal → turn the policy **On**; PowerShell → `Set-DlpCompliancePolicy
  -Identity DLP-Teams-Pilot -Mode Enable`. `DLPTEAMS-Validate.ps1` gate **A4** shows the current mode.
- **Rule action still Audit.** The rule may be **Audit / notify-only** even though the policy is
  enforcing. Set the message action to **block** (with policy tip) per R6.
- **User out of scope.** Enforcement only applies to users/locations in scope. Confirm with
  `DLPTEAMS-ScopeHealth.ps1` / gate **A5**.
- **Propagation delay.** Policy/action changes take time to apply. Wait, then retest.

---

## 7. `New-DlpCompliancePolicy` / location parameter errors

**Symptoms:** Creating the policy errors on a location parameter (`-TeamsLocation` /
`-SharePointLocation` / `-OneDriveLocation`) or the scope value.

**Fix**
- **Verify the location parameter names and permitted values for your tenant.** They **evolve**. Run
  `Get-Help New-DlpCompliancePolicy -Full` and check current Microsoft docs, then adjust. The
  `DLPTEAMS-Configure.ps1` script deliberately **prints the plan** so you can verify before `-Commit`.
- Confirm the pilot group (`SG-TeamsDLP-Pilot`) exists and the identifier is one your tenant accepts
  (`DLPTEAMS-ScopeHealth.ps1`). Avoid `All` during the pilot (gate **A5**).
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPTEAMS-Discovery.ps1` to learn the exact shape in your tenant.

---

## 8. A default Teams DLP policy is interfering

**Symptoms:** DLP behaviour you didn't configure, or two policies acting on the same content.

**Fix**
- **Identify the default policy.** Tenants may have a **default Teams DLP policy**.
  `DLPTEAMS-Discovery.ps1` lists all policies and their locations/modes so you can see what is already
  acting. Reconcile your pilot policy with it (do not double-apply conflicting actions); adjust or
  scope the default per your change control if needed.

---

## 9. Activity report is empty or export fails

**Symptoms:** `DLPTEAMS-Report.ps1` returns no activity, or the Activity Explorer export warns and
skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer**
  / **DLP reports** in the portal.
- **Quiet pilot window.** A small pilot may have no activity in the window — widen `-Days` or perform
  the sanctioned test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.

---

## 10. "It blocked a legitimate conversation / share" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**: `Set-DlpCompliancePolicy -Identity DLP-Teams-Pilot
  -Mode TestWithoutNotifications` (simulation) or `-Mode Disable` (off). Either **stops enforcement at
  once.**
- Or disable the single offending rule: `Set-DlpComplianceRule -Identity <rule> -Disabled $true`.
- Then work the relevant section above (usually §3 false positives or §5 external logic), fix **in
  simulation**, re-validate with `DLPTEAMS-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* external sharing be **blocked** or only **audited**? → the **R6** decision owners.
- Is *this content* actually sensitive / in scope? → **compliance / data owners**.
- Is a user's message/share a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPTEAMS-Report.ps1`, Activity explorer, the validation output) — not
a verdict.
