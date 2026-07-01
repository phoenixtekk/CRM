<#
  rebuild-index.ps1 — regenerates the library master index from per-solution metadata.

  Source of truth: every  library\<category>\<slug>\solution.meta.json
  Outputs (overwritten each run, never hand-edited):
    library\_index\registry.json   — machine-readable array of all solutions
    library\_index\INDEX.md        — human-browsable dashboard grouped by category
    library\_index\INDEX.html      — visual dashboard (metrics + charts + collapsible file browser)

  Run anytime (the skills call it automatically after generate/publish):
    pwsh G:\VisualStudioCode\CRM\library\_index\rebuild-index.ps1
#>

$ErrorActionPreference = 'Stop'
$libRoot   = Split-Path $PSScriptRoot -Parent          # ...\library
$indexDir  = $PSScriptRoot                              # ...\library\_index
$repoRoot  = Split-Path $libRoot -Parent               # ...\CRM

function Money([double]$n) { '$' + ('{0:N2}' -f $n) }
function Enc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }

# collect all solution.meta.json (skip _index / _deliverables)
$metas = Get-ChildItem -Path $libRoot -Recurse -Filter 'solution.meta.json' -File |
         Where-Object { $_.FullName -notmatch '\\_index\\' -and $_.FullName -notmatch '\\_deliverables\\' }

$records = foreach ($m in $metas) {
  try { $j = Get-Content $m.FullName -Raw | ConvertFrom-Json } catch { Write-Warning "Bad JSON: $($m.FullName)"; continue }
  $comm = $j.products | Where-Object { $_.audience -eq 'commercial' } | Select-Object -First 1
  $npo  = $j.products | Where-Object { $_.audience -eq 'nonprofit'  } | Select-Object -First 1
  $verFolder = $m.Directory.Name                          # e.g. v1.0.0
  $relBase   = "../$($j.category_slug)/$($j.slug)/$verFolder"

  # enumerate generated files per group (for the HTML file browser)
  $groups = [ordered]@{}
  foreach ($pair in @(@('Documentation','source'), @('PowerShell Scripts','scripts'), @('Deliverables','deliverables'), @('Listing','listing'))) {
    $label = $pair[0]; $sub = $pair[1]
    $p = Join-Path $m.DirectoryName $sub
    if (Test-Path $p) {
      $files = Get-ChildItem $p -File | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ name = $_.Name; href = "$relBase/$sub/$($_.Name)"; kb = [math]::Round($_.Length/1KB,1) }
      }
      if ($files) { $groups[$label] = @($files) }
    }
  }
  # top-level files (README, meta)
  $top = Get-ChildItem $m.DirectoryName -File | Where-Object { $_.Name -in 'README.md','solution.meta.json' } |
         Sort-Object Name | ForEach-Object { [pscustomobject]@{ name = $_.Name; href = "$relBase/$($_.Name)"; kb = [math]::Round($_.Length/1KB,1) } }
  if ($top) { $groups['Overview'] = @($top) }

  $scriptCount = if ($groups['PowerShell Scripts']) { $groups['PowerShell Scripts'].Count } else { 0 }
  $delivCount  = if ($groups['Deliverables'])       { $groups['Deliverables'].Count }       else { 0 }
  $docCount    = if ($groups['Documentation'])      { $groups['Documentation'].Count }      else { 0 }

  # hero image thumbnail (deliverables/<SOL>-hero.png)
  $heroFile = Join-Path (Join-Path $m.DirectoryName 'deliverables') "$($j.sol_code)-hero.png"
  $heroHref = if (Test-Path $heroFile) { "$relBase/deliverables/$($j.sol_code)-hero.png" } else { $null }

  [pscustomobject]@{
    title         = $j.title
    slug          = $j.slug
    category      = $j.category
    category_slug = $j.category_slug
    sol_code      = $j.sol_code
    version       = $j.version
    status        = $j.status
    created       = $j.created
    updated       = $j.updated
    published_at  = $j.published_at
    commercial    = [double]($comm.price)
    nonprofit     = [double]($npo.price)
    skus          = ($j.products | ForEach-Object { $_.sku })
    deliverables  = $j.deliverables
    rel_path      = $m.DirectoryName.Replace("$repoRoot\", '')
    groups        = $groups
    script_count  = $scriptCount
    deliv_count   = $delivCount
    doc_count     = $docCount
    hero_href     = $heroHref
    product_count = @($j.products).Count
  }
}

