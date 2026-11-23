param(
    [string]$OutputName = "WinUtil-TR.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "[1/3] winutil.ps1 derleniyor (UTF-8 BOM)..." -ForegroundColor Cyan
& "$root\Compile.ps1"

$ps1Path = Join-Path $root "winutil.ps1"
$gzPath = Join-Path $root "launcher\winutil.ps1.gz"
$csPath = Join-Path $root "launcher\Program.cs"
$manifestPath = Join-Path $root "launcher\app.manifest"
$icoPath = Join-Path $root "launcher\winutil.ico"
$outExe = Join-Path $root $OutputName

Write-Host "[2/3] winutil.ps1 GZip ile sikistiriliyor..." -ForegroundColor Cyan
$inputBytes = [System.IO.File]::ReadAllBytes($ps1Path)
$fs = [System.IO.File]::Create($gzPath)
try {
    $gz = New-Object System.IO.Compression.GZipStream($fs, [System.IO.Compression.CompressionLevel]::Optimal)
    try {
        $gz.Write($inputBytes, 0, $inputBytes.Length)
    } finally {
        $gz.Dispose()
    }
} finally {
    $fs.Dispose()
}

$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    throw "csc.exe bulunamadi: $csc"
}

Write-Host "[3/3] $OutputName derleniyor (.NET Framework 4.8 native exe)..." -ForegroundColor Cyan
$cscArgs = @(
    "/nologo",
    "/target:winexe",
    "/platform:anycpu",
    "/optimize+",
    "/utf8output",
    "/r:System.Windows.Forms.dll",
    "/win32manifest:$manifestPath",
    "/resource:$gzPath,winutil.ps1.gz",
    "/out:$outExe"
)
if (Test-Path $icoPath) {
    $cscArgs += "/win32icon:$icoPath"
}
$cscArgs += $csPath

& $csc @cscArgs
if ($LASTEXITCODE -ne 0) {
    throw "csc.exe derleme hatasi (cikis kodu: $LASTEXITCODE)"
}

$exeInfo = Get-Item $outExe
Write-Host ""
Write-Host "Basarili! Olusturulan dosya: $($exeInfo.FullName) ($([math]::Round($exeInfo.Length / 1KB, 1)) KB)" -ForegroundColor Green
