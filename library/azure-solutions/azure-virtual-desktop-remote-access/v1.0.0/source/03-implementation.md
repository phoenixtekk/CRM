# 3. Implementation Guide — Azure Virtual Desktop Remote Access

Follow these steps **in order**, in the **Azure portal** at `portal.azure.com` → search **Azure Virtual Desktop**. Object names use the `<Purpose> – <Scope> – <Stage>` convention from `02-requirements.md` and must be reused verbatim.

> **Model:** Stand up one pooled host pool, publish a Desktop, assign a small pilot, validate the Windows and macOS clients, then expand to production. Identity and FSLogix are configured before users connect.

## Step 1 — Create the assignment groups
1. `portal.azure.com` → **Microsoft Entra ID → Groups → New group → Security**. Name `AVD – Users – Pilot`, add a few representative users. **Create**.
2. Repeat to create `AVD – Users – Production` (the full audience). **Create**.
3. Confirm each member holds an eligible AVD license (Requirement 2.2).

## Step 2 — Prepare identity and networking
1. Decide the host join model (Entra join for cloud-only, or Entra hybrid join for line-of-sight to on-premises).
2. Confirm the virtual network `AVD – VNet – Core` exists with a session-host subnet and correct DNS (Requirement 2.4).
3. For Entra-joined hosts that need access to an Azure Files FSLogix share, confirm the share has identity-based authentication enabled (Requirement 2.6).

## Step 3 — Create the host pool
1. `portal.azure.com` → **Azure Virtual Desktop → Host pools → Create**.
2. **Basics:** Subscription, resource group `AVD – Resource Group – Core`, host pool name `AVD – Host Pool – Pilot`, location = your AVD region.
3. **Host pool type:** **Pooled** (shared multi-session). Set **Load balancing** to **Breadth-first**. (Choose **Personal** here instead only if each user must own a dedicated host.)
4. **Virtual machines:** **Yes, add virtual machines**. Resource group `AVD – Resource Group – Core`, **Name prefix** `avdsh-`, virtual network `AVD – VNet – Core` + session-host subnet, image = your chosen image (Requirement 2.5), VM size and count sized to the pilot.
5. **Domain to join:** select **Microsoft Entra ID** (or **Active Directory** for hybrid) per Step 2; tick **Enroll VM with Intune** only if managing hosts with Intune.
6. **Workspace:** choose **Yes, create a workspace** and name it `AVD – Workspace – Core` (this also creates the Desktop application group). **Review + create → Create**.

## Step 4 — Confirm the workspace and application group
1. **Azure Virtual Desktop → Application groups** — confirm a **Desktop** application group exists for `AVD – Host Pool – Pilot`; rename it (or its friendly name) to `AVD – App Group – Desktop`.
2. **Azure Virtual Desktop → Workspaces →** `AVD – Workspace – Core` **→ Application groups** — confirm `AVD – App Group – Desktop` is registered to the workspace. If not, **+ Add** it.
3. (Optional, to publish individual apps instead of a full desktop) **Application groups → Create → RemoteApp**, host pool `AVD – Host Pool – Pilot`, name `AVD – App Group – RemoteApp`, add the published apps, then register it to `AVD – Workspace – Core`.

## Step 5 — Assign users
1. **Azure Virtual Desktop → Application groups →** `AVD – App Group – Desktop` **→ Assignments → + Add**.
2. Add the group `AVD – Users – Pilot`. **Select**.
3. (Hybrid only) Also grant the same users the **Virtual Machine User Login** role on the host-pool resource group so they can sign in to the session hosts.

## Step 6 — Configure FSLogix on the session hosts
1. Confirm the FSLogix agent is present on the session hosts (baked into the image, or installed now).
2. **Azure Virtual Desktop → Host pools →** `AVD – Host Pool – Pilot` **→ Session hosts** to confirm the `avdsh-` hosts are **Available**.
3. Point FSLogix at the profile share `AVD – FSLogix Share – Core` by setting (via Intune Settings catalog, Group Policy, or registry) `Enabled = 1` and `VHDLocations` = the share UNC path under `HKLM:\SOFTWARE\FSLogix\Profiles`.
4. Ensure the FSLogix users have Modify rights on the share so each user's profile container can be created.

## Step 7 — Apply Conditional Access
1. `portal.azure.com` → **Microsoft Entra ID → Conditional Access → + New policy**. Name `AVD – Conditional Access – MFA`.
2. **Users:** include `AVD – Users – Pilot`; **exclude** your break-glass account.
3. **Target resources → Cloud apps:** include **Azure Virtual Desktop** (and **Microsoft Remote Desktop** / **Windows Cloud Login** as listed for your tenant).
4. **Grant:** **Require multifactor authentication**. Set the policy to **On**. **Create**.

## Step 8 — Connect the Windows client (validate)
1. On a Windows pilot device install the **Windows App** (or **Remote Desktop client**) — `Add work or school account` / subscribe to `https://client.wvd.microsoft.com/arm/webclient/index.html` via **Subscribe with URL**.
2. Sign in as a pilot user (Entra ID); complete the Conditional Access MFA prompt.
3. Confirm `AVD – Workspace – Core` appears and the **Desktop** (from `AVD – App Group – Desktop`) launches to a full Windows session.

## Step 9 — Connect the macOS client (validate)
1. On a Mac pilot device install the **Windows App** (or **Microsoft Remote Desktop**) from the **Mac App Store**.
2. **Add Workspace** → enter `https://client.wvd.microsoft.com/arm/webclient/index.html` (or sign in with the work account) and authenticate as a pilot user; complete MFA.
3. Confirm `AVD – Workspace – Core` and its Desktop appear and the session launches from macOS exactly as on Windows.

## Step 10 — Validate the pilot
1. Run `AVD-Validation.ps1` to confirm the host pool, session hosts (`avdsh-`), workspace, and Desktop application group are healthy and assigned.
2. Run `AVD-Report.ps1` to confirm pilot user sessions and assignments.
3. Complete the **Testing Guide** (`05-testing.md`) — both clients connect, the profile roams, and Conditional Access enforces MFA.

## Step 11 — Expand to production
1. Add session-host capacity to `AVD – Host Pool – Pilot` (or create `AVD – Host Pool – Production` for full scale) sized to the production audience.
2. Add the group `AVD – Users – Production` to `AVD – App Group – Desktop` (Step 5) and to the `AVD – Conditional Access – MFA` policy (Step 7).
3. Configure autoscale / start-on-connect to control idle cost, and re-run `AVD-Report.ps1` each cycle to track usage and assignment.

---
### Order of operations
`Groups → Identity + networking → Host pool → Workspace/app group → Assign users → FSLogix → Conditional Access → Windows client → macOS client → Validate → Expand`
