function Get-WinUtilSavedLanguagePreference {
    $prefFile = Join-Path $sync.winutildir "language.txt"
    if (Test-Path -LiteralPath $prefFile) {
        try {
            $val = (Get-Content -LiteralPath $prefFile -Raw -Encoding UTF8 -ErrorAction Stop).Trim()
            if ($val -in @("Auto", "tr", "en")) {
                return $val
            }
        } catch {}
    }
    return "Auto"
}

function Save-WinUtilLanguagePreference {
    param([ValidateSet("Auto", "tr", "en")][string]$Preference)
    try {
        if (-not (Test-Path -LiteralPath $sync.winutildir)) {
            New-Item -ItemType Directory -Path $sync.winutildir -Force | Out-Null
        }
        $prefFile = Join-Path $sync.winutildir "language.txt"
        [System.IO.File]::WriteAllText($prefFile, $Preference, [System.Text.UTF8Encoding]::new($false))
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not save language preference: $($_.Exception.Message)"
    }
}

function Get-WinUtilEffectiveLanguage {
    param([string]$Preference = $sync.preferences.language)

    if ($Preference -eq "tr" -or $Preference -eq "en") {
        return $Preference
    }

    try {
        $iso = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
        if ($iso -ieq "tr") {
            return "tr"
        }
    } catch {}

    return "en"
}

function Get-WinUtilString {
    param(
        [Parameter(Mandatory)][string]$Key,
        [object[]]$Args
    )

    $val = $null
    if ($sync -and $sync.Locale -and $sync.Locale.ui) {
        $prop = $sync.Locale.ui.PSObject.Properties[$Key]
        if ($prop) { $val = [string]$prop.Value }
    }
    if ($null -eq $val -and $sync -and $sync.configs -and $sync.configs.locales -and $sync.configs.locales.tr) {
        $prop = $sync.configs.locales.tr.ui.PSObject.Properties[$Key]
        if ($prop) { $val = [string]$prop.Value }
    }
    if ($null -eq $val) { $val = $Key }

    if ($Args -and $Args.Count -gt 0) {
        return ($val -f $Args)
    }
    return $val
}

