function Set-WinUtilSysRegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        $Value,
        [string]$Type = "DWord",
        [switch]$Remove
    )

    if ($Remove) {
        if (Test-Path -LiteralPath $Path) {
            Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
        }
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force
}

function Get-WinUtilSysRegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path -LiteralPath $Path) {
        try {
            $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
            return $item.$Name
        } catch {}
    }
    return $null
}

function Get-WinUtilSystemHealthSnapshot {
    $isTr = ($sync.Language -eq "tr")

    # OS & Uptime
    $osText = "Windows"
    $uptimeText = ""
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $osName = ($os.Caption -replace '^Microsoft\s+', '').Trim()
        $osText = "$osName ($($os.BuildNumber))"
        $span = (Get-Date) - $os.LastBootUpTime
        $uptimeText = if ($isTr) {
            "Çalışma süresi: $([int]$span.TotalDays)g $($span.Hours)s $($span.Minutes)dk"
        } else {
            "Uptime: $([int]$span.TotalDays)d $($span.Hours)h $($span.Minutes)m"
        }
    } catch {}

    # CPU
    $cpuText = "-"
    $cpuSub = ""
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $cpuText = ($cpu.Name -replace '\s+', ' ').Trim()
        $load = if ($null -ne $cpu.LoadPercentage) { "$($cpu.LoadPercentage)%" } else { "-" }
        $cpuSub = if ($isTr) {
            "$($cpu.NumberOfCores) Çekirdek / $($cpu.NumberOfLogicalProcessors) İzlek | Kullanım: $load"
        } else {
            "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads | Load: $load"
        }
    } catch {}

    # RAM
    $ramText = "-"
    $ramSub = ""
    try {
        $osMem = if ($os) { $os } else { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
        $totalGB = [math]::Round($osMem.TotalVisibleMemorySize / 1MB, 1)
        $freeGB  = [math]::Round($osMem.FreePhysicalMemory / 1MB, 1)
        $usedGB  = [math]::Round(($totalGB - $freeGB), 1)
        $pct     = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
        $ramText = "$usedGB / $totalGB GB ($pct%)"
        $ramSub  = if ($isTr) { "Kullanılabilir: $freeGB GB" } else { "Available: $freeGB GB" }
    } catch {}

    # GPU
    $gpuText = "-"
    $gpuSub  = ""
    try {
        $allGpus = @(Get-CimInstance Win32_VideoController -ErrorAction Stop)
        $physicalGpus = @($allGpus | Where-Object { $_.Name -notmatch 'Basic Display|Remote|Virtual|Indirect|Parsec|Citrix|Meta|IddSample' })
        $discreteGpus = @($physicalGpus | Where-Object { $_.Name -match 'NVIDIA|GeForce|RTX|GTX|Radeon|AMD|Arc' })
        $gpu = if ($discreteGpus.Count -gt 0) {
            $discreteGpus[0]
        } elseif ($physicalGpus.Count -gt 0) {
            $physicalGpus[0]
        } else {
            $allGpus | Select-Object -First 1
        }
        if ($gpu) {
            $gpuText = $gpu.Name.Trim()
            $gpuSub  = if ($isTr) { "Sürücü: $($gpu.DriverVersion)" } else { "Driver: $($gpu.DriverVersion)" }
        }
    } catch {}

    # Disk C:
    $diskText = "-"
    $diskSub  = ""
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
        $totalD = [math]::Round($disk.Size / 1GB, 1)
        $freeD  = [math]::Round($disk.FreeSpace / 1GB, 1)
        $usedD  = [math]::Round(($totalD - $freeD), 1)
        $pctD   = if ($totalD -gt 0) { [math]::Round(($usedD / $totalD) * 100) } else { 0 }
        $diskText = "$freeD GB / $totalD GB"
        $diskSub  = if ($isTr) { "Doluluk: %$pctD (Boş: $freeD GB)" } else { "Used: $pctD% (Free: $freeD GB)" }
    } catch {}

    # Live toggle states
    $hagsVal = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
    $vbsVal  = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled'
    $fastVal = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
    $dvr1    = Get-WinUtilSysRegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled'
    $dvr2    = Get-WinUtilSysRegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled'
    $animVal = Get-WinUtilSysRegValue 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate'
    $tranVal = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency'
    $pcVal   = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    $secVal  = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemClock'
    $cmpVal  = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseCompactMode'
    $arrVal  = Get-WinUtilSysRegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' '29'
    $lckVal  = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled'
    $tipVal  = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled'

    return @{
        OsText = $osText; UptimeText = $uptimeText
        CpuText = $cpuText; CpuSub = $cpuSub
        RamText = $ramText; RamSub = $ramSub
        GpuText = $gpuText; GpuSub = $gpuSub
        DiskText = $diskText; DiskSub = $diskSub
        Toggles = @{
            WPFSysToggleHAGS            = ($hagsVal -eq 2)
            WPFSysToggleVBS             = ($vbsVal -eq 1)
            WPFSysToggleFastStartup     = ($fastVal -eq 1)
            WPFSysToggleGameDVR         = (($null -eq $dvr1 -or $dvr1 -ne 0) -and ($null -eq $dvr2 -or $dvr2 -ne 0))
            WPFSysToggleAnimations      = ($null -eq $animVal -or [string]$animVal -ne "0")
            WPFSysToggleTransparency    = ($null -eq $tranVal -or $tranVal -ne 0)
            WPFSysToggleThisPC          = ($pcVal -eq 0)
            WPFSysToggleClockSeconds    = ($secVal -eq 1)
            WPFSysToggleCompactExplorer = ($cmpVal -eq 1)
            WPFSysToggleShortcutArrow   = (-not [string]::IsNullOrWhiteSpace([string]$arrVal))
            WPFSysToggleLockScreenAds   = ($lckVal -eq 0)
            WPFSysToggleWindowsTips     = ($tipVal -eq 0)
        }
    }
}

