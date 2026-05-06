# =============================================================
# Reflect OS — SEO Context Extractor
# Run from: E:\reflect-os-website
# Output:   E:\reflect-os-seo-context.md
# Usage:    cd E:\reflect-os-website; .\extract-reflect-os.ps1
# =============================================================

$root   = $PSScriptRoot
$output = Join-Path $root "reflect-os-seo-context.md"
$lines  = [System.Collections.Generic.List[string]]::new()

function Add ($text) { $lines.Add($text) }
function Sep ($label) {
    Add ""
    Add "# ================================================================"
    Add "# $label"
    Add "# ================================================================"
    Add ""
}

# ------------------------------------------------------------------
# 0. Header
# ------------------------------------------------------------------
Add "# Reflect OS — Full Site SEO Context Extract"
Add "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')_"
Add "_Root: $root_"
Add ""

# ------------------------------------------------------------------
# 1. Repo / git info
# ------------------------------------------------------------------
Sep "GIT INFO"
try {
    $remote  = git -C $root remote get-url origin 2>&1
    $branch  = git -C $root rev-parse --abbrev-ref HEAD 2>&1
    $lastMsg = git -C $root log -1 --pretty="%h %s" 2>&1
    Add "Remote : $remote"
    Add "Branch : $branch"
    Add "Last commit: $lastMsg"
} catch {
    Add "Git not available or not a repo at this path."
}

# ------------------------------------------------------------------
# 2. Directory tree (top 3 levels, skip node_modules / .git / dist)
# ------------------------------------------------------------------
Sep "DIRECTORY TREE"
$skip = @('.git','node_modules','dist','.next','.cache','vendor','__pycache__')
function Tree($dir, $indent = "") {
    $children = Get-ChildItem $dir -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $skip }
    foreach ($c in $children) {
        Add "$indent$($c.Name)$(if($c.PSIsContainer){'/'})"
        if ($c.PSIsContainer -and $indent.Length -lt 6) {
            Tree $c.FullName "$indent  "
        }
    }
}
Tree $root

# ------------------------------------------------------------------
# 3. Package / config files (understand framework + build)
# ------------------------------------------------------------------
Sep "PACKAGE / CONFIG FILES"
$configFiles = @(
    "package.json","package-lock.json","astro.config.*","next.config.*",
    "vite.config.*","nuxt.config.*","gatsby-config.*","eleventy.config.*",
    "config.yaml","config.yml","config.toml","hugo.toml","hugo.yaml",
    "tailwind.config.*","postcss.config.*",".env.example"
)
foreach ($pat in $configFiles) {
    $found = Get-ChildItem $root -Filter $pat -Recurse -Depth 2 |
             Where-Object { $_.DirectoryName -notmatch '(node_modules|\.git|dist)' }
    foreach ($f in $found) {
        Add ""
        Add "## $($f.Name)"
        Add '```'
        Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
        Add '```'
    }
}

# ------------------------------------------------------------------
# 4. HTML pages — full content
#    Targets: *.html at root, and pages/ src/ content/ public/ layouts/
# ------------------------------------------------------------------
Sep "HTML PAGES (full content)"
$htmlDirs = @($root,
    (Join-Path $root "src"),
    (Join-Path $root "pages"),
    (Join-Path $root "public"),
    (Join-Path $root "content"),
    (Join-Path $root "layouts"),
    (Join-Path $root "templates")
)
$htmlSeen = @{}
foreach ($dir in $htmlDirs) {
    if (-not (Test-Path $dir)) { continue }
    $files = Get-ChildItem $dir -Filter "*.html" -Recurse -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist|_site)' } |
             Sort-Object FullName
    foreach ($f in $files) {
        if ($htmlSeen[$f.FullName]) { continue }
        $htmlSeen[$f.FullName] = $true
        $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
        Add ""
        Add "## FILE: $rel"
        Add '```html'
        Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
        Add '```'
    }
}

# ------------------------------------------------------------------
# 5. Markdown / MDX content (blog posts, pages)
# ------------------------------------------------------------------
Sep "MARKDOWN CONTENT (blog posts, pages)"
$mdExtensions = @("*.md","*.mdx","*.markdown")
$mdDirs = @(
    (Join-Path $root "src"),
    (Join-Path $root "content"),
    (Join-Path $root "pages"),
    (Join-Path $root "blog"),
    (Join-Path $root "posts"),
    $root
)
$mdSeen = @{}
foreach ($dir in $mdDirs) {
    if (-not (Test-Path $dir)) { continue }
    foreach ($ext in $mdExtensions) {
        $files = Get-ChildItem $dir -Filter $ext -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist|_site)' -and $_.Name -ne 'README.md' } |
                 Sort-Object FullName
        foreach ($f in $files) {
            if ($mdSeen[$f.FullName]) { continue }
            $mdSeen[$f.FullName] = $true
            $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
            Add ""
            Add "## FILE: $rel"
            Add '```markdown'
            Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
            Add '```'
        }
    }
}

