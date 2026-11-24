# Değişiklik Günlüğü (CHANGELOG)

**WinUtil Türkçe** projesindeki tüm sürümler ve yenilikler aşağıda yer alır. Her yeni sürümle birlikte [`WinUtil-TR.exe`](https://github.com/edizdar/winutil-tr/releases/latest), `winutil.ps1`, dokümantasyon rehberleri ve GitHub Releases sayfası eşzamanlı güncellenir.

---

## v2.0 — 2026-11-24
### Yeni Üst Sekme: `Uygulamalarım` (Canlı `github.com/edizdar` Açık Kaynak Kataloğu)
- **Canlı GitHub Senkronizasyonu:** Üst menüye eklenen **Uygulamalarım** (*My Apps*, kısayol `Alt+U`) sekmesi, [github.com/edizdar?tab=repositories](https://github.com/edizdar?tab=repositories) üzerindeki tüm herkese açık projeleri, açıklamalarını, programlama dillerini ve en güncel GitHub Release sürümlerini **API hız limitine takılmadan** canlı olarak listeler.
- **Tek Tıkla İndir ve Çalıştır:** Windows (`.exe` / `.msi`) yayını bulunan projelerde (**İndir ve Çalıştır**) dosyayı canlı ilerleme çubuğuyla `İndirilenler\ErolDizdar\<Proje>\` klasörüne indirip isteğe bağlı olarak hemen başlatır; Android (`.apk`) yayını bulunan projelerde en güncel sürümü indirip klasörde seçili olarak açar.
- **Platform Filtreleri & Tam Çift Dil:** *Tümü*, *Windows (.exe / .msi)*, *Android (.apk)* ve *Kaynak Kod / Diğer* filtre çipleri + tam Türkçe / English desteği eklendi.

---

## v1.9 — 2026-11-24
### Sadeleştirilmiş 5 Sekmeli Üst Menü ve Birleştirilmiş `Güncellemeler` Alt Sekmesi
- **Güncellemeler Artık `Sistem & Bakım` Altında:** Windows Update profil yönetimi (*Önerilen*, *Windows Varsayılanı*, *Güncellemeleri Kapat*) **Sistem & Bakım** merkezinin 6. alt sekmesi (**Güncellemeler**) olarak entegre edildi; `Alt+G` kısayolu doğrudan bu alt sekmeye yönlendirir.
- **Daha Ferah Üst Menü:** Üst gezinme çubuğu 5 temiz ana sekmeden oluşur: `İnce Ayarlar` → `Yapılandırma` → `Win11 Oluşturucu` → `Sistem & Bakım` → `Kurulum`.

---

## v1.8 — 2026-11-24
### Arayüz ve Başlangıç Deneyimi İyileştirmesi
- **Açılış Ekranı `İnce Ayarlar` Oldu:** WinUtil Türkçe artık doğrudan **İnce Ayarlar** sekmesiyle açılır ve bilgisayarınızda zaten uygulanan ayarlar anında yeşil `✓ Uygulu` rozetleriyle görünür.
- **Sekme Sıralaması Yenilendi:** **Kurulum** sekmesi üst menüde en sağa taşındı (`İnce Ayarlar` → `Yapılandırma` → `Güncellemeler` → `Win11 Oluşturucu` → `Sistem & Bakım` → `Kurulum`); `Kurulum` sekmesi arka planda otomatik ön yüklenerek (warm-up) tıklandığında gecikmesiz açılır.

---

## v1.7 — 2026-11-24
### Yeni Özellik: Yüklü Programlar ve Derin Kaldırıcı (Program Ekle/Kaldır + Regedit/AppData/TEMP)
- **Yeni 5. Alt Sekme (`Sistem & Bakım -> Yüklü Programlar`):**
  - Bilgisayarınızda kurulu **tüm Windows programlarını** (64-bit `HKLM`, 32-bit `WOW6432Node` ve kullanıcı `HKCU` Program Ekle/Kaldır kaynaklarından) canlı arama, yayıncı, sürüm ve boyut (MB) bilgisiyle listeler.
  - **Derin Temizlik ile Kaldırma (`Kaldır`):** Programın resmi kaldırıcısını (MSI/EXE) çalıştırır; tamamlandıktan sonra geride kalan **Kurulum Klasörü**, **AppData / LocalAppData / ProgramData**, **Kayıt Defteri (`Regedit`)** ve **TEMP** artıklarını otomatik tarayıp tam önizleme listesiyle onayınızla siler.
  - **Artıkları Tara:** Kırık/sahipsiz kayıtlar veya önceden kaldırılmış yazılımlar için doğrudan artık tarama ve temizleme imkânı sunar.
  - **Koruma Kalkanı:** Windows sistem klasörleri (`C:\Windows`, `Program Files`, `AppData` kökleri) ve genel sistem anahtarları (`Microsoft`, `Windows`, `Google`, `Driver` vb.) sıkı koruma listesiyle engellenir.

### Hata Düzeltmeleri ve Arayüz İyileştirmeleri
- **Kaldırma Onay Penceresi Düzeltildi:** `Invoke-WPFUnInstall.ps1` içindeki `Name` alan hatası (`content` ile) düzeltilerek onay penceresinde uygulama adlarının eksiksiz listelenmesi sağlandı.
- **Canlı Çalışma Ekranı (Spinner) Düzeltildi:** `Start-WinUtilJob.ps1` içindeki `$jobWorkingArea` eşleşmesine tüm Türkçe iş adları (`Kurulum`, `Kaldırma`, `Tüm Uygulamaları Güncelle`, `Yüklü Öğeler`, `İnce Ayarlar`, `Ayarları Geri Al`) eklendi; artık uzun süren işlemlerde canlı bekleme ekranı anında görünür.
- **Meşgul Uyarısı ve OOSU Türkçeleştirildi:** Arka planda işlem sürerken ikinci tıklamada çıkan İngilizce uyarı (`is still running`) ve `O&O ShutUp10++` indirme durumları tam TR/EN çift dilli hale getirildi.
- **Kurulum Sekmesi Butonu Netleştirildi:** Karışıklığı önlemek için buton **"Katalogdan Kurulu Olanları Seç"** olarak güncellendi ve tarama bitince kaç uygulama bulunduğu + tüm Windows programları için `Sistem & Bakım -> Yüklü Programlar` yönlendirmesi eklendi.

---

## v1.6 — 2026-11-24
### Kapsamlı Kod Denetimi, Kararlılık ve Çift Dil İyileştirmeleri
- **Sürücü Temizleyici (`DriverStore`) Güvenli Sürüm Ayrıştırma:** `Invoke-WinUtilSystemHealth.ps1` içindeki eski sürücü temizliği artık standart dışı OEM sürücü sürüm numaralarında hata vermeden güvenli `[version]::TryParse` yedeklemesiyle çalışır.
- **Tam Çift Dilli İpuçları (ToolTip):** İngilizce arayüze geçildiğinde Türkçe kalan pencere büyütme ipucu (`WPFMaximizeButton`), İnce Ayarlar DNS açılır liste açıklaması (`WPFchangedns`) ve `Sistem & Bakım` sekmesindeki tüm 24 araç ipucu (ToolTip) tam **Türkçe / English** desteğine kavuşturuldu.
- **Canlı Dil Değişiminde Başlangıç Listesi Senkronizasyonu:** Dil değiştirildiğinde `Sistem & Bakım` başlangıç listesi önbelleği sıfırlanarak yeni dilde yenilenir.
- **%100 PowerShell 5.1 Kodlama Hijyeni:** `xaml/inputXML.xaml` içindeki XML yorumlarından Windows-1254 akıllı tırnak baytı (`0x94`) taşıyan karakterler temizlendi; derlenen `winutil.ps1` artık hem `ParseFile` hem de `irm | iex` (`ParseInput`) denetimlerinden **0 hata** ve **0 riskli bayt** ile geçer.

---

## v1.5 — 2026-11-24
### Büyük Güncelleme: 4 Alt Sekmeli Wintoys Tarzı `Sistem & Bakım` Merkezi
- **Yeni 4 Alt Sekmeli Düzen:** `Sistem & Bakım` sekmesi **Özet & Donanım**, **Performans & Oyun**, **Temizlik & Ağ** ve **Başlangıç & Ayarlar** olmak üzere 4 temiz alt sekmeye ayrıldı; tüm yeni kontroller tam **Türkçe / English** canlı dil desteğiyle eklendi.
- **Özet & Donanım (Genişletildi):**
  - **Pil Sağlığı Kartı + HTML Pil Raporu:** Dizüstü bilgisayarlarda pil sağlığı (%), mWh kapasite ve şarj döngüsü gösterimi + `powercfg /batteryreport` tek tıkla açma.
  - **Sistem Kimliği, BIOS ve Lisans:** Anakart, BIOS/UEFI sürümü, Secure Boot + TPM durumu ve Windows etkinleştirme / lisans kanalı (OEM/Retail/Volume).
  - **Tüm Diskler ve SSD S.M.A.R.T. Sağlığı:** Tüm sabit disk bölümleri için canlı doluluk çubukları + fiziksel disklerin sağlık, sıcaklık (°C) ve aşınma yüzdesi.
- **Performans & Oyun (Genişletildi):**
  - **Yeni Oyun Anahtarları:** Windows Oyun Modu, Pencereli Oyunlar İçin Optimizasyon (Win11) ve Multi-Plane Overlay (MPO) aç/kapa.
  - **Canlı Güç Planı Seçici:** Dengeli, Yüksek Performans, Güç Tasarrufu ve Nihai Performans arasında tek tıkla geçiş.
  - **Hazırda Bekletme (`hiberfil.sys`) Yönetimi:** Gerçek dosya boyutunu (GB) gösterme ve tek tıkla açıp kapatma.
  - **Anlık RAM Temizleme & GPU Sürücü Yenileme:** Çalışma kümelerini temizleyip serbest kalan MB'ı bildirme + `Win+Ctrl+Shift+B` GPU yenileme butonu.
- **Temizlik & Ağ (Genişletildi):**
  - **Yeni Derin Temizlik Araçları:** Tarayıcı önbellek temizleyici (Chrome, Edge, Brave, Vivaldi, Opera, Firefox — şifre ve oturumlara dokunmaz), Windows Update indirme önbelleği (`SoftwareDistribution`), eski kullanılmayan sürücü paketleri (`DriverStore` / `pnputil`) ve masaüstü simge önbelleği onarımı.
  - **Hızlı DNS Değiştirici & Canlı Ping Testi:** Cloudflare, Google, AdGuard (reklam engelleyici), Quad9 ve Otomatik DNS profilleri + canlı ms gecikme ölçümü + Winsock/TCP-IP ağ sıfırlama.
- **Başlangıç & Ayarlar (Genişletildi):**
  - **Canlı Başlangıç (Startup) Uygulamaları Yöneticisi:** `HKCU/HKLM Run` ve Başlangıç klasöründeki uygulamaları Görev Yöneticisi ile uyumlu (`StartupApproved`) şekilde tek tıkla açıp kapatma.
  - **5 Yeni Hızlı Gezgin/Gizlilik Anahtarı:** Dosya Gezgini'ni 'Bu Bilgisayar' ile aç, dosya uzantılarını göster, gizli dosyaları göster, Windows 11 klasik sağ tık menüsü, Pano Geçmişi (`Win+V`).
  - **Tanrı Modu (God Mode):** Tek tıkla masaüstüne tüm Windows ayarlarını toplayan özel klasör oluşturma.
- **Dokümantasyon & Ekran Görüntüleri:** Tüm 4 yeni alt sekmenin gerçek ekran görüntüleri `rehber/gorseller/` altına eklendi; `README.md` ve `rehber/sistem-ve-bakim.md` tamamen güncellendi.

---

## v1.4 — 2026-11-24
### Yenilikler ve İyileştirmeler
- **Gerçek Arayüz Ekran Görüntüleri:** Tüm 7 sekmenin (Kurulum, İnce Ayarlar, Yapılandırma, Güncellemeler, Win11 Oluşturucu, Sistem & Bakım, AppX) gerçek ekran görüntüleri `rehber/gorseller/` altına eklendi ve `README.md` ile tüm rehber sayfalarına yerleştirildi.
- **Sürüm Değişiklik Günlüğü (`CHANGELOG.md`):** Tüm sürümlerin geçmişi ve değişiklik özetleri tek sayfada toplandı; tüm rehber sayfalarının üst gezinme çubuğu `Sistem & Bakım` bağlantısıyla eşitlendi.
- **Akıllı Ekran Kartı (GPU) Tespiti:** `Sistem & Bakım` sekmesindeki GPU kartı artık sanal ekran bağdaştırıcılarını (*Virtual / Basic Display / Parsec / Indirect*) filtreleyerek doğrudan fiziksel harici ekran kartını (NVIDIA / AMD / Intel Arc) gösterir.
- **`Sistem & Bakım` Yerleşim İyileştirmesi:** Standart pencere boyutunda (1320×820) alt durum çubuğunun ve tüm kartların kaydırma gerektirmeden net görünmesi için boşluklar optimize edildi.

### Hata Düzeltmeleri
- **Sekme Geçişinde Anahtar Sıfırlanması Düzeltildi:** `Reset-WPFCheckBoxes.ps1` içindeki toplu sıfırlama döngüsünün `Sistem & Bakım` sekmesindeki canlı anahtarları (`WPFSysToggle*`) yanlışlıkla kapatması engellendi.
- **Seçili Uygulama Sayacı Düzeltildi:** `Get-WinUtilString` içindeki PowerShell `$Args` parametre çakışması ve `@(0)` truthiness hatası giderildi; Kurulum sekmesindeki `Seçili Uygulamalar: 0` sayacı ve kuyruk/ipucu metinleri artık hatasız biçimlendiriliyor.

---

## v1.3 — 2026-11-23
### Yenilikler
- **Yeni `Sistem & Bakım` Sekmesi (Wintoys Tarzı Yönetim Merkezi):**
  - **Canlı Sistem Özeti (Dashboard):** İşletim sistemi/çalışma süresi, işlemci (CPU), bellek (RAM), ekran kartı (GPU) ve C: disk doluluk oranını canlı gösterir.
  - **Performans ve Hızlandırma (Boost):** HAGS (Donanım Hızlandırmalı GPU Zamanlaması), Çekirdek Yalıtım / VBS, Hızlı Başlatma, Oyun DVR, Pencere Animasyonları ve Şeffaflık Efektleri için canlı okuyan anahtarlar + Dosya Gezgini Yeniden Başlat & DNS Önbelleği Temizle.
  - **Sistem Sağlığı ve Temizlik:** Hızlı Çöp/TEMP/Shader/Geri Dönüşüm temizliği, WinSxS DISM bileşen temizliği, SSD TRIM / Disk Optimizasyonu, DISM + SFC sistem onarımı, Windows Defender Hızlı Tarama ve Microsoft Store sıfırlama (`WSReset`).
  - **Hızlı Masaüstü & Gizlilik Ayarları:** Masaüstünde *Bu Bilgisayar* simgesi, görev çubuğu saatinde saniyeler, kompakt Dosya Gezgini, kısayol okunu kaldırma, kilit ekranı reklamlarını ve Windows ipuçlarını kapatma.
  - **8 Hızlı Sistem Aracı:** Görev Yöneticisi, Hizmetler, Kayıt Defteri, Aygıt Yöneticisi, Disk Yönetimi, Başlangıç Uygulamaları, Depolama Ayarları ve Olay Görüntüleyici.
- **Yeni Rehber:** `rehber/sistem-ve-bakim.md` eklendi.

---

## v1.2 — 2026-11-23
### Yenilikler
- **Wintoys Uygulaması Eklendi:** Popüler Windows optimizasyon aracı **Wintoys** (`msstore:9P8LTPGCBZXD`) kendi 48×48 simgesi ve Türkçe/İngilizce açıklamasıyla Kurulum sekmesine eklendi (toplam 240 uygulama).
- **Otomatik GitHub Releases Akışı:** `.github/workflows/release.yml` eklendi; her `v*` etiketi gönderildiğinde `WinUtil-TR.exe` ve `winutil.ps1` otomatik olarak GitHub Releases sayfasında yayımlanır.

---

## v1.1 — 2026-11-23
### Yenilikler
- **Çift Dil Desteği (Türkçe / English + Otomatik Algılama):** Windows sistem dili Türkçe ise otomatik Türkçe, diğer tüm dillerde otomatik İngilizce açılır. Sağ üstteki **Ayarlar (⚙️)** menüsünden yeniden başlatmadan anlık dil değiştirilebilir ve tercih kaydedilir.
- **Ayrıntılı Türkçe Dokümantasyon (`rehber/`):** Kurulum, İnce Ayarlar, Yapılandırma & Güncellemeler, Win11 Oluşturucu, AppX Yönetimi ve SSS rehberleri eklendi.
- **PowerShell 5.1 Uyumluluk İyileştirmeleri:** `winutil.ps1` BOM'suz UTF-8 olarak derlenerek `irm ... | iex` tek satır komutunun hem PowerShell 5.1 hem PowerShell 7'de hatasız çalışması sağlandı.

---

## v1.0 — 2026-11-23
### İlk Sürüm
- **%100 Türkçe Yerelleştirme:** Tüm arayüz, 239 uygulama, 69 ince ayar, 33 yapılandırma/onarım öğesi ve 34 AppX açıklaması Türkçeye çevrildi.
- **Canlı Sistem Durumu Rozetleri:** İnce Ayarlar'da `✓ Uygulu`, Yapılandırma'da `✓ Etkin`, AppX'te `✓ Kurulu` yeşil durum rozetleri eklendi.
- **Tek Dosya Taşınabilir `.exe` (`WinUtil-TR.exe`):** Ek bağımlılık gerektirmeyen, otomatik UAC yönetici izni isteyen ve konsol penceresini gizleyen `.NET Framework 4.8` yerli çalıştırılabilir dosya oluşturuldu.