function Update-WinUtilSystemHealthUI {
    $snap = Get-WinUtilSystemHealthSnapshot

    $apply = {
        param($Snap)
        $sync.SysHealthUpdating = $true
        try {
            if ($sync.WPFSysValOs)      { $sync.WPFSysValOs.Text      = $Snap.OsText }
            if ($sync.WPFSysValUptime)  { $sync.WPFSysValUptime.Text  = $Snap.UptimeText }
            if ($sync.WPFSysValCpu)     { $sync.WPFSysValCpu.Text     = $Snap.CpuText }
            if ($sync.WPFSysValCpuSub)  { $sync.WPFSysValCpuSub.Text  = $Snap.CpuSub }
            if ($sync.WPFSysValRam)     { $sync.WPFSysValRam.Text     = $Snap.RamText }
            if ($sync.WPFSysValRamSub)  { $sync.WPFSysValRamSub.Text  = $Snap.RamSub }
            if ($sync.WPFSysValGpu)     { $sync.WPFSysValGpu.Text     = $Snap.GpuText }
            if ($sync.WPFSysValGpuSub)  { $sync.WPFSysValGpuSub.Text  = $Snap.GpuSub }
            if ($sync.WPFSysValDisk)    { $sync.WPFSysValDisk.Text    = $Snap.DiskText }
            if ($sync.WPFSysValDiskSub) { $sync.WPFSysValDiskSub.Text = $Snap.DiskSub }

            foreach ($kv in $Snap.Toggles.GetEnumerator()) {
                if ($sync[$kv.Key]) {
                    $sync[$kv.Key].IsChecked = [bool]$kv.Value
                }
            }
        } finally {
            $sync.SysHealthUpdating = $false
        }
    }

    if (Test-WinUtilUIAlive) {
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $apply $snap
        } else {
            Invoke-WPFUIThread -Async -Parameters @{ Snap = $snap } -ScriptBlock $apply
        }
    }
}

