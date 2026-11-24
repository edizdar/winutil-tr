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

function Set-WinUtilSystemHealthSubTab {
    param([ValidateSet("Overview", "Boost", "Clean", "Startup")][string]$Tab)

    $map = @{
        Overview = @{ Btn = "WPFSysSubBtnOverview"; Panel = "WPFSysPanelOverview" }
        Boost    = @{ Btn = "WPFSysSubBtnBoost";    Panel = "WPFSysPanelBoost" }
        Clean    = @{ Btn = "WPFSysSubBtnClean";    Panel = "WPFSysPanelClean" }
        Startup  = @{ Btn = "WPFSysSubBtnStartup";  Panel = "WPFSysPanelStartup" }
    }

    $sync.SysHealthActiveSubTab = $Tab
    $sync.SysHealthSubTabSwitching = $true
    try {
        foreach ($kv in $map.GetEnumerator()) {
            $isActive = ($kv.Key -eq $Tab)
            if ($sync[$kv.Value.Btn]) {
                $sync[$kv.Value.Btn].IsChecked = $isActive
            }
            if ($sync[$kv.Value.Panel]) {
                $sync[$kv.Value.Panel].Visibility = if ($isActive) { "Visible" } else { "Collapsed" }
            }
        }
    } finally {
        $sync.SysHealthSubTabSwitching = $false
    }

    if ($Tab -eq "Startup" -and -not $sync.SysHealthStartupLoaded) {
        Start-WinUtilStartupRefresh
    }
}

