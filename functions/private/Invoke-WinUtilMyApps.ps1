function Set-WinUtilMyAppsStatus {
    param([string]$Message)
    if (Test-WinUtilUIAlive) {
        Invoke-WPFUIThread -Async -Parameters @{ Msg = $Message } -ScriptBlock {
            param($Msg)
            if ($sync.WPFMyAppsStatus) {
                $sync.WPFMyAppsStatus.Text = $Msg
            }
        }
    }
}

function Select-WinUtilPreferredAsset {
    param(
        [string[]]$Urls,
        [ValidateSet("Windows", "Android")][string]$Platform,
        [bool]$IsTr = $true
    )

    if (-not $Urls -or $Urls.Count -eq 0) { return $null }

    $candidates = if ($Platform -eq "Windows") {
        @($Urls | Where-Object { $_ -match '\.(exe|msi|zip)$' })
    } else {
        @($Urls | Where-Object { $_ -match '\.apk$' })
    }
    if ($candidates.Count -eq 0) { return $null }

    # Prefer Turkish-named Windows binary when Turkish UI is active (e.g., VideoKareYakalayici.exe)
    if ($Platform -eq "Windows" -and $IsTr) {
        $trHit = @($candidates | Where-Object { $_ -match '(TR|Turkce|KareYakalayici)' })
        if ($trHit.Count -gt 0) { return $trHit[-1] }
    } elseif ($Platform -eq "Windows" -and -not $IsTr) {
        $enHit = @($candidates | Where-Object { $_ -notmatch '(KareYakalayici)' })
        if ($enHit.Count -gt 0) { $candidates = $enHit }
    }

    # Prefer .exe / .msi over .zip, and pick highest versioned filename when multiple exist
    if ($Platform -eq "Windows") {
        $execs = @($candidates | Where-Object { $_ -match '\.(exe|msi)$' })
        if ($execs.Count -gt 0) { $candidates = $execs }
    }

    $sorted = @($candidates | Sort-Object {
        $fn = [System.IO.Path]::GetFileName($_)
        if ($fn -match '[vV]?(\d+(?:\.\d+)+)') {
            $vObj = $null
            if ([version]::TryParse($matches[1], [ref]$vObj)) { return $vObj }
        }
        return [version]"0.0"
    } -Descending)

    return $sorted[0]
}

function Invoke-WinUtilMyAppsFetch {
    param([Parameter(Mandatory)][string]$Uri)

    $headers = @{ "User-Agent" = "WinUtil-TR/2.0 (Windows)" }
    try {
        try {
            $curProto = [Net.ServicePointManager]::SecurityProtocol
            if ($curProto -ne [Net.SecurityProtocolType]::SystemDefault) {
                [Net.ServicePointManager]::SecurityProtocol = ($curProto -bor [Net.SecurityProtocolType]::Tls12)
            }
        } catch {}
        $resp = Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers $headers -TimeoutSec 15 -ErrorAction Stop
        return @{
            Content  = [string]$resp.Content
            FinalUrl = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri
        }
    } catch {
        # Fallback to Windows built-in curl.exe (native Schannel TLS 1.3)
        $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
        if ($curl) {
            $finalUrl = (& $curl.Source -fsSL -o NUL -w "%{url_effective}" --max-time 15 -A "WinUtil-TR/2.0" $Uri 2>$null)
            $bodyLines = @(& $curl.Source -fsSL --max-time 15 -A "WinUtil-TR/2.0" $Uri 2>$null)
            if ($LASTEXITCODE -eq 0 -and $bodyLines.Count -gt 0) {
                return @{
                    Content  = ($bodyLines -join "`n")
                    FinalUrl = if ($finalUrl) { [string]$finalUrl } else { $Uri }
                }
            }
        }
        throw
    }
}

