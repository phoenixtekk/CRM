# Enrollment Scenarios — Windows & iOS (and where Apple Business Manager fits)

This section explains the enrollment paths this Quick-Start enables, so you know **which method to use for
which device** — and exactly where the one external dependency (Apple Business Manager) comes in.

---

## Windows enrollment

### Automatic enrollment (covered here)
Because you turned on **MDM auto-enrollment** (implementation Step 7), any Windows 10/11 device that is
**Entra-joined** by an in-scope, licensed user is **automatically enrolled** into Intune — no extra action
on the device. This is the path used in testing.

- **When to use:** company-standard PCs signed in with a work account.
- **What the user does:** joins the device to Entra during out-of-box setup or via **Settings → Accounts →
  Access work or school → Connect → Join this device to Microsoft Entra ID**.

### What's next for Windows (paid catalog)
Zero-touch, pre-provisioned Windows (ship the PC straight to the user, self-deploying) is **Windows
Autopilot** — beyond this Quick-Start. See the catalog solution **"Cloud-First Autopilot Zero-Touch
Provisioning"** when you are ready.

---

## iPhone / iPad (iOS/iPadOS) enrollment

There are **two** ways to enroll Apple devices. This Quick-Start fully enables the first; the second needs
Apple Business Manager.

### 1. Personal / BYOD enrollment (covered here)
With the **Apple MDM push certificate** in place (implementation Step 4), a user can enroll their own
iPhone through the **Company Portal** app:

- **When to use:** employee-owned iPhones/iPads; quick pilots; getting Intune working today.
- **What the user does:** installs **Intune Company Portal** from the App Store, signs in with their
  licensed work account, and follows the prompts to enroll. Management profile is user-approved.
- **Requirement:** only the tenant-level Apple MDM push certificate — **no Apple Business Manager needed.**
  This is the path used in `05-testing.md`.

### 2. Corporate zero-touch enrollment — Automated Device Enrollment (ADE) — **requires Apple Business Manager**
For **company-owned** iPhones/iPads that should enroll **automatically at first power-on**, supervised and
locked to your organization, you use **Automated Device Enrollment (ADE)**, formerly DEP. ADE depends on
**Apple Business Manager (ABM)** — an Apple portal, **separate from Intune**, where your organization's
purchased devices are registered and assigned to your MDM (Intune).

**Why it's a separate step:** ABM is operated by Apple, tied to your organization's **D-U-N-S number** and
verified business identity, and it is where Apple device tokens are generated and exchanged with Intune.
None of that happens inside the Intune admin center, so it cannot be covered by an Intune-only Quick-Start.

**The one-paragraph shape of ADE (so you know what's involved):** enroll your organization in Apple
Business Manager → download a public key from Intune's ADE token page → upload it in ABM to create an
**MDM server token** → upload that token back into Intune → assign your ABM devices to the Intune MDM
server → create an **ADE enrollment profile** in Intune → devices enroll automatically on activation.

> ### ⭐ Get the full Apple Business Manager walkthrough
> Setting up Apple Business Manager and wiring it to Intune for zero-touch iPhone enrollment is covered
> **end to end** in a dedicated solution in the Workplace catalog:
>
> **→ "Implement Entra ID Integration with ABM for Account Auto Provisioning for Microsoft Intune"**
> — available at **workplace.phoenixtekk.com** (search the catalog for *Apple Business Manager* or *ABM*).
>
> That solution walks the ABM enrollment, the token exchange, device assignment, and the Intune ADE
> enrollment profile with the same click-by-click detail you see in this free Quick-Start. When you need
> corporate zero-touch iPhones, start there.

---

## Which method should I use?

| Your situation | Use this | Covered in this Quick-Start? |
|---|---|---|
| Company Windows PCs signed in with work accounts | **Automatic Windows enrollment** | ✅ Yes |
| Employee-owned iPhones (BYOD) | **Company Portal user enrollment** | ✅ Yes |
| Company-owned iPhones, zero-touch at first boot | **ADE via Apple Business Manager** | ➡️ Pointer to the ABM catalog solution |
| Ship-to-user zero-touch Windows | **Windows Autopilot** | ➡️ Pointer to the Autopilot catalog solution |

For this Quick-Start you will enroll **one Windows PC (automatic)** and **one iPhone (BYOD via Company
Portal)** — both require nothing beyond what you configured in `03-implementation.md`.