function Start-WinUtilSystemHealthRefresh {
    if ($null -ne $sync.RunspacePool) {
        try {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $sync.RunspacePool
            [void]$ps.AddScript({ Update-WinUtilSystemHealthUI })
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
    Update-WinUtilSystemHealthUI
}

function Set-WinUtilSystemHealthStatus {
    param([string]$Message)
    if (Test-WinUtilUIAlive) {
        Invoke-WPFUIThread -Async -Parameters @{ Msg = $Message } -ScriptBlock {
            param($Msg)
            if ($sync.WPFSysActionStatus) {
                $sync.WPFSysActionStatus.Text = $Msg
            }
        }
    }
}

function Set-WinUtilSystemHealthToggle {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Enabled
    )

    if ($sync.SysHealthUpdating) { return }

    $isTr = ($sync.Language -eq "tr")
    try {
        switch ($Name) {
            "WPFSysToggleHAGS" {
                Set-WinUtilSysRegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value $(if ($Enabled) { 2 } else { 1 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "HAGS güncellendi. Değişikliğin etkili olması için bilgisayarı yeniden başlatın." } else { "HAGS updated. Restart Windows for the change to take effect." })
            }
            "WPFSysToggleVBS" {
                Set-WinUtilSysRegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Çekirdek Yalıtım (VBS) güncellendi. Etkili olması için yeniden başlatın." } else { "Core Isolation (VBS) updated. Restart Windows to apply." })
            }
            "WPFSysToggleFastStartup" {
                Set-WinUtilSysRegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Hızlı Başlatma ayarı güncellendi." } else { "Fast Startup setting updated." })
            }
            "WPFSysToggleGameDVR" {
                $val = if ($Enabled) { 1 } else { 0 }
                Set-WinUtilSysRegValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value $val -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Oyun DVR ayarı güncellendi." } else { "Game DVR setting updated." })
            }
            "WPFSysToggleAnimations" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value $(if ($Enabled) { "1" } else { "0" }) -Type String
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Pencere animasyonları güncellendi (tam etki için oturumu kapatıp açın)." } else { "Window animations updated (sign out and back in for full effect)." })
            }
            "WPFSysToggleTransparency" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Şeffaflık efektleri güncellendi." } else { "Transparency effects updated." })
            }
            "WPFSysToggleThisPC" {
                $val = if ($Enabled) { 0 } else { 1 }
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu' -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -Value $val -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Masaüstü 'Bu Bilgisayar' simgesi güncellendi (masaüstünde F5 ile yenileyin)." } else { "Desktop 'This PC' icon updated (press F5 on desktop to refresh)." })
            }
            "WPFSysToggleClockSeconds" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Görev çubuğu saati saniye ayarı güncellendi." } else { "Taskbar clock seconds setting updated." })
            }
            "WPFSysToggleCompactExplorer" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Dosya Gezgini kompakt görünüm güncellendi." } else { "File Explorer compact mode updated." })
            }
            "WPFSysToggleShortcutArrow" {
                $shellIcons = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
                if ($Enabled) {
                    Set-WinUtilSysRegValue -Path $shellIcons -Name '29' -Value '%windir%\System32\shell32.dll,-50' -Type String
                } else {
                    Set-WinUtilSysRegValue -Path $shellIcons -Name '29' -Remove
                }
                Invoke-WinUtilExplorerUpdate -action "restart"
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Kısayol ok ayarı uygulandı ve Dosya Gezgini yenilendi." } else { "Shortcut arrow setting applied and Explorer restarted." })
            }
            "WPFSysToggleLockScreenAds" {
                $val = if ($Enabled) { 0 } else { 1 }
                $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                Set-WinUtilSysRegValue -Path $cdm -Name 'RotatingLockScreenOverlayEnabled' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path $cdm -Name 'SubscribedContent-338387Enabled' -Value $val -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Kilit ekranı reklam/ipucu ayarı güncellendi." } else { "Lock screen tips/ads setting updated." })
            }
            "WPFSysToggleWindowsTips" {
                $val = if ($Enabled) { 0 } else { 1 }
                $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                Set-WinUtilSysRegValue -Path $cdm -Name 'SoftLandingEnabled' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path $cdm -Name 'SubscribedContent-338389Enabled' -Value $val -Type DWord
                Set-WinUtilSysRegValue -Path $cdm -Name 'SubscribedContent-310093Enabled' -Value $val -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Windows ipuçları ve önerileri güncellendi." } else { "Windows tips and suggestions updated." })
            }
        }
    } catch {
        Write-WinUtilLog -Level "ERROR" -Component "SystemHealth" -Message "Toggle $Name failed: $($_.Exception.Message)"
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Hata: $($_.Exception.Message)" } else { "Error: $($_.Exception.Message)" })
    }
}