function Get-WinUtilMyAppsFromGitHub {
    param([string]$Username = "edizdar")

    $isTr = ($sync.Language -eq "tr")
    $results = New-Object System.Collections.ArrayList

    try {
        $url = "https://github.com/${Username}?tab=repositories"
        $fetched = Invoke-WinUtilMyAppsFetch -Uri $url
        $html = $fetched.Content

        $liMatches = [regex]::Matches($html, '(?s)<li[^>]*itemprop="owns"[^>]*>(.*?)</li>')
        foreach ($m in $liMatches) {
            $blk = $m.Groups[1].Value
            $name = if ($blk -match "href=`"/$Username/([^`"/?#]+)`"\s+itemprop=`"name codeRepository`"") { $matches[1] } else { "" }
            if ([string]::IsNullOrWhiteSpace($name)) { continue }

            $desc = if ($blk -match '(?s)itemprop="description"[^>]*>(.*?)</p>') {
                [System.Net.WebUtility]::HtmlDecode(($matches[1] -replace '<[^>]+>', '').Trim())
            } else { "" }
            $lang = if ($blk -match 'itemprop="programmingLanguage">([^<]+)<') { $matches[1].Trim() } else { "" }

            $tag = ""
            $assets = @()
            try {
                $relRes = Invoke-WinUtilMyAppsFetch -Uri "https://github.com/$Username/$name/releases/latest"
                $finalUrl = $relRes.FinalUrl
                if ($finalUrl -match '/releases/tag/([^/?#]+)$') {
                    $tag = [System.Uri]::UnescapeDataString($matches[1])
                    $expRes = Invoke-WinUtilMyAppsFetch -Uri "https://github.com/$Username/$name/releases/expanded_assets/$tag"
                    $assets = @([regex]::Matches($expRes.Content, "href=`"(/$Username/[^`"]+/releases/download/[^`"]+)`"") | ForEach-Object {
                        "https://github.com$($_.Groups[1].Value)"
                    } | Select-Object -Unique)
                }
            } catch {}

            $winAsset = Select-WinUtilPreferredAsset -Urls $assets -Platform "Windows" -IsTr $isTr
            $apkAsset = Select-WinUtilPreferredAsset -Urls $assets -Platform "Android" -IsTr $isTr

            $category = if ($winAsset -and $apkAsset) {
                "Both"
            } elseif ($winAsset) {
                "Windows"
            } elseif ($apkAsset) {
                "Android"
            } else {
                "Other"
            }

            [void]$results.Add([pscustomobject]@{
                Name        = $name
                Description = $desc
                Language    = $lang
                Tag         = $tag
                RepoUrl     = "https://github.com/$Username/$name"
                ReleasesUrl = "https://github.com/$Username/$name/releases"
                WinAssetUrl = $winAsset
                ApkAssetUrl = $apkAsset
                AllAssets   = $assets
                Category    = $category
            })
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "MyApps" -Message "Failed to fetch github.com/$Username repos: $($_.Exception.Message)"
        throw
    }

    return @($results)
}