function Set-WinUtilConfigLocale {
    param([ValidateSet("tr", "en")][string]$Lang)

    if (-not $sync.configs.locales -or -not $sync.configs.locales.$Lang) {
        return
    }

    $pack = $sync.configs.locales.$Lang
    $sync.Language = $Lang
    $sync.Locale = $pack

    # 1. Applications
    if ($pack.applications -and $sync.configs.applications) {
        foreach ($prop in $pack.applications.PSObject.Properties) {
            $target = $sync.configs.applications.PSObject.Properties[$prop.Name]
            if ($target -and $target.Value) {
                $target.Value.category = $prop.Value.category
                $target.Value.content = $prop.Value.content
                $target.Value.description = $prop.Value.description
            }
        }
        $sync.configs.applicationsHashtable = @{}
        $sync.configs.applications.PSObject.Properties | ForEach-Object {
            $sync.configs.applicationsHashtable[$_.Name] = $_.Value
        }
    }

    # 2. App Navigation
    if ($pack.appnavigation -and $sync.configs.appnavigation) {
        foreach ($prop in $pack.appnavigation.PSObject.Properties) {
            $target = $sync.configs.appnavigation.PSObject.Properties[$prop.Name]
            if ($target -and $target.Value) {
                $target.Value.Content = $prop.Value.Content
                $target.Value.Category = $prop.Value.Category
                $target.Value.Description = $prop.Value.Description
            }
        }
    }

    # 3. AppX
    if ($pack.appx -and $sync.configs.appx) {
        foreach ($prop in $pack.appx.PSObject.Properties) {
            $target = $sync.configs.appx.PSObject.Properties[$prop.Name]
            if ($target -and $target.Value) {
                $target.Value.Category = $prop.Value.Category
                $target.Value.Content = $prop.Value.Content
                $target.Value.Description = $prop.Value.Description
            }
        }
        $sync.configs.appxHashtable = @{}
        $sync.configs.appx.PSObject.Properties | ForEach-Object {
            $sync.configs.appxHashtable[$_.Name] = $_.Value
        }
    }

    # 4. Feature (Config tab)
    if ($pack.feature -and $sync.configs.feature) {
        foreach ($prop in $pack.feature.PSObject.Properties) {
            $target = $sync.configs.feature.PSObject.Properties[$prop.Name]
            if ($target -and $target.Value) {
                $target.Value.Content = $prop.Value.Content
                $target.Value.category = $prop.Value.category
                if ($prop.Value.PSObject.Properties["Description"]) {
                    if ($target.Value.PSObject.Properties["Description"]) {
                        $target.Value.Description = $prop.Value.Description
                    } else {
                        $target.Value | Add-Member -NotePropertyName "Description" -NotePropertyValue $prop.Value.Description -Force
                    }
                }
            }
        }
    }

    # 5. Tweaks
    if ($pack.tweaks -and $sync.configs.tweaks) {
        foreach ($prop in $pack.tweaks.PSObject.Properties) {
            $target = $sync.configs.tweaks.PSObject.Properties[$prop.Name]
            if ($target -and $target.Value) {
                $target.Value.Content = $prop.Value.Content
                $target.Value.category = $prop.Value.category
                if ($prop.Value.PSObject.Properties["Description"]) {
                    if ($target.Value.PSObject.Properties["Description"]) {
                        $target.Value.Description = $prop.Value.Description
                    } else {
                        $target.Value | Add-Member -NotePropertyName "Description" -NotePropertyValue $prop.Value.Description -Force
                    }
                }
                if ($prop.Value.PSObject.Properties["ComboItems"]) {
                    $target.Value.ComboItems = $prop.Value.ComboItems
                }
                if ($prop.Value.PSObject.Properties["ComboDescriptions"]) {
                    $target.Value.ComboDescriptions = $prop.Value.ComboDescriptions
                }
                if ($prop.Name -eq "WPFMultiplaneOverlay" -and $prop.Value.ValuesOrder -and $target.Value.registry) {
                    $newKeys = @($prop.Value.ValuesOrder)
                    foreach ($reg in $target.Value.registry) {
                        if ($reg.Values) {
                            $oldVals = @($reg.Values.PSObject.Properties | ForEach-Object { $_.Value })
                            if ($oldVals.Count -eq $newKeys.Count) {
                                $rebuilt = [ordered]@{}
                                for ($i = 0; $i -lt $newKeys.Count; $i++) {
                                    $rebuilt[$newKeys[$i]] = $oldVals[$i]
                                }
                                $reg.Values = [pscustomobject]$rebuilt
                            }
                        }
                    }
                }
            }
        }
    }
}

function Initialize-WinUtilLanguage {
    $pref = Get-WinUtilSavedLanguagePreference
    $sync.preferences.language = $pref
    $effective = Get-WinUtilEffectiveLanguage -Preference $pref
    Set-WinUtilConfigLocale -Lang $effective
    Write-WinUtilLog -Component "UI" -Message "Language initialized: preference=$pref, effective=$effective (system UI=$([System.Globalization.CultureInfo]::CurrentUICulture.Name))"
}

function Set-WinUtilNamedControlText {
    param([string]$Name, [string]$Value, [string]$Property = "Text")
    $ctrl = $sync[$Name]
    if ($null -eq $ctrl -and $sync.Form) {
        $ctrl = $sync.Form.FindName($Name)
    }
    if ($null -ne $ctrl) {
        $ctrl.$Property = $Value
    }
}