function Invoke-WinUtilSystemHealthAction {
    param([Parameter(Mandatory)][string]$Action)

    $isTr = ($sync.Language -eq "tr")

    switch ($Action) {
        "RestartExplorer" {
            Invoke-WinUtilExplorerUpdate -action "restart"
            Set-WinUtilSystemHealthStatus $(if ($isTr) { "Dosya Gezgini (Explorer) yeniden başlatıldı." } else { "Windows Explorer restarted." })
        }
        "FlushDns" {
            try {
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                & ipconfig.exe /flushdns | Out-Null
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "DNS önbelleği başarıyla temizlendi." } else { "DNS cache flushed successfully." })
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "DNS temizlenemedi: $($_.Exception.Message)" } else { "Failed to flush DNS: $($_.Exception.Message)" })
            }
        }
        "StoreReset" {
            Start-Process "wsreset.exe"
            Set-WinUtilSystemHealthStatus $(if ($isTr) { "Microsoft Store önbellek sıfırlama (wsreset.exe) başlatıldı." } else { "Microsoft Store cache reset (wsreset.exe) launched." })
        }
        "SystemRepair" {
            Invoke-WPFButton "WPFPanelDISM"
        }
        "QuickClean" {
            $jobName = if ($isTr) { "Hızlı Temizlik" } else { "Quick Cleanup" }
            $jobDesc = if ($isTr) { "Geçici dosyalar ve önbellekler temizleniyor" } else { "Cleaning temporary files and caches" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                $targets = @(
                    $env:TEMP,
                    "$env:SystemRoot\Temp",
                    "$env:LocalAppData\D3DSCache",
                    "$env:LocalAppData\NVIDIA\DXCache",
                    "$env:LocalAppData\AMD\DxCache",
                    "$env:SystemRoot\Prefetch"
                )
                $freedBytes = [int64]0
                $idx = 0
                foreach ($dir in $targets) {
                    $idx++
                    $pct = [int](($idx / ($targets.Count + 1)) * 100)
                    Step-WinUtilJob -Status $(if ($IsTr) { "Temizleniyor: $dir" } else { "Cleaning: $dir" }) -Percent $pct
                    if ($dir -and (Test-Path -LiteralPath $dir)) {
                        Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | ForEach-Object {
                            try {
                                $len = if ($_.PSIsContainer) {
                                    (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                                } else { $_.Length }
                                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                                if ($len) { $freedBytes += [int64]$len }
                            } catch {}
                        }
                    }
                }
                Step-WinUtilJob -Status $(if ($IsTr) { "Geri Dönüşüm Kutusu temizleniyor..." } else { "Emptying Recycle Bin..." }) -Percent 92
                try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
                $freedMB = [math]::Round($freedBytes / 1MB, 1)
                $msg = if ($IsTr) { "Hızlı temizlik tamamlandı: ~$freedMB MB önbellek/geçici dosya silindi + Geri Dönüşüm Kutusu boşaltıldı." } else { "Quick cleanup finished: ~$freedMB MB freed + Recycle Bin emptied." }
                Set-WinUtilSystemHealthStatus $msg
                Update-WinUtilSystemHealthUI
            }
        }
        "WinSxS" {
            $jobName = if ($isTr) { "WinSxS Temizliği" } else { "WinSxS Cleanup" }
            $jobDesc = if ($isTr) { "Windows bileşen deposu temizleniyor" } else { "Cleaning Windows component store" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                Step-WinUtilJob -Status $(if ($IsTr) { "DISM StartComponentCleanup çalıştırılıyor..." } else { "Running DISM StartComponentCleanup..." }) -State "Indeterminate"
                & dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Host
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "WinSxS bileşen deposu temizliği tamamlandı." } else { "WinSxS component store cleanup completed." })
                Update-WinUtilSystemHealthUI
            }
        }
        "OptimizeDrive" {
            $jobName = if ($isTr) { "Disk Optimizasyonu" } else { "Drive Optimization" }
            $jobDesc = if ($isTr) { "C: sürücüsü optimize ediliyor" } else { "Optimizing C: drive" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                Step-WinUtilJob -Status $(if ($IsTr) { "C: sürücüsü optimize ediliyor (TRIM / Birleştirme)..." } else { "Optimizing C: drive (TRIM / Defrag)..." }) -State "Indeterminate"
                Optimize-Volume -DriveLetter C -ErrorAction Stop
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "C: sürücüsü başarıyla optimize edildi." } else { "Drive C: optimized successfully." })
            }
        }
        "DefenderScan" {
            $jobName = if ($isTr) { "Defender Hızlı Tarama" } else { "Defender Quick Scan" }
            $jobDesc = if ($isTr) { "Windows Defender hızlı taraması yapılıyor" } else { "Running Windows Defender quick scan" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                Step-WinUtilJob -Status $(if ($IsTr) { "Windows Defender hızlı taraması çalışıyor..." } else { "Windows Defender quick scan running..." }) -State "Indeterminate"
                Start-MpScan -ScanType QuickScan -ErrorAction Stop
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "Windows Defender hızlı taraması tamamlandı." } else { "Windows Defender quick scan completed." })
            }
        }
    }
}

