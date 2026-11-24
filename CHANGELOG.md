# Değişiklik Günlüğü (CHANGELOG)

**WinUtil Türkçe** projesindeki tüm sürümler ve yenilikler aşağıda yer alır. Her yeni sürümle birlikte [`WinUtil-TR.exe`](https://github.com/edizdar/winutil-tr/releases/latest), `winutil.ps1`, dokümantasyon rehberleri ve GitHub Releases sayfası eşzamanlı güncellenir.

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