function Apply-WinUtilLanguageToUI {
    if ($null -eq $sync.Form -or $null -eq $sync.Locale) { return }

    $ui = $sync.Locale.ui
    $pref = $sync.preferences.language

    $sync.Form.Title = $ui.WindowTitle
    try { $Host.UI.RawUI.WindowTitle = $ui.WindowTitle } catch {}

    # Top bar & nav
    Set-WinUtilNamedControlText -Name "WPFOfflineBannerText" -Value $ui.OfflineBanner -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFNavTab1Text" -Value $ui.NavTab1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFNavTab2Text" -Value $ui.NavTab2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFNavTab3Text" -Value $ui.NavTab3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFNavTab4Text" -Value $ui.NavTab4 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFNavTab5Text" -Value $ui.NavTab5 -Property "Text"
    if ($PARAM_OFFLINE -and $sync.WPFTab1BT) {
        $sync.WPFTab1BT.ToolTip = $ui.OfflineInstallTooltip
    }

    Set-WinUtilNamedControlText -Name "SearchBar" -Value $ui.SearchBarToolTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "JobQueueButton" -Value $ui.JobQueueToolTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "ThemeButton" -Value $ui.ThemeButtonToolTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "AutoThemeMenuItem" -Value $ui.AutoThemeHeader -Property "Header"
    Set-WinUtilNamedControlText -Name "DarkThemeMenuItem" -Value $ui.DarkThemeHeader -Property "Header"
    Set-WinUtilNamedControlText -Name "LightThemeMenuItem" -Value $ui.LightThemeHeader -Property "Header"
    if ($sync.AutoThemeMenuItem -and $sync.AutoThemeMenuItem.ToolTip) { $sync.AutoThemeMenuItem.ToolTip.Content = $ui.AutoThemeTip }
    if ($sync.DarkThemeMenuItem -and $sync.DarkThemeMenuItem.ToolTip) { $sync.DarkThemeMenuItem.ToolTip.Content = $ui.DarkThemeTip }
    if ($sync.LightThemeMenuItem -and $sync.LightThemeMenuItem.ToolTip) { $sync.LightThemeMenuItem.ToolTip.Content = $ui.LightThemeTip }

    # Font Scaling popup
    Set-WinUtilNamedControlText -Name "FontScalingButton" -Value $ui.FontScalingToolTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "WPFFontScalingTitle" -Value $ui.FontScalingTitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFFontSmall" -Value $ui.FontSmall -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFFontLarge" -Value $ui.FontLarge -Property "Text"
    Set-WinUtilNamedControlText -Name "FontScalingResetButton" -Value $ui.FontReset -Property "Content"
    Set-WinUtilNamedControlText -Name "FontScalingApplyButton" -Value $ui.FontApply -Property "Content"

    # Settings menu & Language items
    Set-WinUtilNamedControlText -Name "SettingsButton" -Value $ui.SettingsToolTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "ImportMenuItem" -Value $ui.ImportHeader -Property "Header"
    Set-WinUtilNamedControlText -Name "ExportMenuItem" -Value $ui.ExportHeader -Property "Header"
    Set-WinUtilNamedControlText -Name "ExportEnvironmentReportMenuItem" -Value $ui.EnvReportHeader -Property "Header"
    if ($sync.ImportMenuItem -and $sync.ImportMenuItem.ToolTip) { $sync.ImportMenuItem.ToolTip.Content = $ui.ImportTip }
    if ($sync.ExportMenuItem -and $sync.ExportMenuItem.ToolTip) { $sync.ExportMenuItem.ToolTip.Content = $ui.ExportTip }
    if ($sync.ExportEnvironmentReportMenuItem -and $sync.ExportEnvironmentReportMenuItem.ToolTip) { $sync.ExportEnvironmentReportMenuItem.ToolTip.Content = $ui.EnvReportTip }

    $chk = "$([char]0x2713) "
    $pad = "   "
    $autoPrefix = if ($pref -eq "Auto") { $chk } else { $pad }
    $trPrefix   = if ($pref -eq "tr")   { $chk } else { $pad }
    $enPrefix   = if ($pref -eq "en")   { $chk } else { $pad }
    Set-WinUtilNamedControlText -Name "LangAutoMenuItem" -Value ($autoPrefix + $ui.LangAutoHeader) -Property "Header"
    Set-WinUtilNamedControlText -Name "LangTrMenuItem" -Value ($trPrefix + $ui.LangTrHeader) -Property "Header"
    Set-WinUtilNamedControlText -Name "LangEnMenuItem" -Value ($enPrefix + $ui.LangEnHeader) -Property "Header"
    if ($sync.LangAutoMenuItem -and $sync.LangAutoMenuItem.ToolTip) { $sync.LangAutoMenuItem.ToolTip.Content = $ui.LangAutoTip }

    Set-WinUtilNamedControlText -Name "AboutMenuItem" -Value $ui.AboutHeader -Property "Header"
    Set-WinUtilNamedControlText -Name "WPFMinimizeButton" -Value $ui.MinimizeTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "WPFCloseButton" -Value $ui.CloseTip -Property "ToolTip"

    # Install tab chips & tags
    Set-WinUtilNamedControlText -Name "WPFFilterIcon" -Value $ui.FilterChipTip -Property "ToolTip"
    $chipMap = @(
        @{ Name = "WPFSearchChipAll";             Label = $ui.ChipAll;              Category = "" }
        @{ Name = "WPFSearchChipBrowsers";        Label = $ui.ChipBrowsers;         Category = $ui.ChipBrowsers }
        @{ Name = "WPFSearchChipCommunications";  Label = $ui.ChipCommunications;   Category = $ui.ChipCommunications }
        @{ Name = "WPFSearchChipDevelopment";     Label = $ui.ChipDevelopment;      Category = $ui.ChipDevelopment }
        @{ Name = "WPFSearchChipDocument";        Label = $ui.ChipDocument;         Category = $ui.ChipDocument }
        @{ Name = "WPFSearchChipGames";           Label = $ui.ChipGames;            Category = $ui.ChipGames }
        @{ Name = "WPFSearchChipMicrosoftTools";  Label = $ui.ChipMicrosoftTools;   Category = $ui.ChipMicrosoftTools }
        @{ Name = "WPFSearchChipMultimediaTools"; Label = $ui.ChipMultimediaTools;  Category = $ui.ChipMultimediaTools }
        @{ Name = "WPFSearchChipProTools";        Label = $ui.ChipProTools;         Category = $ui.ChipProTools }
        @{ Name = "WPFSearchChipSelfhostedTools"; Label = $ui.ChipSelfhostedTools;  Category = $ui.ChipSelfhostedTools }
        @{ Name = "WPFSearchChipUtilities";       Label = $ui.ChipUtilities;        Category = $ui.ChipUtilities }
    )
    $sync.AppCategoryChips = $chipMap
    foreach ($chip in $chipMap) {
        if ($sync[$chip.Name]) {
            $sync[$chip.Name].Content = $chip.Label
            $sync[$chip.Name].Tag = $chip.Category
        }
    }
    Set-WinUtilNamedControlText -Name "WPFInstallWorkingLabel" -Value $ui.InstallWorkingLabel -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFInstallWorkingSubLabel" -Value $ui.WorkingSubLabel -Property "Text"

    # Tweaks tab
    Set-WinUtilNamedControlText -Name "WPFTweaksRecommendedLabel" -Value $ui.TweaksRecommendedLabel -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFstandard" -Value $ui.BtnStandard -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFminimal" -Value $ui.BtnMinimal -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFAdvanced" -Value $ui.BtnAdvanced -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFClearTweaksSelection" -Value $ui.BtnClear -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFGetInstalledTweaks" -Value $ui.BtnGetInstalledTweaks -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFAppxRemoval" -Value $ui.BtnAppxRemoval -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFTweaksNote1" -Value $ui.TweaksNote1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFTweaksNote2" -Value $ui.TweaksNote2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFTweaksbutton" -Value $ui.BtnRunTweaks -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFUndoall" -Value $ui.BtnUndoTweaks -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFTweaksWorkingLabel" -Value $ui.TweaksWorkingLabel -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFTweaksWorkingSubLabel" -Value $ui.WorkingSubLabel -Property "Text"

    # Updates tab
    Set-WinUtilNamedControlText -Name "WPFUpdatesTitle" -Value $ui.UpdatesTitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdatesSubtitle" -Value $ui.UpdatesSubtitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecTitle" -Value $ui.UpdRecTitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecSub" -Value $ui.UpdRecSub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecB1" -Value $ui.UpdRecB1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecB2" -Value $ui.UpdRecB2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecB3" -Value $ui.UpdRecB3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecB4" -Value $ui.UpdRecB4 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdRecNote" -Value $ui.UpdRecNote -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdatessecurity" -Value $ui.UpdRecBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFUpdDefTitle" -Value $ui.UpdDefTitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDefSub" -Value $ui.UpdDefSub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDefB1" -Value $ui.UpdDefB1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDefB2" -Value $ui.UpdDefB2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDefB3" -Value $ui.UpdDefB3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDefNote" -Value $ui.UpdDefNote -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdatesdefault" -Value $ui.UpdDefBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFUpdDisTitle" -Value $ui.UpdDisTitle -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDisSub" -Value $ui.UpdDisSub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDisB1" -Value $ui.UpdDisB1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDisB2" -Value $ui.UpdDisB2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDisB3" -Value $ui.UpdDisB3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdDisNote" -Value $ui.UpdDisNote -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFUpdatesdisable" -Value $ui.UpdDisBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFUpdFooter" -Value $ui.UpdFooter -Property "Text"

    # Win11 Creator tab
    Set-WinUtilNamedControlText -Name "WPFWin11ISOSelectSection" -Value $ui.Win11Step1Header -Property "Header"
    Set-WinUtilNamedControlText -Name "WPFWin11Step1Title" -Value $ui.Win11Step1Title -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Step1Sub" -Value $ui.Win11Step1Sub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11IsoFileLabel" -Value $ui.Win11IsoFileLabel -Property "Text"
    if ($sync.WPFWin11ISOPath -and ($sync.WPFWin11ISOPath.Text -in @("ISO seçilmedi...", "No ISO selected..."))) {
        $sync.WPFWin11ISOPath.Text = $ui.Win11IsoPathPlaceholder
    }
    Set-WinUtilNamedControlText -Name "WPFWin11ISOBrowseButton" -Value $ui.Win11BrowseBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOMountButton" -Value $ui.Win11MountBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11OfficialWarn" -Value $ui.Win11OfficialWarn -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11OfficialBody1" -Value $ui.Win11OfficialBody1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11OfficialBody2" -Value $ui.Win11OfficialBody2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ISODownloadLink" -Value $ui.Win11DownloadBtn -Property "Content"

    Set-WinUtilNamedControlText -Name "WPFWin11ISOModifySection" -Value $ui.Win11Step2Header -Property "Header"
    Set-WinUtilNamedControlText -Name "WPFWin11Step2Title" -Value $ui.Win11Step2Title -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Step2Sub" -Value $ui.Win11Step2Sub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11MountedAt" -Value $ui.Win11MountedAt -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ImageFile" -Value $ui.Win11ImageFile -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11EditionLabel" -Value $ui.Win11EditionLabel -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOInjectDrivers" -Value $ui.Win11InjectDrivers -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOInjectDrivers" -Value $ui.Win11InjectDriversTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOModifyButton" -Value $ui.Win11ModifyBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11WhatItDoes" -Value $ui.Win11WhatItDoes -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Does1" -Value $ui.Win11Does1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Does2" -Value $ui.Win11Does2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Does3" -Value $ui.Win11Does3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Does4" -Value $ui.Win11Does4 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Does5" -Value $ui.Win11Does5 -Property "Text"

    Set-WinUtilNamedControlText -Name "WPFWin11ISOOutputSection" -Value $ui.Win11Step3Header -Property "Header"
    Set-WinUtilNamedControlText -Name "WPFWin11Step3Title" -Value $ui.Win11Step3Title -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11Step3Sub" -Value $ui.Win11Step3Sub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOChooseISOButton" -Value $ui.Win11SaveIsoBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOChooseUSBButton" -Value $ui.Win11ChooseUsbBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11UsbWarn" -Value $ui.Win11UsbWarn -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11UsbDriveLabel" -Value $ui.Win11UsbDriveLabel -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ISORefreshUSBButton" -Value $ui.Win11RefreshBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOWriteUSBButton" -Value $ui.Win11WriteUsbBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ResetSub" -Value $ui.Win11ResetSub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOCleanResetButton" -Value $ui.Win11StartOverBtn -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOCleanResetButton" -Value $ui.Win11StartOverTip -Property "ToolTip"
    Set-WinUtilNamedControlText -Name "WPFWin11ISOWorkingLabel" -Value $ui.Win11WorkingLabel -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11WorkingSub" -Value $ui.Win11WorkingSub -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFWin11StatusLogTitle" -Value $ui.Win11StatusLogTitle -Property "Text"
    if ($sync.WPFWin11ISOStatusLog -and ($sync.WPFWin11ISOStatusLog.Text -in @("Hazır. Başlamak için lütfen bir Windows 11 ISO dosyası seçin.", "Ready. Please select a Windows 11 ISO to begin."))) {
        $sync.WPFWin11ISOStatusLog.Text = $ui.Win11StatusLogReady
    }

    # AppX tab
    Set-WinUtilNamedControlText -Name "WPFAppxSelectionsLabel" -Value $ui.AppxSelectionsLabel -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFDefaultAppxSelection" -Value $ui.AppxBtnDefault -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFGetInstalledAppx" -Value $ui.AppxBtnInstalled -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFSelectAllAppx" -Value $ui.AppxBtnAll -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFClearAppxSelection" -Value $ui.AppxBtnClear -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFAppxNote1" -Value $ui.AppxNote1 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFAppxNote2" -Value $ui.AppxNote2 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFAppxNote3" -Value $ui.AppxNote3 -Property "Text"
    Set-WinUtilNamedControlText -Name "WPFBackToTweaks" -Value $ui.AppxBtnBack -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFInstallSelectedAppx" -Value $ui.AppxBtnInstall -Property "Content"
    Set-WinUtilNamedControlText -Name "WPFRemoveSelectedAppx" -Value $ui.AppxBtnRemove -Property "Content"
}

