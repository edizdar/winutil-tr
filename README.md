# WinUtil Türkçe

[![Sürüm](https://img.shields.io/badge/S%C3%BCr%C3%BCm-v1.4-2F7D78?style=flat-square)](https://github.com/edizdar/winutil-tr/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6?style=flat-square)](#hızlı-başlangıç)
[![Dil](https://img.shields.io/badge/Dil-T%C3%BCrk%C3%A7e%20%7C%20English-E84A4A?style=flat-square)](#öne-çıkan-özellikler)
[![Lisans](https://img.shields.io/badge/Lisans-MIT-green?style=flat-square)](LICENSE)

**WinUtil Türkçe**; Windows 10 ve Windows 11 sistemlerde toplu uygulama kurulumu (**240+ uygulama**), gizlilik ve performans ince ayarları, **Wintoys tarzı Sistem & Bakım merkezi**, sistem onarımı, Windows Update profil yönetimi ve özel Windows 11 kurulum kalıbı (**ISO / USB**) oluşturma işlemlerini tek bir **Türkçe / İngilizce** arayüzde toplayan açık kaynaklı araçtır.

> **Hazırlayan:** Erol Dizdar — [https://www.eroldizdar.tr/](https://www.eroldizdar.tr/)  
> **Esinlenme:** [ChrisTitusTech / winutil](https://github.com/christitustech/winutil) · **Sürüm Geçmişi:** [CHANGELOG.md](CHANGELOG.md)

---

## Hızlı Başlangıç

### Yöntem 1: PowerShell Tek Satır Komutu *(İndirme Gerektirmez)*
Herhangi bir Windows 10/11 bilgisayarda **PowerShell**'i açın ve aşağıdaki komutu çalıştırın *(yönetici izni otomatik istenir)*:

```powershell
irm https://raw.githubusercontent.com/edizdar/winutil-tr/main/winutil.ps1 | iex
```

### Yöntem 2: Tek Dosya `.exe` *(Taşınabilir)*
1. **[Releases sayfasından en son `WinUtil-TR.exe` sürümünü](https://github.com/edizdar/winutil-tr/releases/latest)** indirin ve çift tıklayın.
2. Windows Yönetici İzni (UAC) penceresinde **Evet** deyin — siyah konsol penceresi açılmadan doğrudan arayüz başlar.
3. Canlı konsol çıktısını da görmek isterseniz komut satırından `.\WinUtil-TR.exe -Console` şeklinde başlatabilirsiniz.

---

## Ekran Görüntüleri

### 📦 Kurulum (240+ Uygulama, Kategori Filtreleri ve `#FOSS` Rozeti)
![WinUtil Türkçe — Kurulum Sekmesi](rehber/gorseller/01-kurulum.png)

### ⚙️ İnce Ayarlar (Otomatik `✓ Uygulu` Rozetleri ve Canlı Sistem Tercihleri)
![WinUtil Türkçe — İnce Ayarlar Sekmesi](rehber/gorseller/02-ince-ayarlar.png)

### 🩺 Sistem & Bakım (Wintoys Tarzı Canlı Donanım Özeti, Boost ve Temizlik)
![WinUtil Türkçe — Sistem & Bakım Sekmesi](rehber/gorseller/06-sistem-ve-bakim.png)

<details>
<summary><strong>Diğer sekmelerin ekran görüntülerini aç (Yapılandırma, Güncellemeler, Win11 Oluşturucu, AppX)</strong></summary>

#### 🛠️ Yapılandırma (`✓ Etkin` Özellikler, Onarım Araçları ve Klasik Paneller)
![WinUtil Türkçe — Yapılandırma Sekmesi](rehber/gorseller/03-yapilandirma.png)

#### 🔄 Güncellemeler (Windows Update Profilleri)
![WinUtil Türkçe — Güncellemeler Sekmesi](rehber/gorseller/04-guncellemeler.png)

#### 💿 Win11 Oluşturucu (Özel Bloatware'siz Windows 11 ISO / USB)
![WinUtil Türkçe — Win11 Oluşturucu Sekmesi](rehber/gorseller/05-win11-olusturucu.png)

#### 📱 AppX Yönetimi (Yerleşik Microsoft Store Uygulamaları)
![WinUtil Türkçe — AppX Yönetimi](rehber/gorseller/07-appx.png)

</details>

---

## Dokümantasyon Rehberi

Her sekmenin ve ayarın ne işe yaradığını ayrıntılı olarak aşağıdaki rehberlerde bulabilirsiniz:

| Rehber | Kapsam |
| :--- | :--- |
| **[📦 Kurulum (Install) Rehberi](rehber/kurulum.md)** | 240 popüler uygulamanın (Wintoys dahil) tek tıkla kurulumu, güncellenmesi, kaldırılması, WinGet/Chocolatey ve kategori listesi. |
| **[⚙️ İnce Ayarlar (Tweaks) Rehberi](rehber/ince-ayarlar.md)** | Standart/Minimal/Gelişmiş profiller, 69 ince ayar ve sistem tercihinin tam açıklaması, DNS seçimi ve geri alma. |
| **[🛠️ Yapılandırma ve Güncellemeler](rehber/yapilandirma-ve-guncellemeler.md)** | Windows özellikleri (WSL, Hyper-V, .NET, Sandbox), sistem/ağ/update onarımları, eski paneller ve Windows Update profilleri. |
| **[💿 Win11 Oluşturucu Rehberi](rehber/win11-olusturucu.md)** | Resmi Windows 11 ISO'sundan bloatware'siz, TPM/Microsoft hesabı engelsiz özel kurulum ISO'su veya format USB'si hazırlama. |
| **[🩺 Sistem & Bakım (Wintoys Tarzı)](rehber/sistem-ve-bakim.md)** | Canlı donanım/sistem özeti (OS/CPU/RAM/GPU/Disk), HAGS/VBS/Fast Startup performans anahtarları, tek tıkla TEMP/Shader/WinSxS/SSD TRIM temizliği ve hızlı masaüstü ayarları. |
| **[📱 AppX Yönetimi Rehberi](rehber/appx-yonetimi.md)** | Windows ile yüklü gelen 34 Microsoft Store uygulamasının açıklamaları, güvenli kaldırma ve yeniden kurma rehberi. |
| **[❓ Sık Sorulan Sorular (SSS)](rehber/sss.md)** | Yönetici izni, SmartScreen uyarısı, geri alma, İçe/Dışa Aktar, komut satırı parametreleri ve günlük dosyaları. |

---

## Öne Çıkan Özellikler

- **Çift Dil Desteği (Türkçe / English + Otomatik Algılama):** Windows sistem dili Türkçe olan bilgisayarlarda otomatik **Türkçe**, diğer tüm sistem dillerinde otomatik **English** açılır. Sağ üstteki **Ayarlar (⚙️)** menüsünden yeniden başlatmadan anında dil değiştirebilirsiniz.
- **Wintoys Tarzı Sistem & Bakım Merkezi:** Canlı donanım özeti (fiziksel harici GPU öncelikli), HAGS / VBS / Fast Startup / Oyun DVR performans anahtarları, tek tıkla TEMP/Shader/WinSxS/SSD TRIM/DISM+SFC bakım araçları, hızlı masaüstü gizlilik ayarları ve 8 sistem aracı kısayolu.
- **%100 Türkçe Arayüz ve Açıklamalar:** Tüm sekmeler, butonlar, diyaloglar, 240 uygulama açıklaması (Wintoys dahil), 69 ince ayar, 33 özellik/onarım ve 34 AppX açıklaması Türkçedir.
- **Canlı Sistem Durumu Rozetleri:** Hangi bilgisayarda açılırsa o sistemi arka planda otomatik tarar:
  - **İnce Ayarlar** sekmesinde zaten uygulanmış ayarların yanında **`✓ Uygulu`**
  - **Yapılandırma** sekmesinde etkin Windows özelliklerinin yanında **`✓ Etkin`**
  - **AppX** sekmesinde kurulu uygulamaların yanında **`✓ Kurulu`** etiketi görünür.
- **Güvenli Seçim Mantığı:** İşaretlemediğiniz hiçbir ayar geri alınmaz veya uygulama kaldırılmaz; yalnızca sizin seçtiğiniz öğeler işlenir.
- **Tek Dosya Taşınabilir `.exe`:** Ek runtime kurulumu gerekmeden Windows 10/11'de yerleşik .NET Framework 4.8 ile çalışır.

---

## Kaynaktan Derleme

Kodlarda değişiklik yaptıktan sonra `winutil.ps1` ve `WinUtil-TR.exe` dosyalarını yeniden derlemek için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Exe.ps1
```

Sürüm numarası **[VERSION](VERSION)** dosyasından okunur; her yeni sürümde bu dosya güncellenerek hem uygulama içi **Hakkında** ekranı hem de `.exe` dosya özellikleri otomatik güncellenir. Tüm sürümlerin ayrıntılı geçmişi için **[CHANGELOG.md](CHANGELOG.md)** dosyasına göz atabilirsiniz.

## Lisans

Bu proje orijinal [MIT Lisansı](LICENSE) altında sunulmaktadır.
