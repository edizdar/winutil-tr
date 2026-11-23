[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)

# 📦 Kurulum (Install) Sekmesi Rehberi

**Kurulum** sekmesi, Windows bilgisayarınıza en popüler yazılımları tek tek web sitelerine girmeden, reklamsız ve sessiz kurulumla tek tıkla yüklemenizi, güncellemenizi veya kaldırmanızı sağlar.

## Temel Özellikler

| Özellik | Ne İşe Yarar? |
| :--- | :--- |
| **Uygulamaları Kur / Güncelle** | İşaretlediğiniz tüm uygulamaları sırayla kurar; zaten kuruluysa en güncel sürüme yükseltir. |
| **Uygulamaları Kaldır** | İşaretlediğiniz uygulamaları sistemden temiz şekilde kaldırır (işlem öncesi onay ister). |
| **Tüm Uygulamaları Güncelle** | Bilgisayarınızda yüklü olan tüm uygulamaları tek seferde en son sürüme günceller (`winget upgrade --all` / `choco upgrade all`). |
| **Paket Yöneticisi (WinGet / Chocolatey)** | Varsayılan olarak Microsoft'un resmi **WinGet** aracını kullanır; dilerseniz **Chocolatey** seçebilirsiniz. |
| **Yüklü Uygulamaları Göster** | Sisteminizde zaten kurulu olan uygulamaları tarar ve işaretler. |
| **Kategori Filtre Çipleri** | Üstteki kategori butonlarına tıklayarak listeyi filtreleyebilirsiniz. **Ctrl + Tık** ile birden fazla kategori seçilebilir. |
| **Hızlı Arama (`Ctrl+F`)** | Üstteki arama kutusuna uygulama adı veya açıklama yazarak anında filtreleme yapabilirsiniz (`Esc` temizler). |
| **Sağ Tık Menüsü** | Herhangi bir uygulamaya sağ tıklayarak tek başına **Kur**, **Kaldır** veya **Web Sitesini Aç** işlemlerini yapabilirsiniz. |
| **Yeşil `#FOSS` Köşe Simgesi** | Uygulamanın **Özgür ve Açık Kaynaklı Yazılım** olduğunu gösterir. |

## Desteklenen Uygulamalar (239 Adet)

Kategoriyi açmak için başlığa tıklayın:

<details>
<summary><strong>Belgeler (17 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Adobe Acrobat Reader](https://www.adobe.com/acrobat/pdf-reader.html) | — | PDF belgelerini görüntüleme, yazdırma ve açıklama ekleme özellikleri sunan ücretsiz PDF görüntüleyici. |
| [Foxit PDF Reader](https://www.foxit.com/pdf-reader/) | — | Tanıdık şerit (ribbon) arayüzlü ücretsiz ve hızlı PDF görüntüleyici. |
| [Joplin](https://joplinapp.org/) | 🟢 Evet | Cihazlar arası eşitleme destekli açık kaynaklı not alma ve yapılacaklar listesi uygulaması. |
| [LibreOffice](https://www.libreoffice.org/) | 🟢 Evet | Diğer büyük ofis paketleriyle uyumlu, güçlü ve ücretsiz açık kaynaklı ofis yazılımı. |
| [NAPS2 (Tarayıcı)](https://www.naps2.com/) | 🟢 Evet | Belge tarayıcılarından PDF ve görsel oluşturmayı kolaylaştıran ücretsiz belge tarama uygulaması. |
| [Obsidian](https://obsidian.md/) | — | Markdown tabanlı, bağlantılı not alma ve kişisel bilgi yönetimi uygulaması. |
| [Okular](https://okular.kde.org/) | 🟢 Evet | Gelişmiş özelliklere sahip çok yönlü PDF ve belge görüntüleyici. |
| [ONLYOFFICE Desktop](https://www.onlyoffice.com/desktop.aspx) | 🟢 Evet | Microsoft Office belgeleriyle yüksek uyumluluğa sahip kapsamlı ücretsiz ofis paketi. |
| [PDF-XChange Editor](https://www.pdf-xchange.com/) | — | PDF oluşturma, görüntüleme, düzenleme, açıklama ekleme ve imzalama için kapsamlı PDF editörü. |
| [PDF24 Creator](https://tools.pdf24.org/en/creator) | — | PDF birleştirme, bölme, sıkıştırma ve dönüştürme için ücretsiz ve kolay masaüstü PDF araç seti. |
| [PDFgear](https://www.pdfgear.com/) | — | Tamamen ücretsiz, kapsamlı PDF görüntüleme, düzenleme ve dönüştürme yazılımı. |
| [PDFsam Basic](https://pdfsam.org/) | 🟢 Evet | PDF dosyalarını bölmek, birleştirmek ve döndürmek için ücretsiz, açık kaynaklı araç. |
| [QOwnNotes](https://www.qownnotes.org/) | 🟢 Evet | Nextcloud/ownCloud entegrasyonlu, ücretsiz ve açık kaynaklı Markdown not alma uygulaması. |
| [Simplenote](https://simplenote.com/) | 🟢 Evet | Notlarınızı, listelerinizi ve fikirlerinizi sade biçimde tutmanızı sağlayan ücretsiz not uygulaması. |
| [Sumatra PDF](https://www.sumatrapdfreader.org/free-pdf-reader.html) | 🟢 Evet | Minimalist tasarımlı, çok hafif ve anında açılan ücretsiz PDF, ePub ve çizgi roman görüntüleyici. |
| [Xournal++](https://xournalpp.github.io/) | 🟢 Evet | PDF üzerine açıklama ekleme destekli açık kaynaklı el yazısı ve not alma yazılımı. |
| [Zotero](https://www.zotero.org/) | 🟢 Evet | Araştırma kaynaklarınızı toplamanıza, düzenlemenize ve kaynakça oluşturmanıza yarayan ücretsiz akademik araç. |

</details>

<details>
<summary><strong>Geliştirme (43 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Amazon Corretto 21 (LTS)](https://aws.amazon.com/corretto) | 🟢 Evet | Amazon tarafından sağlanan ücretsiz, üretime hazır OpenJDK 21 (LTS) Java dağıtımı. |
| [Amazon Corretto 25 (LTS)](https://aws.amazon.com/corretto) | 🟢 Evet | Amazon tarafından sağlanan ücretsiz, üretime hazır OpenJDK 25 (LTS) Java dağıtımı. |
| [Amazon Corretto 8 (LTS)](https://aws.amazon.com/corretto) | 🟢 Evet | Amazon tarafından sağlanan ücretsiz, üretime hazır OpenJDK 8 (LTS) Java dağıtımı. |
| [Bruno](https://www.usebruno.com/) | 🟢 Evet | API koleksiyonlarını düz metin dosyaları olarak saklayan, sürüm kontrolü dostu yerel API istemcisi. |
| [ChatGPT Desktop](https://openai.com/chatgpt/download/) | — | Microsoft Store üzerinden dağıtılan resmi Windows ChatGPT masaüstü uygulaması. |
| [Claude Code](https://code.claude.com/) | — | Terminal ve IDE geliştirme akışları için Anthropic'in yapay zeka kodlama ajanı. |
| [Claude Desktop](https://claude.ai/download) | — | Yapay zeka destekli çalışma ve sohbet için Anthropic'in resmi Claude masaüstü uygulaması. |
| [CMake](https://cmake.org/) | 🟢 Evet | Yazılımları derlemek, test etmek ve paketlemek için açık kaynaklı, çapraz platform derleme aracı. |
| [Codex](https://developers.openai.com/codex/cli) | 🟢 Evet | Terminalinizde yerel olarak çalışan OpenAI kodlama ajanı (Codex CLI). |
| [Cursor](https://cursor.com/) | — | VS Code tabanlı, entegre yapay zeka destekli ve otonom kodlama özellikli kod editörü. |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | — | Windows üzerinde konteyner tabanlı uygulamalar oluşturmak, çalıştırmak ve test etmek için yerel ortam. |
| [Fast Node Manager](https://github.com/Schniz/fnm) | 🟢 Evet | Node.js sürümlerini hızla kurmanızı ve aralarında geçiş yapmanızı sağlayan çapraz platform araç. |
| [Git](https://git-scm.com/) | 🟢 Evet | Yazılım geliştirmede kaynak kod değişikliklerini takip etmek için yaygın dağıtık sürüm kontrol sistemi. |
| [Git Extensions](https://gitextensions.github.io/) | 🟢 Evet | Depo, geçmiş ve commit yönetimi sunan Windows için görsel Git istemcisi. |
| [GitHub CLI](https://cli.github.com/) | 🟢 Evet | Pull request, issue ve sürüm gibi GitHub iş akışlarını doğrudan terminale getiren komut satırı aracı. |
| [GitHub Desktop](https://desktop.github.com/) | 🟢 Evet | GitHub depolarında çalışmayı kolaylaştıran görsel Git istemcisi. |
| [Go](https://go.dev/) | 🟢 Evet | Sadelik, güvenilirlik ve verimlilik için tasarlanmış derlenen programlama dili (Go). |
| [Hugo](https://gohugo.io) | 🟢 Evet | Statik web siteleri oluşturmak için dünyanın en hızlı açık kaynaklı çatı araçlarından biri. |
| [Jetbrains Toolbox](https://www.jetbrains.com/toolbox/) | — | JetBrains geliştirici IDE'lerini kolayca kurmak ve güncellemek için yönetim aracı. |
| [Lazygit](https://github.com/jesseduffield/lazygit/) | 🟢 Evet | Git komutları için sade ve hızlı terminal arayüzü. |
| [Lua](https://github.com/rjpcomputing/luaforwindows) | 🟢 Evet | Windows için tüm temel araçları hazır içeren Lua betik dili ortamı. |
| [Neovim](https://neovim.io/) | 🟢 Evet | Vim editörünün modernleştirilmiş, yüksek derecede genişletilebilir terminal metin editörü. |
| [NodeJS](https://nodejs.org/) | 🟢 Evet | Sunucu tarafı ve ağ uygulamaları geliştirmek için Chrome V8 tabanlı JavaScript çalışma ortamı. |
| [NodeJS LTS](https://nodejs.org/) | 🟢 Evet | Kararlı ve uzun süreli destekli (LTS) Node.js JavaScript çalışma ortamı. |
| [Notepad++](https://notepad-plus-plus.org/) | 🟢 Evet | Çoklu dil ve sözdizimi vurgulama destekli ücretsiz, açık kaynaklı kod ve metin editörü. |
| [Oh My Posh (Komut İstemi)](https://ohmyposh.dev/) | 🟢 Evet | PowerShell ve diğer kabuklar için özelleştirilebilir, şık komut istemi tema motoru. |
| [OpenCode](https://opencode.ai/) | 🟢 Evet | Yerel ve bulut yapay zeka modellerini destekleyen açık kaynaklı terminal kodlama ajanı. |
| [pnpm](https://pnpm.io/) | 🟢 Evet | JavaScript ve Node.js projeleri için hızlı ve disk alanı dostu paket yöneticisi. |
| [Postman](https://www.postman.com/downloads/) | — | API tasarlama, test etme ve belgeleme için yaygın geliştirici masaüstü istemcisi. |
| [Python3](https://www.python.org/) | 🟢 Evet | Web geliştirme, veri analizi, otomasyon ve yapay zeka için çok yönlü Python 3 programlama dili. |
| [Ruby](https://rubyinstaller.org/) | 🟢 Evet | MSYS2 kurulumu ile birlikte gelen Ruby programlama dili çalışma ortamı. |
| [Rust](https://www.rust-lang.org/) | 🟢 Evet | Güvenlik ve yüksek performans için tasarlanmış sistem programlama dili (Rust). |
| [Starship (Kabuk İstemi)](https://starship.rs/) | 🟢 Evet | PowerShell ve diğer kabuklar için hızlı, minimalist ve özelleştirilebilir komut istemi. |
| [Sublime Text](https://www.sublimetext.com/) | — | Kod, biçimlendirme ve düz metin için son derece hızlı ve gelişmiş metin editörü. |
| [Unity Game Engine](https://unity.com/) | — | 2B, 3B, AR ve VR oyunlar geliştirmek için güçlü oyun motoru ve geliştirme platformu. |
| [uv](https://docs.astral.sh/uv/getting-started/installation/) | 🟢 Evet | Rust ile yazılmış, son derece hızlı modern Python paket ve proje yöneticisi. |
| [Vagrant](https://developer.hashicorp.com/vagrant) | — | Tekrarlanabilir sanal makine geliştirme ortamlarını kolayca oluşturup yöneten araç. |
| [Visual Studio 2022](https://visualstudio.microsoft.com/) | — | Uygulama geliştirme, hata ayıklama ve dağıtım için kapsamlı Microsoft Visual Studio 2022 IDE. |
| [Visual Studio 2026](https://visualstudio.microsoft.com/) | — | Uygulama geliştirme, hata ayıklama ve dağıtım için en yeni Microsoft Visual Studio 2026 IDE. |
| [VS Code](https://code.visualstudio.com/) | 🟢 Evet | Geniş eklenti ekosistemi ve çoklu dil desteğine sahip ücretsiz, açık kaynaklı kod editörü. |
| [VS Codium](https://vscodium.com/) | 🟢 Evet | Microsoft telemetrisi çıkarılmış, tamamen açık kaynaklı topluluk derlemesi VS Code. |
| [Yarn](https://yarnpkg.com/) | 🟢 Evet | JavaScript projeleri için hızlı, güvenilir ve güvenli bağımlılık/paket yöneticisi. |
| [Zed](https://zed.dev/) | 🟢 Evet | Hız ve gerçek zamanlı iş birliği için sıfırdan tasarlanmış modern, yüksek performanslı kod editörü. |

</details>

<details>
<summary><strong>Microsoft Araçları (19 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [.NET Desktop Runtime 10](https://dotnet.microsoft.com/download/dotnet/10.0) | 🟢 Evet | .NET 10 ile geliştirilmiş uygulamaları çalıştırmak için gereken çalışma zamanı ortamı. |
| [.NET Desktop Runtime 6](https://dotnet.microsoft.com/download/dotnet/6.0) | 🟢 Evet | .NET 6 ile geliştirilmiş uygulamaları çalıştırmak için gereken çalışma zamanı ortamı. |
| [.NET Desktop Runtime 8](https://dotnet.microsoft.com/download/dotnet/8.0) | 🟢 Evet | .NET 8 ile geliştirilmiş uygulamaları çalıştırmak için gereken çalışma zamanı ortamı. |
| [.NET Desktop Runtime 9](https://dotnet.microsoft.com/download/dotnet/9.0) | 🟢 Evet | .NET 9 ile geliştirilmiş uygulamaları çalıştırmak için gereken çalışma zamanı ortamı. |
| [Autoruns](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns) | — | Sistem açılışında ve oturum açıldığında hangi programların otomatik çalıştığını ayrıntılı şekilde gösteren Microsoft aracı. |
| [DISMTools](https://github.com/CodingWonders/DISMTools) | 🟢 Evet | Windows kalıplarını (ISO/WIM) yönetmek ve düzenlemek için hızlı, görsel arayüzlü DISM aracı. |
| [NTLite](https://ntlite.com) | — | Windows kurulum kalıplarına güncelleme ve sürücü entegre eden, kurulumu özelleştiren ve hızlandıran araç. |
| [NuGet](https://www.nuget.org/) | 🟢 Evet | .NET uygulamalarında kütüphane yönetimi ve paylaşımı sağlayan resmi paket yöneticisi. |
| [OneDrive](https://onedrive.live.com/) | — | Microsoft'un dosyalarınızı cihazlar arasında saklayıp eşitleyen bulut depolama servisi. |
| [PowerShell](https://github.com/PowerShell/PowerShell) | 🟢 Evet | Sistem yöneticileri ve geliştiriciler için modern, çapraz platform PowerShell 7 komut satırı ve betik ortamı. |
| [PowerToys](https://github.com/microsoft/PowerToys) | 🟢 Evet | FancyZones, PowerRename ve renk seçici gibi üretkenlik araçları sunan resmi Microsoft yardımcı araç paketi. |
| [Process Explorer](https://learn.microsoft.com/sysinternals/downloads/process-explorer) | — | Çalışan işlemleri, DLL'leri ve sistem kaynaklarını derinlemesine gösteren gelişmiş Sysinternals görev yöneticisi. |
| [Process Monitor](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon) | — | Dosya sistemi, kayıt defteri ve işlem etkinliklerini gerçek zamanlı izleyen gelişmiş Sysinternals aracı. |
| [PsTools](https://learn.microsoft.com/en-us/sysinternals/downloads/pstools) | — | Yerel ve uzak Windows sistemlerini yönetmek için Sysinternals komut satırı araçları (PsExec vb.). |
| [RDCMan](https://learn.microsoft.com/en-us/sysinternals/downloads/rdcman) | — | Birden fazla uzak masaüstü (RDP) bağlantısını tek pencereden yönetmeye yarayan Microsoft aracı. |
| [TCPView](https://docs.microsoft.com/en-us/sysinternals/downloads/tcpview) | — | Sisteminizdeki tüm etkin TCP ve UDP ağ bağlantılarını gerçek zamanlı listeleyen Sysinternals aracı. |
| [Visual C++ 2015-2022 32-bit](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads) | — | 32-bit C++ uygulamalarının çalışması için gereken Microsoft Visual C++ 2015-2022 çalışma zamanı paketi. |
| [Visual C++ 2015-2022 64-bit](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads) | — | 64-bit C++ uygulamalarının çalışması için gereken Microsoft Visual C++ 2015-2022 çalışma zamanı paketi. |
| [Windows Terminal](https://aka.ms/terminal) | 🟢 Evet | Çoklu sekme ve bölme destekli, modern ve hızlı resmi Microsoft Windows Terminal uygulaması. |

</details>

<details>
<summary><strong>Multimedya Araçları (21 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [AIMP (Müzik Çalar)](https://www.aimp.ru/) | — | Çeşitli ses formatları, çalma listeleri ve özelleştirilebilir arayüz desteği sunan zengin özellikli müzik çalar. |
| [Audacity](https://www.audacityteam.org/) | 🟢 Evet | Güçlü ses kayıt ve düzenleme yetenekleriyle tanınan ücretsiz, açık kaynaklı ses düzenleme yazılımı. |
| [Blender (3B Grafik)](https://www.blender.org/) | 🟢 Evet | Modelleme, heykel, animasyon ve render araçları sunan güçlü, açık kaynaklı 3B tasarım yazılımı. |
| [Calibre](https://calibre-ebook.com/) | 🟢 Evet | Güçlü ve kullanımı kolay e-kitap yöneticisi, görüntüleyicisi ve format dönüştürücüsü. |
| [EarTrumpet (Ses Kontrolü)](https://eartrumpet.app/) | 🟢 Evet | Windows için uygulama bazlı ses düzeylerini kolayca yönetmeyi sağlayan gelişmiş ses kontrol aracı. |
| [File Converter](https://file-converter.io/) | 🟢 Evet | Dosya Gezgini sağ tık menüsünden doğrudan dosya dönüştürme ve sıkıştırma yapan araç. |
| [foobar2000 (Müzik Çalar)](https://www.foobar2000.org/) | — | Modüler yapısı ve gelişmiş özellikleriyle tanınan, son derece özelleştirilebilir müzik çalar. |
| [GIMP (Görsel Düzenleyici)](https://www.gimp.org/) | 🟢 Evet | Fotoğraf rötuşlama, görsel düzenleme ve grafik tasarım için güçlü açık kaynaklı görsel düzenleyici. |
| [HandBrake](https://handbrake.fr/) | 🟢 Evet | Videoları neredeyse her formattan yaygın kodeklere dönüştürebilen açık kaynaklı video dönüştürücü. |
| [ImageGlass (Görsel Görüntüleyici)](https://imageglass.org/) | 🟢 Evet | Hız ve sadeliğe odaklanan, çok sayıda görsel formatını destekleyen modern resim görüntüleyici. |
| [IrfanView](https://irfanview.com/) | — | Çoklu format, toplu işleme ve eklenti desteği sunan hafif, hızlı ve ücretsiz resim görüntüleyici. |
| [iTunes](https://www.apple.com/itunes/) | — | Apple tarafından geliştirilen medya oynatıcı, müzik kütüphanesi ve cihaz yönetim uygulaması. |
| [K-Lite Codec Standard](https://www.codecguide.com/) | — | Tüm yaygın ses ve video dosyalarını sorunsuz oynatmak için gerekli kodek paketi (Standart). |
| [Media Player Classic - Home Cinema](https://mpc-hc.org/) | 🟢 Evet | Windows için ücretsiz, hafif ve açık kaynaklı klasik video ve ses oynatıcısı (MPC-HC). |
| [mpc-qt](https://mpc-qt.github.io) | 🟢 Evet | Media Player Classic tarzında modern, açık kaynaklı video oynatıcı. |
| [mpv](https://mpv.io/) | 🟢 Evet | Geniş kodek ve altyazı desteği sunan ücretsiz, açık kaynaklı ve yüksek performanslı medya oynatıcı. |
| [nomacs](https://nomacs.org/) | 🟢 Evet | RAW ve PSD dahil tüm yaygın görsel formatlarını destekleyen ücretsiz, açık kaynaklı resim görüntüleyici. |
| [OBS Studio](https://obsproject.com/) | 🟢 Evet | Video kaydı ve canlı yayın için ücretsiz, açık kaynaklı ve en yaygın içerik üretici yazılımı. |
| [Paint.NET](https://www.getpaint.net/) | — | Kullanıcı dostu arayüze ve güçlü düzenleme araçlarına sahip ücretsiz Windows resim ve fotoğraf editörü. |
| [ShareX (Ekran Görüntüsü)](https://getsharex.com/) | 🟢 Evet | Gelişmiş düzenleme, ekran kaydı ve hızlı paylaşım özellikleri sunan ücretsiz, açık kaynaklı ekran görüntüsü aracı. |
| [VLC (Video Oynatıcı)](https://www.videolan.org/vlc/) | 🟢 Evet | Neredeyse tüm ses ve video formatlarını ek kodek gerekmeden oynatan ücretsiz, açık kaynaklı medya oynatıcı. |

</details>

<details>
<summary><strong>Oyunlar (17 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Battle.net](https://battle.net) | — | Activision Blizzard oyunlarını indirmek ve başlatmak için resmi oyun platformu. |
| [Cemu](https://cemu.info/) | 🟢 Evet | PC üzerinde Wii U oyun ve uygulamalarını çalıştırmayı sağlayan emülatör. |
| [CurseForge](https://www.overwolf.com/app/overwolf-curseforge) | — | Overwolf destekli, birçok oyun için mod ve mod paketlerini yöneten CurseForge masaüstü uygulaması. |
| [EA App](https://www.ea.com/ea-app) | — | Electronic Arts (EA) oyunlarına erişmek ve oynamak için resmi oyun platformu. |
| [EmulationStation Desktop Edition](https://es-de.org/) | 🟢 Evet | Çoklu platform oyun koleksiyonunuza göz atmak ve başlatmak için masaüstü emülatör arayüzü. |
| [Epic Games Launcher](https://www.epicgames.com/store/en-US/) | — | Epic Games Store'daki oyunları indirmek ve oynamak için resmi başlatıcı. |
| [GeForce NOW](https://www.nvidia.com/en-us/geforce-now/) | — | Yüksek kaliteli PC oyunlarını bulut üzerinden cihazınızda oynamanızı sağlayan bulut oyun servisi. |
| [GOG Galaxy](https://www.gog.com/galaxy) | — | DRM'siz oyunlar ve birleşik oyun kütüphanesi sunan GOG oyun istemcisi. |
| [Heroic Games Launcher](https://heroicgameslauncher.com/) | 🟢 Evet | Epic Games Store, GOG ve Amazon Games için açık kaynaklı alternatif oyun başlatıcı. |
| [Itch.io](https://itch.io/) | 🟢 Evet | Bağımsız (indie) oyunlar ve yaratıcı projeler için dijital dağıtım platformu. |
| [Modrinth App](https://modrinth.com/app) | 🟢 Evet | Minecraft modlarını ve mod paketlerini yönetmek için masaüstü uygulaması. |
| [Playnite](https://playnite.link/) | 🟢 Evet | Tüm oyun mağazalarındaki ve emülatörlerdeki oyunlarınızı tek bir arayüzde toplayan açık kaynaklı oyun kütüphanesi. |
| [Prism Launcher](https://prismlauncher.org/) | 🟢 Evet | Çoklu profil, hesap ve mod yönetimi sunan açık kaynaklı Minecraft başlatıcısı. |
| [Roblox](https://www.roblox.com/) | — | Topluluk tarafından oluşturulan oyunları oynamanızı ve kendi oyunlarınızı geliştirmenizi sağlayan platform. |
| [Steam](https://store.steampowered.com/about/) | — | PC oyunları satın almak, indirmek ve çok oyunculu oynamak için en yaygın dijital oyun platformu. |
| [Ubisoft Connect](https://ubisoftconnect.com/) | — | Ubisoft oyunlarına erişmek ve oynamak için resmi dijital oyun platformu. |
| [Virtual Desktop Streamer](https://www.vrdesktop.net/) | — | Bilgisayar ekranınızı sanal gerçeklik (VR) başlıklarına akışla aktaran yardımcı uygulama. |

</details>

<details>
<summary><strong>Profesyonel Araçlar (24 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Advanced IP Scanner](https://www.advanced-ip-scanner.com/) | — | Yerel ağları (LAN) analiz ederek bağlı cihazlar hakkında bilgi veren hızlı ve kolay ağ tarayıcı. |
| [Angry IP Scanner](https://angryip.org/) | 🟢 Evet | IP adreslerini ve portları tarayarak ağ bağlantısı bilgisi sunan açık kaynaklı, çapraz platform ağ tarayıcı. |
| [Cinebench R23](https://www.maxon.net/en/cinebench) | — | İşlemci (CPU) render performansını karşılaştırmak için kullanılan kıyaslama (benchmark) aracı. |
| [CPU-Z](https://www.cpuid.com/softwares/cpu-z.html) | — | İşlemci, bellek (RAM) ve anakart gibi donanım bileşenleri hakkında ayrıntılı bilgi sunan sistem tanılama aracı. |
| [Display Driver Uninstaller](https://www.wagnardsoft.com/display-driver-uninstaller-DDU-) | 🟢 Evet | NVIDIA, AMD ve Intel ekran kartı sürücülerini kalıntı bırakmadan tamamen kaldıran sorun giderme aracı. |
| [GPU-Z](https://www.techpowerup.com/gpuz/) | — | Ekran kartınız ve grafik işlemciniz (GPU) hakkında ayrıntılı teknik bilgi ve sensör verileri sunar. |
| [gsudo](https://github.com/gerardog/gsudo) | 🟢 Evet | Mevcut konsol penceresinde doğrudan yönetici yetkisiyle komut çalıştırmayı sağlayan Windows 'sudo' aracı. |
| [HWiNFO](https://www.hwinfo.com/) | — | Windows için kapsamlı donanım bilgisi, sensör izleme ve sistem tanılama aracı. |
| [HWMonitor](https://www.cpuid.com/softwares/hwmonitor.html) | — | Bilgisayarın sıcaklık, voltaj ve fan hızı gibi temel sağlık sensörlerini okuyan donanım izleme programı. |
| [ImHex](https://imhex.werwolv.net/) | 🟢 Evet | Tersine mühendislik ve geliştiriciler için açık kaynaklı hex editörü, ayrıştırıcı ve veri analiz aracı. |
| [MSI Afterburner](https://www.msi.com/Landing/afterburner) | — | Ekran kartı hız aşırtma (overclock), fan kontrolü ve oyun içi FPS izleme aracı. |
| [Mullvad VPN](https://mullvad.net/) | 🟢 Evet | Gizlilik odaklı Mullvad VPN servisinin resmi istemci yazılımı. |
| [Nmap](https://nmap.org/) | 🟢 Evet | Ağ keşfi, port tarama ve güvenlik denetimi için açık kaynaklı ağ analiz aracı. |
| [OpenVPN Connect](https://openvpn.net/) | — | OpenVPN sunucularına güvenli ve şifreli şekilde bağlanmanızı sağlayan resmi VPN istemcisi. |
| [Proton VPN](https://protonvpn.com/) | 🟢 Evet | Kayıt tutmayan, Secure Core ve Tor over VPN özellikli gizlilik odaklı VPN istemcisi. |
| [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/) | 🟢 Evet | SSH, Telnet ve seri konsol bağlantılarını destekleyen ücretsiz, açık kaynaklı terminal emülatörü. |
| [Rufus Imager](https://rufus.ie/) | 🟢 Evet | ISO dosyalarından önyüklenebilir (bootable) Windows/Linux USB bellekleri oluşturan hızlı araç. |
| [Simplewall](https://github.com/henrypp/simplewall) | 🟢 Evet | Uygulamaların gelen ve giden ağ trafiğini kontrol etmenizi sağlayan hafif, açık kaynaklı Windows güvenlik duvarı. |
| [System Informer](https://systeminformer.com/) | 🟢 Evet | Sistem kaynaklarını izleme, yazılım hata ayıklama ve zararlı tespitine yardımcı güçlü açık kaynaklı araç. |
| [Tailscale](https://tailscale.com/) | — | WireGuard tabanlı, cihazlarınızı zahmetsizce özel ve güvenli bir ağda birleştiren VPN istemcisi. |
| [Ventoy](https://www.ventoy.net/) | 🟢 Evet | Tek bir USB belleğe birden fazla ISO dosyası atıp önyüklemenizi sağlayan açık kaynaklı araç. |
| [WinSCP](https://winscp.net/) | 🟢 Evet | Yerel ve uzak bilgisayarlar arasında güvenli dosya aktarımı sağlayan açık kaynaklı SFTP, FTP ve SCP istemcisi. |
| [WireGuard](https://www.wireguard.com/) | 🟢 Evet | Hızlı, modern, sade ve yüksek güvenlikli açık kaynaklı VPN protokolü istemcisi. |
| [Wireshark](https://www.wireshark.org/) | 🟢 Evet | Ağ trafiğini gerçek zamanlı yakalayıp derinlemesine inceleyen açık kaynaklı ağ protokol analizörü. |

</details>

<details>
<summary><strong>Sunucu Araçları (12 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Jellyfin Media Player](https://jellyfin.org/) | 🟢 Evet | Jellyfin medya sunucunuzdaki içeriklere erişip izlemenizi sağlayan masaüstü istemcisi. |
| [Jellyfin Server](https://jellyfin.org/) | 🟢 Evet | Kişisel medya arşivinizi düzenleyip yayınlamanızı sağlayan ücretsiz, açık kaynaklı medya sunucusu. |
| [Kodi Media Center](https://kodi.tv/) | 🟢 Evet | Video, müzik, podcast ve dijital medyalarınızı oynatıp yöneten açık kaynaklı medya merkezi. |
| [LocalSend](https://localsend.org/) | 🟢 Evet | Aynı yerel ağdaki cihazlar arasında dosya paylaşımı sağlayan açık kaynaklı AirDrop alternatifi. |
| [Moonlight/GameStream Client](https://moonlight-stream.org/) | 🟢 Evet | PC oyunlarınızı yerel ağ üzerinden diğer cihazlara düşük gecikmeyle yayınlayan istemci. |
| [NetBird](https://netbird.io/) | 🟢 Evet | Kendi sunucunuza da bağlanabilen, Tailscale benzeri açık kaynaklı WireGuard ağ aracı. |
| [Nextcloud Desktop](https://nextcloud.com/install/#install-clients) | 🟢 Evet | Nextcloud dosya eşitleme ve paylaşım platformunun resmi masaüstü istemcisi. |
| [Plex Desktop](https://www.plex.tv) | — | Plex Media Server için resmi Windows masaüstü izleme uygulaması. |
| [Plex Media Server](https://www.plex.tv/your-media/) | — | Kişisel film, dizi ve müzik arşivinizi düzenleyip tüm cihazlara yayınlayan medya sunucusu. |
| [Sunshine/GameStream Server](https://app.lizardbyte.dev/Sunshine/) | 🟢 Evet | PC oyunlarınızı diğer cihazlara düşük gecikmeyle yayınlamanızı sağlayan açık kaynaklı GameStream sunucusu. |
| [Syncthing (CLI / Web UI)](https://syncthing.net/) | 🟢 Evet | Bulut sunucusu olmadan cihazlar arasında doğrudan, şifreli dosya eşitleme yapan açık kaynaklı araç. |
| [SyncTrayzor](https://github.com/GermanCoding/SyncTrayzor) | — | Syncthing dosya eşitleme aracını yerel sistem tepsisi uygulaması gibi yönetmeyi kolaylaştıran Windows arayüzü. |

</details>

<details>
<summary><strong>Tarayıcılar (15 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Brave](https://www.brave.com) | 🟢 Evet | Reklamları ve izleyicileri yerleşik olarak engelleyen, hızlı ve gizlilik odaklı web tarayıcısı. |
| [Chrome](https://www.google.com/chrome/) | — | Hızı, sadeliği ve Google servisleriyle entegrasyonuyla tanınan yaygın web tarayıcısı. |
| [Chromium](https://www.chromium.org/) | 🟢 Evet | Chrome dahil birçok modern web tarayıcısının temelini oluşturan açık kaynaklı tarayıcı projesi. |
| [Edge](https://www.microsoft.com/edge) | — | Chromium tabanlı, Microsoft servisleriyle entegre modern web tarayıcısı. |
| [Firefox](https://www.mozilla.org/en-US/firefox/new/) | 🟢 Evet | Özelleştirme seçenekleri, gizlilik özellikleri ve eklentileriyle tanınan açık kaynaklı web tarayıcısı. |
| [Firefox ESR](https://www.mozilla.org/en-US/firefox/enterprise/) | 🟢 Evet | Uzun süreli destek (ESR) sürümüne sahip, kararlılık ve güvenlik güncellemelerine odaklanan Mozilla Firefox. |
| [Floorp](https://floorp.app/) | 🟢 Evet | Sade, hızlı ve özelleştirilebilir bir gezinme deneyimi sunan açık kaynaklı web tarayıcısı. |
| [Helium](https://helium.computer) | 🟢 Evet | Gizlilik odaklı, hızlı ve sade web tarayıcısı. |
| [LibreWolf](https://librewolf.net/) | 🟢 Evet | Firefox tabanlı, ek gizlilik ve güvenlik sertleştirmeleri içeren açık kaynaklı tarayıcı. |
| [Mullvad Browser](https://mullvad.net/browser) | 🟢 Evet | Tor Projesi iş birliğiyle geliştirilen, izleme karşıtı gizlilik odaklı web tarayıcısı. |
| [Tor Browser](https://www.torproject.org/) | 🟢 Evet | Tor ağını kullanarak çevrimiçi gizlilik ve anonim web gezintisi sağlayan tarayıcı. |
| [Ungoogled Chromium](https://github.com/Eloston/ungoogled-chromium) | 🟢 Evet | Daha yüksek gizlilik için Google servisleri ve entegrasyonları çıkarılmış Chromium tarayıcısı. |
| [Vivaldi](https://vivaldi.com/) | — | Kişiselleştirme ve üretkenlik özelliklerine odaklanan son derece özelleştirilebilir web tarayıcısı. |
| [Waterfox](https://www.waterfox.net/) | 🟢 Evet | Kullanıcı seçimi ve gizliliğini korumaya odaklanan hızlı, Firefox tabanlı web tarayıcısı. |
| [Zen Browser](https://zen-browser.app/) | 🟢 Evet | Firefox tabanlı, modern, gizlilik ve performans odaklı yeni nesil web tarayıcısı. |

</details>

<details>
<summary><strong>Yardımcı Programlar (53 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [1Password](https://1password.com/) | — | Parolalarınızı güvenli bir şekilde saklamanızı ve yönetmenizi sağlayan parola yöneticisi. |
| [7-Zip](https://www.7-zip.org/) | 🟢 Evet | Yüksek sıkıştırma oranı ve geniş format desteği sunan ücretsiz, açık kaynaklı dosya arşivleme aracı. |
| [AB Download Manager](https://abdownloadmanager.com/) | 🟢 Evet | Çoklu iş parçacıklı indirme, kuyruk zamanlama, hız sınırlama ve tarayıcı entegrasyonu sunan açık kaynaklı indirme yöneticisi. |
| [AnyDesk](https://anydesk.com/) | — | Hızlı bağlantı ve düşük gecikme ile bilinen uzaktan masaüstü erişim ve kontrol yazılımı. |
| [AutoHotkey](https://www.autohotkey.com/) | 🟢 Evet | Windows için özel otomasyon betikleri, makrolar ve klavye kısayolları oluşturmanızı sağlayan betik dili. |
| [Bitwarden](https://bitwarden.com/) | 🟢 Evet | Parolalarınızı şifreli bir kasada birden fazla cihazda eşitleyerek saklayan açık kaynaklı parola yöneticisi. |
| [BlurAutoClicker](https://blur009.vercel.app/projects/blur-autoclicker/) | 🟢 Evet | Gelişmiş özelliklere ve yüksek performansa sahip otomatik tıklama aracı. |
| [Bulk Crap Uninstaller](https://www.bcuninstaller.com/) | 🟢 Evet | İstenmeyen programları toplu olarak ve kalıntı bırakmadan kaldırmaya yarayan ücretsiz, açık kaynaklı kaldırıcı. |
| [Cloudflare WARP](https://one.one.one.one) | — | Cloudflare DNS desteği de sunan ücretsiz/freemium hızlı VPN ve gizlilik uygulaması. |
| [Crystal Disk Info](https://crystalmark.info/en/software/crystaldiskinfo/) | 🟢 Evet | Sabit disk ve SSD'lerin sağlık durumunu ve S.M.A.R.T. verilerini izleyen disk sağlığı aracı. |
| [Crystal Disk Mark](https://crystalmark.info/en/software/crystaldiskmark/) | 🟢 Evet | Sabit disk ve SSD'lerin okuma ve yazma hızlarını ölçen disk performans testi aracı. |
| [Deskflow](https://github.com/deskflow/deskflow) | 🟢 Evet | Tek bir klavye ve fareyi ağ üzerinden birden fazla bilgisayarda paylaşmanızı sağlayan açık kaynaklı yazılım KVM. |
| [Dropbox](https://www.dropbox.com/desktop) | — | Dosyalarınızı cihazlar arasında eşitleyen ve paylaşmanızı sağlayan bulut depolama istemcisi. |
| [Ente Auth](https://ente.io/auth/) | 🟢 Evet | Ücretsiz, çapraz platform ve uçtan uca şifreli iki faktörlü doğrulama (2FA) uygulaması. |
| [Everything](https://www.voidtools.com/) | — | Windows'taki tüm dosya ve klasörleri adlarına göre milisaniyeler içinde bulan anlık arama motoru. |
| [F.lux](https://justgetflux.com/) | — | Gece kullanımında göz yorgunluğunu azaltmak için ekran renk sıcaklığını otomatik ayarlayan araç. |
| [Files](https://files.community) | 🟢 Evet | Modern tasarımlı, sekmeli alternatif Windows dosya yöneticisi. |
| [GlazeWM](https://github.com/glzr-io/glazewm) | 🟢 Evet | i3 ve Polybar'dan esinlenen, Windows için döşemeli (tiling) pencere yöneticisi. |
| [Google Drive](https://www.google.com/drive/) | — | Dosyalarınızı Google hesabınızla tüm cihazlar arasında eşitleyen bulut depolama istemcisi. |
| [HxD Hex Editor](https://mh-nexus.de/en/hxd/) | — | İkili (binary) dosyaları görüntülemek, düzenlemek ve analiz etmek için ücretsiz hex editörü (HxD). |
| [Internet Download Manager](https://www.internetdownloadmanager.com/) | — | Dosya indirmelerini hızlandıran, duraklatıp devam ettirebilen ve zamanlayabilen indirme yöneticisi (IDM). |
| [JPEG View](https://github.com/sylikc/jpegview) | 🟢 Evet | JPEG, PNG, WEBP, HEIC, AVIF ve TIFF gibi formatlar için minimalist ve çok hızlı resim görüntüleyici. |
| [KeePassXC](https://keepassxc.org/) | 🟢 Evet | Parolalarınızı çevrimdışı şifreli bir dosyada güvenle saklayan modern, açık kaynaklı parola yöneticisi. |
| [MiniTool Partition Wizard](https://www.partitionwizard.com/) | — | Bölüm birleştirme, dosya sistemi dönüştürme ve disk yönetimi sunan kapsamlı ücretsiz disk bölümleme aracı. |
| [MSEdgeRedirect](https://github.com/rcmaehl/MSEdgeRedirect) | 🟢 Evet | Windows Haberler, Arama ve Widget bağlantılarını Edge yerine varsayılan tarayıcınıza yönlendiren araç. |
| [NanaZip](https://nanazip.org) | 🟢 Evet | 7-Zip tabanlı, modern Windows 11 sağ tık menüsü destekli hızlı arşivleme aracı. |
| [Nilesoft Shell](https://nilesoft.org/) | — | Windows sağ tık bağlam menüsünü özelleştiren ve ek işlevler kazandıran güçlü araç. |
| [NVCleanstall](https://www.techpowerup.com/nvcleanstall/) | — | NVIDIA ekran kartı sürücü kurulumunu özelleştirerek yalnızca istediğiniz bileşenleri kurmanızı sağlayan araç. |
| [OFGB (Oh Frick Go Back)](https://github.com/xM4ddy/OFGB) | 🟢 Evet | Windows 11'in çeşitli yerlerindeki reklamları kolayca kapatmaya yarayan görsel araç. |
| [OPAutoClicker](https://www.opautoclicker.com) | — | İmleç konumunda veya belirli koordinatta çalışabilen iki modlu otomatik tıklama aracı. |
| [OpenRGB](https://openrgb.org/) | 🟢 Evet | Farklı marka donanım ve çevre birimlerinin RGB aydınlatmasını tek yerden yöneten açık kaynaklı yazılım. |
| [Oracle VirtualBox](https://www.virtualbox.org/) | 🟢 Evet | Bilgisayarınızda sanal işletim sistemleri çalıştırmanızı sağlayan ücretsiz, açık kaynaklı sanallaştırma yazılımı. |
| [Parsec](https://parsec.app/) | — | Oyun ve ortak çalışma için ultra düşük gecikmeli, yüksek kaliteli uzak masaüstü paylaşım uygulaması. |
| [PeaZip](https://peazip.github.io/) | 🟢 Evet | Çoklu arşiv formatı ve güçlü şifreleme desteği sunan ücretsiz, açık kaynaklı arşiv yöneticisi. |
| [Policy Plus](https://github.com/Fleex255/PolicyPlus) | 🟢 Evet | Home sürümü dahil tüm Windows sürümlerinde Yerel Grup İlkesi Düzenleyicisi (gpedit) sağlayan araç. |
| [Process Lasso](https://bitsum.com/) | — | İşlem önceliklerini ve CPU çekirdek atamalarını optimize ederek sistem akıcılığını artıran araç. |
| [Proton Authenticator](https://proton.me/authenticator) | 🟢 Evet | İki faktörlü doğrulama (2FA) kodlarınızı güvenle eşitleyip yedekleyen Proton uygulaması. |
| [Proton Drive](https://proton.me/drive) | 🟢 Evet | Dosyalarınızı İsviçre gizlilik standartlarında uçtan uca şifreleyerek koruyan bulut depolama. |
| [Proton Pass](https://proton.me/pass) | 🟢 Evet | Uçtan uca şifreli, benzersiz e-posta takma adları sunan bulut tabanlı parola yöneticisi. |
| [qBittorrent](https://www.qbittorrent.org/) | 🟢 Evet | Hafif, reklamsız, ücretsiz ve açık kaynaklı BitTorrent indirme istemcisi. |
| [Revo Uninstaller](https://www.revouninstaller.com/) | — | İstenmeyen programları kayıt defteri ve dosya kalıntılarıyla birlikte temizleyen gelişmiş kaldırıcı. |
| [SignalRGB](https://www.signalrgb.com/) | — | Farklı markalardaki RGB cihazlarınızı tek bir ücretsiz uygulamadan kontrol edip senkronize eder. |
| [Snappy Driver Installer Origin](https://www.glenn.delahoy.com/snappy-driver-installer-origin/) | 🟢 Evet | Geniş sürücü veritabanına sahip ücretsiz, açık kaynaklı Windows sürücü güncelleme aracı. |
| [StartAllBack](https://www.startallback.com/) | — | Windows 11 görev çubuğunu, Başlat menüsünü ve Dosya Gezgini'ni klasik ve geliştirilmiş hale getirir. |
| [TeamViewer](https://www.teamviewer.com/) | — | Uzak bilgisayarlara bağlanıp destek ve kontrol sağlayan popüler uzaktan erişim yazılımı. |
| [TightVNC](https://www.tightvnc.com/) | 🟢 Evet | Ağ üzerinden başka bir bilgisayara erişip kontrol etmenizi sağlayan ücretsiz, açık kaynaklı uzak masaüstü yazılımı. |
| [Total Commander](https://www.ghisler.com/) | — | Çift panelli arayüzüyle güçlü ve hızlı klasik Windows dosya yöneticisi. |
| [TranslucentTB](https://translucenttb.github.io) | 🟢 Evet | Windows görev çubuğunun şeffaflığını ve görünümünü özelleştirmenizi sağlayan hafif araç. |
| [TreeSize Free](https://www.jam-software.com/treesize_free/) | — | Sürücülerinizde en çok yer kaplayan klasörleri hızlıca analiz edip görselleştiren disk analiz aracı. |
| [UniGetUI](https://devolutions.net/unigetui/) | 🟢 Evet | WinGet, Chocolatey ve diğer Windows paket yöneticileri için modern görsel arayüz (UniGetUI). |
| [WinRAR](https://www.win-rar.com/) | — | RAR ve ZIP arşivleri oluşturma, yönetme ve çıkarma için güçlü arşiv yöneticisi. |
| [Wise Program Uninstaller (WiseCleaner)](https://www.wisecleaner.com/wise-program-uninstaller.html) | — | Windows programlarını hızlı, eksiksiz ve kalıntısız kaldırmak için kullanıcı dostu araç. |
| [WizTree](https://wiztreefree.com/) | — | Sabit diskinizde en çok yer kaplayan dosya ve klasörleri saniyeler içinde bulan ultra hızlı disk analiz aracı. |

</details>

<details>
<summary><strong>İletişim (18 uygulama)</strong></summary>

| Uygulama | Açık Kaynak | Açıklama |
| :--- | :---: | :--- |
| [Betterbird](https://www.betterbird.eu/) | 🟢 Evet | Ek özellikler ve hata düzeltmeleri içeren geliştirilmiş Mozilla Thunderbird çatalı. |
| [Chatterino](https://www.chatterino.com/) | 🟢 Evet | Daha akıcı bir yayın deneyimi için temiz ve özelleştirilebilir Twitch sohbet istemcisi. |
| [Discord](https://discord.com/) | — | Sesli, görüntülü ve yazılı sohbet sunan, oyuncular ve topluluklar arasında popüler iletişim platformu. |
| [Dorion](https://spikehd.dev/projects/dorion/) | 🟢 Evet | Daha düşük bellek tüketimi, hızlı açılış, tema ve eklenti desteği sunan hafif alternatif Discord istemcisi. |
| [Element](https://element.io/) | 🟢 Evet | Güvenli ve merkeziyetsiz iletişim ağı Matrix için resmi Element istemcisi. |
| [Proton Mail](https://proton.me/mail) | 🟢 Evet | Sıfır erişimli uçtan uca şifreleme ile gizliliğinizi koruyan Proton e-posta uygulaması. |
| [QTox](https://qtox.github.io/) | 🟢 Evet | Gizlilik ve güvenliği ön planda tutan ücretsiz, açık kaynaklı mesajlaşma uygulaması. |
| [Signal](https://signal.org/) | 🟢 Evet | Uçtan uca şifreleme ile güvenli ve gizli iletişim sunan gizlilik odaklı mesajlaşma uygulaması. |
| [Slack](https://slack.com/) | — | Kanallar, mesajlaşma ve dosya paylaşımıyla ekipleri bir araya getiren iş birliği platformu. |
| [Teams](https://www.microsoft.com/en-us/microsoft-teams/group-chat-software) | — | Sohbet, görüntülü toplantı ve dosya paylaşımı sunan Microsoft iş birliği uygulaması. |
| [TeamSpeak 3](https://www.teamspeak.com/) | — | Düşük gecikmeli, kristal netliğinde sesli iletişim sunan klasik TeamSpeak 3 istemcisi. |
| [TeamSpeak 6](https://www.teamspeak.com/) | — | Modern arayüzlü, yüksek ses kaliteli ve düşük gecikmeli yeni nesil TeamSpeak 6 istemcisi. |
| [Telegram](https://telegram.org/) | 🟢 Evet | Hızı, bulut eşitlemesi ve güvenlik özellikleriyle tanınan anlık mesajlaşma uygulaması. |
| [Thunderbird](https://www.thunderbird.net/) | 🟢 Evet | Gelişmiş özelliklere sahip ücretsiz ve açık kaynaklı Mozilla e-posta, haber ve takvim istemcisi. |
| [Vesktop](https://vesktop.dev) | 🟢 Evet | Vencord eklentisi hazır kurulu gelen, daha akıcı ve çapraz platform alternatif Discord masaüstü uygulaması. |
| [Viber](https://www.viber.com/) | — | Grup sohbetleri, sesli ve görüntülü aramalar sunan ücretsiz mesajlaşma uygulaması. |
| [WhatsApp Desktop](https://www.whatsapp.com/download) | — | Microsoft Store üzerinden dağıtılan resmi Meta WhatsApp Windows masaüstü uygulaması. |
| [Zoom](https://zoom.us/) | — | Çevrimiçi toplantılar, web seminerleri ve görüntülü görüşmeler için popüler konferans uygulaması. |

</details>

---

[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)
