# =============================================================================
# Reflect OS SEO — Apply Script v2
# Run from: E:\reflect-os-website
# Requires: seo-patches.json in the same folder
# =============================================================================

$root = $PSScriptRoot
Set-Location $root

$changed = [System.Collections.Generic.List[string]]::new()
$enc = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Reflect OS SEO — applying all changes" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# PART 1: Title / meta rewrites from JSON patches file
# ------------------------------------------------------------------
Write-Host "PART 1: Title and meta rewrites" -ForegroundColor White
Write-Host ""

$patchFile = Join-Path $root "seo-patches.json"
if (-not (Test-Path $patchFile)) {
    Write-Host "ERROR: seo-patches.json not found in $root" -ForegroundColor Red
    Write-Host "Make sure both files are in E:\reflect-os-website" -ForegroundColor Yellow
    exit 1
}

$patches = Get-Content $patchFile -Raw | ConvertFrom-Json

foreach ($entry in $patches) {
    $filePath = Join-Path $root $entry.file
    if (-not (Test-Path $filePath)) {
        Write-Host "  SKIP (not found): $($entry.file)" -ForegroundColor Yellow
        continue
    }
    $content = [System.IO.File]::ReadAllText($filePath, $enc)
    $fileChanged = $false
    foreach ($patch in $entry.patches) {
        if ($content.Contains($patch.old)) {
            $content = $content.Replace($patch.old, $patch.new)
            $fileChanged = $true
            Write-Host "  OK  $($entry.file) -- $($patch.desc)" -ForegroundColor Green
        } else {
            Write-Host "  --  $($entry.file) -- $($patch.desc) (already updated or not found)" -ForegroundColor Gray
        }
    }
    if ($fileChanged) {
        [System.IO.File]::WriteAllText($filePath, $content, $enc)
        if (-not $changed.Contains($entry.file)) { $changed.Add($entry.file) }
    }
}


# ------------------------------------------------------------------
# PART 2: HowTo schema — decision-making-framework
# ------------------------------------------------------------------
Write-Host ""
Write-Host "PART 2: HowTo schema (decision-making-framework)" -ForegroundColor White

$fwFile = Join-Path $root "blog\decision-making-framework.html"
if (Test-Path $fwFile) {
    $fw = [System.IO.File]::ReadAllText($fwFile, $enc)
    if (-not $fw.Contains('"@type": "HowTo"')) {
        $howTo = '
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"HowTo","name":"How to Choose and Apply a Decision-Making Framework","description":"A step-by-step guide to selecting the right decision-making framework for any situation.","totalTime":"PT30M","step":[{"@type":"HowToStep","position":1,"name":"Classify the decision","text":"Determine whether this is reversible (two-way door) or irreversible (one-way door). Irreversible decisions need significantly more rigorous process."},{"@type":"HowToStep","position":2,"name":"Assign roles with RAPID","text":"For group decisions, explicitly assign Recommend, Agree, Perform, Input, and Decide roles before discussion begins."},{"@type":"HowToStep","position":3,"name":"Apply second-order thinking","text":"For strategic decisions, ask and then what at least two steps beyond the immediate consequence before committing."},{"@type":"HowToStep","position":4,"name":"Run a pre-mortem","text":"Assume the decision has already failed and spend 10-15 minutes explaining what went wrong. Surfaces risks standard discussion misses."},{"@type":"HowToStep","position":5,"name":"Log with a confidence score","text":"Record the decision, rationale, and a 0-100% confidence score before the outcome is known. Set a review date."}]}
  </script>'
        $fw = $fw.Replace("</head>", "$howTo`n</head>")
        [System.IO.File]::WriteAllText($fwFile, $fw, $enc)
        if (-not $changed.Contains("blog\decision-making-framework.html")) { $changed.Add("blog\decision-making-framework.html") }
        Write-Host "  OK  HowTo schema added" -ForegroundColor Green
    } else {
        Write-Host "  --  HowTo schema already present" -ForegroundColor Gray
    }
}


# ------------------------------------------------------------------
# PART 3: BreadcrumbList schema — all blog posts
# ------------------------------------------------------------------
Write-Host ""
Write-Host "PART 3: BreadcrumbList schema (all blog posts)" -ForegroundColor White

