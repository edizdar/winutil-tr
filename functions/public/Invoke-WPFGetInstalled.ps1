function Invoke-WPFGetInstalled {
    <#
    .SYNOPSIS
        Detects what is already installed or applied and ticks the matching boxes

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)

    if (($sync.ChocoRadioButton.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }

    $isTr = ($sync.Language -eq "tr")
    $jobName = if ($isTr) { "Yüklü Öğeler" } else { "Installed Items" }
    $jobDesc = if ($isTr) { "Katalogdaki kurulu öğeler taranıyor" } else { "Scanning installed catalog items" }

    Start-WinUtilJob -Name $jobName -Description $jobDesc -Parameters @{
        Checkbox = $checkbox
        ManagerPreference = $sync.preferences.packagemanager
        IsTr = $isTr
    } -ScriptBlock {
        param($Checkbox, $ManagerPreference, $IsTr)

        $stepMsg = if ($IsTr) { "Katalogdaki yüklü öğeler kontrol ediliyor..." } else { "Checking installed catalog items..." }
        Step-WinUtilJob -Status $stepMsg -State "Indeterminate"

        $found = @()
        if ($Checkbox -eq "winget") {
            $source = if ($ManagerPreference -eq "Choco") { "choco" } else { $Checkbox }
            $found = @(Invoke-WinUtilCurrentSystem -CheckBox $source)
        } elseif ($Checkbox -eq "tweaks") {
            $found = @(Get-WinUtilDetectedAppliedTweaks)
        }

        Write-WinUtilLog -Component "Install" -Message "Detected $($found.Count) existing item(s) for $Checkbox."

        # Ticking boxes touches the controls, so it happens on the interface thread
        Invoke-WPFUIThread -Parameters @{ Checkbox = $Checkbox; Found = $found; IsTr = $IsTr } -ScriptBlock {
            param($Checkbox, $Found, $IsTr)

            if ($Checkbox -eq "winget") {
                foreach ($name in $Found) {
                    if (-not $sync.selectedApps.Contains($name)) {
                        $sync.selectedApps.Add($name)
                    }
                }
                Reset-WPFCheckBoxes -checkboxfilterpattern "WPFInstall*"
                $infoMsg = if ($IsTr) {
                    "Katalogdaki uygulamalardan $($Found.Count) tanesi bilgisayarınızda kurulu olarak tespit edildi ve seçildi.`n`nBilgisayarınızdaki TÜM Program Ekle/Kaldır uygulamalarını görüp kayıt defteri + TEMP artıklarıyla birlikte kaldırmak için 'Sistem & Bakım -> Yüklü Programlar' sekmesini kullanabilirsiniz."
                } else {
                    "Detected and selected $($Found.Count) installed catalog application(s) on this PC.`n`nTo view ALL Windows Add/Remove Programs and deep-uninstall them with Registry + TEMP leftovers, use 'System & Health -> Installed Apps'."
                }
                Show-WinUtilMessage -Message $infoMsg -Title (Get-WinUtilString -Key "WindowTitle") -Button "OK" -Icon "Info" | Out-Null
            } else {
                foreach ($name in $Found) {
                    if ($sync.$name) {
                        $sync.$name.ischecked = $true
                    }
                }
            }
        }
    }
}
