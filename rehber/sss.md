[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)

# ❓ Sık Sorulan Sorular (SSS) ve Sorun Giderme

### 1. Yönetici olarak mı çalıştırmam gerekiyor?
Evet, WinUtil sistem ayarlarını ve paketleri yönettiği için yönetici yetkisi gerekir. Ancak sizin sağ tıklayıp *"Yönetici olarak çalıştır"* demenize gerek yoktur:
- **`WinUtil-TR.exe`** çift tıklandığında Windows otomatik olarak Yönetici İzni (UAC) penceresini açar.
- **PowerShell tek satır komutu (`irm ... | iex`)** normal terminalde çalıştırılsa bile otomatik olarak yönetici izni isteyip yükseltilmiş oturumda devam eder.

### 2. Başka bir bilgisayarda çalıştırırsam ne olur?
`WinUtil-TR.exe` tamamen taşınabilirdir ve çalıştırıldığı bilgisayarın kendi kayıt defterini, hizmetlerini, Windows özelliklerini ve kurulu AppX paketlerini **o anda canlı olarak tarar**. Her bilgisayarda o makinenin kendi durumunu doğru şekilde gösterir.

### 3. Zaten uygulanmış bir ayarı veya kurulu bir uygulamayı işaretlemezsem kaldırılır mı?
**Hayır, kesinlikle dokunulmaz.** WinUtil yalnızca kutucuğunu işaretleyip işlem butonuna bastığınız öğeler üzerinde işlem yapar. İşaretlemediğiniz (boş bıraktığınız) ayarlar veya uygulamalar olduğu gibi korunur.

### 4. Yaptığım bir ince ayarı beğenmezsem nasıl geri alırım?
1. **İnce Ayarlar** sekmesine gidin (uygulanan ayarların yanında yeşil **`✓ Uygulu`** etiketi görünür).
2. Geri almak istediğiniz ayarların kutucuklarını işaretleyin.
3. Alttaki **Seçili Ayarları Geri Al** butonuna tıklayın.
4. Ek güvence olarak işlem öncesinde **Sistem Geri Yükleme Noktası - Oluştur** seçeneğini kullandıysanız, **Yapılandırma -> Sistem Geri Yükleme** üzerinden sistemi önceki haline döndürebilirsiniz.

### 5. Windows SmartScreen / Defender neden uyarı verebilir?
`WinUtil-TR.exe` açık kaynaklı ve ücretli bir kod imzalama sertifikasıyla imzalanmamış (topluluk derlemesi) bir `.exe` dosyası olduğu için Windows SmartScreen *"Windows kişisel bilgisayarınızı korudu"* uyarısı gösterebilir.
- İsterseniz kaynak kodun tamamını bu depoda inceleyip `Build-Exe.ps1` ile **kendi bilgisayarınızda sıfırdan derleyebilir** veya hiç `.exe` indirmeden doğrudan PowerShell tek satır komutunu (`irm ... | iex`) kullanabilirsiniz.

### 6. İçe Aktar / Dışa Aktar ne işe yarar?
Sağ üstteki **Ayarlar (⚙️)** menüsünden:
- **Dışa Aktar:** Seçtiğiniz tüm uygulama, ince ayar, tercih, özellik ve AppX listesini bir `.json` dosyasına kaydeder. Format sonrası veya başka bir bilgisayarda aynı ayarları tek seferde yüklemek için harikadır.
- **İçe Aktar:** Kaydettiğiniz `.json` dosyasını yükleyerek aynı seçimleri anında geri getirir.
- **Sistem Raporu Dışa Aktar:** Sorun giderme amacıyla sisteminizdeki mevcut ayarların salt okunur bir JSON raporunu oluşturur.

### 7. Komut satırı parametreleri nelerdir?
Hem `WinUtil-TR.exe` hem de `winutil.ps1` şu parametreleri destekler:

| Parametre | Açıklama |
| :--- | :--- |
| `-Console` *(sadece `.exe`)* | Gizli çalışan PowerShell penceresini görünür yapar; canlı konsol çıktılarını takip etmenizi sağlar. |
| `-Preset Standard` / `Minimal` / `Advanced` | Arayüzü açmadan belirtilen ince ayar profilini otomatik uygular. |
| `-Config "yol\ayarlar.json"` | Dışa aktarılmış bir yapılandırma dosyasını otomatik (arayüzsüz) uygular. |
| `-Offline` | Çevrimdışı modda açar (Kurulum sekmesi devre dışı kalır, yerel ince ayarlar kullanılabilir). |

### 8. İşlem günlükleri (log dosyaları) nerede saklanır?
Her çalıştırmanın ayrıntılı günlüğü şu klasöre kaydedilir:
```text
%LocalAppData%\winutil\logs\
```
Bir hata yaşarsanız en son tarihli `.log` dosyasını inceleyebilirsiniz.

---

[🏠 Ana Sayfa](../README.md) · [📦 Kurulum](kurulum.md) · [⚙️ İnce Ayarlar](ince-ayarlar.md) · [🛠️ Yapılandırma & Güncellemeler](yapilandirma-ve-guncellemeler.md) · [💿 Win11 Oluşturucu](win11-olusturucu.md) · [📱 AppX Yönetimi](appx-yonetimi.md) · [❓ SSS](sss.md)