function Invoke-WinUtilLanguageChange {
    param([ValidateSet("Auto", "tr", "en")][string]$Preference)

    if ($sync.ActiveJob) {
        return
    }

    $sync.preferences.language = $Preference
    Save-WinUtilLanguagePreference -Preference $Preference
    $effective = Get-WinUtilEffectiveLanguage -Preference $Preference

    Set-WinUtilConfigLocale -Lang $effective
    Apply-WinUtilLanguageToUI

    # Clear active category chip filters when switching language so chips match new localized categories
    if ($sync.SelectedAppCategories) {
        $sync.SelectedAppCategories.Clear()
    }
    foreach ($chip in $sync.AppCategoryChips) {
        if ($sync[$chip.Name]) {
            $sync[$chip.Name].IsChecked = ($chip.Name -eq "WPFSearchChipAll")
        }
    }

    # Rebuild dynamic tab panels live so every item, category, and badge reflects the newly chosen language
    foreach ($panelName in @("appscategory", "appspanel", "tweakspanel", "featurespanel", "appxpanel")) {
        $panel = $sync.Form.FindName($panelName)
        if ($panel) {
            $panel.Children.Clear()
            if ($panel.ColumnDefinitions) { $panel.ColumnDefinitions.Clear() }
            if ($panel.RowDefinitions) { $panel.RowDefinitions.Clear() }
        }
    }

    $sync.InitializedTabs = @{}
    $sync.TweakStatusBadges = [Hashtable]::Synchronized(@{})
    $sync.FeatureStatusBadges = [Hashtable]::Synchronized(@{})
    $sync.AppxStatusBadges = [Hashtable]::Synchronized(@{})

    $tabButton = switch ($sync.currentTab) {
        "Tweaks"   { "WPFTab2BT" }
        "Config"   { "WPFTab3BT" }
        "Updates"  { "WPFTab4BT" }
        "Win11ISO" { "WPFTab5BT" }
        "AppX"     { "WPFTab6BT" }
        default    { "WPFTab1BT" }
    }
    Invoke-WPFTab $tabButton
    if ($sync.WPFselectedAppsButton) {
        $sync.WPFselectedAppsButton.Content = Get-WinUtilString -Key "SelectedAppsFmt" -Args @($sync.selectedApps.Count)
    }
}
