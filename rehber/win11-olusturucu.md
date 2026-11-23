[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)

# 💿 Win11 Oluşturucu (Özel Windows 11 ISO / USB) Rehberi

**Win11 Oluşturucu** (orijinal adıyla *MicroWin*), mevcut kurulu Windows sisteminize **hiç dokunmadan**; temiz format atarken kullanmak üzere Microsoft'un resmi Windows 11 ISO dosyasından **hafifletilmiş, gereksiz uygulamalardan arındırılmış ve donanım engelleri kaldırılmış özel bir Windows 11 kurulum kalıbı** oluşturur.

## Kalıba Otomatik Olarak Neler Uygulanır?

| İşlem | Açıklama |
| :--- | :--- |
| **Gereksiz Uygulamaları ve OneDrive'ı Kaldırma** | Kurulumla birlikte otomatik gelen Microsoft Store şişkinliklerini (bloatware) ve OneDrive kurulumunu kalıptan çıkarır. |
| **Donanım Kısıtlamalarını Atlama** | **TPM 2.0, Secure Boot, CPU, RAM ve depolama** gereksinim kontrollerini devre dışı bırakır (desteklenmeyen eski PC'lere de kurulum yapılabilir). |
| **Microsoft Hesabı Ekranını Atlama** | Kurulum sırasında internet veya Microsoft hesabı zorunluluğu olmadan doğrudan **yerel kullanıcı hesabı** oluşturabilmenizi sağlar. |
| **Gizlilik ve Temizlik Ayarları** | Telemetri, Copilot, görev çubuğu sohbet simgesi ve arama kutusu önerilerini kurulumda kapalı olacak şekilde ayarlar. |
| **Sürüm Sabitleme** | Seçtiğiniz Windows 11 sürümünü (ör. Home, Pro) sabitler; kurulumun anakart anahtarına göre farklı bir sürüm seçmesini önler. |
| **Mevcut Sistem Sürücülerini Entegre Etme** *(İsteğe Bağlı)* | Halihazırda kullandığınız bilgisayardaki depolama/donanım sürücülerini kalıba gömer; format sonrası NVMe disk görünmeme veya Wi-Fi sürücüsü eksikliği sorunlarını azaltır. |

---

## Adım Adım Nasıl Kullanılır?

### 1. Adım — Resmi Windows 11 ISO Dosyasını Seçin
1. Henüz indirmediyseniz ekrandaki **Microsoft İndirme Sayfasını Aç** butonuna tıklayıp Microsoft'un resmi sitesinden **Windows 11 (64-bit / x64)** ISO dosyasını indirin.
2. **Gözat** butonuyla indirdiğiniz `.iso` dosyasını seçin.
3. **ISO'yu Bağla ve Doğrula** butonuna tıklayın. WinUtil kalıbı bağlayıp içindeki `install.wim` / `install.esd` dosyasını ve Windows 11 sürümlerini doğrular.

> ⚠️ **Önemli:** Üçüncü taraf veya önceden modifiye edilmiş ISO dosyaları desteklenmez; yalnızca Microsoft'un resmi ISO dosyasını kullanın.

### 2. Adım — Kalıbı Düzenleyin
1. Açılır listeden kurmak istediğiniz **Windows sürümünü** (ör. *Windows 11 Pro* veya *Windows 11 Home*) seçin.
2. Aynı bilgisayara format atacaksanız **Mevcut sistem sürücülerini entegre et** kutucuğunu işaretleyebilirsiniz *(başka bir bilgisayara kuracaksanız işaretlememeniz önerilir)*.
3. **Windows ISO Düzenleme ve Oluşturmayı Başlat** butonuna tıklayın. Bu işlem işlemci ve disk hızınıza göre birkaç dakika sürer; tüm adımlar sağdaki **Durum Günlüğü** ekranından canlı izlenebilir.

### 3. Adım — Çıktıyı Kaydedin veya USB'ye Yazın
İşlem tamamlandığında iki seçeneğiniz vardır:
- **ISO Dosyası Olarak Kaydet:** Düzenlenmiş temiz Windows 11'i yeni bir `.iso` dosyası olarak bilgisayarınıza kaydeder. Daha sonra **Rufus** veya **Ventoy** ile istediğiniz zaman USB'ye yazabilirsiniz.
- **Doğrudan USB Belleğe Yaz:** Önyüklenebilir (bootable) format USB belleğini doğrudan oluşturur.

> 🚨 **DİKKAT:** **Sil ve USB'ye Yaz** seçeneği, seçtiğiniz USB sürücüdeki **TÜM VERİLERİ KALICI OLARAK SİLER**. İşlem öncesi doğru USB belleği seçtiğinizden ve yedek aldığınızdan emin olun.

---

[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)