function Initialize-WinUtilSystemHealthHandlers {
    if ($sync.SysHealthHandlersWired) { return }
    $sync.SysHealthHandlersWired = $true

    if ($sync.WPFSysRefreshBtn) {
        $sync.WPFSysRefreshBtn.Add_Click({ Start-WinUtilSystemHealthRefresh })
    }

    $toggleNames = @(
        "WPFSysToggleHAGS", "WPFSysToggleVBS", "WPFSysToggleFastStartup",
        "WPFSysToggleGameDVR", "WPFSysToggleAnimations", "WPFSysToggleTransparency",
        "WPFSysToggleThisPC", "WPFSysToggleClockSeconds", "WPFSysToggleCompactExplorer",
        "WPFSysToggleShortcutArrow", "WPFSysToggleLockScreenAds", "WPFSysToggleWindowsTips"
    )
    foreach ($tn in $toggleNames) {
        if ($sync[$tn]) {
            $sync[$tn].Add_Checked({
                param($sender, $e)
                Set-WinUtilSystemHealthToggle -Name $sender.Name -Enabled $true
            })
            $sync[$tn].Add_Unchecked({
                param($sender, $e)
                Set-WinUtilSystemHealthToggle -Name $sender.Name -Enabled $false
            })
        }
    }

    $actionMap = @{
        WPFSysBtnRestartExplorer = "RestartExplorer"
        WPFSysBtnFlushDns        = "FlushDns"
        WPFSysBtnQuickClean      = "QuickClean"
        WPFSysBtnWinSxS          = "WinSxS"
        WPFSysBtnOptimizeDrive   = "OptimizeDrive"
        WPFSysBtnSystemRepair    = "SystemRepair"
        WPFSysBtnDefenderScan    = "DefenderScan"
        WPFSysBtnStoreReset      = "StoreReset"
    }
    foreach ($kv in $actionMap.GetEnumerator()) {
        if ($sync[$kv.Key]) {
            $sync[$kv.Key].Tag = $kv.Value
            $sync[$kv.Key].Add_Click({
                param($sender, $e)
                Invoke-WinUtilSystemHealthAction -Action $sender.Tag
            })
        }
    }

    $toolMap = @{
        WPFSysToolTaskMgr  = "taskmgr.exe"
        WPFSysToolServices = "services.msc"
        WPFSysToolRegedit  = "regedit.exe"
        WPFSysToolDevMgmt  = "devmgmt.msc"
        WPFSysToolDiskMgmt = "diskmgmt.msc"
        WPFSysToolStartup  = "ms-settings:startupapps"
        WPFSysToolStorage  = "ms-settings:storagesense"
        WPFSysToolEventVwr = "eventvwr.msc"
    }
    foreach ($kv in $toolMap.GetEnumerator()) {
        if ($sync[$kv.Key]) {
            $sync[$kv.Key].Tag = $kv.Value
            $sync[$kv.Key].Add_Click({
                param($sender, $e)
                try { Start-Process $sender.Tag } catch {}
            })
        }
    }
}