$records = @($records | Sort-Object category, title)

# ============================ registry.json ============================
# -AsArray => always a JSON array (0 or 1 record); assign-then-write so an empty
# result still overwrites the file instead of being skipped.
$json = $records | ConvertTo-Json -Depth 8 -AsArray
Set-Content -Path (Join-Path $indexDir 'registry.json') -Value $json -Encoding UTF8

# ============================ shared metrics ============================
$total = $records.Count
$pub   = @($records | Where-Object { $_.status -eq 'published' }).Count
$gen   = @($records | Where-Object { $_.status -eq 'generated' }).Count
$catGroups = $records | Group-Object category | Sort-Object Name
$catCount  = @($catGroups).Count
$scriptTotal = ($records | Measure-Object script_count -Sum).Sum
$delivTotal  = ($records | Measure-Object deliv_count  -Sum).Sum
$docTotal    = ($records | Measure-Object doc_count    -Sum).Sum
# Distinct SKUs across all solutions = the actual number of buyable listings (auto-updates
# with the data). Solutions (offerings) is the $total card; this is the per-audience SKU count.
$skuTotal = @($records | ForEach-Object { $_.skus } | Where-Object { $_ } | Select-Object -Unique).Count
$catalogValue = ($records | Measure-Object commercial -Sum).Sum
if (-not $scriptTotal) { $scriptTotal = 0 }; if (-not $delivTotal) { $delivTotal = 0 }
if (-not $docTotal) { $docTotal = 0 }; if (-not $skuTotal) { $skuTotal = 0 }; if (-not $catalogValue) { $catalogValue = 0 }
$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm')

