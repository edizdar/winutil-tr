function Get-WinUtilDetectedAppliedTweaks {
    <#
    .SYNOPSIS
        Detects currently applied tweaks on the live Windows system, including both
        registry/service tweaks and detectable script-only tweaks.
    #>
    $applied = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        foreach ($key in @(Invoke-WinUtilCurrentSystem -CheckBox "tweaks")) {
            if ($key) {
                [void]$applied.Add([string]$key)
            }
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "Tweaks" -Message "Could not scan standard tweaks: $($_.Exception.Message)"
    }

    # Additional fast live checks for popular script-only tweaks
    try {
        if (Test-Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -ErrorAction SilentlyContinue) {
            [void]$applied.Add('WPFTweaksRightClickMenu')
        }
    } catch {}

    try {
        $folderType = (Get-ItemProperty -Path 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'FolderType' -ErrorAction SilentlyContinue).FolderType
        if ($folderType -eq 'NotSpecified') {
            [void]$applied.Add('WPFTweaksDisableExplorerAutoDiscovery')
        }
    } catch {}

    try {
        $hasOneDrive = (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") -or
                       (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") -or
                       (Test-Path "$env:LocalAppData\Microsoft\OneDrive\OneDrive.exe")
        if (-not $hasOneDrive) {
            [void]$applied.Add('WPFTweaksRemoveOneDrive')
        }
    } catch {}

    try {
        $edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        $edgeExe64 = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
        if (-not (Test-Path $edgeExe) -and -not (Test-Path $edgeExe64)) {
            [void]$applied.Add('WPFTweaksRemoveEdge')
        }
    } catch {}

    try {
        $widgetsPkg = Get-AppxPackage -Name 'MicrosoftWindows.Client.WebExperience' -ErrorAction SilentlyContinue
        if (-not $widgetsPkg) {
            [void]$applied.Add('WPFTweaksWidget')
        }
    } catch {}

    try {
        $threshold = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -ErrorAction SilentlyContinue).SvcHostSplitThresholdInKB
        if ($threshold -and [uint64]$threshold -gt 3670016) {
            $ramKB = (Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object Capacity -Sum).Sum / 1KB
            if ($ramKB -gt 0 -and [uint64]$threshold -ge [uint64]($ramKB * 0.9)) {
                [void]$applied.Add('WPFTweaksSvcHostSplitting')
            }
        }
    } catch {}

    try {
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        if (Test-Path $hostsPath) {
            $hostsContent = Get-Content -Path $hostsPath -Raw -ErrorAction SilentlyContinue
            if ($hostsContent -match 'lmlicenses\.wip4\.adobe\.com|ic\.adobe\.io|adobestats\.io') {
                [void]$applied.Add('WPFTweaksBlockAdobeNet')
            }
        }
    } catch {}

    try {
        $programFiles64 = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
        $logiPath = "$programFiles64\LogiDownloadAssistant"
        if (Test-Path $logiPath) {
            $acl = Get-Acl -Path $logiPath -ErrorAction SilentlyContinue
            $hasDeny = $acl.Access | Where-Object {
                $_.AccessControlType -eq 'Deny' -and
                $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-1-0'
            }
            if ($hasDeny) {
                [void]$applied.Add('WPFTweaksLogiBlock')
            }
        }
    } catch {}

    try {
        $storeDb = "$env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"
        if (Test-Path $storeDb) {
            $acl = Get-Acl -Path $storeDb -ErrorAction SilentlyContinue
            $hasDeny = $acl.Access | Where-Object {
                $_.AccessControlType -eq 'Deny' -and
                $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-1-0'
            }
            if ($hasDeny) {
                [void]$applied.Add('WPFTweaksDisableStoreSearch')
            }
        }
    } catch {}

    return @($applied)
}

function Update-WinUtilAppliedTweakBadges {
    <#
    .SYNOPSIS
        Refreshes the green "✓ Uygulu" badges next to tweaks that are currently applied on the system.
    #>
    if ($null -eq $sync.TweakStatusBadges -or $sync.TweakStatusBadges.Count -eq 0) {
        return
    }

    $applied = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(Get-WinUtilDetectedAppliedTweaks),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $applyToUI = {
        param($AppliedSet)
        if ($null -eq $sync.TweakStatusBadges) { return }
        foreach ($entry in $sync.TweakStatusBadges.GetEnumerator()) {
            $badge = $entry.Value
            if ($null -ne $badge) {
                $badge.Visibility = if ($AppliedSet.Contains($entry.Key)) {
                    [Windows.Visibility]::Visible
                } else {
                    [Windows.Visibility]::Collapsed
                }
            }
        }
    }

    if (Test-WinUtilUIAlive) {
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $applyToUI $applied
        } else {
            Invoke-WPFUIThread -Async -Parameters @{ AppliedSet = $applied } -ScriptBlock $applyToUI
        }
    }
}

