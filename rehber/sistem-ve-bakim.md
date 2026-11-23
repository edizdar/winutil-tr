[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [🩺 Sistem & Bakım](sistem-ve-bakim.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)

# 🩺 Sistem & Bakım (Wintoys Tarzı Yönetim Merkezi) Rehberi

**Sistem & Bakım** (*System & Health*) sekmesi, popüler **Wintoys** aracının en sevilen özelliklerini doğrudan **WinUtil Türkçe** içine entegre eder: canlı donanım/sistem özeti, performans ve oyun hızlandırma anahtarları, tek tıkla sağlık/temizlik araçları, hızlı masaüstü gizlilik ayarları ve sistem yönetim kısayolları.

---

## 1. 📊 Canlı Sistem Özeti (Dashboard)
Sekme açıldığında (veya **Yenile** butonuna bastığınızda) arka planda sisteminizi tarayarak şu 5 kartı canlı gösterir:
- **İşletim Sistemi:** Windows sürümü, yapı numarası (Build) ve sistemin çalışma süresi (Uptime).
- **İşlemci (CPU):** İşlemci modeli, çekirdek/izlek sayısı ve anlık işlemci kullanım yüzdesi.
- **Bellek (RAM):** Kullanılan / toplam bellek miktarı (GB ve %) ile kullanılabilir boş bellek.
- **Ekran Kartı (GPU):** Aktif ekran kartı modeli ve sürücü sürümü.
- **Sistem Diski (C:):** Boş / toplam depolama alanı ve doluluk oranı.

---

## 2. ⚡ Performans ve Hızlandırma (Boost)
Tüm anahtarlar bilgisayarınızın **mevcut gerçek durumunu otomatik okur** ve tıkladığınızda anında uygulanır:

| Ayar | Ne İşe Yarar? |
| :--- | :--- |
| **Donanım Hızlandırmalı GPU Zamanlaması (HAGS)** | Ekran kartı bellek yönetimini Windows yerine doğrudan GPU donanımına devrederek oyunlarda gecikmeyi azaltır *(yeniden başlatma gerektirir)*. |
| **Çekirdek Yalıtım / Bellek Bütünlüğü (VBS)** | Sanallaştırma tabanlı güvenliği kontrol eder. Güvenlik için açık kalır; yüksek FPS/oyun performansı isteyen kullanıcılar kapatabilir *(yeniden başlatma gerektirir)*. |
| **Hızlı Başlatma (Fast Startup)** | Kapanışta sistem çekirdeğini diske kaydederek bilgisayarın daha hızlı açılmasını sağlar. Çift işletim sistemi (Linux/Windows dual-boot) kullananlar kapatmalıdır. |
| **Oyun DVR / Arka Plan Video Kaydı** | Xbox/Windows arka plan oyun kaydını kontrol eder; kapatılması oyunlarda FPS kararlılığını artırabilir. |
| **Pencere Animasyonları** | Kapatıldığında pencereler animasyon beklemeden anında açılıp kapanır ve sistem daha akıcı hissedilir. |
| **Şeffaflık Efektleri** | Görev çubuğu ve menülerdeki yarı saydamlık efektlerini açar/kapatır; düşük donanımlarda kapatmak GPU yükünü azaltır. |
| **Dosya Gezgini'ni Yeniden Başlat** | Görev çubuğu veya Dosya Gezgini donduğunda/görsel değişiklik sonrası tek tıkla yeniler. |
| **DNS Önbelleğini Temizle** | Eski DNS kayıtlarını siler (`Clear-DnsClientCache` + `ipconfig /flushdns`), site erişim hatalarını gidermeye yardımcı olur. |

---

## 3. 🩺 Sistem Sağlığı ve Temizlik (Health & Cleanup)
Tüm işlemler alt ilerleme çubuğu üzerinden güvenli arka plan işi olarak çalışır:

| İşlem | Ne Yapar? |
| :--- | :--- |
| **Hızlı Çöp, TEMP, Shader ve Geri Dönüşüm Temizliği** | Kullanıcı ve Windows `TEMP` klasörlerini, DirectX / NVIDIA / AMD Shader önbelleklerini, Prefetch klasörünü ve Geri Dönüşüm Kutusu'nu temizler; kaç MB yer açıldığını raporlar. |
| **WinSxS Bileşen Deposu Temizliği (DISM)** | `DISM /StartComponentCleanup` çalıştırarak eski Windows güncelleme artıklarını güvenle temizler ve disk alanı açar. |
| **Sistem Sürücüsünü Optimize Et (SSD TRIM / C:)** | SSD diskler için TRIM komutunu, mekanik HDD'ler için disk birleştirmeyi çalıştırır. |
| **Sistem Dosyası Onarımı (DISM + SFC)** | Bozuk veya eksik Windows sistem dosyalarını tarayıp onarır. |
| **Windows Defender Hızlı Tarama Başlat** | Yerleşik Windows Defender ile hızlı zararlı yazılım taraması başlatır. |
| **Microsoft Store Önbelleğini Sıfırla (WSReset)** | Microsoft Store açılmama veya indirmelerin takılı kalması sorununu giderir. |

---

## 4. 🎨 Hızlı Masaüstü ve Gizlilik Ayarları
| Ayar | Ne İşe Yarar? |
| :--- | :--- |
| **Masaüstünde 'Bu Bilgisayar' Simgesini Göster** | Masaüstüne klasik *Bu Bilgisayar* simgesini tek tıkla ekler veya gizler. |
| **Görev Çubuğu Saatinde Saniyeleri Göster** | Sistem tepsisindeki saatte saniyelerin görünmesini açar/kapatır. |
| **Dosya Gezgini Kompakt Görünüm** | Dosya Gezgini satır aralıklarını daraltarak tek ekranda daha fazla dosya listeler. |
| **Kısayol Simgelerindeki Oku Kaldır** | Masaüstü kısayollarındaki küçük ok işaretini kaldırır (geri açıldığında eski haline döner). |
| **Kilit Ekranı Reklam ve İpuçlarını Kapat** | Kilit ekranındaki Windows öneri ve bilgi kutucuklarını gizler. |
| **Windows İpuçları ve Önerilerini Kapat** | Bildirim ve Ayarlar içindeki *"Windows'tan en iyi şekilde yararlanın"* tarzı önerileri kapatır. |

---

## 5. 🧰 Hızlı Sistem Araçları
Tek tıkla **Görev Yöneticisi**, **Hizmetler**, **Kayıt Defteri**, **Aygıt Yöneticisi**, **Disk Yönetimi**, **Başlangıç Uygulamaları**, **Depolama Ayarları** ve **Olay Görüntüleyici** pencerelerine doğrudan erişim sağlar.

---

[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [🩺 Sistem & Bakım](sistem-ve-bakim.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)
