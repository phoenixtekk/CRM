# Executive Summary — Enable Microsoft Intune (Quick-Start)

This Quick-Start takes you from **no device management** to a **working Microsoft Intune** in a single,
short session — whether you are standing up a **brand-new Microsoft 365 tenant** or **turning Intune on
for the first time in an existing tenant**. When you finish, Intune is the enrollment authority, the
basics and sensible defaults are in place, and you can **enroll and manage a Windows PC and an iPhone
(iOS/iPadOS)** end to end.

It is intentionally focused on the **fundamentals** — the smallest set of correct steps that gives you a
functioning Intune you can build on. It is not an exhaustive hardening guide; it is the confident first
mile.

## What you will accomplish
- Confirm licensing and set **Intune as the MDM authority** (a one-time tenant switch).
- Configure the **tenant-wide enrollment defaults** so the right platforms enroll and the wrong ones
  are blocked.
- Turn on **automatic Windows enrollment** so Entra-joined PCs manage themselves.
- Add the **Apple MDM push certificate** so iPhones and iPads can enroll.
- Apply a **minimal baseline** (one compliance policy, one configuration profile) so devices report
  health from day one.
- **Enroll a Windows device and an iPhone**, and confirm both check in and show as compliant.

## Where the boundary is (and where to go next)
Personal/BYOD iPhone enrollment works with only the Intune-side steps in this guide. **Corporate,
zero-touch iPhone enrollment (Automated Device Enrollment)** additionally requires **Apple Business
Manager (ABM)** — an Apple portal that lives *outside* Intune. This guide tells you exactly where ABM
fits and **points you to the dedicated catalog solution** that walks ABM setup end to end (see
`04-enrollment-scenarios.md`), so you are never left guessing.

## Why this exists
This Quick-Start is a **free preview** of the full solution catalog. It is written in the same
click-by-click house style, ships the same tested-script quality, and follows the same pilot-first
method as every paid solution — so you can see exactly what to expect before you buy. Once Intune is
live, the catalog picks up where this leaves off: Autopilot zero-touch, Conditional Access, compliance
at scale, application deployment, and more.

## Effort and outcome
A competent administrator completes the tenant-side configuration in well under an hour, plus a few
minutes per test device. The outcome is a **functioning Intune** with a repeatable enrollment path for
Windows and iOS — a foundation, not a dead end.
