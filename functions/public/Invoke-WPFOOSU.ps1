function Invoke-WPFOOSU {
    $isTr = ($sync.Language -eq "tr")
    $desc = if ($isTr) { "O&O ShutUp10++ indiriliyor" } else { "Downloading O&O ShutUp10++" }
    Start-WinUtilJob -Name "OOSU" -Description $desc -Parameters @{
        DownloadPath = Join-Path $sync.winutildir "ooshutup10.exe"
        IsTr = $isTr
    } -ScriptBlock {
        param($DownloadPath, $IsTr)

        Write-WinUtilLog -Component "OOSU" -Message "Downloading O&O ShutUp10++."

        Save-WinUtilFile -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -DestinationPath $DownloadPath -ProgressCallback {
            param($percent, $totalBytes)

            $progress = if ($totalBytes -gt 0) {
                "$percent% / $([math]::Round($totalBytes / 1MB)) MB"
            } else {
                "$percent%"
            }
            $st = if ($IsTr) { "O&O ShutUp10++ indiriliyor ($progress)" } else { "Downloading O&O ShutUp10++ ($progress)" }
            Step-WinUtilJob -Status $st -Percent $percent
        }

        Step-WinUtilJob -Status $(if ($IsTr) { "O&O ShutUp10++ başlatılıyor..." } else { "Launching O&O ShutUp10++..." }) -Percent 100
        Start-Process -FilePath $DownloadPath
        Write-WinUtilLog -Component "OOSU" -Message "O&O ShutUp10++ launched."
    }
}