$blogDir = Join-Path $root "blog"
$blogFiles = Get-ChildItem $blogDir -Filter "*.html" -ErrorAction SilentlyContinue
$bcCount = 0
foreach ($f in $blogFiles) {
    $fc = [System.IO.File]::ReadAllText($f.FullName, $enc)
    if ($fc.Contains('"BreadcrumbList"')) { continue }

    $canonMatch = [regex]::Match($fc, 'rel="canonical"\s+href="([^"]+)"')
    if (-not $canonMatch.Success) { continue }

    $url = $canonMatch.Groups[1].Value
    $titleMatch = [regex]::Match($fc, '<title>([^<]+)</title>')
    $pageTitle = if ($titleMatch.Success) {
        $titleMatch.Groups[1].Value.Split('|')[0].Trim() -replace '"', "'"
    } else { $f.BaseName }

    $bc = '
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://www.reflect-os.com/"},{"@type":"ListItem","position":2,"name":"Blog","item":"https://www.reflect-os.com/blog"},{"@type":"ListItem","position":3,"name":"' + $pageTitle + '","item":"' + $url + '"}]}
  </script>'
    $fc = $fc.Replace("</head>", "$bc`n</head>")
    [System.IO.File]::WriteAllText($f.FullName, $fc, $enc)
    $rel = "blog\" + $f.Name
    if (-not $changed.Contains($rel)) { $changed.Add($rel) }
    $bcCount++
}
Write-Host "  OK  BreadcrumbList added to $bcCount blog posts" -ForegroundColor Green


# ------------------------------------------------------------------
# PART 4: Sitemap — add missing pages, refresh lastmod
# ------------------------------------------------------------------
Write-Host ""
Write-Host "PART 4: Sitemap updates" -ForegroundColor White

$sitemapFile = Join-Path $root "sitemap.xml"
if (Test-Path $sitemapFile) {
    $sm = [System.IO.File]::ReadAllText($sitemapFile, $enc)
    $today = Get-Date -Format "yyyy-MM-dd"

    $sm = [regex]::Replace($sm, '<lastmod>\d{4}-\d{2}-\d{2}</lastmod>', "<lastmod>$today</lastmod>")

    $newPages = @(
        @{ url="https://www.reflect-os.com/alternatives";                  pri="0.85" },
        @{ url="https://www.reflect-os.com/what-is-decision-intelligence"; pri="0.90" },
        @{ url="https://www.reflect-os.com/blog/reflect-os-vs-notion";     pri="0.80" },
        @{ url="https://www.reflect-os.com/blog/reflect-os-vs-obsidian";   pri="0.80" }
    )
    $additions = ""
    foreach ($p in $newPages) {
        if (-not $sm.Contains($p.url)) {
            $additions += "  <url><loc>$($p.url)</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>$($p.pri)</priority></url>`n"
            Write-Host "  OK  sitemap -- added $($p.url)" -ForegroundColor Green
        } else {
            Write-Host "  --  sitemap -- already has $($p.url)" -ForegroundColor Gray
        }
    }
    if ($additions) { $sm = $sm.Replace("</urlset>", "$additions</urlset>") }

    [System.IO.File]::WriteAllText($sitemapFile, $sm, $enc)
    if (-not $changed.Contains("sitemap.xml")) { $changed.Add("sitemap.xml") }
    Write-Host "  OK  sitemap lastmod refreshed to $today" -ForegroundColor Green
}


# ------------------------------------------------------------------
# PART 5: robots.txt — block /marketing/
# ------------------------------------------------------------------
Write-Host ""
Write-Host "PART 5: robots.txt" -ForegroundColor White

$robotsFile = Join-Path $root "robots.txt"
if (Test-Path $robotsFile) {
    $rb = [System.IO.File]::ReadAllText($robotsFile, $enc)
    if (-not $rb.Contains("/marketing/")) {
        $rb = $rb.TrimEnd() + "`nDisallow: /marketing/`n"
        [System.IO.File]::WriteAllText($robotsFile, $rb, $enc)
        if (-not $changed.Contains("robots.txt")) { $changed.Add("robots.txt") }
        Write-Host "  OK  /marketing/ disallowed" -ForegroundColor Green
    } else {
        Write-Host "  --  /marketing/ already disallowed" -ForegroundColor Gray
    }
}


# ------------------------------------------------------------------
# SUMMARY + GIT
# ------------------------------------------------------------------
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Files modified: $($changed.Count)" -ForegroundColor White
foreach ($f in $changed) { Write-Host "  $f" -ForegroundColor Gray }
Write-Host ""

Write-Host "Committing to git..." -ForegroundColor White
git add -A
git commit -m "seo: title/meta rewrites, schema, sitemap, robots"

$push = git push 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Pushed successfully." -ForegroundColor Green
} else {
    Write-Host "Committed locally. Run 'git push' when ready." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done. Check Google Search Console and request re-index for changed URLs." -ForegroundColor Green
