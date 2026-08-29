# Builds book.html from template.html + data\recipes\*.json, with validation & kosher audit.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataDir = Join-Path $root "data\recipes"
$template = Join-Path $root "template.html"
$out = Join-Path $root "book.html"

$catOrder = @("dairy-vegetarian-mains","meat-mains","legumes-grains","snacks","baking-savory","baking-sweet","desserts-dairy","desserts-pareve")

$all = @()
$problems = @()
$warnings = @()

$files = Get-ChildItem $dataDir -Filter *.json | Sort-Object Name
foreach ($f in $files) {
    try {
        $arr = Get-Content -Raw -Encoding UTF8 $f.FullName | ConvertFrom-Json
    } catch {
        $problems += "PARSE FAIL: $($f.Name) - $($_.Exception.Message)"
        continue
    }
    foreach ($r in $arr) { $all += $r }
    Write-Output ("{0}: {1} recipes" -f $f.Name, @($arr).Count)
}

# --- validation ---
$ids = @{}
$nutriKeys = @("calories","fatG","satFatG","proteinG","carbsG","fiberG","netCarbsG","sugarG","sodiumMg")
$dairyWords = "butter|cream|milk|cheese|whey|yogurt|yoghurt|mascarpone|labneh|labaneh|ricotta|mozzarella|parmesan|kashkaval|cottage|halloumi|feta|ghee"
$dairyOk = "coconut|almond|peanut|nut |nut-|cashew|soy|oat |cocoa butter|nondairy|non-dairy|dairy-free|pareve"

foreach ($r in $all) {
    $tag = "$($r.category)/$($r.id)"
    if (-not $r.id) { $problems += "missing id: $($r.name)"; continue }
    if ($ids.ContainsKey($r.id)) { $problems += "duplicate id: $($r.id)" } else { $ids[$r.id] = 1 }
    if ($catOrder -notcontains $r.category) { $problems += "${tag}: bad category" }
    if (@("dairy","pareve","meat") -notcontains $r.kosherType) { $problems += "${tag}: bad kosherType '$($r.kosherType)'" }
    if ($r.kosherType -eq "meat" -and $r.category -ne "meat-mains") { $problems += "${tag}: meat recipe outside meat-mains" }
    if ($r.category -eq "meat-mains" -and $r.kosherType -ne "meat") { $problems += "${tag}: meat-mains recipe not labeled meat" }
    if (@("keto","lowcarb") -notcontains $r.dietTags) { $problems += "${tag}: bad dietTags '$($r.dietTags)'" }
    if (-not $r.nutrition) { $problems += "${tag}: missing nutrition" }
    else {
        foreach ($k in $nutriKeys) {
            if ($null -eq $r.nutrition.$k) { $problems += "${tag}: nutrition missing $k" }
        }
        $nc = $r.nutrition.netCarbsG
        if ($nc -gt 20) { $problems += "${tag}: net carbs $nc > 20" }
        if ($r.dietTags -eq "keto" -and $nc -gt 10) { $problems += "${tag}: tagged keto but $nc g net" }
        if ($r.dietTags -eq "lowcarb" -and $nc -le 10) { $warnings += "${tag}: tagged lowcarb but only $nc g net (could be keto)" }
    }
    if (-not $r.ingredients -or @($r.ingredients).Count -lt 2) { $problems += "${tag}: too few ingredients" }
    if (-not $r.instructions -or @($r.instructions).Count -lt 2) { $problems += "${tag}: too few instructions" }
    if (-not $r.sources -or @($r.sources).Count -lt 1) { $warnings += "${tag}: no sources" }
    if (-not $r.servings -or $r.servings -lt 1) { $problems += "${tag}: bad servings" }

    # kosher audit: pareve and MEAT recipes must not contain dairy-ish ingredients
    if ($r.kosherType -eq "pareve" -or $r.kosherType -eq "meat") {
        foreach ($ing in $r.ingredients) {
            $it = "$($ing.item)".ToLower()
            if ($it -match $dairyWords -and $it -notmatch $dairyOk) {
                $warnings += "${tag}: $($r.kosherType.ToUpper()) but ingredient looks dairy: '$($ing.item)'"
            }
        }
    }
    # gelatin check
    foreach ($ing in $r.ingredients) {
        if ("$($ing.item)" -match "(?i)gelatin" -and "$($ing.item) $($ing.israelNote)" -notmatch "(?i)kosher") {
            $warnings += "${tag}: gelatin without kosher note"
        }
    }
}

Write-Output ("TOTAL: {0} recipes" -f $all.Count)
$byCat = $all | Group-Object category
foreach ($g in $byCat) { Write-Output ("  {0}: {1}" -f $g.Name, $g.Count) }

if ($problems.Count) {
    Write-Output "`n=== PROBLEMS ==="
    $problems | ForEach-Object { Write-Output $_ }
}
if ($warnings.Count) {
    Write-Output "`n=== WARNINGS ==="
    $warnings | ForEach-Object { Write-Output $_ }
}

if ($problems.Count -and -not $env:KLK_FORCE) {
    Write-Output "`nBuild aborted (set KLK_FORCE=1 to override)."
    exit 1
}

# --- order recipes by category, then by net carbs ---
$ordered = @()
foreach ($c in $catOrder) {
    $ordered += @($all | Where-Object { $_.category -eq $c } | Sort-Object { $_.nutrition.netCarbsG })
}

$json = ConvertTo-Json -InputObject $ordered -Depth 10 -Compress

$tpl = Get-Content -Raw -Encoding UTF8 $template
if ($tpl -notmatch [regex]::Escape("/*__DATA__*/[]")) { Write-Output "template marker missing!"; exit 1 }
$html = $tpl.Replace("/*__DATA__*/[]", $json)

# inject Supabase config (public anon key) if configured
$supaFile = Join-Path $root "data\supabase-config.json"
if (Test-Path $supaFile) {
    $sjson = (Get-Content -Raw -Encoding UTF8 $supaFile).Trim()
    $html = $html.Replace("/*__SUPA__*/null", $sjson)
    Write-Output "Injected Supabase config"
}

# bake latest community data (ratings/family recipes synced from the artifact) into the static build
$communityFile = Join-Path $root "data\community.json"
if (Test-Path $communityFile) {
    $cjson = (Get-Content -Raw -Encoding UTF8 $communityFile).Trim()
    $html = $html.Replace('id="communityData">{"ratings":{},"submissions":[]}</script>', 'id="communityData">' + $cjson + '</script>')
    Write-Output "Baked community data ($($cjson.Length) chars)"
}
[System.IO.File]::WriteAllText($out, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("`nWrote {0} ({1:n0} KB)" -f $out, ((Get-Item $out).Length/1KB))
