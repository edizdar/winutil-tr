function Invoke-WPFFeatureInstall {
    <#

    .SYNOPSIS
        Installs selected Windows Features

    #>

    if ($null -eq $sync.selectedFeatures -or $sync.selectedFeatures.Count -eq 0) {
        Show-WinUtilMessage -Message "Hiçbir Windows özelliği seçilmedi." -Title "WinUtil Türkçe" -Button "OK" -Icon "Warning"
        return
    }

    Start-WinUtilJob -Name "Özellikler" -Description "Windows özellikleri kuruluyor" -QueueIfBusy -Parameters @{
        Features = @($sync.selectedFeatures)
    } -ScriptBlock {
        param($Features)

        $total = @($Features).Count
        $completed = 0

        foreach ($feature in $Features) {
            $completed++
            Step-WinUtilJob -Status "Kuruluyor: $feature ($completed/$total)" -Percent ([int]((($completed - 1) / $total) * 100))
            Measure-WinUtilStep -Scope "Features" -Name $feature -ScriptBlock {
                Invoke-WinUtilFeatureInstall $feature
            }
            Step-WinUtilJob -Status "Kuruldu: $feature ($completed/$total)" -Percent ([int](($completed / $total) * 100))
        }

        Write-Host "A reboot may be required."
        Update-WinUtilEnabledFeatureBadges
    }
}
