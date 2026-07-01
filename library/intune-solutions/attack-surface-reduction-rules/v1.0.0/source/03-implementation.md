# 3. Implementation Guide — Attack Surface Reduction (ASR) Rules

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Deploy the high-value rules in **Audit** → review → exclude → switch to **Block** → expand.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `ASR-Pilot` → add pilot devices. **Create**.

## Step 2 — Create the ASR policy (Audit mode)
1. Intune → **Endpoint security → Attack surface reduction → Create Policy**.
2. **Platform:** Windows. **Profile:** **Attack Surface Reduction Rules**. **Create**.
3. **Name:** `ASR - Rules - Audit (Pilot)`. **Next**.

## Step 3 — Set the rules to Audit
On **Configuration settings**, set these to **Audit**:
1. **Block all Office applications from creating child processes** → Audit.
2. **Block credential stealing from the Windows local security authority subsystem (lsass.exe)** → Audit.
3. **Block executable content from email client and webmail** → Audit.
4. **Block execution of potentially obfuscated scripts** → Audit.
5. **Block Office applications from injecting code into other processes** → Audit.
6. **Block Win32 API calls from Office macros** → Audit.
7. **Block process creations originating from PSExec and WMI commands** → Audit.
8. **Use advanced protection against ransomware** → Audit.
Click **Next**.

## Step 4 — Assign and run the audit
1. **Assignments → Add groups →** `ASR-Pilot`. **Next → Create**.
2. Let pilot devices run normally for **1–2 weeks**.

## Step 5 — Review audit events
1. On pilot devices run **`ASR-AuditReport.ps1`** (reads Defender ASR audit events), and review the **Attack surface reduction rules report** (Defender portal, if onboarded).
2. Identify legitimate apps that *would* have been blocked.

## Step 6 — Add exclusions
1. Edit the ASR policy → for each rule with false positives, add **ASR Only Per Rule Exclusions** (or global ASR exclusions) for the verified legitimate file/path. **Save**.

## Step 7 — Switch proven rules to Block
1. Duplicate the policy as `ASR - Rules - Block (Pilot)` (or edit) and change the validated rules from **Audit** to **Block**. Keep any still-noisy rule in Audit. **Save**.
2. Re-validate with **`ASR-Validation.ps1`**.

## Step 8 — Expand to production
1. Add a production group to the **Block** policy **Assignments**; roll out in waves, watching the ASR report.
2. Re-run audit for any new rule before blocking it fleet-wide.
3. Re-validate each wave with **`ASR-Validation.ps1`** / **`ASR-AuditReport.ps1`**.

---
### Order of operations
`Pilot group → ASR policy (Audit) → Assign → Review audit → Exclusions → Block → Expand`
