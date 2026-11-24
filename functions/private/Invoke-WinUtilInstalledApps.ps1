function Get-WinUtilInstalledPrograms {
    $isTr = ($sync.Language -eq "tr")
    $hives = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"; Scope = "64-bit" },
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"; Scope = "32-bit" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"; Scope = $(if ($isTr) { "Kullanıcı" } else { "User" }) }
    )

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $list = New-Object System.Collections.ArrayList

    foreach ($h in $hives) {
        if (-not (Test-Path ($h.Path -replace '\\\*$', ''))) { continue }
        Get-ItemProperty -Path $h.Path -ErrorAction SilentlyContinue | ForEach-Object {
            $name = [string]$_.DisplayName
            if ([string]::IsNullOrWhiteSpace($name)) { return }
            if ($_.SystemComponent -eq 1) { return }
            if (-not [string]::IsNullOrWhiteSpace([string]$_.ParentKeyName)) { return }
            if ($_.ReleaseType -in @("Security Update", "Update Rollup", "Hotfix")) { return }

            $uninst = [string]$_.UninstallString
            $quiet  = [string]$_.QuietUninstallString
            if ([string]::IsNullOrWhiteSpace($uninst) -and [string]::IsNullOrWhiteSpace($quiet)) { return }

            $ver = [string]$_.DisplayVersion
            $dedupKey = "$($name.Trim())|$($ver.Trim())"
            if (-not $seen.Add($dedupKey)) { return }

            $sizeMB = $null
            if ($_.EstimatedSize -and [double]$_.EstimatedSize -gt 0) {
                $sizeMB = [math]::Round(([double]$_.EstimatedSize / 1024.0), 1)
            }

            [void]$list.Add([pscustomobject]@{
                Name                 = $name.Trim()
                Version              = $ver.Trim()
                Publisher            = ([string]$_.Publisher).Trim()
                SizeMB               = $sizeMB
                InstallLocation      = ([string]$_.InstallLocation).Trim().Trim('"')
                UninstallString      = $uninst.Trim()
                QuietUninstallString = $quiet.Trim()
                RegPath              = $_.PSPath
                Scope                = $h.Scope
            })
        }
    }

    return @($list | Sort-Object Name)
}

function Test-WinUtilSafeAppToken {
    param([string]$Token)
    if ([string]::IsNullOrWhiteSpace($Token)) { return $false }
    $t = $Token.Trim()
    if ($t.Length -lt 4) { return $false }

    $blocked = @(
        "microsoft", "windows", "system", "system32", "syswow64", "common", "shared",
        "program files", "program files (x86)", "programdata", "appdata", "local", "roaming",
        "temp", "users", "public", "default", "intel", "nvidia", "realtek", "driver", "drivers",
        "update", "updates", "runtime", "redistributable", "visual", "directx", "dotnet",
        "office", "google", "adobe", "apple", "steam", "setup", "install", "installer",
        "tools", "utilities", "application", "applications", "software", "desktop",
        "documents", "downloads", "config", "cache", "logs", "data", "microsoft corporation",
        "microsoft edge", "windows defender", "windows security"
    )
    if ($blocked -contains $t.ToLowerInvariant()) { return $false }
    return $true
}

function Get-WinUtilNormalizedAppName {
    param([string]$DisplayName)
    if ([string]::IsNullOrWhiteSpace($DisplayName)) { return "" }
    $n = $DisplayName
    $n = $n -replace '\([^)]*\)', ''
    $n = $n -replace '\b(v?\d+(\.\d+)+|x64|x86|64-bit|32-bit|win64|win32|amd64|arm64)\b', ''
    $n = $n -replace '[\s\-_:]+$', ''
    $n = $n -replace '\s{2,}', ' '
    return $n.Trim()
}