function Invoke-WinUtilMyAppDownload {
    param(
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][string]$DownloadUrl,
        [ValidateSet("Windows", "Android")][string]$Platform
    )

    $isTr = ($sync.Language -eq "tr")
    $fileName = [System.Uri]::UnescapeDataString([System.IO.Path]::GetFileName($DownloadUrl))
    $downloadsRoot = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    $destDir = Join-Path (Join-Path $downloadsRoot "ErolDizdar") $RepoName
    $destPath = Join-Path $destDir $fileName

    $jobName = if ($isTr) { "Uygulama İndirme" } else { "App Download" }
    $jobDesc = if ($isTr) { "$RepoName ($fileName) indiriliyor" } else { "Downloading $RepoName ($fileName)" }

    Start-WinUtilJob -Name $jobName -Description $jobDesc -QueueIfBusy -Parameters @{
        RepoName    = $RepoName
        DownloadUrl = $DownloadUrl
        DestDir     = $destDir
        DestPath    = $destPath
        FileName    = $fileName
        Platform    = $Platform
        IsTr        = $isTr
    } -ScriptBlock {
        param($RepoName, $DownloadUrl, $DestDir, $DestPath, $FileName, $Platform, $IsTr)

        try {
            if (-not (Test-Path -LiteralPath $DestDir)) {
                New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
            }

            Set-WinUtilMyAppsStatus $(if ($IsTr) { "İndiriliyor: $FileName..." } else { "Downloading: $FileName..." })
            Save-WinUtilFile -Uri $DownloadUrl -DestinationPath $DestPath -ProgressCallback {
                param($percent, $totalBytes)
                $progTxt = if ($totalBytes -gt 0) {
                    "$percent% ($([math]::Round($totalBytes / 1MB, 1)) MB)"
                } else {
                    "$percent%"
                }
                Step-WinUtilJob -Status $(if ($IsTr) { "$FileName indiriliyor ($progTxt)" } else { "Downloading $FileName ($progTxt)" }) -Percent $percent
            }

            Step-WinUtilJob -Status $(if ($IsTr) { "İndirme tamamlandı: $FileName" } else { "Download finished: $FileName" }) -Percent 100
            Set-WinUtilMyAppsStatus $(if ($IsTr) { "İndirildi: $DestPath" } else { "Downloaded: $DestPath" })

            if ($Platform -eq "Windows" -and ($FileName -match '\.(exe|msi)$')) {
                Invoke-WPFUIThread -Parameters @{ DestPath = $DestPath; FileName = $FileName; RepoName = $RepoName; IsTr = $IsTr } -ScriptBlock {
                    param($DestPath, $FileName, $RepoName, $IsTr)
                    $ask = if ($IsTr) {
                        "$RepoName ($FileName) başarıyla indirildi:`n`n$DestPath`n`nŞimdi çalıştırmak ister misiniz?"
                    } else {
                        "$RepoName ($FileName) downloaded successfully:`n`n$DestPath`n`nDo you want to run it now?"
                    }
                    $ans = Show-WinUtilMessage -Message $ask -Title (Get-WinUtilString -Key "WindowTitle") -Button "YesNo" -Icon "Info"
                    if ($ans -eq "Yes") {
                        Start-Process -FilePath $DestPath -WorkingDirectory (Split-Path -Parent $DestPath)
                    } else {
                        Start-Process "explorer.exe" -ArgumentList "/select,`"$DestPath`""
                    }
                }
            } else {
                Start-Process "explorer.exe" -ArgumentList "/select,`"$DestPath`""
                Invoke-WPFUIThread -Parameters @{ DestPath = $DestPath; FileName = $FileName; IsTr = $IsTr } -ScriptBlock {
                    param($DestPath, $FileName, $IsTr)
                    $done = if ($IsTr) {
                        "$FileName başarıyla indirildi ve klasör açıldı:`n`n$DestPath"
                    } else {
                        "$FileName downloaded successfully and folder opened:`n`n$DestPath"
                    }
                    Show-WinUtilMessage -Message $done -Title (Get-WinUtilString -Key "WindowTitle") -Button "OK" -Icon "Info" | Out-Null
                }
            }
        } catch {
            $err = if ($IsTr) { "İndirme hatası ($FileName): $($_.Exception.Message)" } else { "Download failed ($FileName): $($_.Exception.Message)" }
            Set-WinUtilMyAppsStatus $err
            Invoke-WPFUIThread -Parameters @{ Msg = $err } -ScriptBlock {
                param($Msg)
                Show-WinUtilMessage -Message $Msg -Title (Get-WinUtilString -Key "ErrorTitle") -Button "OK" -Icon "Error" | Out-Null
            }
        }
    }
}

function Set-WinUtilMyAppsFilter {
    param([ValidateSet("All", "Windows", "Android", "Other")][string]$Filter)

    $map = @{
        All     = "WPFMyAppsFilterAll"
        Windows = "WPFMyAppsFilterWin"
        Android = "WPFMyAppsFilterAndroid"
        Other   = "WPFMyAppsFilterOther"
    }
    $sync.MyAppsActiveFilter = $Filter
    $sync.MyAppsFilterSwitching = $true
    try {
        foreach ($kv in $map.GetEnumerator()) {
            if ($sync[$kv.Value]) {
                $sync[$kv.Value].IsChecked = ($kv.Key -eq $Filter)
            }
        }
    } finally {
        $sync.MyAppsFilterSwitching = $false
    }

    Render-WinUtilMyAppsCards
}

function Render-WinUtilMyAppsCards {
    if (-not $sync.WPFMyAppsCards) { return }
    $isTr = ($sync.Language -eq "tr")
    $all = if ($sync.MyAppsCache) { @($sync.MyAppsCache) } else { @() }
    $filter = if ($sync.MyAppsActiveFilter) { $sync.MyAppsActiveFilter } else { "All" }

    $filtered = switch ($filter) {
        "Windows" { @($all | Where-Object { $_.WinAssetUrl }) }
        "Android" { @($all | Where-Object { $_.ApkAssetUrl }) }
        "Other"   { @($all | Where-Object { -not $_.WinAssetUrl -and -not $_.ApkAssetUrl }) }
        default   { $all }
    }

    $sync.WPFMyAppsCards.Children.Clear()
    $borderStyle = $sync.Form.FindResource("BorderStyle")

    if ($filtered.Count -eq 0) {
        $emptyCard = New-Object Windows.Controls.Border
        if ($borderStyle) { $emptyCard.Style = $borderStyle }
        $emptyCard.Padding = New-Object Windows.Thickness(14)
        $emptyCard.Margin = New-Object Windows.Thickness(4)
        $tb = New-Object Windows.Controls.TextBlock
        $tb.Text = if ($isTr) { "Bu kategoride gösterilecek proje bulunamadı." } else { "No projects found in this category." }
        $tb.FontSize = 12.5
        $tb.Opacity = 0.8
        $tb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
        $emptyCard.Child = $tb
        [void]$sync.WPFMyAppsCards.Children.Add($emptyCard)
        return
    }

    foreach ($repo in $filtered) {
        $card = New-Object Windows.Controls.Border
        if ($borderStyle) { $card.Style = $borderStyle }
        $card.Padding = New-Object Windows.Thickness(14,12,14,12)
        $card.Margin = New-Object Windows.Thickness(4)

        $grid = New-Object Windows.Controls.Grid
        $r0 = New-Object Windows.Controls.RowDefinition; $r0.Height = "Auto"
        $r1 = New-Object Windows.Controls.RowDefinition; $r1.Height = "*"
        $r2 = New-Object Windows.Controls.RowDefinition; $r2.Height = "Auto"
        [void]$grid.RowDefinitions.Add($r0)
        [void]$grid.RowDefinitions.Add($r1)
        [void]$grid.RowDefinitions.Add($r2)

        # Row 0: Title + Version/Platform Badges
        $topDock = New-Object Windows.Controls.DockPanel
        [Windows.Controls.Grid]::SetRow($topDock, 0)

        $badgePanel = New-Object Windows.Controls.StackPanel
        $badgePanel.Orientation = "Horizontal"
        $badgePanel.VerticalAlignment = "Center"
        [Windows.Controls.DockPanel]::SetDock($badgePanel, [Windows.Controls.Dock]::Right)

        if ($repo.Tag) {
            $verBadge = New-Object Windows.Controls.Border
            $verBadge.CornerRadius = New-Object Windows.CornerRadius(4)
            $verBadge.Padding = New-Object Windows.Thickness(7,2,7,2)
            $verBadge.Margin = New-Object Windows.Thickness(4,0,0,0)
            $verBadge.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(47, 125, 120))
            $verTb = New-Object Windows.Controls.TextBlock
            $verTb.Text = $repo.Tag
            $verTb.FontSize = 11
            $verTb.FontWeight = "SemiBold"
            $verTb.Foreground = [Windows.Media.Brushes]::White
            $verBadge.Child = $verTb
            [void]$badgePanel.Children.Add($verBadge)
        }
        if ($repo.WinAssetUrl) {
            $winBadge = New-Object Windows.Controls.Border
            $winBadge.CornerRadius = New-Object Windows.CornerRadius(4)
            $winBadge.Padding = New-Object Windows.Thickness(7,2,7,2)
            $winBadge.Margin = New-Object Windows.Thickness(4,0,0,0)
            $winBadge.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(0, 120, 214))
            $winTb = New-Object Windows.Controls.TextBlock
            $winTb.Text = "Windows"
            $winTb.FontSize = 11
            $winTb.FontWeight = "SemiBold"
            $winTb.Foreground = [Windows.Media.Brushes]::White
            $winBadge.Child = $winTb
            [void]$badgePanel.Children.Add($winBadge)
        }
        if ($repo.ApkAssetUrl) {
            $apkBadge = New-Object Windows.Controls.Border
            $apkBadge.CornerRadius = New-Object Windows.CornerRadius(4)
            $apkBadge.Padding = New-Object Windows.Thickness(7,2,7,2)
            $apkBadge.Margin = New-Object Windows.Thickness(4,0,0,0)
            $apkBadge.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(61, 166, 92))
            $apkTb = New-Object Windows.Controls.TextBlock
            $apkTb.Text = "Android"
            $apkTb.FontSize = 11
            $apkTb.FontWeight = "SemiBold"
            $apkTb.Foreground = [Windows.Media.Brushes]::White
            $apkBadge.Child = $apkTb
            [void]$badgePanel.Children.Add($apkBadge)
        }

        $titlePanel = New-Object Windows.Controls.StackPanel
        $titlePanel.Orientation = "Horizontal"
        $titleTb = New-Object Windows.Controls.TextBlock
        $titleTb.Text = $repo.Name
        $titleTb.FontSize = 15
        $titleTb.FontWeight = "Bold"
        $titleTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
        [void]$titlePanel.Children.Add($titleTb)

        if ($repo.Language) {
            $langTb = New-Object Windows.Controls.TextBlock
            $langTb.Text = "  ($($repo.Language))"
            $langTb.FontSize = 11.5
            $langTb.Opacity = 0.68
            $langTb.VerticalAlignment = "Center"
            $langTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
            [void]$titlePanel.Children.Add($langTb)
        }

        [void]$topDock.Children.Add($badgePanel)
        [void]$topDock.Children.Add($titlePanel)

        # Row 1: Description
        $descTb = New-Object Windows.Controls.TextBlock
        [Windows.Controls.Grid]::SetRow($descTb, 1)
        $descTb.Text = if (-not [string]::IsNullOrWhiteSpace($repo.Description)) {
            $repo.Description
        } elseif ($isTr) {
            "github.com/edizdar üzerindeki açık kaynak proje. Ayrıntılar ve kaynak kod için GitHub sayfasını ziyaret edebilirsiniz."
        } else {
            "Open-source project on github.com/edizdar. Open the GitHub page for source code and details."
        }
        $descTb.FontSize = 12
        $descTb.Opacity = 0.85
        $descTb.TextWrapping = "Wrap"
        $descTb.Margin = New-Object Windows.Thickness(0,7,0,10)
        $descTb.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")

        # Row 2: Action Buttons
        $btnWrap = New-Object Windows.Controls.WrapPanel
        [Windows.Controls.Grid]::SetRow($btnWrap, 2)
        $btnWrap.Orientation = "Horizontal"

        if ($repo.WinAssetUrl) {
            $winFile = [System.Uri]::UnescapeDataString([System.IO.Path]::GetFileName($repo.WinAssetUrl))
            $winBtn = New-Object Windows.Controls.Button
            $winBtn.Content = if ($isTr) { "İndir ve Çalıştır (Windows)" } else { "Download & Run (Windows)" }
            $winBtn.ToolTip = $winFile
            $winBtn.Height = 29
            $winBtn.Width = [double]::NaN
            $winBtn.Padding = New-Object Windows.Thickness(12,2,12,2)
            $winBtn.Margin = New-Object Windows.Thickness(0,0,6,4)
            $winBtn.Tag = @{ Name = $repo.Name; Url = $repo.WinAssetUrl; Platform = "Windows" }
            $winBtn.Add_Click({
                param($sender, $e)
                Invoke-WinUtilMyAppDownload -RepoName $sender.Tag.Name -DownloadUrl $sender.Tag.Url -Platform "Windows"
            })
            [void]$btnWrap.Children.Add($winBtn)
        }

        if ($repo.ApkAssetUrl) {
            $apkFile = [System.Uri]::UnescapeDataString([System.IO.Path]::GetFileName($repo.ApkAssetUrl))
            $apkBtn = New-Object Windows.Controls.Button
            $apkBtn.Content = if ($isTr) { "APK İndir (Android)" } else { "Download APK (Android)" }
            $apkBtn.ToolTip = $apkFile
            $apkBtn.Height = 29
            $apkBtn.Width = [double]::NaN
            $apkBtn.Padding = New-Object Windows.Thickness(12,2,12,2)
            $apkBtn.Margin = New-Object Windows.Thickness(0,0,6,4)
            $apkBtn.Tag = @{ Name = $repo.Name; Url = $repo.ApkAssetUrl; Platform = "Android" }
            $apkBtn.Add_Click({
                param($sender, $e)
                Invoke-WinUtilMyAppDownload -RepoName $sender.Tag.Name -DownloadUrl $sender.Tag.Url -Platform "Android"
            })
            [void]$btnWrap.Children.Add($apkBtn)
        }

        $ghBtn = New-Object Windows.Controls.Button
        $ghBtn.Content = if ($isTr) { "GitHub Sayfası" } else { "GitHub Page" }
        $ghBtn.ToolTip = $repo.RepoUrl
        $ghBtn.Height = 29
        $ghBtn.Width = [double]::NaN
        $ghBtn.Padding = New-Object Windows.Thickness(12,2,12,2)
        $ghBtn.Margin = New-Object Windows.Thickness(0,0,0,4)
        $ghBtn.Tag = $repo.RepoUrl
        $ghBtn.Add_Click({
            param($sender, $e)
            try { Start-Process $sender.Tag } catch {}
        })
        [void]$btnWrap.Children.Add($ghBtn)

        [void]$grid.Children.Add($topDock)
        [void]$grid.Children.Add($descTb)
        [void]$grid.Children.Add($btnWrap)
        $card.Child = $grid
        [void]$sync.WPFMyAppsCards.Children.Add($card)
    }
}