# ------------------------------------------------------------------
# 6. Layout / template files (where <head> lives in SSGs)
# ------------------------------------------------------------------
Sep "LAYOUT AND TEMPLATE FILES"
$layoutExts = @("*.astro","*.njk","*.liquid","*.hbs","*.ejs","*.pug","*.svelte","*.vue","*.jsx","*.tsx")
$layoutDirs = @(
    (Join-Path $root "src\layouts"),
    (Join-Path $root "src\components"),
    (Join-Path $root "layouts"),
    (Join-Path $root "templates"),
    (Join-Path $root "_includes"),
    (Join-Path $root "components"),
    (Join-Path $root "src\pages")
)
$layoutSeen = @{}
foreach ($dir in $layoutDirs) {
    if (-not (Test-Path $dir)) { continue }
    foreach ($ext in $layoutExts) {
        $files = Get-ChildItem $dir -Filter $ext -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist)' } |
                 Sort-Object FullName
        foreach ($f in $files) {
            if ($layoutSeen[$f.FullName]) { continue }
            $layoutSeen[$f.FullName] = $true
            $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
            Add ""
            Add "## FILE: $rel"
            Add "``````"
            Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
            Add "``````"
        }
    }
}

# ------------------------------------------------------------------
# 7. Any existing schema / JSON-LD files
# ------------------------------------------------------------------
Sep "EXISTING SCHEMA / JSON-LD"
$schemaFiles = Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Extension -in @('.json','.jsonld') -and
        $_.FullName -notmatch '(node_modules|\.git|dist|package)'
    }
foreach ($f in $schemaFiles) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
    Add ""
    Add "## FILE: $rel"
    Add '```json'
    Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
    Add '```'
}

# ------------------------------------------------------------------
# 8. Sitemap / robots
# ------------------------------------------------------------------
Sep "SITEMAP AND ROBOTS"
$seoFiles = @("sitemap.xml","sitemap_index.xml","robots.txt")
foreach ($name in $seoFiles) {
    $candidates = @(
        (Join-Path $root $name),
        (Join-Path $root "public\$name"),
        (Join-Path $root "static\$name"),
        (Join-Path $root "dist\$name")
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $rel = $path.Substring($root.Length).TrimStart('\','/')
            Add ""
            Add "## FILE: $rel"
            Add '```'
            Add (Get-Content $path -Raw -ErrorAction SilentlyContinue)
            Add '```'
            break
        }
    }
}

# ------------------------------------------------------------------
# 9. CSS (top-level / global only — skip generated/vendor)
# ------------------------------------------------------------------
Sep "GLOBAL CSS FILES"
$cssCandidates = Get-ChildItem $root -Filter "*.css" -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '(node_modules|\.git|dist|vendor|_site)' -and
        $_.Name -notmatch '(\.min\.|chunk)'
    } |
    Sort-Object { $_.FullName.Length }  |  # shortest path = most global
    Select-Object -First 6
foreach ($f in $cssCandidates) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
    Add ""
    Add "## FILE: $rel"
    Add '```css'
    Add (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
    Add '```'
}

# ------------------------------------------------------------------
# 10. Quick grep — existing title/meta/OG patterns across all files
# ------------------------------------------------------------------
Sep "EXISTING TITLE AND META PATTERNS (grep summary)"
Add "Searching all HTML/MD/template files for title, description, og: tags..."
Add ""
$grepExts = @("*.html","*.md","*.mdx","*.astro","*.njk","*.liquid","*.hbs","*.jsx","*.tsx","*.svelte","*.vue")
$allFiles = @()
foreach ($ext in $grepExts) {
    $allFiles += Get-ChildItem $root -Filter $ext -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist|_site)' }
}

$metaPattern = '(<title>|<meta\s[^>]*(name|property)="(description|og:|twitter:)[^"]*"[^>]*>|title:|description:|seoTitle:|metaDescription:)'
foreach ($f in $allFiles) {
    $matches = Select-String -Path $f.FullName -Pattern $metaPattern -ErrorAction SilentlyContinue
    if ($matches) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
        Add "### $rel"
        foreach ($m in $matches) {
            Add "  L$($m.LineNumber): $($m.Line.Trim())"
        }
        Add ""
    }
}

# ------------------------------------------------------------------
# 11. Internal link audit — anchor text patterns
# ------------------------------------------------------------------
Sep "INTERNAL LINK PATTERNS (grep summary)"
Add "Searching for internal <a href> links to map current link graph..."
Add ""
$linkPattern = '<a\s[^>]*href="(/[^"]*)"[^>]*>([^<]{1,80})</a>'
foreach ($f in $allFiles) {
    $matches = Select-String -Path $f.FullName -Pattern $linkPattern -ErrorAction SilentlyContinue
    if ($matches) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
        Add "### $rel"
        foreach ($m in $matches) {
            Add "  $($m.Line.Trim())"
        }
        Add ""
    }
}

# ------------------------------------------------------------------
# 12. Output summary
# ------------------------------------------------------------------
Sep "EXTRACT SUMMARY"
Add "HTML files    : $($htmlSeen.Count)"
Add "Markdown files: $($mdSeen.Count)"
Add "Layout files  : $($layoutSeen.Count)"

# ------------------------------------------------------------------
# Write output
# ------------------------------------------------------------------
$content = $lines -join "`n"
[System.IO.File]::WriteAllText($output, $content, [System.Text.Encoding]::UTF8)

$sizeKB = [math]::Round((Get-Item $output).Length / 1KB, 1)
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Output : $output" -ForegroundColor Cyan
Write-Host "Size   : $sizeKB KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: upload reflect-os-seo-context.md to Claude" -ForegroundColor Yellow