function Test-WinUtilSafeDeletePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $false }
        $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
        $lower = $full.ToLowerInvariant()

        $protectedRoots = @(
            $env:SystemDrive.TrimEnd('\'),
            $env:SystemRoot.TrimEnd('\'),
            "$($env:SystemRoot.TrimEnd('\'))\system32",
            "$($env:SystemRoot.TrimEnd('\'))\syswow64",
            "$($env:SystemDrive.TrimEnd('\'))\program files",
            "$($env:SystemDrive.TrimEnd('\'))\program files\common files",
            "$($env:SystemDrive.TrimEnd('\'))\program files (x86)",
            "$($env:SystemDrive.TrimEnd('\'))\program files (x86)\common files",
            $env:ProgramData.TrimEnd('\'),
            "$($env:SystemDrive.TrimEnd('\'))\users",
            $env:USERPROFILE.TrimEnd('\'),
            $env:AppData.TrimEnd('\'),
            $env:LocalAppData.TrimEnd('\'),
            "$($env:LocalAppData.TrimEnd('\'))\programs",
            $env:TEMP.TrimEnd('\'),
            "$($env:SystemRoot.TrimEnd('\'))\temp"
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.ToLowerInvariant() }

        if ($protectedRoots -contains $lower) { return $false }

        # Never delete anything directly under C:\Windows unless it is inside C:\Windows\Temp\...
        $winLower = $env:SystemRoot.TrimEnd('\').ToLowerInvariant()
        $winTempLower = "$winLower\temp\"
        if ($lower.StartsWith("$winLower\") -and -not $lower.StartsWith($winTempLower)) {
            return $false
        }

        # Require at least 2 segments below drive root (e.g., C:\Program Files\MyApp -> 3 parts)
        $segments = @($full.Split('\') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($segments.Count -lt 3) { return $false }

        return $true
    } catch {
        return $false
    }
}

function Find-WinUtilAppLeftovers {
    param(
        [Parameter(Mandatory)]$Entry,
        [switch]$IncludeUninstallRegKey
    )

    $folders  = [System.Collections.Generic.List[string]]::new()
    $regKeys  = [System.Collections.Generic.List[string]]::new()
    $tempList = [System.Collections.Generic.List[string]]::new()
    $seenPath = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $cleanName = Get-WinUtilNormalizedAppName -DisplayName $Entry.Name
    $rawName   = $Entry.Name.Trim()
    $pub       = ($Entry.Publisher -replace '\b(Inc\.?|LLC\.?|Ltd\.?|Corp\.?|Corporation|GmbH|Co\.?)\b', '').Trim(' ,.')

    $nameCandidates = @($rawName, $cleanName) | Where-Object { Test-WinUtilSafeAppToken $_ } | Select-Object -Unique

    # 1. InstallLocation (if still exists and safe)
    if (-not [string]::IsNullOrWhiteSpace($Entry.InstallLocation)) {
        if (Test-WinUtilSafeDeletePath -Path $Entry.InstallLocation) {
            $norm = [System.IO.Path]::GetFullPath($Entry.InstallLocation).TrimEnd('\')
            if ($seenPath.Add($norm)) { $folders.Add($norm) }
        }
    }

    # 2. AppData / LocalAppData / ProgramData exact leaf folders
    $dataRoots = @($env:AppData, $env:LocalAppData, $env:ProgramData) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
    foreach ($rootDir in $dataRoots) {
        foreach ($cand in $nameCandidates) {
            $p1 = Join-Path $rootDir $cand
            if ((Test-WinUtilSafeDeletePath -Path $p1) -and $seenPath.Add($p1)) {
                $folders.Add($p1)
            }
            if (-not [string]::IsNullOrWhiteSpace($pub) -and $pub.Length -ge 3) {
                $p2 = Join-Path (Join-Path $rootDir $pub) $cand
                if ((Test-WinUtilSafeDeletePath -Path $p2) -and $seenPath.Add($p2)) {
                    $folders.Add($p2)
                }
            }
        }
    }

    # 3. Registry (Regedit) leftovers
    if ($IncludeUninstallRegKey -and -not [string]::IsNullOrWhiteSpace($Entry.RegPath) -and (Test-Path -LiteralPath $Entry.RegPath)) {
        if ($seenPath.Add($Entry.RegPath)) { $regKeys.Add($Entry.RegPath) }
    }
    $regRoots = @(
        "HKCU:\Software",
        "HKLM:\SOFTWARE",
        "HKLM:\SOFTWARE\WOW6432Node"
    )
    foreach ($rr in $regRoots) {
        foreach ($cand in $nameCandidates) {
            $k1 = "$rr\$cand"
            if ((Test-Path -LiteralPath $k1) -and $seenPath.Add($k1)) {
                $regKeys.Add($k1)
            }
            if (-not [string]::IsNullOrWhiteSpace($pub) -and $pub.Length -ge 3) {
                $k2 = "$rr\$pub\$cand"
                if ((Test-Path -LiteralPath $k2) -and $seenPath.Add($k2)) {
                    $regKeys.Add($k2)
                }
            }
        }
    }

    # 4. TEMP leftovers (files & folders matching clean app name)
    $tempRoots = @($env:TEMP, "$env:SystemRoot\Temp") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
    $safeTokens = @($nameCandidates | Where-Object { $_.Length -ge 4 })
    if ($safeTokens.Count -gt 0) {
        foreach ($trDir in $tempRoots) {
            Get-ChildItem -LiteralPath $trDir -Force -ErrorAction SilentlyContinue | ForEach-Object {
                $itemName = $_.Name
                foreach ($tk in $safeTokens) {
                    if ($itemName.IndexOf($tk, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                        if ((Test-WinUtilSafeDeletePath -Path $_.FullName) -and $seenPath.Add($_.FullName)) {
                            $tempList.Add($_.FullName)
                        }
                        break
                    }
                }
            }
        }
    }

    return @{
        Folders      = @($folders)
        RegistryKeys = @($regKeys)
        TempItems    = @($tempList)
        TotalCount   = ($folders.Count + $regKeys.Count + $tempList.Count)
    }
}

function Remove-WinUtilAppLeftoversInteractive {
    param(
        [Parameter(Mandatory)]$Entry,
        [switch]$AfterUninstall
    )

    $isTr = ($sync.Language -eq "tr")
    $res = Find-WinUtilAppLeftovers -Entry $Entry -IncludeUninstallRegKey:$AfterUninstall

    if ($res.TotalCount -eq 0) {
        $noneMsg = if ($isTr) {
            "'$($Entry.Name)' için geride kalan klasör, Kayıt Defteri (Regedit) veya TEMP artığı bulunamadı."
        } else {
            "No leftover folders, Registry keys, or TEMP files found for '$($Entry.Name)'."
        }
        Set-WinUtilSystemHealthStatus $noneMsg
        Show-WinUtilMessage -Message $noneMsg -Title (Get-WinUtilString -Key "WindowTitle") -Button "OK" -Icon "Info" | Out-Null
        return
    }

    $previewLines = New-Object System.Collections.ArrayList
    if ($res.Folders.Count -gt 0) {
        [void]$previewLines.Add($(if ($isTr) { "[Klasörler: $($res.Folders.Count)]" } else { "[Folders: $($res.Folders.Count)]" }))
        foreach ($f in ($res.Folders | Select-Object -First 6)) { [void]$previewLines.Add("  - $f") }
    }
    if ($res.RegistryKeys.Count -gt 0) {
        [void]$previewLines.Add($(if ($isTr) { "[Kayıt Defteri / Regedit: $($res.RegistryKeys.Count)]" } else { "[Registry Keys: $($res.RegistryKeys.Count)]" }))
        foreach ($r in ($res.RegistryKeys | Select-Object -First 6)) {
            $niceR = $r -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
            [void]$previewLines.Add("  - $niceR")
        }
    }
    if ($res.TempItems.Count -gt 0) {
        [void]$previewLines.Add($(if ($isTr) { "[TEMP Artıkları: $($res.TempItems.Count)]" } else { "[TEMP Leftovers: $($res.TempItems.Count)]" }))
        foreach ($t in ($res.TempItems | Select-Object -First 6)) { [void]$previewLines.Add("  - $t") }
    }

    $confirmMsg = if ($isTr) {
        "'$($Entry.Name)' için toplam $($res.TotalCount) artık öğe bulundu:`n`n$($previewLines -join "`n")`n`nBu klasör, Kayıt Defteri (Regedit) ve TEMP artıklarını kalıcı olarak silmek istiyor musunuz?"
    } else {
        "Found $($res.TotalCount) leftover item(s) for '$($Entry.Name)':`n`n$($previewLines -join "`n")`n`nDo you want to permanently delete these folder, Registry, and TEMP leftovers?"
    }

    $ans = Show-WinUtilMessage -Message $confirmMsg -Title (Get-WinUtilString -Key "WindowTitle") -Button "YesNo" -Icon "Warning"
    if ($ans -ne "Yes") {
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Artık temizleme iptal edildi." } else { "Leftover cleanup cancelled." })
        return
    }

    $deleted = 0
    foreach ($f in $res.Folders) {
        try {
            if (Test-WinUtilSafeDeletePath -Path $f) {
                Remove-Item -LiteralPath $f -Recurse -Force -ErrorAction Stop
                $deleted++
            }
        } catch {}
    }
    foreach ($t in $res.TempItems) {
        try {
            if (Test-WinUtilSafeDeletePath -Path $t) {
                Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction Stop
                $deleted++
            }
        } catch {}
    }
    foreach ($r in $res.RegistryKeys) {
        try {
            if (Test-Path -LiteralPath $r) {
                Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction Stop
                $deleted++
            }
        } catch {}
    }

    $doneMsg = if ($isTr) {
        "'$($Entry.Name)' için derin temizlik tamamlandı: $deleted / $($res.TotalCount) artık öğe (klasör, Regedit, TEMP) silindi."
    } else {
        "Deep cleanup completed for '$($Entry.Name)': $deleted / $($res.TotalCount) leftover item(s) removed."
    }
    Set-WinUtilSystemHealthStatus $doneMsg
    Show-WinUtilMessage -Message $doneMsg -Title (Get-WinUtilString -Key "WindowTitle") -Button "OK" -Icon "Info" | Out-Null
    Start-WinUtilInstalledAppsRefresh
}

function Invoke-WinUtilInstalledAppUninstall {
    param(
        [Parameter(Mandatory)]$Entry,
        [bool]$DeepClean = $true
    )

    $isTr = ($sync.Language -eq "tr")
    $deepNote = if ($DeepClean) {
        if ($isTr) { "`n`nKaldırma tamamlandıktan sonra geride kalan Klasör, Kayıt Defteri (Regedit) ve TEMP artıkları otomatik taranacaktır." }
        else { "`n`nAfter uninstall completes, leftover Folders, Registry keys, and TEMP files will be scanned automatically." }
    } else { "" }

    $askMsg = if ($isTr) {
        "'$($Entry.Name)' programını kaldırmak istediğinizden emin misiniz?$deepNote"
    } else {
        "Are you sure you want to uninstall '$($Entry.Name)'?$deepNote"
    }
    $confirm = Show-WinUtilMessage -Message $askMsg -Title (Get-WinUtilString -Key "MsgAreYouSure") -Button "YesNo" -Icon "Warning"
    if ($confirm -ne "Yes") { return }

    $cmdRaw = if (-not [string]::IsNullOrWhiteSpace($Entry.UninstallString)) { $Entry.UninstallString } else { $Entry.QuietUninstallString }
    if ([string]::IsNullOrWhiteSpace($cmdRaw)) {
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Bu program için kaldırma komutu bulunamadı." } else { "No uninstall command found for this program." })
        return
    }

    $jobName = if ($isTr) { "Program Kaldırma" } else { "Uninstall Program" }
    $jobDesc = if ($isTr) { "$($Entry.Name) kaldırılıyor" } else { "Uninstalling $($Entry.Name)" }

    Start-WinUtilJob -Name $jobName -Description $jobDesc -Parameters @{
        Entry     = $Entry
        CmdRaw    = $cmdRaw
        DeepClean = $DeepClean
        IsTr      = $isTr
    } -ScriptBlock {
        param($Entry, $CmdRaw, $DeepClean, $IsTr)

        Step-WinUtilJob -Status $(if ($IsTr) { "$($Entry.Name) kaldırıcısı çalışıyor..." } else { "Running uninstaller for $($Entry.Name)..." }) -State "Indeterminate"
        Set-WinUtilSystemHealthStatus $(if ($IsTr) { "$($Entry.Name) kaldırıcısı başlatıldı, tamamlanması bekleniyor..." } else { "Uninstaller started for $($Entry.Name), waiting for completion..." })

        try {
            $exe = $null
            $argStr = ""

            if ($CmdRaw -match '(?i)msiexec(?:\.exe)?\s*(.*)$') {
                $exe = "msiexec.exe"
                $argStr = ($matches[1] -replace '(?i)/I\s*\{', '/X{')
            } elseif ($CmdRaw -match '^"([^"]+)"\s*(.*)$') {
                $exe = $matches[1]
                $argStr = $matches[2]
            } elseif (Test-Path -LiteralPath $CmdRaw) {
                $exe = $CmdRaw
                $argStr = ""
            } elseif ($CmdRaw -match '^([^\s]+\.(?:exe|bat|cmd))\s*(.*)$') {
                $exe = $matches[1]
                $argStr = $matches[2]
            } else {
                $exe = "cmd.exe"
                $argStr = "/c $CmdRaw"
            }

            if ([string]::IsNullOrWhiteSpace($argStr)) {
                Start-Process -FilePath $exe -Wait -ErrorAction Stop
            } else {
                Start-Process -FilePath $exe -ArgumentList $argStr -Wait -ErrorAction Stop
            }
        } catch {
            $errMsg = if ($IsTr) { "Kaldırıcı başlatılamadı: $($_.Exception.Message)" } else { "Failed to launch uninstaller: $($_.Exception.Message)" }
            Set-WinUtilSystemHealthStatus $errMsg
            Invoke-WPFUIThread -Parameters @{ Msg = $errMsg } -ScriptBlock {
                param($Msg)
                Show-WinUtilMessage -Message $Msg -Title (Get-WinUtilString -Key "ErrorTitle") -Button "OK" -Icon "Error" | Out-Null
            }
            return
        }

        Start-Sleep -Milliseconds 700
        Set-WinUtilSystemHealthStatus $(if ($IsTr) { "$($Entry.Name) kaldırma işlemi tamamlandı." } else { "Uninstallation finished for $($Entry.Name)." })

        if ($DeepClean) {
            Step-WinUtilJob -Status $(if ($IsTr) { "Regedit, AppData ve TEMP artıkları taranıyor..." } else { "Scanning Registry, AppData and TEMP leftovers..." }) -Percent 85
            Invoke-WPFUIThread -Parameters @{ Entry = $Entry } -ScriptBlock {
                param($Entry)
                Remove-WinUtilAppLeftoversInteractive -Entry $Entry -AfterUninstall
            }
        } else {
            Start-WinUtilInstalledAppsRefresh
        }
    }
}

function Render-WinUtilInstalledAppsList {
    param([string]$FilterText = "")

    if (-not $sync.WPFSysAppsList) { return }
    $isTr = ($sync.Language -eq "tr")
    $all = if ($sync.SysInstalledApps) { @($sync.SysInstalledApps) } else { @() }
    $q = if ($FilterText) { $FilterText.Trim() } else { "" }

    $filtered = if ([string]::IsNullOrWhiteSpace($q)) {
        $all
    } else {
        @($all | Where-Object {
            ($_.Name -and $_.Name.IndexOf($q, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) -or
            ($_.Publisher -and $_.Publisher.IndexOf($q, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        })
    }

    if ($sync.WPFSysAppsCount) {
        $sync.WPFSysAppsCount.Text = if ($isTr) {
            if ($q) { "$($filtered.Count) / $($all.Count) program" } else { "$($all.Count) yüklü program" }
        } else {
            if ($q) { "$($filtered.Count) / $($all.Count) programs" } else { "$($all.Count) installed programs" }
        }
    }

    $sync.WPFSysAppsList.Children.Clear()
    if ($filtered.Count -eq 0) {
        $empty = New-Object Windows.Controls.TextBlock
        $empty.Text = if ($isTr) { "Eşleşen yüklü program bulunamadı." } else { "No matching installed programs found." }
        $empty.FontSize = 12
        $empty.Opacity = 0.75
        $empty.Margin = New-Object Windows.Thickness(8)
        $empty.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
        [void]$sync.WPFSysAppsList.Children.Add($empty)
        return
    }

    $uninstText = if ($isTr) { "Kaldır" } else { "Uninstall" }
    $scanText   = if ($isTr) { "Artıkları Tara" } else { "Scan Leftovers" }

    foreach ($app in $filtered) {
        $rowBorder = New-Object Windows.Controls.Border
        $rowBorder.BorderThickness = New-Object Windows.Thickness(0,0,0,1)
        $rowBorder.Padding = New-Object Windows.Thickness(8,5,8,5)
        $rowBorder.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, "BorderColor")

        $dock = New-Object Windows.Controls.DockPanel

        $btnPanel = New-Object Windows.Controls.StackPanel
        $btnPanel.Orientation = "Horizontal"
        $btnPanel.VerticalAlignment = "Center"
        [Windows.Controls.DockPanel]::SetDock($btnPanel, [Windows.Controls.Dock]::Right)

        $scanBtn = New-Object Windows.Controls.Button
        $scanBtn.Content = $scanText
        $scanBtn.Height = 25
        $scanBtn.Width = [double]::NaN
        $scanBtn.Padding = New-Object Windows.Thickness(9,1,9,1)
        $scanBtn.Margin = New-Object Windows.Thickness(0,0,6,0)
        $scanBtn.Tag = $app
        $scanBtn.Add_Click({
            param($sender, $e)
            Remove-WinUtilAppLeftoversInteractive -Entry $sender.Tag
        })

        $uninstBtn = New-Object Windows.Controls.Button
        $uninstBtn.Content = $uninstText
        $uninstBtn.Height = 25
        $uninstBtn.Width = [double]::NaN
        $uninstBtn.Padding = New-Object Windows.Thickness(12,1,12,1)
        $uninstBtn.Tag = $app
        $uninstBtn.Add_Click({
            param($sender, $e)
            $deep = if ($sync.WPFSysToggleDeepClean) { [bool]$sync.WPFSysToggleDeepClean.IsChecked } else { $true }
            Invoke-WinUtilInstalledAppUninstall -Entry $sender.Tag -DeepClean $deep
        })

        [void]$btnPanel.Children.Add($scanBtn)
        [void]$btnPanel.Children.Add($uninstBtn)

        $infoSp = New-Object Windows.Controls.StackPanel
        $infoSp.HorizontalAlignment = "Left"
        $infoSp.Margin = New-Object Windows.Thickness(0,0,12,0)

        $nameTb = New-Object Windows.Controls.TextBlock
        $nameTb.Text = $app.Name
        $nameTb.FontSize = 12.5
        $nameTb.FontWeight = "SemiBold"
        $nameTb.HorizontalAlignment = "Left"
        $nameTb.TextTrimming = "CharacterEllipsis"
        $nameTb.MaxWidth = 650
        $nameTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

        $metaParts = @()
        if ($app.Publisher) { $metaParts += $app.Publisher }
        if ($app.Version)   { $metaParts += "v$($app.Version)" }
        if ($null -ne $app.SizeMB) { $metaParts += "$($app.SizeMB) MB" }
        $metaParts += "[$($app.Scope)]"

        $metaTb = New-Object Windows.Controls.TextBlock
        $metaTb.Text = ($metaParts -join " | ")
        $metaTb.FontSize = 11
        $metaTb.Opacity = 0.72
        $metaTb.HorizontalAlignment = "Left"
        $metaTb.TextTrimming = "CharacterEllipsis"
        $metaTb.MaxWidth = 650
        $metaTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

        [void]$infoSp.Children.Add($nameTb)
        [void]$infoSp.Children.Add($metaTb)

        [void]$dock.Children.Add($btnPanel)
        [void]$dock.Children.Add($infoSp)
        $rowBorder.Child = $dock
        [void]$sync.WPFSysAppsList.Children.Add($rowBorder)
    }
}

function Update-WinUtilInstalledAppsUI {
    $items = Get-WinUtilInstalledPrograms
    $sync.SysInstalledApps = $items
    $sync.SysHealthAppsLoaded = $true

    if (Test-WinUtilUIAlive) {
        $apply = {
            $q = if ($sync.WPFSysAppsSearchBox) { $sync.WPFSysAppsSearchBox.Text } else { "" }
            Render-WinUtilInstalledAppsList -FilterText $q
        }
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $apply
        } else {
            Invoke-WPFUIThread -Async -ScriptBlock $apply
        }
    }
}

function Start-WinUtilInstalledAppsRefresh {
    if ($null -ne $sync.RunspacePool) {
        try {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $sync.RunspacePool
            [void]$ps.AddScript({ Update-WinUtilInstalledAppsUI })
            $handle = $ps.BeginInvoke()
            [System.Threading.ThreadPool]::RegisterWaitForSingleObject(
                $handle.AsyncWaitHandle,
                [System.Threading.WaitOrTimerCallback]{
                    param($state, $timedOut)
                    try { $state.PS.EndInvoke($state.Handle) } catch {}
                    try { $state.PS.Dispose() } catch {}
                },
                @{ PS = $ps; Handle = $handle },
                30000,
                $true
            ) | Out-Null
            return
        } catch {}
    }
    Update-WinUtilInstalledAppsUI
}
