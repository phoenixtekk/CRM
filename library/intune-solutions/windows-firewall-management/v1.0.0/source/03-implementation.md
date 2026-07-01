# 3. Implementation Guide — Windows Firewall Management

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A firewall policy enabling all profiles with default-deny inbound, plus an optional
> rules policy, assigned to a pilot group.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `Firewall-Pilot` → add pilot devices. **Create**.

## Step 2 — Create the firewall policy
1. Intune → **Endpoint security → Firewall → Create Policy**.
2. **Platform:** Windows. **Profile:** **Windows Firewall**. **Create**.
3. **Name:** `Firewall - Pilot`. **Next**.

## Step 3 — Configure the firewall settings
On **Configuration settings**, for **Domain**, **Private**, and **Public** profiles set:
1. **Firewall enabled** = **Allowed** (turns the firewall on for that profile).
2. **Default inbound action** = **Block**.
3. **Default outbound action** = **Allow**.
4. **Stealth mode** = **Block** (not configured to disable) — keeps the device from responding to probes.
5. **Inbound notifications** = **Block** (suppress per-app prompts to users) or as your policy prefers.
6. **Unicast responses to multicast broadcast** = **Block** (recommended).
7. **Log file path / size**, **Log dropped packets** = **Enable**, **Log successful connections** = optional.
Click **Next**.

## Step 4 — Assign to the pilot group
1. **Assignments → Add groups →** `Firewall-Pilot`. **Next → Create**.

## Step 5 — (Optional) create a firewall rules policy
Only if you need explicit allow/block rules (e.g. allow Remote Help inbound, allow a LOB app).

1. **Endpoint security → Firewall → Create Policy → Windows → Windows Firewall Rules**. **Create**.
2. **Name:** `Firewall Rules - Pilot`. Add each rule: **Name**, **Direction** (In/Out), **Action** (Allow/Block), **Protocol/Ports**, **Program**, **Local/Remote address** scope.
3. **Assignments → Add groups →** `Firewall-Pilot`. **Create**.

## Step 6 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the firewall is on for all profiles and the default inbound action is Block.

## Step 7 — Validate the pilot
1. Run **`WFM-Validation.ps1`** → confirms all profiles enabled with default-deny inbound.
2. Run **`WFM-RuleReport.ps1`** → lists effective firewall rules.
3. Run **`WFM-ConflictCheck.ps1`** → flags GPO/baseline firewall conflicts. Complete the **Testing Guide**.

## Step 8 — Expand to production
1. Add a production group to the firewall policy **Assignments**; roll out in waves.
2. Verify required inbound services still work (add explicit allow rules as needed) before broad rollout.
3. Re-validate each wave with **`WFM-Validation.ps1`**.

---
### Order of operations
`Pilot group → Firewall policy (profiles on + default-deny inbound) → (optional) rules policy → Assign → Apply → Validate → Expand`