function Update-WinUtilMyAppsUI {
    $isTr = ($sync.Language -eq "tr")
    Set-WinUtilMyAppsStatus $(if ($isTr) { "github.com/edizdar üzerindeki herkese açık projeler ve sürümler taranıyor..." } else { "Fetching public projects and latest releases from github.com/edizdar..." })
    try {
        $repos = Get-WinUtilMyAppsFromGitHub -Username "edizdar"
        $sync.MyAppsCache = $repos
        $sync.MyAppsLoaded = $true

        $apply = {
            param($Count, $IsTr)
            Render-WinUtilMyAppsCards
            if ($sync.WPFMyAppsStatus) {
                $sync.WPFMyAppsStatus.Text = if ($IsTr) {
                    "github.com/edizdar üzerinden $Count herkese açık proje ve güncel sürüm bağlantısı yüklendi."
                } else {
                    "Loaded $Count public project(s) and latest release links from github.com/edizdar."
                }
            }
        }
        if (Test-WinUtilUIAlive) {
            if ($sync.Form.Dispatcher.CheckAccess()) {
                & $apply $repos.Count $isTr
            } else {
                Invoke-WPFUIThread -Async -Parameters @{ Count = $repos.Count; IsTr = $isTr } -ScriptBlock $apply
            }
        }
    } catch {
        Set-WinUtilMyAppsStatus $(if ($isTr) { "GitHub bağlantısı kurulamadı: $($_.Exception.Message)" } else { "Could not load from GitHub: $($_.Exception.Message)" })
    }
}

