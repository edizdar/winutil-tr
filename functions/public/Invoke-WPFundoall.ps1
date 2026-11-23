function Invoke-WPFundoall {
    <#

    .SYNOPSIS
        Undoes every selected tweak

    #>

    $tweaks = $sync.selectedTweaks

    if ($tweaks.count -eq 0) {
        Show-WinUtilMessage -Message "Lütfen geri almak istediğiniz ince ayarları işaretleyin." -Title "WinUtil Türkçe" -Button "OK" -Icon "Warning"
        return
    }

    Start-WinUtilJob -Name "Ayarları Geri Al" -Description "İnce ayarlar geri alınıyor" -QueueIfBusy -Parameters @{
        Tweaks = @($tweaks)
    } -ScriptBlock {
        param($Tweaks)

        $total = @($Tweaks).Count
        Write-WinUtilLog -Component "Tweaks" -Message "Undo tweaks requested: $total selected tweak(s)."

        for ($i = 0; $i -lt $total; $i++) {
            $tweakLabel = Get-WinUtilTweakDisplayName -Key $Tweaks[$i]
            Step-WinUtilJob -Status "Geri alınıyor: $tweakLabel ($($i + 1)/$total)" -Percent ([int](($i / $total) * 100))
            Measure-WinUtilStep -Scope "Undo tweaks" -Name $Tweaks[$i] -ScriptBlock {
                Invoke-WinUtiltweaks $Tweaks[$i] -undo $true
            }
            Step-WinUtilJob -Percent ([int]((($i + 1) / $total) * 100))
        }

        Update-WinUtilAppliedTweakBadges
    }
}