# ============================ INDEX.md ============================
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Phoenixtekk Workplace Marketplace — Solution Library Index')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> Auto-generated by `_index\rebuild-index.ps1` — do not edit by hand. Source of truth: each solution''s `solution.meta.json`. A visual version is in `INDEX.html`.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("**$total solution(s)** — $pub published, $gen generated (not yet live).")
[void]$sb.AppendLine('')
if ($total -eq 0) {
  [void]$sb.AppendLine('_No solutions yet. Run `/generate-solution "<topic>"` to create the first one._')
} else {
  foreach ($cat in ($records | Select-Object -ExpandProperty category -Unique | Sort-Object)) {
    [void]$sb.AppendLine("## $cat"); [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Solution | Ver | Status | Commercial | Non-Profit | SKUs | Updated | Folder |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|')
    foreach ($r in ($records | Where-Object { $_.category -eq $cat })) {
      $skus = ($r.skus -join '<br>'); $folder = '`' + $r.rel_path + '`'
      [void]$sb.AppendLine("| $($r.title) | $($r.version) | $($r.status) | $(Money $r.commercial) | $(Money $r.nonprofit) | $skus | $($r.updated) | $folder |")
    }
    [void]$sb.AppendLine('')
  }
}
$sb.ToString() | Set-Content -Path (Join-Path $indexDir 'INDEX.md') -Encoding UTF8

# ============================ INDEX.html ============================
$css = @'
:root{--navy:#1F3A5F;--accent:#2E86C1;--bg:#f4f6f9;--card:#fff;--ink:#1c2733;--muted:#6b7a8d;--line:#e3e8ef;--green:#1e8e5a;--amber:#c98a1b;}
*{box-sizing:border-box}body{margin:0;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:var(--bg);color:var(--ink)}
header{background:linear-gradient(135deg,var(--navy),#2c5687);color:#fff;padding:26px 34px}
header h1{margin:0;font-size:22px;letter-spacing:.5px}header .sub{opacity:.85;font-size:13px;margin-top:4px}
.wrap{max-width:1100px;margin:0 auto;padding:24px 34px 60px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin:-44px 0 26px}
.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 18px;box-shadow:0 2px 8px rgba(20,40,70,.06)}
.card .n{font-size:30px;font-weight:700;color:var(--navy);line-height:1;white-space:nowrap;overflow:hidden}
.card .l{font-size:12px;color:var(--muted);margin-top:6px;text-transform:uppercase;letter-spacing:.4px}
.panel{display:grid;grid-template-columns:240px 1fr;gap:20px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:20px;margin-bottom:26px}
@media(max-width:720px){.panel{grid-template-columns:1fr}}
.donut{width:160px;height:160px;border-radius:50%;margin:6px auto;display:flex;align-items:center;justify-content:center}
.donut .hole{width:108px;height:108px;background:var(--card);border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center}
.donut .hole b{font-size:26px;color:var(--navy)}.donut .hole span{font-size:11px;color:var(--muted)}
.legend{font-size:12px;color:var(--muted);text-align:center;margin-top:6px}
.legend i{display:inline-block;width:10px;height:10px;border-radius:2px;margin:0 4px 0 10px;vertical-align:middle}
.bars{display:flex;flex-direction:column;gap:10px;justify-content:center}
.bar{display:grid;grid-template-columns:150px 1fr 36px;align-items:center;gap:10px;font-size:13px}
.bar .track{background:#eef2f7;border-radius:6px;height:18px;overflow:hidden}
.bar .fill{height:100%;background:linear-gradient(90deg,var(--accent),var(--navy));border-radius:6px}
.bar .cnt{text-align:right;color:var(--muted);font-variant-numeric:tabular-nums}
h2.sec{font-size:15px;color:var(--navy);border-bottom:2px solid var(--line);padding-bottom:6px;margin:30px 0 14px}
details.sol{background:var(--card);border:1px solid var(--line);border-radius:10px;margin:10px 0;overflow:hidden}
details.sol[open]{box-shadow:0 3px 12px rgba(20,40,70,.08)}
summary{list-style:none;cursor:pointer;padding:14px 18px;display:flex;align-items:center;gap:12px;flex-wrap:wrap}
summary::-webkit-details-marker{display:none}
summary .caret{transition:transform .15s;color:var(--accent);font-size:13px}
details[open] summary .caret{transform:rotate(90deg)}
summary .title{font-weight:600;font-size:15px}
summary .meta{color:var(--muted);font-size:12px}
.thumb{width:56px;height:56px;border-radius:8px;object-fit:cover;border:1px solid var(--line);flex-shrink:0;background:#0c1f38}
.badge{font-size:11px;font-weight:600;padding:2px 9px;border-radius:20px;text-transform:uppercase;letter-spacing:.3px}
.badge.published{background:#e3f5ec;color:var(--green)}.badge.generated{background:#fdf3e0;color:var(--amber)}
.price{margin-left:auto;font-weight:700;color:var(--navy);font-size:14px}.price small{color:var(--muted);font-weight:500}
.body{padding:4px 18px 18px;border-top:1px solid var(--line)}
.grp{margin:14px 0 4px;font-size:12px;font-weight:700;color:var(--navy);text-transform:uppercase;letter-spacing:.4px}
.files{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:8px}
.file{display:flex;align-items:center;gap:9px;padding:9px 11px;border:1px solid var(--line);border-radius:8px;text-decoration:none;color:var(--ink);font-size:13px;background:#fbfcfe;transition:.12s}
.file:hover{border-color:var(--accent);background:#f0f7fd}
.file .ico{width:22px;height:22px;border-radius:5px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;color:#fff;flex-shrink:0}
.file .nm{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.file .kb{margin-left:auto;color:var(--muted);font-size:11px}
.ico.md{background:#557}.ico.pdf{background:#c0392b}.ico.docx{background:#2b579a}.ico.zip{background:#b7791f}.ico.ps1{background:#012456}.ico.json{background:#1e8e5a}.ico.other{background:#888}
.empty{padding:40px;text-align:center;color:var(--muted)}
.search{position:sticky;top:0;z-index:20;background:var(--bg);padding:12px 0 10px;margin:0 0 4px}
.search input{width:100%;padding:12px 16px;font-size:15px;border:1px solid var(--line);border-radius:10px;background:var(--card);color:var(--ink);box-shadow:0 2px 8px rgba(20,40,70,.06)}
.search input:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 3px rgba(46,134,193,.15)}
.search .cnt{display:block;font-size:12px;color:var(--muted);margin-top:6px;min-height:14px}
.noresults{display:none;padding:40px;text-align:center;color:var(--muted)}
footer{color:var(--muted);font-size:11px;text-align:center;padding:20px}
'@

function FileIcon([string]$name){
  switch -regex ($name){ '\.pdf$'{'pdf';break} '\.docx?$'{'docx';break} '\.zip$'{'zip';break} '\.ps1$'{'ps1';break} '\.json$'{'json';break} '\.md$'{'md';break} default{'other'} }
}

$h = [System.Text.StringBuilder]::new()
[void]$h.AppendLine('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$h.AppendLine('<title>Phoenixtekk Solution Library</title><style>'+$css+'</style></head><body>')
[void]$h.AppendLine('<header><h1>Phoenixtekk Workplace Marketplace — Solution Library</h1><div class="sub">Auto-generated dashboard · '+$stamp+' · do not edit by hand</div></header>')
[void]$h.AppendLine('<div class="wrap">')

# metric cards
[void]$h.AppendLine('<div class="cards">')
$cards = @(
  @($total,'Solutions (products)'), @($pub,'Published'), @($gen,'Generated'), @($catCount,'Categories'),
  @($skuTotal,'SKUs (Comm + NPO)'), @($scriptTotal,'PowerShell Scripts'), @($delivTotal,'Deliverable Files'), @((Money $catalogValue),'Catalog Value (Comm.)')
)
foreach($c in $cards){
  $val = [string]$c[0]
  # auto-fit the number: card min width 150px - 18px padding each side => ~114px usable, keeping
  # the required >=15px clear space from the border. Shrink only when the value is wide.
  $fs = [int][math]::Floor(114 / ([math]::Max(1, $val.Length) * 0.60))
  if ($fs -gt 30) { $fs = 30 }; if ($fs -lt 15) { $fs = 15 }
  [void]$h.AppendLine('<div class="card"><div class="n" style="font-size:'+$fs+'px">'+(Enc $val)+'</div><div class="l">'+(Enc $c[1])+'</div></div>')
}
[void]$h.AppendLine('</div>')

if($total -eq 0){
  [void]$h.AppendLine('<div class="empty">No solutions yet. Run <code>/generate-solution "&lt;topic&gt;"</code> to create the first one.</div>')
} else {
  # status donut + per-category bars
  $pubPct = if($total){[math]::Round($pub/$total*100)}else{0}
  [void]$h.AppendLine('<div class="panel">')
  [void]$h.AppendLine('<div><div class="donut" style="background:conic-gradient(var(--green) 0 '+$pubPct+'%, #e6ebf1 '+$pubPct+'% 100%)"><div class="hole"><b>'+$pubPct+'%</b><span>published</span></div></div>')
  [void]$h.AppendLine('<div class="legend"><i style="background:var(--green)"></i>Published '+$pub+'<i style="background:#e6ebf1"></i>Generated '+$gen+'</div></div>')
  [void]$h.AppendLine('<div class="bars">')
  $maxCat = ($catGroups | Measure-Object Count -Maximum).Maximum; if(-not $maxCat){$maxCat=1}
  foreach($cg in $catGroups){
    $w=[math]::Round($cg.Count/$maxCat*100)
    [void]$h.AppendLine('<div class="bar"><span>'+(Enc $cg.Name)+'</span><div class="track"><div class="fill" style="width:'+$w+'%"></div></div><span class="cnt">'+$cg.Count+'</span></div>')
  }
  [void]$h.AppendLine('</div></div>')

  # search box (filters the solution list below by title / category / slug / SKU / file names)
  [void]$h.AppendLine('<div class="search"><input id="q" type="search" placeholder="Search solutions, categories, or files&#8230;" autocomplete="off" spellcheck="false" aria-label="Search solutions"><span class="cnt" id="qcount"></span></div>')
  [void]$h.AppendLine('<div class="noresults" id="noresults">No solutions match your search.</div>')

  # solution list grouped by category
  foreach($cat in ($records | Select-Object -ExpandProperty category -Unique | Sort-Object)){
    [void]$h.AppendLine('<section class="catsec">')
    [void]$h.AppendLine('<h2 class="sec">'+(Enc $cat)+'</h2>')
    foreach($r in ($records | Where-Object { $_.category -eq $cat })){
      $searchParts = @($r.title,$r.category,$r.slug,$r.sol_code) + @($r.skus)
      foreach($gN in $r.groups.Keys){ foreach($gf in $r.groups[$gN]){ $searchParts += $gf.name } }
      $searchAttr = Enc ((($searchParts | Where-Object { $_ }) -join ' ').ToLower())
      [void]$h.AppendLine('<details class="sol" data-search="'+$searchAttr+'">')
      $thumb = if ($r.hero_href) { '<img class="thumb" src="'+$r.hero_href+'" alt="hero">' } else { '' }
      [void]$h.AppendLine('<summary><span class="caret">&#9654;</span>'+$thumb+'<span class="title">'+(Enc $r.title)+'</span>'+
        '<span class="badge '+$r.status+'">'+(Enc $r.status)+'</span>'+
        '<span class="meta">'+(Enc $r.version)+' · '+$r.doc_count+' docs · '+$r.script_count+' scripts · '+$r.deliv_count+' files</span>'+
        '<span class="price">'+(Money $r.commercial)+' <small>/ '+(Money $r.nonprofit)+' NPO</small></span></summary>')
      [void]$h.AppendLine('<div class="body">')
      foreach($grpName in $r.groups.Keys){
        [void]$h.AppendLine('<div class="grp">'+(Enc $grpName)+'</div><div class="files">')
        foreach($f in $r.groups[$grpName]){
          $ic = FileIcon $f.name
          [void]$h.AppendLine('<a class="file" href="'+$f.href+'" target="_blank" rel="noopener"><span class="ico '+$ic+'">'+$ic.ToUpper().Substring(0,[math]::Min(3,$ic.Length))+'</span><span class="nm">'+(Enc $f.name)+'</span><span class="kb">'+$f.kb+' KB</span></a>')
        }
        [void]$h.AppendLine('</div>')
      }
      [void]$h.AppendLine('</div></details>')
    }
    [void]$h.AppendLine('</section>')
  }
}
$js = @'
<script>
(function(){
  var q=document.getElementById("q"); if(!q) return;
  var count=document.getElementById("qcount"), nores=document.getElementById("noresults");
  var sols=[].slice.call(document.querySelectorAll("details.sol"));
  var secs=[].slice.call(document.querySelectorAll("section.catsec"));
  function apply(){
    var terms=(q.value||"").trim().toLowerCase().split(/\s+/).filter(Boolean);
    var vis=0;
    sols.forEach(function(d){
      var hay=d.getAttribute("data-search")||"";
      var show=terms.every(function(tm){return hay.indexOf(tm)>=0;});
      d.style.display=show?"":"none";
      if(show) vis++;
    });
    secs.forEach(function(s){
      var any=[].slice.call(s.querySelectorAll("details.sol")).some(function(d){return d.style.display!=="none";});
      s.style.display=any?"":"none";
    });
    if(nores) nores.style.display=(vis===0 && terms.length)?"block":"none";
    count.textContent=terms.length?(vis+" match"+(vis===1?"":"es")):"";
  }
  q.addEventListener("input",apply);
  q.addEventListener("keydown",function(e){ if(e.key==="Escape"){ q.value=""; apply(); } });
})();
</script>
'@
[void]$h.AppendLine($js)
[void]$h.AppendLine('</div><footer>Phoenixtekk · generated from solution.meta.json by rebuild-index.ps1</footer></body></html>')
$h.ToString() | Set-Content -Path (Join-Path $indexDir 'INDEX.html') -Encoding UTF8

Write-Output "Index rebuilt: $total solution(s). Wrote registry.json + INDEX.md + INDEX.html."
