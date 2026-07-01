# 1. Solution Overview — Azure Virtual Desktop Remote Access

## What Azure Virtual Desktop is
Azure Virtual Desktop (AVD) is Microsoft's cloud service for delivering a full Windows desktop and individual Windows applications from Azure, reached securely over the internet from a thin client app. Instead of shipping laptops or exposing on-premises systems, you run the session hosts (the actual Windows VMs) inside your Azure subscription, publish them through a workspace, and users connect from the AVD client on Windows or macOS. Identity is governed by Microsoft Entra ID, access is gated by Conditional Access, and user profiles roam between hosts with FSLogix.

## How it works
1. A `host pool` is a collection of identical Windows session-host VMs. It is either pooled (many users share a set of multi-session hosts) or personal (each user gets a dedicated host).
2. An `application group` publishes what users see from that host pool — either a full Desktop or a curated set of RemoteApps.
3. A `workspace` bundles one or more application groups into the single entry the user subscribes to in the AVD client.
4. Users and groups are assigned to an application group; Entra ID authenticates them and Conditional Access decides whether the connection is allowed.
5. `FSLogix` stores each user's profile on a file share so the desktop, settings, and Outlook/Teams cache follow the user across any pooled host.
6. The user opens the AVD client on Windows or macOS, signs in with their Entra ID account, and the desktop or apps stream down over the Remote Desktop Protocol.

## What you can control
- Host pool type (pooled multi-session vs. personal) and the session-host VM size, image, and count.
- What is published — a full `Desktop` application group, a `RemoteApp` application group, or both.
- Who gets access, through Entra ID group assignment to the application group.
- Sign-in security through Conditional Access (require MFA, compliant device, trusted network).
- Profile storage and roaming behavior through FSLogix on an Azure Files or Azure NetApp Files share.
- Autoscale / start-on-connect to control running cost when hosts are idle.

## Benefits
- **Remote access without exposure** — internal Windows desktops and apps reach users anywhere, with no inbound ports opened to on-premises systems.
- **Cross-platform** — the same governed desktop is reachable from both Windows and macOS clients.
- **Governed entry** — every connection passes Entra ID and Conditional Access, so MFA and device/location rules are enforced at the door.
- **Consistent profiles** — FSLogix means a user gets the same desktop on any pooled host, with no roaming-profile pain.
- **Elastic cost** — autoscale and start-on-connect run session hosts only when people are working.

## Limitations (be honest with buyers)
- AVD delivers Windows desktops/apps; it does not publish macOS or Linux desktops (macOS is a client only).
- Session hosts are real VMs you size, image, and patch — capacity planning and an update strategy still apply.
- FSLogix needs a performant, highly available file share; an undersized share is the most common cause of slow logons.
- Rich connection/usage insights depend on enabling the AVD Insights workbook and a Log Analytics workspace (noted in requirements).

## The deployment model
> **Assess identity, networking, and licensing → configure the host pool, workspace, application groups, FSLogix and Conditional Access → pilot to a small group → validate the Windows and macOS client experience → expand to the full audience.** The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**
