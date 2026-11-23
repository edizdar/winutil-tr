function Invoke-WPFImpex {
    <#

    .SYNOPSIS
        Handles importing and exporting of the checkboxes checked for the tweaks section

    .PARAMETER type
        Indicates whether to 'import' or 'export'

    .PARAMETER checkbox
        The checkbox to export to a file or apply the imported file to

    .EXAMPLE
        Invoke-WPFImpex -type "export"

    #>
    param(
        $type,
        $Config = $null,

        # Add to the current selection instead of replacing it. Used when a preset has already
        # set a baseline that the imported file is meant to extend.
        [switch]$Merge,

        # Headless runs cannot show a dialog and must fail rather than applying a partial request.
        [switch]$ThrowOnError
    )

    function ConfigDialog {
        if (!$Config) {
            switch ($type) {
                "export" { $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog }
                "import" { $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog }
            }
            $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $FileBrowser.Filter = "JSON Dosyaları (*.json)|*.json"
            $FileBrowser.ShowDialog() | Out-Null

            if ($FileBrowser.FileName -eq "") {
                return $null
            } else {
                return $FileBrowser.FileName
            }
        } else {
            return $Config
        }
    }

    switch ($type) {
        "export" {
            try {
                $Config = ConfigDialog
                if ($Config) {
                    $allConfs = ($sync.selectedApps + $sync.selectedTweaks + $sync.selectedToggles + $sync.selectedFeatures + $sync.selectedAppx) | ForEach-Object { [string]$_ }
                    if (-not $allConfs) {
                        Show-WinUtilMessage -Message (
                            "Dışa aktarılacak hiçbir ayar seçilmedi. Lütfen dışa aktarmadan önce en az bir uygulama, ince ayar, tercih, özellik veya AppX paketi seçin."
                        ) -Title "Dışa Aktarılacak Öğe Yok" -Button "OK" -Icon "Warning" | Out-Null
                        return
                    }
                    $jsonFile = $allConfs | ConvertTo-Json
                    $jsonFile | Out-File -LiteralPath $Config -Force
                    # Keep the path literal when the copied command is pasted into PowerShell.
                    $escapedConfig = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($Config)
                    "& ([ScriptBlock]::Create((Invoke-RestMethod 'https://christitus.com/win'))) -Config '$escapedConfig'" | Set-Clipboard
                }
            } catch {
                Write-Error "An error occurred while exporting: $_"
            }
        }
        "import" {
            try {
                $Config = ConfigDialog
                if ($Config) {
                    try {
                        if ($Config -match '^https?://') {
                            $jsonFile = (Invoke-WebRequest "$Config" -UseBasicParsing -ErrorAction Stop).Content | ConvertFrom-Json
                        } else {
                            $jsonFile = Get-Content -LiteralPath $Config -ErrorAction Stop | ConvertFrom-Json
                        }
                    } catch {
                        $message = "Failed to load the JSON file from the specified path or URL: $_"
                        if ($ThrowOnError) { throw $message }
                        Write-Error $message
                        return
                    }
                    $isLegacyConfig = $jsonFile -is [System.Management.Automation.PSCustomObject] -and
                        $null -ne $jsonFile.PSObject.Properties["Install"] -and
                        $null -ne $jsonFile.PSObject.Properties["WPFInstall"]
                    if ($isLegacyConfig) {
                        Write-WinUtilLog -Component "Impex" -Message "Detected legacy WinUtil config structure; flattening import object."
                        # Legacy exports stored checkbox keys in WPFInstall and duplicated package
                        # source metadata in Install. Current package IDs come from the app catalog,
                        # so only the selection-key properties are restored.
                        $flattenedJson = @(
                            foreach ($property in $jsonFile.PSObject.Properties) {
                                if ($property.Name -notmatch '^WPF(?:Install|Tweaks|Toggle|Feature|Appx)') {
                                    continue
                                }

                                foreach ($selection in @($property.Value)) {
                                    if ($selection -is [string] -and -not [string]::IsNullOrWhiteSpace($selection)) {
                                        $selection
                                    }
                                }
                            }
                        )
                    } else {
                        # New style config: flat array of strings
                        $flattenedJson = $jsonFile
                    }

                    if (-not $flattenedJson) {
                        Show-WinUtilMessage -Message "Seçilen dosya içe aktarılacak herhangi bir ayar içermiyor. Değişiklik yapılmadı." -Title "Boş Yapılandırma" -Button "OK" -Icon "Warning" | Out-Null
                        return
                    }

                    # Replace unless this import is merging onto something already selected,
                    # which the headless path does when it is given a preset and a config
                    $replaceMode = @{}
                    if (-not $Merge) { $replaceMode["Replace"] = $true }

                    # Modern configs stay strict. Legacy configs can reference entries that no
                    # longer exist, so restore supported selections and report the retired keys.
                    if ($isLegacyConfig) {
                        $skippedSelections = @(Update-WinUtilSelections -flatJson $flattenedJson @replaceMode -SkipUnknown)

                        if ($skippedSelections.Count -gt 0) {
                            $skippedSummary = $skippedSelections -join ", "
                            Write-WinUtilLog -Component "Impex" -Level "WARN" -Message "Skipped unsupported legacy selections: $skippedSummary"
                        }

                        if ($skippedSelections.Count -eq @($flattenedJson).Count) {
                            if ($sync.Form) {
                                Show-WinUtilMessage -Message "Bu eski yapılandırma dosyası bu WinUtil sürümü tarafından desteklenen hiçbir ayar içermiyor. Değişiklik yapılmadı." -Title "Desteklenmeyen Eski Yapılandırma" -Icon "Warning" | Out-Null
                            }
                            return
                        }

                        if ($skippedSelections.Count -gt 0) {
                            $skippedDisplay = @($skippedSelections | Select-Object -First 10) -join ", "
                            if ($skippedSelections.Count -gt 10) {
                                $skippedDisplay += "`n...ve $($skippedSelections.Count - 10) öğe daha. Ayrıntılar için WinUtil günlüğüne bakın."
                            }
                            if ($sync.Form) {
                                Show-WinUtilMessage -Message "Desteklenen ayarlar içe aktarıldı. Aşağıdaki artık kullanılmayan ayarlar atlandı:`n`n$skippedDisplay" -Title "Eski Yapılandırma Kısmen İçe Aktarıldı" -Icon "Warning" | Out-Null
                            }
                        }
                    } else {
                        # Build and validate every imported selection before replacing the current
                        # state. This keeps a malformed config from leaving partial selections behind.
                        Update-WinUtilSelections -flatJson $flattenedJson @replaceMode
                    }

                    if ($sync.Form) {
                        Reset-WPFCheckBoxes -doToggles $true
                    }
                }
            } catch {
                if ($ThrowOnError) { throw }
                Write-Error "An error occurred while importing: $_"
            }
        }
    }
}
