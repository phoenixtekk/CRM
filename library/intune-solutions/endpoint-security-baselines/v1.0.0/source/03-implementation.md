# 3. Implementation Guide — Endpoint Security Baselines

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Deploy the latest Windows security baseline to a pilot, resolve conflicts, then expand
> and keep it version-current.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `Baseline-Pilot` → add pilot devices. **Create**.

## Step 2 — Review available baselines
1. Intune → **Endpoint security → Security baselines**.
2. Note the available baselines and their **latest version** (e.g. **Security Baseline for Windows 10 and later**).

## Step 3 — Create a baseline profile
1. Select **Security Baseline for Windows 10 and later → Create profile**.
2. **Name:** `Baseline - Windows - Pilot`. **Next**.
3. Confirm the profile is created from the **latest version** shown.

## Step 4 — Review and adjust settings
1. On **Configuration settings**, the categories show Microsoft's recommended values.
2. Leave defaults unless a setting conflicts with a required app or another solution you manage explicitly (e.g. if you manage BitLocker/Firewall/ASR via their own solutions, decide which owns those settings to avoid conflicts).
3. Click **Next**.

## Step 5 — Scope tags (optional)
1. Add scope tags if used, else **Next**.

## Step 6 — Assign to the pilot group
1. **Assignments → Add groups →** `Baseline-Pilot`. **Next → Create**.

## Step 7 — Monitor application and conflicts
1. Intune → **Endpoint security → Security baselines →** profile → **View report** / **Per-setting status**.
2. Resolve **Conflicts** — a setting controlled by two policies. Run **`ESB-ConflictCheck.ps1`** to list overlapping policies; make one policy authoritative per setting.

## Step 8 — Validate the pilot
1. On a pilot device, run **`ESB-Validation.ps1`** → confirms representative baseline settings applied.
2. Run **`ESB-TenantReport.ps1`** → confirms assignment + per-setting success across the pilot. Complete the **Testing Guide**.

## Step 9 — Expand and keep current
1. Add a production group to the baseline **Assignments**; roll out in waves.
2. When Microsoft releases a **new baseline version**, select the profile → **Change version** → review changes → update.
3. Re-validate with **`ESB-Validation.ps1`** / **`ESB-TenantReport.ps1`**.

---
### Order of operations
`Pilot group → Review baselines → Create profile (latest version) → Adjust → Assign → Resolve conflicts → Validate → Expand → Version-update`