function Update-WinUtilInstalledAppxBadges {
    <#
    .SYNOPSIS
        Refreshes the green "✓ Kurulu" badges next to AppX packages currently installed on the system.
    #>
    if ($null -eq $sync.AppxStatusBadges -or $sync.AppxStatusBadges.Count -eq 0) {
        return
    }

    $installed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        foreach ($pkg in @(Get-WinUtilInstalledAPPX)) {
            if ($pkg) {
                [void]$installed.Add([string]$pkg)
            }
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "AppX" -Message "Could not scan installed AppX packages: $($_.Exception.Message)"
        return
    }

    $applyToUI = {
        param($InstalledSet)
        if ($null -eq $sync.AppxStatusBadges) { return }
        foreach ($entry in $sync.AppxStatusBadges.GetEnumerator()) {
            $badge = $entry.Value
            $appxCfg = $sync.configs.appxHashtable[$entry.Key]
            if ($null -ne $badge -and $null -ne $appxCfg) {
                $badge.Visibility = if ($InstalledSet.Contains([string]$appxCfg.PackageId)) {
                    [Windows.Visibility]::Visible
                } else {
                    [Windows.Visibility]::Collapsed
                }
            }
        }
    }

    if (Test-WinUtilUIAlive) {
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $applyToUI $installed
        } else {
            Invoke-WPFUIThread -Async -Parameters @{ InstalledSet = $installed } -ScriptBlock $applyToUI
        }
    }
}

function Get-WinUtilDetectedEnabledFeatures {
    <#
    .SYNOPSIS
        Detects currently enabled Windows features and configuration options shown on the Config tab.
    #>
    $enabledKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $enabledOptional = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        foreach ($opt in @(Get-CimInstance -ClassName Win32_OptionalFeature -Filter "InstallState = 1" -ErrorAction SilentlyContinue)) {
            if ($opt.Name) {
                [void]$enabledOptional.Add([string]$opt.Name)
            }
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "Feature" -Message "Could not query Win32_OptionalFeature: $($_.Exception.Message)"
    }

    if ($null -ne $sync.configs.feature) {
        foreach ($prop in $sync.configs.feature.PSObject.Properties) {
            $reqFeatures = @($prop.Value.feature | Where-Object { $_ })
            if ($reqFeatures.Count -gt 0) {
                $allEnabled = $true
                foreach ($rf in $reqFeatures) {
                    if (-not $enabledOptional.Contains([string]$rf)) {
                        $allEnabled = $false
                        break
                    }
                }
                if ($allEnabled) {
                    [void]$enabledKeys.Add($prop.Name)
                }
            }
        }
    }

    # Registry Backup (Daily Task 00:30)
    try {
        $regVal = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager' -Name 'EnablePeriodicBackup' -ErrorAction SilentlyContinue).EnablePeriodicBackup
        if ($regVal -eq 1) {
            [void]$enabledKeys.Add('WPFFeatureRegBackup')
        }
    } catch {}

    # Legacy F8 Boot Recovery (bcdedit bootmenupolicy)
    try {
        $bcdOut = (& bcdedit /enum '{current}' 2>$null) -join "`n"
        if ($bcdOut -match '(?im)^\s*bootmenupolicy\s+(\S+)') {
            $policy = $Matches[1].Trim()
            if ($policy -ieq 'Legacy') {
                [void]$enabledKeys.Add('WPFFeatureEnableLegacyRecovery')
            } elseif ($policy -ieq 'Standard') {
                [void]$enabledKeys.Add('WPFFeatureDisableLegacyRecovery')
            }
        }
    } catch {}

    return @($enabledKeys)
}

function Update-WinUtilEnabledFeatureBadges {
    <#
    .SYNOPSIS
        Refreshes the green "✓ Etkin" badges next to Windows features currently enabled on the system.
    #>
    if ($null -eq $sync.FeatureStatusBadges -or $sync.FeatureStatusBadges.Count -eq 0) {
        return
    }

    $enabledSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(Get-WinUtilDetectedEnabledFeatures),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $applyToUI = {
        param($EnabledSet)
        if ($null -eq $sync.FeatureStatusBadges) { return }
        foreach ($entry in $sync.FeatureStatusBadges.GetEnumerator()) {
            $badge = $entry.Value
            if ($null -ne $badge) {
                $badge.Visibility = if ($EnabledSet.Contains($entry.Key)) {
                    [Windows.Visibility]::Visible
                } else {
                    [Windows.Visibility]::Collapsed
                }
            }
        }
    }

    if (Test-WinUtilUIAlive) {
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $applyToUI $enabledSet
        } else {
            Invoke-WPFUIThread -Async -Parameters @{ EnabledSet = $enabledSet } -ScriptBlock $applyToUI
        }
    }
}

function Start-WinUtilBadgeRefresh {
    <#
    .SYNOPSIS
        Runs tweak, Config feature, or AppX badge detection off the UI thread so the interface never stutters.
    #>
    param(
        [ValidateSet("Tweaks", "AppX", "Config")]
        [string]$Target
    )

    $workerScript = switch ($Target) {
        "AppX"   { { Update-WinUtilInstalledAppxBadges } }
        "Config" { { Update-WinUtilEnabledFeatureBadges } }
        default  { { Update-WinUtilAppliedTweakBadges } }
    }

    if ($null -ne $sync.RunspacePool) {
        try {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $sync.RunspacePool
            [void]$ps.AddScript($workerScript)
            $handle = $ps.BeginInvoke()
            # Clean up the lightweight PowerShell wrapper asynchronously once finished
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
        } catch {
            Write-WinUtilLog -Level "DEBUG" -Component "UI" -Message "Async badge refresh fallback: $($_.Exception.Message)"
        }
    }

    & $workerScript
}

