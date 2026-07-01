# Solution Library

The managed home for every marketplace solution the factory produces. Browse it in
Explorer; each solution is self-contained and copy/zip-ready.

## Layout
```
library\
  _index\
    INDEX.html         ← open this in a browser: visual dashboard (metrics, charts, click-to-open file browser)
    INDEX.md           ← same data as Markdown (auto-generated)
    registry.json      ← machine registry (auto-generated)
    rebuild-index.ps1  ← regenerates INDEX.html + INDEX.md + registry.json from solution.meta.json files
  _deliverables\
    <slug>\            ← flat shelf: copies of just the customer files (PDF + scripts ZIP)
  <category>\          ← e.g. intune-solutions\  (mirrors the store categories)
    <slug>\            ← e.g. windows-hello-for-business\
      v1.0.0\          ← one version (frozen once published; new release = new vN.N.N folder)
        source\        ← markdown sources (overview, requirements, implementation, testing, troubleshooting)
        scripts\       ← raw PowerShell .ps1 files
        deliverables\  ← buyer files: <SLUG>-Solution.docx, .pdf, <SLUG>-Scripts.zip
        listing\       ← marketplace copy + bagisto-products.json (the publish contract)
        solution.meta.json  ← metadata: slug, category, SKUs, prices, version, status, dates
        README.md      ← one-glance summary of this solution/version
      LATEST.txt       ← names the current version folder (Explorer-friendly; no symlinks)
```

## Conventions
- **slug** = kebab-case of the title (`windows-hello-for-business`).
- **category folder** = kebab-case of the store category (`intune-solutions`).
- **SOL code** = short uppercase token used in SKUs (`WHFB` → `PTK-WHFB-COMM-001`).
- **version** = semver; bump for any content change. Old version folders are kept.
- To grab a whole product: copy/zip the `<slug>\v<version>\` folder.
- To see "what the customer gets" across everything: browse `_deliverables\`.

## Keeping the index honest
`INDEX.md` and `registry.json` are **generated**, never hand-edited. After any manual change
run:
```
pwsh library\_index\rebuild-index.ps1
```
The `/generate-solution` and `/publish-solution` skills run this for you automatically.