function Start-WinUtilMyAppsRefresh {
    if ($null -ne $sync.RunspacePool) {
        try {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $sync.RunspacePool
            [void]$ps.AddScript({ Update-WinUtilMyAppsUI })
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
    Update-WinUtilMyAppsUI
}

function Initialize-WinUtilMyAppsHandlers {
    if ($sync.MyAppsHandlersWired) { return }
    $sync.MyAppsHandlersWired = $true

    if ($sync.WPFMyAppsBtnRefresh) {
        $sync.WPFMyAppsBtnRefresh.Add_Click({ Start-WinUtilMyAppsRefresh })
    }
    if ($sync.WPFMyAppsBtnOpenGitHub) {
        $sync.WPFMyAppsBtnOpenGitHub.Add_Click({
            try { Start-Process "https://github.com/edizdar?tab=repositories" } catch {}
        })
    }

    $filterMap = @{
        WPFMyAppsFilterAll     = "All"
        WPFMyAppsFilterWin     = "Windows"
        WPFMyAppsFilterAndroid = "Android"
        WPFMyAppsFilterOther   = "Other"
    }
    foreach ($kv in $filterMap.GetEnumerator()) {
        if ($sync[$kv.Key]) {
            $sync[$kv.Key].Tag = $kv.Value
            $sync[$kv.Key].Add_Click({
                param($sender, $e)
                if (-not $sync.MyAppsFilterSwitching) {
                    Set-WinUtilMyAppsFilter -Filter $sender.Tag
                }
            })
        }
    }
}