function Get-WinUtilActiveNetworkInfo {
    $isTr = ($sync.Language -eq "tr")
    try {
        $cfg = Get-NetIPConfiguration -ErrorAction Stop | Where-Object {
            $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway -ne $null
        } | Select-Object -First 1
        if (-not $cfg) {
            $cfg = Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
        }
        if ($cfg) {
            $dns = @((Get-DnsClientServerAddress -InterfaceIndex $cfg.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses)
            $dnsStr = if ($dns.Count -gt 0) { $dns -join ", " } else { if ($isTr) { "Otomatik (DHCP)" } else { "Auto (DHCP)" } }
            $ipStr = if ($cfg.IPv4Address) { ($cfg.IPv4Address | Select-Object -First 1).IPAddress } else { "-" }
            if ($isTr) {
                return "Aktif Ağ: $($cfg.InterfaceAlias) ($ipStr) | DNS: $dnsStr"
            } else {
                return "Active Network: $($cfg.InterfaceAlias) ($ipStr) | DNS: $dnsStr"
            }
        }
    } catch {}
    if ($isTr) { return "Aktif ağ bağdaştırıcısı bulunamadı." }
    return "No active network adapter detected."
}

function Get-WinUtilStartupEntries {
    $entries = New-Object System.Collections.ArrayList

    $sources = @(
        @{ Scope = "HKCU"; RunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; ApprovedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
        @{ Scope = "HKLM"; RunPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; ApprovedPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
        @{ Scope = "HKLM32"; RunPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; ApprovedPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" }
    )

    foreach ($src in $sources) {
        if (-not (Test-Path -LiteralPath $src.RunPath)) { continue }
        try {
            $props = (Get-Item -LiteralPath $src.RunPath -ErrorAction Stop).Property
            $itemObj = Get-ItemProperty -LiteralPath $src.RunPath -ErrorAction Stop
            foreach ($name in $props) {
                if ([string]::IsNullOrWhiteSpace($name) -or $name -eq "(default)") { continue }
                $cmd = [string]$itemObj.$name
                $enabled = $true
                $appVal = Get-WinUtilSysRegValue -Path $src.ApprovedPath -Name $name
                if ($appVal -is [byte[]] -and $appVal.Length -ge 1) {
                    if (($appVal[0] -band 1) -eq 1) { $enabled = $false }
                }
                [void]$entries.Add(@{
                    Name         = $name
                    Command      = $cmd
                    Scope        = $src.Scope
                    ApprovedPath = $src.ApprovedPath
                    Enabled      = $enabled
                })
            }
        } catch {}
    }

    # User Startup Folder
    $startupDir = [Environment]::GetFolderPath("Startup")
    $folderApproved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
    if ($startupDir -and (Test-Path -LiteralPath $startupDir)) {
        Get-ChildItem -LiteralPath $startupDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" } | ForEach-Object {
            $enabled = $true
            $appVal = Get-WinUtilSysRegValue -Path $folderApproved -Name $_.Name
            if ($appVal -is [byte[]] -and $appVal.Length -ge 1) {
                if (($appVal[0] -band 1) -eq 1) { $enabled = $false }
            }
            [void]$entries.Add(@{
                Name         = $_.Name
                Command      = $_.FullName
                Scope        = "Folder"
                ApprovedPath = $folderApproved
                Enabled      = $enabled
            })
        }
    }

    return @($entries | Sort-Object { $_.Name })
}

function Set-WinUtilStartupEntryState {
    param(
        [Parameter(Mandatory)][hashtable]$Entry,
        [Parameter(Mandatory)][bool]$Enabled
    )

    if ($sync.SysHealthStartupUpdating) { return }
    $isTr = ($sync.Language -eq "tr")
    try {
        $bytes = if ($Enabled) {
            [byte[]]@(2,0,0,0,0,0,0,0,0,0,0,0)
        } else {
            [byte[]]@(3,0,0,0,0,0,0,0,0,0,0,0)
        }
        Set-WinUtilSysRegValue -Path $Entry.ApprovedPath -Name $Entry.Name -Value $bytes -Type Binary
        $stateTxt = if ($Enabled) {
            if ($isTr) { "etkinleştirildi" } else { "enabled" }
        } else {
            if ($isTr) { "devre dışı bırakıldı" } else { "disabled" }
        }
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Başlangıç öğesi '$($Entry.Name)' $stateTxt." } else { "Startup item '$($Entry.Name)' $stateTxt." })
    } catch {
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Başlangıç ayarı değiştirilemedi: $($_.Exception.Message)" } else { "Failed to update startup item: $($_.Exception.Message)" })
    }
}

function Update-WinUtilStartupListUI {
    $items = Get-WinUtilStartupEntries
    $isTr = ($sync.Language -eq "tr")

    $render = {
        param($Items, $IsTr)
        if (-not $sync.WPFSysStartupList) { return }
        $sync.SysHealthStartupLoaded = $true
        $sync.SysHealthStartupUpdating = $true
        try {
            $sync.WPFSysStartupList.Children.Clear()
            if (-not $Items -or $Items.Count -eq 0) {
                $empty = New-Object Windows.Controls.TextBlock
                $empty.Text = if ($IsTr) { "Kayıtlı başlangıç uygulaması bulunamadı." } else { "No startup applications found." }
                $empty.FontSize = 12
                $empty.Opacity = 0.75
                $empty.Margin = New-Object Windows.Thickness(6)
                $empty.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
                [void]$sync.WPFSysStartupList.Children.Add($empty)
                return
            }

            $toggleStyle = $sync.Form.FindResource("ColorfulToggleSwitchStyle")
            foreach ($entry in $Items) {
                $rowBorder = New-Object Windows.Controls.Border
                $rowBorder.BorderThickness = New-Object Windows.Thickness(0,0,0,1)
                $rowBorder.Padding = New-Object Windows.Thickness(6,5,6,5)
                $rowBorder.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, "BorderColor")

                $dock = New-Object Windows.Controls.DockPanel

                $chk = New-Object Windows.Controls.CheckBox
                if ($toggleStyle) { $chk.Style = $toggleStyle }
                $chk.VerticalAlignment = "Center"
                $chk.IsChecked = [bool]$entry.Enabled
                $chk.Tag = $entry
                [Windows.Controls.DockPanel]::SetDock($chk, [Windows.Controls.Dock]::Right)
                $chk.Add_Checked({
                    param($sender, $e)
                    Set-WinUtilStartupEntryState -Entry $sender.Tag -Enabled $true
                })
                $chk.Add_Unchecked({
                    param($sender, $e)
                    Set-WinUtilStartupEntryState -Entry $sender.Tag -Enabled $false
                })

                $infoPanel = New-Object Windows.Controls.StackPanel
                $infoPanel.Margin = New-Object Windows.Thickness(0,0,8,0)

                $titleRow = New-Object Windows.Controls.StackPanel
                $titleRow.Orientation = "Horizontal"
                $titleRow.HorizontalAlignment = "Left"

                $nameTb = New-Object Windows.Controls.TextBlock
                $nameTb.Text = $entry.Name
                $nameTb.FontSize = 12.5
                $nameTb.FontWeight = "SemiBold"
                $nameTb.TextTrimming = "CharacterEllipsis"
                $nameTb.MaxWidth = 340
                $nameTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                $scopeTb = New-Object Windows.Controls.TextBlock
                $scopeTb.Text = " [$($entry.Scope)]"
                $scopeTb.FontSize = 10.5
                $scopeTb.Opacity = 0.65
                $scopeTb.VerticalAlignment = "Center"
                $scopeTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                [void]$titleRow.Children.Add($nameTb)
                [void]$titleRow.Children.Add($scopeTb)

                $cmdTb = New-Object Windows.Controls.TextBlock
                $cmdTb.Text = $entry.Command
                $cmdTb.ToolTip = $entry.Command
                $cmdTb.FontSize = 10.5
                $cmdTb.Opacity = 0.68
                $cmdTb.HorizontalAlignment = "Left"
                $cmdTb.TextTrimming = "CharacterEllipsis"
                $cmdTb.MaxWidth = 440
                $cmdTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                [void]$infoPanel.Children.Add($titleRow)
                [void]$infoPanel.Children.Add($cmdTb)

                [void]$dock.Children.Add($chk)
                [void]$dock.Children.Add($infoPanel)
                $rowBorder.Child = $dock
                [void]$sync.WPFSysStartupList.Children.Add($rowBorder)
            }
        } finally {
            $sync.SysHealthStartupUpdating = $false
        }
    }

    if (Test-WinUtilUIAlive) {
        if ($sync.Form.Dispatcher.CheckAccess()) {
            & $render $items $isTr
        } else {
            Invoke-WPFUIThread -Async -Parameters @{ Items = $items; IsTr = $isTr } -ScriptBlock $render
        }
    }
}

function Start-WinUtilStartupRefresh {
    if ($null -ne $sync.RunspacePool) {
        try {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $sync.RunspacePool
            [void]$ps.AddScript({ Update-WinUtilStartupListUI })
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
    Update-WinUtilStartupListUI
}

function Get-WinUtilSystemHealthSnapshot {
    $isTr = ($sync.Language -eq "tr")

    # 1. OS & Uptime
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

    # 2. CPU
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

    # 3. RAM
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

    # 4. GPU (exclude virtual/indirect display adapters and prefer discrete GPU)
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

    # 5. All Logical Drives & Disk C:
    $diskText = "-"
    $diskSub  = ""
    $logicalDrives = @()
    try {
        $disks = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop)
        foreach ($d in $disks) {
            if (-not $d.Size -or $d.Size -le 0) { continue }
            $tot = [math]::Round($d.Size / 1GB, 1)
            $fre = [math]::Round($d.FreeSpace / 1GB, 1)
            $usd = [math]::Round(($tot - $fre), 1)
            $pct = [math]::Round(($usd / $tot) * 100)
            $logicalDrives += @{
                DeviceID   = $d.DeviceID
                VolumeName = if ($d.VolumeName) { $d.VolumeName } else { if ($isTr) { "Yerel Disk" } else { "Local Disk" } }
                TotalGB    = $tot
                FreeGB     = $fre
                UsedGB     = $usd
                UsedPct    = $pct
            }
            if ($d.DeviceID -eq "C:") {
                $diskText = "$fre GB / $tot GB"
                $diskSub  = if ($isTr) { "Doluluk: %$pct (Boş: $fre GB)" } else { "Used: $pct% (Free: $fre GB)" }
            }
        }
    } catch {}

    # 6. Physical Disks S.M.A.R.T. Health
    $physicalDisks = @()
    try {
        $pDisks = @(Get-PhysicalDisk -ErrorAction Stop)
        foreach ($pd in $pDisks) {
            $sizeGB = [math]::Round($pd.Size / 1GB, 0)
            $tempStr = ""
            $wearStr = ""
            try {
                $rel = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction Stop
                if ($rel.Temperature -and $rel.Temperature -gt 0) {
                    $deg = [char]0x00B0
                    $tempStr = "$($rel.Temperature)${deg}C"
                }
                if ($null -ne $rel.Wear -and $rel.Wear -ge 0) {
                    $wearStr = if ($isTr) { "Aşınma: %$($rel.Wear)" } else { "Wear: $($rel.Wear)%" }
                }
            } catch {}
            $health = switch ($pd.HealthStatus) {
                "Healthy"   { if ($isTr) { "Sağlıklı" } else { "Healthy" } }
                "Warning"   { if ($isTr) { "Uyarı" } else { "Warning" } }
                "Unhealthy" { if ($isTr) { "Kritik" } else { "Unhealthy" } }
                default     { [string]$pd.HealthStatus }
            }
            $physicalDisks += @{
                Name    = $pd.FriendlyName
                Media   = "$($pd.MediaType) / $($pd.BusType)"
                SizeGB  = $sizeGB
                Health  = $health
                Temp    = $tempStr
                Wear    = $wearStr
            }
        }
    } catch {}

    # 7. Battery Health
    $batHealth = if ($isTr) { "Masaüstü Bilgisayar (Pil Algılanmadı)" } else { "Desktop PC (No Battery Detected)" }
    $batSub    = if ($isTr) { "Sistem doğrudan priz gücüyle çalışıyor." } else { "System is running directly on AC power." }
    try {
        $bat = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1
        if ($bat) {
            $charge = $bat.EstimatedChargeRemaining
            $isCharging = ($bat.BatteryStatus -in @(2, 6, 7, 8, 9))
            $plugTxt = if ($isCharging) {
                if ($isTr) { "Prizde / Şarj Oluyor" } else { "Plugged In / Charging" }
            } else {
                if ($isTr) { "Pil Gücünde" } else { "On Battery" }
            }
            $healthPct = $null
            $designMwh = $null
            $fullMwh   = $null
            $cycles    = $null
            try {
                $sd = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1
                $fc = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1
                if ($sd -and $fc -and $sd.DesignedCapacity -gt 0) {
                    $designMwh = $sd.DesignedCapacity
                    $fullMwh   = $fc.FullChargedCapacity
                    $healthPct = [math]::Round(($fullMwh / $designMwh) * 100, 1)
                }
                $cc = Get-CimInstance -Namespace root\wmi -ClassName BatteryCycleCount -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($cc -and $cc.CycleCount -gt 0) { $cycles = $cc.CycleCount }
            } catch {}

            if ($null -ne $healthPct) {
                $batHealth = if ($isTr) { "Pil Sağlığı: %$healthPct | Şarj: %$charge ($plugTxt)" } else { "Battery Health: $healthPct% | Charge: $charge% ($plugTxt)" }
                $cycPart = if ($cycles) { if ($isTr) { " | Döngü: $cycles" } else { " | Cycles: $cycles" } } else { "" }
                $batSub = if ($isTr) {
                    "Kapasite: $fullMwh / $designMwh mWh$cycPart"
                } else {
                    "Capacity: $fullMwh / $designMwh mWh$cycPart"
                }
            } else {
                $batHealth = if ($isTr) { "Pil Şarjı: %$charge ($plugTxt)" } else { "Battery Charge: $charge% ($plugTxt)" }
                $batSub = if ($isTr) { "Ayrıntılı kapasite bilgisi için 'HTML Pil Raporu' butonunu kullanın." } else { "Click 'HTML Battery Report' for detailed capacity metrics." }
            }
        }
    } catch {}

    # 8. Active Power Plan
    $powerPlanName = "-"
    $powerPlanKey  = "Balanced"
    try {
        $pOut = (& powercfg.exe /getactivescheme 2>$null) -join " "
        if ($pOut -match '([0-9a-fA-F-]{36})\s+\((.+)\)') {
            $guid = $matches[1].ToLowerInvariant()
            $powerPlanName = $matches[2].Trim()
            if ($guid -eq "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c") { $powerPlanKey = "HighPerf" }
            elseif ($guid -eq "a1841308-58c1-4feb-b9df-851c3aa579f7") { $powerPlanKey = "PowerSaver" }
            elseif ($guid -eq "e9a42b02-d5df-448d-aa00-03f14749eb61" -or $powerPlanName -match "Ultimate|Nihai") { $powerPlanKey = "Ultimate" }
            else { $powerPlanKey = "Balanced" }
        }
    } catch {}

    # 9. System Identity (Board / BIOS / TPM+SecureBoot / License)
    $boardText = "-"
    try {
        $bb = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | Select-Object -First 1
        if ($bb) { $boardText = ("$($bb.Manufacturer) $($bb.Product)").Trim() }
    } catch {}

    $biosText = "-"
    try {
        $bi = Get-CimInstance Win32_BIOS -ErrorAction Stop | Select-Object -First 1
        if ($bi) {
            $bDate = if ($bi.ReleaseDate) { $bi.ReleaseDate.ToString("yyyy-MM-dd") } else { "" }
            $biosText = if ($bDate) { "$($bi.SMBIOSBIOSVersion) ($bDate)" } else { "$($bi.SMBIOSBIOSVersion)" }
        }
    } catch {}

    $secText = "-"
    try {
        $sbState = try {
            if (Confirm-SecureBootUEFI -ErrorAction Stop) { if ($isTr) { "Açık" } else { "Enabled" } }
            else { if ($isTr) { "Kapalı" } else { "Disabled" } }
        } catch { if ($isTr) { "Bilinmiyor" } else { "Unknown" } }
        $tpmState = try {
            $t = Get-Tpm -ErrorAction Stop
            if ($t.TpmPresent -and $t.TpmReady) { if ($isTr) { "Hazır" } else { "Ready" } }
            elseif ($t.TpmPresent) { if ($isTr) { "Mevcut" } else { "Present" } }
            else { if ($isTr) { "Yok" } else { "Absent" } }
        } catch { if ($isTr) { "Bilinmiyor" } else { "Unknown" } }
        $secText = "Secure Boot: $sbState | TPM: $tpmState"
    } catch {}

    $licText = "-"
    try {
        $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop | Select-Object -First 1
        if ($lic) {
            $ch = if ($lic.Description -match 'OEM') { "OEM" } elseif ($lic.Description -match 'RETAIL') { "Retail" } elseif ($lic.Description -match 'VOLUME|KMS|MAK') { "Volume" } else { "Windows" }
            $st = if ($lic.LicenseStatus -eq 1) { if ($isTr) { "Etkinleştirildi" } else { "Activated" } } else { if ($isTr) { "Etkinleştirilmedi" } else { "Not Activated" } }
            $licText = "$st ($ch - ...$($lic.PartialProductKey))"
        }
    } catch {}

    # 10. Hibernation (hiberfil.sys)
    $hiberEnabled = $false
    $hiberSizeText = ""
    try {
        $hReg = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled'
        $hFile = Get-Item -LiteralPath "$env:SystemDrive\hiberfil.sys" -Force -ErrorAction SilentlyContinue
        $hiberEnabled = ($hReg -eq 1) -or ($null -ne $hFile)
        if ($hFile) {
            $hGB = [math]::Round($hFile.Length / 1GB, 1)
            $hiberSizeText = if ($isTr) { "hiberfil.sys boyutu: $hGB GB (kapatarak disk alanı açabilirsiniz)" } else { "hiberfil.sys size: $hGB GB (disable to reclaim disk space)" }
        } else {
            $hiberSizeText = if ($isTr) { "Hazırda bekletme kapalı (0 GB disk kullanımı)" } else { "Hibernation disabled (0 GB disk usage)" }
        }
    } catch {}

    # 11. Active Network & DNS
    $activeDnsText = Get-WinUtilActiveNetworkInfo

    # 12. All 21 Live Toggle States
    $hagsVal   = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
    $vbsVal    = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled'
    $fastVal   = Get-WinUtilSysRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
    $gmVal     = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
    $dxVal     = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings'
    $mpoVal    = Get-WinUtilSysRegValue 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode'
    $dvr1      = Get-WinUtilSysRegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled'
    $dvr2      = Get-WinUtilSysRegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled'
    $animVal   = Get-WinUtilSysRegValue 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate'
    $tranVal   = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency'

    $pcVal     = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    $secVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemClock'
    $cmpVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseCompactMode'
    $launchVal = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'LaunchTo'
    $extVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt'
    $hidVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden'
    $clsMenu   = Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    $arrVal    = Get-WinUtilSysRegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' '29'
    $lckVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled'
    $tipVal    = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled'
    $clipVal   = Get-WinUtilSysRegValue 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory'

    $winGamesOn = ($dxVal -and ([string]$dxVal -match 'SwapEffectUpgradeEnable=1'))
    $mpoOn      = ($null -eq $mpoVal -or $mpoVal -ne 5)

    return @{
        OsText = $osText; UptimeText = $uptimeText
        CpuText = $cpuText; CpuSub = $cpuSub
        RamText = $ramText; RamSub = $ramSub
        GpuText = $gpuText; GpuSub = $gpuSub
        DiskText = $diskText; DiskSub = $diskSub
        LogicalDrives = $logicalDrives
        PhysicalDisks = $physicalDisks
        BatHealth = $batHealth; BatSub = $batSub
        PowerPlanName = $powerPlanName; PowerPlanKey = $powerPlanKey
        BoardText = $boardText; BiosText = $biosText; SecText = $secText; LicText = $licText
        HiberSizeText = $hiberSizeText
        ActiveDnsText = $activeDnsText
        IsTr = $isTr
        Toggles = @{
            WPFSysToggleHAGS            = ($hagsVal -eq 2)
            WPFSysToggleVBS             = ($vbsVal -eq 1)
            WPFSysToggleFastStartup     = ($fastVal -eq 1)
            WPFSysToggleGameMode        = ($null -eq $gmVal -or $gmVal -eq 1)
            WPFSysToggleWindowedGames   = [bool]$winGamesOn
            WPFSysToggleMPO             = [bool]$mpoOn
            WPFSysToggleGameDVR         = (($null -eq $dvr1 -or $dvr1 -ne 0) -and ($null -eq $dvr2 -or $dvr2 -ne 0))
            WPFSysToggleAnimations      = ($null -eq $animVal -or [string]$animVal -ne "0")
            WPFSysToggleTransparency    = ($null -eq $tranVal -or $tranVal -ne 0)
            WPFSysToggleHibernation     = [bool]$hiberEnabled
            WPFSysToggleThisPC          = ($pcVal -eq 0)
            WPFSysToggleClockSeconds    = ($secVal -eq 1)
            WPFSysToggleCompactExplorer = ($cmpVal -eq 1)
            WPFSysToggleOpenThisPC      = ($launchVal -eq 1)
            WPFSysToggleFileExt         = ($extVal -eq 0)
            WPFSysToggleHiddenFiles     = ($hidVal -eq 1)
            WPFSysToggleClassicMenu     = [bool]$clsMenu
            WPFSysToggleShortcutArrow   = (-not [string]::IsNullOrWhiteSpace([string]$arrVal))
            WPFSysToggleLockScreenAds   = ($lckVal -eq 0)
            WPFSysToggleWindowsTips     = ($tipVal -eq 0)
            WPFSysToggleClipboard       = ($clipVal -eq 1)
        }
    }
}

function Update-WinUtilSystemHealthUI {
    $snap = Get-WinUtilSystemHealthSnapshot

    $apply = {
        param($Snap)
        $sync.SysHealthUpdating = $true
        try {
            if ($sync.WPFSysValOs)            { $sync.WPFSysValOs.Text            = $Snap.OsText }
            if ($sync.WPFSysValUptime)        { $sync.WPFSysValUptime.Text        = $Snap.UptimeText }
            if ($sync.WPFSysValCpu)           { $sync.WPFSysValCpu.Text           = $Snap.CpuText }
            if ($sync.WPFSysValCpuSub)        { $sync.WPFSysValCpuSub.Text        = $Snap.CpuSub }
            if ($sync.WPFSysValRam)           { $sync.WPFSysValRam.Text           = $Snap.RamText }
            if ($sync.WPFSysValRamSub)        { $sync.WPFSysValRamSub.Text        = $Snap.RamSub }
            if ($sync.WPFSysValGpu)           { $sync.WPFSysValGpu.Text           = $Snap.GpuText }
            if ($sync.WPFSysValGpuSub)        { $sync.WPFSysValGpuSub.Text        = $Snap.GpuSub }
            if ($sync.WPFSysValDisk)          { $sync.WPFSysValDisk.Text          = $Snap.DiskText }
            if ($sync.WPFSysValDiskSub)       { $sync.WPFSysValDiskSub.Text       = $Snap.DiskSub }
            if ($sync.WPFSysValBatteryHealth) { $sync.WPFSysValBatteryHealth.Text = $Snap.BatHealth }
            if ($sync.WPFSysValBatterySub)    { $sync.WPFSysValBatterySub.Text    = $Snap.BatSub }
            if ($sync.WPFSysValPowerNow) {
                $sync.WPFSysValPowerNow.Text = if ($Snap.IsTr) { "Aktif Güç Planı: $($Snap.PowerPlanName)" } else { "Active Power Plan: $($Snap.PowerPlanName)" }
            }
            if ($sync.WPFSysValActivePlan) {
                $sync.WPFSysValActivePlan.Text = if ($Snap.IsTr) { "Aktif Plan: $($Snap.PowerPlanName)" } else { "Active Plan: $($Snap.PowerPlanName)" }
            }
            if ($sync.WPFSysPowerPlanCombo) {
                for ($i = 0; $i -lt $sync.WPFSysPowerPlanCombo.Items.Count; $i++) {
                    if ($sync.WPFSysPowerPlanCombo.Items[$i].Tag -eq $Snap.PowerPlanKey) {
                        $sync.WPFSysPowerPlanCombo.SelectedIndex = $i
                        break
                    }
                }
            }
            if ($sync.WPFSysValBoard)     { $sync.WPFSysValBoard.Text     = $Snap.BoardText }
            if ($sync.WPFSysValBios)      { $sync.WPFSysValBios.Text      = $Snap.BiosText }
            if ($sync.WPFSysValSecurity)  { $sync.WPFSysValSecurity.Text  = $Snap.SecText }
            if ($sync.WPFSysValLicense)   { $sync.WPFSysValLicense.Text   = $Snap.LicText }
            if ($sync.WPFSysValHiberSize) { $sync.WPFSysValHiberSize.Text = $Snap.HiberSizeText }
            if ($sync.WPFSysValActiveDns) { $sync.WPFSysValActiveDns.Text = $Snap.ActiveDnsText }

            # Populate All Drives + S.M.A.R.T. Health List
            if ($sync.WPFSysDrivesList) {
                $sync.WPFSysDrivesList.Children.Clear()
                $pbStyle = $sync.Form.FindResource("RoundedProgressBarStyle")

                foreach ($drv in $Snap.LogicalDrives) {
                    $card = New-Object Windows.Controls.Border
                    $card.CornerRadius = New-Object Windows.CornerRadius(6)
                    $card.BorderThickness = New-Object Windows.Thickness(1)
                    $card.Padding = New-Object Windows.Thickness(9,7,9,7)
                    $card.Margin = New-Object Windows.Thickness(0,0,0,6)
                    $card.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, "MainBackgroundColor")
                    $card.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, "BorderColor")

                    $sp = New-Object Windows.Controls.StackPanel
                    $topRow = New-Object Windows.Controls.DockPanel
                    $rightTb = New-Object Windows.Controls.TextBlock
                    $rightTb.Text = if ($Snap.IsTr) {
                        "$($drv.UsedGB) / $($drv.TotalGB) GB (%$($drv.UsedPct) dolu - Boş: $($drv.FreeGB) GB)"
                    } else {
                        "$($drv.UsedGB) / $($drv.TotalGB) GB ($($drv.UsedPct)% used - Free: $($drv.FreeGB) GB)"
                    }
                    $rightTb.FontSize = 11.5
                    $rightTb.Opacity = 0.82
                    $rightTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
                    [Windows.Controls.DockPanel]::SetDock($rightTb, [Windows.Controls.Dock]::Right)

                    $leftTb = New-Object Windows.Controls.TextBlock
                    $leftTb.Text = "$($drv.DeviceID) ($($drv.VolumeName))"
                    $leftTb.FontSize = 12.5
                    $leftTb.FontWeight = "SemiBold"
                    $leftTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                    [void]$topRow.Children.Add($rightTb)
                    [void]$topRow.Children.Add($leftTb)

                    $pb = New-Object Windows.Controls.ProgressBar
                    if ($pbStyle) { $pb.Style = $pbStyle }
                    $pb.Height = 7
                    $pb.Minimum = 0
                    $pb.Maximum = 100
                    $pb.Value = [double]$drv.UsedPct
                    $pb.Margin = New-Object Windows.Thickness(0,5,0,0)

                    [void]$sp.Children.Add($topRow)
                    [void]$sp.Children.Add($pb)
                    $card.Child = $sp
                    [void]$sync.WPFSysDrivesList.Children.Add($card)
                }

                if ($Snap.PhysicalDisks -and $Snap.PhysicalDisks.Count -gt 0) {
                    $hdr = New-Object Windows.Controls.TextBlock
                    $hdr.Text = if ($Snap.IsTr) { "Fiziksel Disk S.M.A.R.T. Durumu" } else { "Physical Disk S.M.A.R.T. Health" }
                    $hdr.FontSize = 12.5
                    $hdr.FontWeight = "SemiBold"
                    $hdr.Margin = New-Object Windows.Thickness(0,4,0,5)
                    $hdr.Opacity = 0.85
                    $hdr.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
                    [void]$sync.WPFSysDrivesList.Children.Add($hdr)

                    foreach ($pd in $Snap.PhysicalDisks) {
                        $pCard = New-Object Windows.Controls.Border
                        $pCard.CornerRadius = New-Object Windows.CornerRadius(6)
                        $pCard.BorderThickness = New-Object Windows.Thickness(1)
                        $pCard.Padding = New-Object Windows.Thickness(9,6,9,6)
                        $pCard.Margin = New-Object Windows.Thickness(0,0,0,5)
                        $pCard.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, "MainBackgroundColor")
                        $pCard.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, "BorderColor")

                        $pSp = New-Object Windows.Controls.StackPanel
                        $pName = New-Object Windows.Controls.TextBlock
                        $pName.Text = "$($pd.Name) ($($pd.SizeGB) GB - $($pd.Media))"
                        $pName.FontSize = 12
                        $pName.FontWeight = "SemiBold"
                        $pName.TextWrapping = "Wrap"
                        $pName.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                        $metaParts = @($pd.Health)
                        if ($pd.Temp) { $metaParts += $pd.Temp }
                        if ($pd.Wear) { $metaParts += $pd.Wear }
                        $pMeta = New-Object Windows.Controls.TextBlock
                        $pMeta.Text = $metaParts -join " | "
                        $pMeta.FontSize = 11.5
                        $pMeta.Opacity = 0.8
                        $pMeta.Margin = New-Object Windows.Thickness(0,2,0,0)
                        $pMeta.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

                        [void]$pSp.Children.Add($pName)
                        [void]$pSp.Children.Add($pMeta)
                        $pCard.Child = $pSp
                        [void]$sync.WPFSysDrivesList.Children.Add($pCard)
                    }
                }
            }

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
            "WPFSysToggleGameMode" {
                $v = if ($Enabled) { 1 } else { 0 }
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value $v -Type DWord
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value $v -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Windows Oyun Modu güncellendi." } else { "Windows Game Mode updated." })
            }
            "WPFSysToggleWindowedGames" {
                $dxPath = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
                $cur = [string](Get-WinUtilSysRegValue -Path $dxPath -Name 'DirectXUserGlobalSettings')
                $parts = @($cur -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and ($_ -notmatch '^SwapEffectUpgradeEnable=') })
                $parts += "SwapEffectUpgradeEnable=$(if ($Enabled) { 1 } else { 0 })"
                $newVal = ($parts -join ';') + ';'
                Set-WinUtilSysRegValue -Path $dxPath -Name 'DirectXUserGlobalSettings' -Value $newVal -Type String
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Pencereli oyun optimizasyonu güncellendi." } else { "Windowed games optimization updated." })
            }
            "WPFSysToggleMPO" {
                $dwmPath = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'
                if ($Enabled) {
                    Set-WinUtilSysRegValue -Path $dwmPath -Name 'OverlayTestMode' -Remove
                } else {
                    Set-WinUtilSysRegValue -Path $dwmPath -Name 'OverlayTestMode' -Value 5 -Type DWord
                }
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Multi-Plane Overlay (MPO) güncellendi. Etkili olması için yeniden başlatın." } else { "Multi-Plane Overlay (MPO) updated. Restart Windows to apply." })
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
            "WPFSysToggleHibernation" {
                $arg = if ($Enabled) { "on" } else { "off" }
                & powercfg.exe /h $arg 2>&1 | Out-Null
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Hazırda bekletme (hiberfil.sys) $(if ($Enabled) { 'etkinleştirildi' } else { 'kapatıldı' })." } else { "Hibernation (hiberfil.sys) $(if ($Enabled) { 'enabled' } else { 'disabled' })." })
                Start-WinUtilSystemHealthRefresh
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
            "WPFSysToggleOpenThisPC" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value $(if ($Enabled) { 1 } else { 2 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Dosya Gezgini başlangıç konumu güncellendi." } else { "File Explorer startup target updated." })
            }
            "WPFSysToggleFileExt" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value $(if ($Enabled) { 0 } else { 1 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Dosya uzantıları görünürlüğü güncellendi." } else { "File extensions visibility updated." })
            }
            "WPFSysToggleHiddenFiles" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value $(if ($Enabled) { 1 } else { 2 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Gizli dosya görünürlüğü güncellendi." } else { "Hidden files visibility updated." })
            }
            "WPFSysToggleClassicMenu" {
                $clsidKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
                if ($Enabled) {
                    New-Item -Path "$clsidKey\InprocServer32" -Force | Out-Null
                    Set-ItemProperty -LiteralPath "$clsidKey\InprocServer32" -Name '(default)' -Value '' -Force
                } else {
                    if (Test-Path -LiteralPath $clsidKey) {
                        Remove-Item -LiteralPath $clsidKey -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                Invoke-WinUtilExplorerUpdate -action "restart"
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Sağ tık menüsü güncellendi ve Dosya Gezgini yenilendi." } else { "Context menu updated and Explorer restarted." })
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
            "WPFSysToggleClipboard" {
                Set-WinUtilSysRegValue -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value $(if ($Enabled) { 1 } else { 0 }) -Type DWord
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Pano geçmişi (Win+V) güncellendi." } else { "Clipboard history (Win+V) updated." })
            }
        }
    } catch {
        Write-WinUtilLog -Level "ERROR" -Component "SystemHealth" -Message "Toggle $Name failed: $($_.Exception.Message)"
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "Hata: $($_.Exception.Message)" } else { "Error: $($_.Exception.Message)" })
    }
}

function Set-WinUtilQuickDns {
    param([string]$Provider)
    $isTr = ($sync.Language -eq "tr")
    try {
        $ifaces = @(Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway -ne $null })
        if ($ifaces.Count -eq 0) {
            $ifaces = @(Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' })
        }
        if ($ifaces.Count -eq 0) {
            Set-WinUtilSystemHealthStatus $(if ($isTr) { "Aktif ağ bağdaştırıcısı bulunamadı." } else { "No active network adapter found." })
            return
        }

        $servers = switch ($Provider) {
            "Cloudflare" { @("1.1.1.1", "1.0.0.1") }
            "Google"     { @("8.8.8.8", "8.8.4.4") }
            "AdGuard"    { @("94.140.14.14", "94.140.15.15") }
            "Quad9"      { @("9.9.9.9", "149.112.112.112") }
            default      { $null }
        }

        foreach ($if in $ifaces) {
            if ($null -eq $servers) {
                Set-DnsClientServerAddress -InterfaceIndex $if.InterfaceIndex -ResetServerAddresses -ErrorAction Stop
            } else {
                Set-DnsClientServerAddress -InterfaceIndex $if.InterfaceIndex -ServerAddresses $servers -ErrorAction Stop
            }
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        $dnsInfo = Get-WinUtilActiveNetworkInfo
        Invoke-WPFUIThread -Async -Parameters @{ Info = $dnsInfo } -ScriptBlock {
            param($Info)
            if ($sync.WPFSysValActiveDns) { $sync.WPFSysValActiveDns.Text = $Info }
        }
        $label = if ($null -eq $servers) { if ($isTr) { "Otomatik (DHCP)" } else { "Auto (DHCP)" } } else { "$Provider ($($servers -join ', '))" }
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "DNS başarıyla değiştirildi: $label" } else { "DNS updated successfully: $label" })
    } catch {
        Set-WinUtilSystemHealthStatus $(if ($isTr) { "DNS değiştirilemedi: $($_.Exception.Message)" } else { "Failed to set DNS: $($_.Exception.Message)" })
    }
}

function Invoke-WinUtilSystemHealthAction {
    param([Parameter(Mandatory)][string]$Action)

    $isTr = ($sync.Language -eq "tr")

    switch ($Action) {
        "BatteryReport" {
            try {
                $reportPath = Join-Path $env:TEMP "WinUtil-BatteryReport.html"
                & powercfg.exe /batteryreport /output "$reportPath" 2>&1 | Out-Null
                if (Test-Path -LiteralPath $reportPath) {
                    Start-Process $reportPath
                    Set-WinUtilSystemHealthStatus $(if ($isTr) { "HTML Pil Raporu oluşturuldu ve tarayıcıda açıldı." } else { "HTML Battery Report generated and opened in browser." })
                } else {
                    Set-WinUtilSystemHealthStatus $(if ($isTr) { "Bu bilgisayarda pil bulunmadığı için pil raporu oluşturulamadı." } else { "No battery detected on this PC; battery report could not be generated." })
                }
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Pil raporu hatası: $($_.Exception.Message)" } else { "Battery report error: $($_.Exception.Message)" })
            }
        }
        "ApplyPowerPlan" {
            try {
                $selected = $sync.WPFSysPowerPlanCombo.SelectedItem
                if (-not $selected) { return }
                $tag = [string]$selected.Tag
                $guid = switch ($tag) {
                    "Balanced"   { "381b4222-f694-41f0-9685-ff5bb260df2e" }
                    "HighPerf"   { "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
                    "PowerSaver" { "a1841308-58c1-4feb-b9df-851c3aa579f7" }
                    "Ultimate"   { "e9a42b02-d5df-448d-aa00-03f14749eb61" }
                }
                $listOut = (& powercfg.exe /list 2>$null) -join "`n"
                if ($tag -eq "Ultimate" -and $listOut -notmatch $guid) {
                    $dup = (& powercfg.exe -duplicatescheme $guid 2>$null) -join " "
                    if ($dup -match '([0-9a-fA-F-]{36})') { $guid = $matches[1] }
                } elseif ($listOut -notmatch $guid) {
                    $dup = (& powercfg.exe -duplicatescheme $guid 2>$null) -join " "
                    if ($dup -match '([0-9a-fA-F-]{36})') { $guid = $matches[1] }
                }
                & powercfg.exe /setactive $guid 2>&1 | Out-Null
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Güç planı uygulandı: $($selected.Content)" } else { "Power plan applied: $($selected.Content)" })
                Start-WinUtilSystemHealthRefresh
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Güç planı uygulanamadı: $($_.Exception.Message)" } else { "Failed to apply power plan: $($_.Exception.Message)" })
            }
        }
        "CleanRam" {
            try {
                $before = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).FreePhysicalMemory
                if (-not ("WinUtilMemHelper" -as [type])) {
                    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class WinUtilMemHelper {
    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@ -ErrorAction SilentlyContinue
                }
                if ("WinUtilMemHelper" -as [type]) {
                    Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
                        try { [void][WinUtilMemHelper]::EmptyWorkingSet($_.Handle) } catch {}
                    }
                }
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                Start-Sleep -Milliseconds 350
                $after = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).FreePhysicalMemory
                $freedMB = if ($after -gt $before) { [math]::Round(($after - $before) / 1024, 0) } else { 0 }
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "RAM çalışma kümeleri temizlendi: ~$freedMB MB bellek serbest bırakıldı." } else { "RAM working sets trimmed: ~$freedMB MB memory freed." })
                Start-WinUtilSystemHealthRefresh
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "RAM temizleme hatası: $($_.Exception.Message)" } else { "RAM cleanup error: $($_.Exception.Message)" })
            }
        }
        "RestartGpu" {
            try {
                if (-not ("WinUtilGpuKeyHelper" -as [type])) {
                    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class WinUtilGpuKeyHelper {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public static void TriggerGpuRestart() {
        const uint KEYEVENTF_KEYUP = 0x0002;
        byte[] keys = new byte[] { 0x5B, 0x11, 0x10, 0x42 }; // LWin, Ctrl, Shift, B
        for (int i = 0; i < keys.Length; i++) keybd_event(keys[i], 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(60);
        for (int i = keys.Length - 1; i >= 0; i--) keybd_event(keys[i], 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }
}
"@ -ErrorAction Stop
                }
                [WinUtilGpuKeyHelper]::TriggerGpuRestart()
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "GPU sürücüsü yenileme kısayolu (Win+Ctrl+Shift+B) gönderildi." } else { "GPU driver reset shortcut (Win+Ctrl+Shift+B) triggered." })
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "GPU yenileme hatası: $($_.Exception.Message)" } else { "GPU reset error: $($_.Exception.Message)" })
            }
        }
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
        "DnsAuto"       { Set-WinUtilQuickDns -Provider "Auto" }
        "DnsCloudflare" { Set-WinUtilQuickDns -Provider "Cloudflare" }
        "DnsGoogle"     { Set-WinUtilQuickDns -Provider "Google" }
        "DnsAdGuard"    { Set-WinUtilQuickDns -Provider "AdGuard" }
        "DnsQuad9"      { Set-WinUtilQuickDns -Provider "Quad9" }
        "PingTest" {
            Set-WinUtilSystemHealthStatus $(if ($isTr) { "Canlı DNS ping testi çalışıyor..." } else { "Running live DNS ping test..." })
            $jobName = if ($isTr) { "Canlı Ping Testi" } else { "Live Ping Test" }
            $jobDesc = if ($isTr) { "DNS sunucularına gecikme ölçülüyor" } else { "Measuring latency to DNS providers" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                $hosts = @(
                    @{ Label = "Cloudflare (1.1.1.1)"; IP = "1.1.1.1" },
                    @{ Label = "Google (8.8.8.8)";     IP = "8.8.8.8" },
                    @{ Label = "AdGuard (94.140.14.14)"; IP = "94.140.14.14" },
                    @{ Label = "Quad9 (9.9.9.9)";      IP = "9.9.9.9" }
                )
                $ping = New-Object System.Net.NetworkInformation.Ping
                $results = @()
                $best = $null
                $i = 0
                foreach ($h in $hosts) {
                    $i++
                    Step-WinUtilJob -Status "$($h.Label)..." -Percent ([int](($i / $hosts.Count) * 100))
                    $times = @()
                    for ($t = 0; $t -lt 2; $t++) {
                        try {
                            $rep = $ping.Send($h.IP, 1500)
                            if ($rep.Status -eq "Success") { $times += $rep.RoundtripTime }
                        } catch {}
                    }
                    if ($times.Count -gt 0) {
                        $avg = [math]::Round(($times | Measure-Object -Average).Average, 0)
                        $results += "$($h.Label): ${avg} ms"
                        if ($null -eq $best -or $avg -lt $best.Ms) {
                            $best = @{ Label = $h.Label; Ms = $avg }
                        }
                    } else {
                        $results += "$($h.Label): " + $(if ($IsTr) { "Zaman aşımı" } else { "Timeout" })
                    }
                }
                $ping.Dispose()
                $summary = ($results -join "`n")
                if ($best) {
                    $bestLine = if ($IsTr) { "`nEn hızlı: $($best.Label) ($($best.Ms) ms)" } else { "`nFastest: $($best.Label) ($($best.Ms) ms)" }
                    $summary += $bestLine
                }
                Invoke-WPFUIThread -Async -Parameters @{ Res = $summary } -ScriptBlock {
                    param($Res)
                    if ($sync.WPFSysValPingResult) { $sync.WPFSysValPingResult.Text = $Res }
                }
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "Canlı DNS ping testi tamamlandı." } else { "Live DNS ping test completed." })
            }
        }
        "NetReset" {
            $jobName = if ($isTr) { "Ağ Sıfırlama" } else { "Network Reset" }
            $jobDesc = if ($isTr) { "Winsock, TCP/IP ve DNS önbelleği sıfırlanıyor" } else { "Resetting Winsock, TCP/IP and DNS cache" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                Step-WinUtilJob -Status "Winsock reset..." -Percent 25
                & netsh.exe winsock reset 2>&1 | Out-Null
                Step-WinUtilJob -Status "TCP/IP reset..." -Percent 55
                & netsh.exe int ip reset 2>&1 | Out-Null
                Step-WinUtilJob -Status "DNS flush..." -Percent 85
                & ipconfig.exe /flushdns 2>&1 | Out-Null
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "Ağ yığını sıfırlandı (tam etki için bilgisayarı yeniden başlatın)." } else { "Network stack reset (restart PC for full effect)." })
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
        "BrowserClean" {
            $jobName = if ($isTr) { "Tarayıcı Önbellek Temizliği" } else { "Browser Cache Cleanup" }
            $jobDesc = if ($isTr) { "Tarayıcı önbellekleri temizleniyor (şifreler korunur)" } else { "Cleaning browser caches (passwords preserved)" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                $chromiumRoots = @(
                    "$env:LocalAppData\Google\Chrome\User Data",
                    "$env:LocalAppData\Microsoft\Edge\User Data",
                    "$env:LocalAppData\BraveSoftware\Brave-Browser\User Data",
                    "$env:LocalAppData\Vivaldi\User Data"
                )
                $cacheDirs = New-Object System.Collections.ArrayList
                foreach ($root in $chromiumRoots) {
                    if (Test-Path -LiteralPath $root) {
                        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile *" } | ForEach-Object {
                            foreach ($sub in @("Cache\Cache_Data", "Code Cache", "GPUCache")) {
                                $p = Join-Path $_.FullName $sub
                                if (Test-Path -LiteralPath $p) { [void]$cacheDirs.Add($p) }
                            }
                        }
                    }
                }
                # Opera / Opera GX
                foreach ($op in @("$env:LocalAppData\Opera Software\Opera Stable\Cache", "$env:LocalAppData\Opera Software\Opera GX Stable\Cache")) {
                    if (Test-Path -LiteralPath $op) { [void]$cacheDirs.Add($op) }
                }
                # Firefox
                $ffRoot = "$env:LocalAppData\Mozilla\Firefox\Profiles"
                if (Test-Path -LiteralPath $ffRoot) {
                    Get-ChildItem -LiteralPath $ffRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        $p = Join-Path $_.FullName "cache2"
                        if (Test-Path -LiteralPath $p) { [void]$cacheDirs.Add($p) }
                    }
                }

                $freedBytes = [int64]0
                $idx = 0
                $total = [math]::Max(1, $cacheDirs.Count)
                foreach ($dir in $cacheDirs) {
                    $idx++
                    Step-WinUtilJob -Status $(if ($IsTr) { "Önbellek temizleniyor ($idx/$total)..." } else { "Cleaning cache ($idx/$total)..." }) -Percent ([int](($idx / $total) * 100))
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
                $freedMB = [math]::Round($freedBytes / 1MB, 1)
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "Tarayıcı önbellek temizliği tamamlandı: ~$freedMB MB serbest bırakıldı (şifre ve oturumlar korundu)." } else { "Browser cache cleanup done: ~$freedMB MB freed (passwords & sessions kept)." })
                Update-WinUtilSystemHealthUI
            }
        }
        "CleanWinUpdate" {
            $jobName = if ($isTr) { "Windows Update Önbellek Temizliği" } else { "Windows Update Cache Cleanup" }
            $jobDesc = if ($isTr) { "SoftwareDistribution indirme önbelleği temizleniyor" } else { "Cleaning SoftwareDistribution download cache" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                $dlPath = "$env:SystemRoot\SoftwareDistribution\Download"
                Step-WinUtilJob -Status $(if ($IsTr) { "Windows Update hizmetleri durduruluyor..." } else { "Stopping Windows Update services..." }) -Percent 20
                Stop-Service -Name wuauserv, bits -Force -ErrorAction SilentlyContinue
                $freedBytes = [int64]0
                Step-WinUtilJob -Status $(if ($IsTr) { "SoftwareDistribution\Download temizleniyor..." } else { "Cleaning SoftwareDistribution\Download..." }) -Percent 60
                if (Test-Path -LiteralPath $dlPath) {
                    Get-ChildItem -LiteralPath $dlPath -Force -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            $len = if ($_.PSIsContainer) {
                                (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                            } else { $_.Length }
                            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                            if ($len) { $freedBytes += [int64]$len }
                        } catch {}
                    }
                }
                Step-WinUtilJob -Status $(if ($IsTr) { "Windows Update hizmetleri yeniden başlatılıyor..." } else { "Restarting Windows Update services..." }) -Percent 90
                Start-Service -Name bits, wuauserv -ErrorAction SilentlyContinue
                $freedMB = [math]::Round($freedBytes / 1MB, 1)
                Set-WinUtilSystemHealthStatus $(if ($IsTr) { "Windows Update indirme önbelleği temizlendi: ~$freedMB MB yer açıldı." } else { "Windows Update download cache cleaned: ~$freedMB MB freed." })
                Update-WinUtilSystemHealthUI
            }
        }
        "CleanDrivers" {
            $jobName = if ($isTr) { "Eski Sürücü Temizliği" } else { "Old Driver Store Cleanup" }
            $jobDesc = if ($isTr) { "Kullanılmayan eski sürücü paketleri taranıyor" } else { "Scanning superseded driver packages" }
            Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{ IsTr = $isTr } -ScriptBlock {
                param($IsTr)
                Step-WinUtilJob -Status $(if ($IsTr) { "DriverStore paketleri analiz ediliyor..." } else { "Analyzing DriverStore packages..." }) -Percent 25
                $raw = (& pnputil.exe /enum-drivers 2>$null) -join "`n"
                $blocks = $raw -split "(`r?`n){2,}"
                $parsed = @()
                foreach ($b in $blocks) {
                    $pub = $null; $orig = $null; $ver = $null; $dt = $null
                    if ($b -match '(?:Published Name|Yayımlanan Ad)[^:]*:\s*(oem\d+\.inf)') { $pub = $matches[1] }
                    if ($b -match '(?:Original Name|Özgün Ad)[^:]*:\s*(\S+)') { $orig = $matches[1].ToLowerInvariant() }
                    if ($b -match '(?:Driver Version|Sürücü Sürümü)[^:]*:\s*(\d{2}/\d{2}/\d{4})\s+([\d\.]+)') {
                        $dt = $matches[1]; $ver = $matches[2]
                    }
                    if ($pub -and $orig -and $ver) {
                        $parsedVer = $null
                        if (-not [version]::TryParse($ver, [ref]$parsedVer)) {
                            $parts = @($ver -split '\.' | Select-Object -First 4)
                            while ($parts.Count -lt 2) { $parts += "0" }
                            $null = [version]::TryParse(($parts -join '.'), [ref]$parsedVer)
                        }
                        if ($null -eq $parsedVer) { $parsedVer = [version]"0.0" }
                        $parsed += [pscustomobject]@{ Published = $pub; Original = $orig; Version = $parsedVer }
                    }
                }
                $removed = 0
                $groups = @($parsed | Group-Object Original | Where-Object { $_.Count -gt 1 })
                $gIdx = 0
                foreach ($g in $groups) {
                    $gIdx++
                    Step-WinUtilJob -Status $(if ($IsTr) { "Eski sürücüler temizleniyor ($gIdx/$($groups.Count))..." } else { "Cleaning old drivers ($gIdx/$($groups.Count))..." }) -Percent ([int](30 + ($gIdx / [math]::Max(1,$groups.Count)) * 65))
                    $older = @($g.Group | Sort-Object Version -Descending | Select-Object -Skip 1)
                    foreach ($old in $older) {
                        & pnputil.exe /delete-driver $old.Published 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) { $removed++ }
                    }
                }
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "DriverStore taraması tamamlandı: $removed eski kullanılmayan sürücü paketi temizlendi." } else { "DriverStore scan finished: $removed old unused driver package(s) removed." })
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
        "RepairIcons" {
            try {
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 600
                Remove-Item -LiteralPath "$env:LocalAppData\IconCache.db" -Force -ErrorAction SilentlyContinue
                Get-ChildItem -LiteralPath "$env:LocalAppData\Microsoft\Windows\Explorer" -Filter "iconcache_*.db" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Start-Process "explorer.exe"
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Masaüstü simge önbelleği sıfırlandı ve Dosya Gezgini yeniden başlatıldı." } else { "Desktop icon cache rebuilt and Explorer restarted." })
            } catch {
                Start-Process "explorer.exe" -ErrorAction SilentlyContinue
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Simge önbelleği onarım hatası: $($_.Exception.Message)" } else { "Icon cache repair error: $($_.Exception.Message)" })
            }
        }
        "GodMode" {
            try {
                $desktop = [Environment]::GetFolderPath("Desktop")
                $folderName = if ($isTr) { "Tanri Modu.{ED7BA470-8E54-465E-825C-99712043E01C}" } else { "God Mode.{ED7BA470-8E54-465E-825C-99712043E01C}" }
                $fullPath = Join-Path $desktop $folderName
                if (-not (Test-Path -LiteralPath $fullPath)) {
                    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                }
                Start-Process "explorer.exe" -ArgumentList "`"$fullPath`""
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Masaüstünde 'Tanrı Modu' (God Mode) klasörü oluşturuldu ve açıldı." } else { "'God Mode' folder created on Desktop and opened." })
            } catch {
                Set-WinUtilSystemHealthStatus $(if ($isTr) { "Tanrı Modu oluşturulamadı: $($_.Exception.Message)" } else { "Failed to create God Mode folder: $($_.Exception.Message)" })
            }
        }
    }
}

function Initialize-WinUtilSystemHealthHandlers {
    if ($sync.SysHealthHandlersWired) { return }
    $sync.SysHealthHandlersWired = $true

    if ($sync.WPFSysRefreshBtn) {
        $sync.WPFSysRefreshBtn.Add_Click({
            Start-WinUtilSystemHealthRefresh
            if ($sync.SysHealthActiveSubTab -eq "Startup") {
                Start-WinUtilStartupRefresh
            }
        })
    }

    if ($sync.WPFSysBtnRefreshStartup) {
        $sync.WPFSysBtnRefreshStartup.Add_Click({ Start-WinUtilStartupRefresh })
    }

    # Sub-Tab Switch Buttons
    $subMap = @{
        WPFSysSubBtnOverview = "Overview"
        WPFSysSubBtnBoost    = "Boost"
        WPFSysSubBtnClean    = "Clean"
        WPFSysSubBtnStartup  = "Startup"
    }
    foreach ($kv in $subMap.GetEnumerator()) {
        if ($sync[$kv.Key]) {
            $sync[$kv.Key].Tag = $kv.Value
            $sync[$kv.Key].Add_Click({
                param($sender, $e)
                if (-not $sync.SysHealthSubTabSwitching) {
                    Set-WinUtilSystemHealthSubTab -Tab $sender.Tag
                }
            })
        }
    }

    # All 21 Live Toggle Switches
    $toggleNames = @(
        "WPFSysToggleHAGS", "WPFSysToggleVBS", "WPFSysToggleFastStartup",
        "WPFSysToggleGameMode", "WPFSysToggleWindowedGames", "WPFSysToggleMPO",
        "WPFSysToggleGameDVR", "WPFSysToggleAnimations", "WPFSysToggleTransparency",
        "WPFSysToggleHibernation",
        "WPFSysToggleThisPC", "WPFSysToggleClockSeconds", "WPFSysToggleCompactExplorer",
        "WPFSysToggleOpenThisPC", "WPFSysToggleFileExt", "WPFSysToggleHiddenFiles",
        "WPFSysToggleClassicMenu", "WPFSysToggleShortcutArrow", "WPFSysToggleLockScreenAds",
        "WPFSysToggleWindowsTips", "WPFSysToggleClipboard"
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

    # All Action Buttons
    $actionMap = @{
        WPFSysBtnBatteryReport   = "BatteryReport"
        WPFSysBtnApplyPowerPlan  = "ApplyPowerPlan"
        WPFSysBtnCleanRam        = "CleanRam"
        WPFSysBtnRestartGpu      = "RestartGpu"
        WPFSysBtnRestartExplorer = "RestartExplorer"
        WPFSysBtnFlushDns        = "FlushDns"
        WPFSysBtnQuickClean      = "QuickClean"
        WPFSysBtnBrowserClean    = "BrowserClean"
        WPFSysBtnCleanWinUpdate  = "CleanWinUpdate"
        WPFSysBtnCleanDrivers    = "CleanDrivers"
        WPFSysBtnWinSxS          = "WinSxS"
        WPFSysBtnOptimizeDrive   = "OptimizeDrive"
        WPFSysBtnSystemRepair    = "SystemRepair"
        WPFSysBtnDefenderScan    = "DefenderScan"
        WPFSysBtnStoreReset      = "StoreReset"
        WPFSysBtnRepairIcons     = "RepairIcons"
        WPFSysBtnDnsAuto         = "DnsAuto"
        WPFSysBtnDnsCloudflare   = "DnsCloudflare"
        WPFSysBtnDnsGoogle       = "DnsGoogle"
        WPFSysBtnDnsAdGuard      = "DnsAdGuard"
        WPFSysBtnDnsQuad9        = "DnsQuad9"
        WPFSysBtnPingTest        = "PingTest"
        WPFSysBtnNetReset        = "NetReset"
        WPFSysBtnGodMode         = "GodMode"
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

    # Quick System Admin Tools
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
