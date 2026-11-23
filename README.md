# WinUtil Türkçe

Windows 10 ve Windows 11 için kapsamlı **Türkçe** uygulama kurulum, ince ayar (tweaks), sistem yapılandırma, Windows Update profil yönetimi ve Windows 11 ISO oluşturma aracı.

> **Hazırlayan:** Erol Dizdar — [https://www.eroldizdar.tr/](https://www.eroldizdar.tr/)  
> **Esinlenme:** [ChrisTitusTech / winutil](https://github.com/christitustech/winutil)

---

## Öne Çıkan Özellikler

- **Tam Türkçe Arayüz ve İçerik:** 239 uygulamanın açıklamaları, 69 ince ayar, 33 Windows özelliği/onarım, 34 AppX paketi, Windows Update profilleri ve Win11 ISO sihirbazı tamamen Türkçedir.
- **Tek Dosya `.exe` (`WinUtil-TR.exe`):** Ek kurulum veya runtime gerektirmez. Çift tıkladığınızda otomatik yönetici yetkisi (UAC) ister ve siyah konsol penceresi açmadan doğrudan grafik arayüzle başlar.
- **Canlı Sistem Durumu Rozetleri:**
  - **İnce Ayarlar:** Sisteminizde hâlihazırda uygulanmış ince ayarların yanında otomatik yeşil **`✓ Uygulu`** etiketi görünür.
  - **Yapılandırma:** Etkin Windows özelliklerinin yanında otomatik yeşil **`✓ Etkin`** etiketi görünür.
  - **AppX:** Kurulu Microsoft Store uygulamalarının yanında otomatik yeşil **`✓ Kurulu`** etiketi görünür.
  - Kutucuklar zorla işaretlenmez; yalnızca sizin seçtiğiniz öğeler üzerinde işlem yapılır.

## Kullanım

1. **[WinUtil-TR.exe](WinUtil-TR.exe)** dosyasını indirin ve çift tıklayın.
2. Windows Yönetici İzni (UAC) penceresinde **Evet** deyin.
3. Canlı konsol günlüğü görmek isterseniz komut satırından şu şekilde çalıştırabilirsiniz:
   ```powershell
   .\WinUtil-TR.exe -Console
   ```

## Kaynaktan Derleme

Değişiklik yaptıktan sonra `winutil.ps1` ve `WinUtil-TR.exe` dosyalarını yeniden oluşturmak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Exe.ps1
```

## Lisans

Bu proje orijinal [MIT Lisansı](LICENSE) altında sunulmaktadır.
