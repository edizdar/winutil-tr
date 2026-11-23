function Invoke-WPFExportEnvironmentReport {
    <#
    .SYNOPSIS
        Exports an allowlisted, read-only environment report as JSON, with an optional bundle of
        recent WinUtil logs.
    #>

    try {
        $includeLogs = (Show-WinUtilMessage `
            -Message "Son 7 günlük WinUtil günlük dosyaları da eklensin mi? Bu ek dosya yerel dosya yolları, komutlar ve hata ayrıntıları içerebilir. Paylaşmadan önce gözden geçirin." `
            -Title "Sistem Raporu" -Button "YesNo" -Icon "Question") -eq "Yes"

        Add-Type -AssemblyName System.Windows.Forms
        $dialog = [System.Windows.Forms.SaveFileDialog]::new()
        $dialog.Title = "Sistem Raporunu Dışa Aktar"
        $dialog.Filter = "JSON dosyaları (*.json)|*.json"
        $dialog.FileName = "WinUtilSistemRaporu_$(Get-Date -Format 'yyyyMMdd').json"
        $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        $jsonPath = $dialog.FileName
        $logsPath = Get-WinUtilEnvironmentReportLogsPath -JsonPath $jsonPath

        # SaveFileDialog's own overwrite prompt only covers $jsonPath. A derived companion from a
        # previous export must neither be silently replaced nor left looking like it belongs to new JSON.
        if (Test-Path -LiteralPath $logsPath) {
            if (-not $includeLogs) {
                Show-WinUtilMessage `
                    -Message "Bu konumda zaten bir günlük dosyası mevcut:`n$logsPath`n`nFarklı bir dosya adı seçin veya mevcut günlükleri değiştirin." `
                    -Title "Sistem Raporu" -Button "OK" -Icon "Warning" | Out-Null
                return
            }

            $replaceLogs = (Show-WinUtilMessage `
                -Message "Bu konumda zaten bir günlük dosyası mevcut:`n$logsPath`n`nÜzerine yazılsın mı?" `
                -Title "Sistem Raporu" -Button "YesNo" -Icon "Warning") -eq "Yes"
            if (-not $replaceLogs) {
                return
            }
        }

        # Registry reads across every tweak/toggle and the log bundle's file read add up to a
        # couple of seconds, so the job layer keeps the Settings handler responsive and owns the
        # progress, taskbar state, logging, and error reporting.
        Start-WinUtilJob -Name "Sistem Raporu" -Description "Sistem raporu dışa aktarılıyor" -Parameters @{
            JsonPath = $jsonPath
            LogsPath = $logsPath
            IncludeLogs = $includeLogs
        } -ScriptBlock {
            param($JsonPath, $LogsPath, $IncludeLogs)

            Step-WinUtilJob -Status "Sistem bilgileri toplanıyor" -Percent 10
            $report = Get-WinUtilEnvironmentReport
            $json = $report | ConvertTo-Json -Depth 6

            if ($IncludeLogs) {
                Step-WinUtilJob -Status "Son WinUtil günlükleri toplanıyor" -Percent 60
                $logs = Get-WinUtilRecentLogs
            }

            Step-WinUtilJob -Status "Sistem raporu yazılıyor" -Percent 80
            Write-WinUtilEnvironmentReportExport -JsonPath $JsonPath -Json $json `
                -LogsPath $LogsPath -Logs $logs -IncludeLogs:$IncludeLogs

            Write-WinUtilLog -Component "EnvironmentReport" -Message "Environment report exported to $JsonPath."
            Step-WinUtilJob -Status "Sistem raporu dışa aktarıldı" -Percent 100
        }
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "ERROR" -Message "Environment report export failed: $($_.Exception.Message)"
        Show-WinUtilMessage -Message "Sistem raporu dışa aktarılamadı. $($_.Exception.Message)" `
            -Title "Sistem Raporu" -Button "OK" -Icon "None" | Out-Null
    }
}
