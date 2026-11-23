param (
    [switch]$Run
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$versionFile = Join-Path (Get-Location) "VERSION"
$appVersion = if (Test-Path $versionFile) { (Get-Content -Path $versionFile -Raw -Encoding UTF8).Trim() } else { "1.0" }
$script = (Get-Content -Path scripts\start.ps1 -Encoding UTF8) -replace '#{replaceme}', $appVersion
$isLocalCompile = -not [string]::Equals($env:GITHUB_ACTIONS, "true", [StringComparison]::OrdinalIgnoreCase)
$script = $script -replace '#{islocalcompile}', $isLocalCompile.ToString().ToLowerInvariant()

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Get-Content -Path $_.FullName -Raw -Encoding UTF8
}

Get-ChildItem config -File -Filter *.json | ForEach-Object {
    $obj = Get-Content -Path $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    if ($_.Name -eq "applications.json") {
        $fixed = [ordered]@{}
        foreach ($p in $obj.PSObject.Properties) {
            $fixed["WPFInstall$($p.Name)"] = $p.Value
        }
        $obj = [pscustomobject]$fixed
    }

    $json = $obj | ConvertTo-Json -Depth 10

    $sync.configs[$_.BaseName] = $obj
    $script += "`$sync.configs.$($_.BaseName) = @'`r`n$json`r`n'@ | ConvertFrom-Json"
}

# Icons are one PNG per app in config\icons\<key>.png, named after the key in applications.json.
# They ship as a single key -> base64 map, which the Install tab reads from $sync.configs.icons.
$icons = [ordered]@{}
Get-ChildItem config\icons -File -Filter *.png | ForEach-Object {
    $icons[$_.BaseName] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
}
$iconsObject = [pscustomobject]$icons
$sync.configs["icons"] = $iconsObject
$script += "`$sync.configs.icons = @'`r`n$($iconsObject | ConvertTo-Json)`r`n'@ | ConvertFrom-Json"

# Embed Turkish & English locale packs for automatic system-language detection and live switching
$localesScript = "`$sync.configs.locales = @{}`r`n"
Get-ChildItem config\locales -File -Filter *.json | ForEach-Object {
    $locRaw = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    $localesScript += "`$sync.configs.locales.$($_.BaseName) = @'`r`n$locRaw`r`n'@ | ConvertFrom-Json`r`n"
}
$script += $localesScript

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw -Encoding UTF8
$script += "`$inputXML = @'`r`n$xaml`r`n'@"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw -Encoding UTF8
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Get-Content -Path scripts\main.ps1 -Raw -Encoding UTF8

# Write UTF-8 without BOM so PowerShell 5.1 'irm ... | iex' works cleanly with Turkish characters.
# (The standalone EXE launcher prepends a UTF-8 BOM when extracting the temp file for -File execution.)
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "winutil.ps1"), ($script -join "`r`n"), [System.Text.UTF8Encoding]::new($false))

if ($Run) {
    .\Winutil.ps1
}
