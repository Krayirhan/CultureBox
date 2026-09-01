# START HERE

Bu paket agent bağımsız, hot-swap destekli full-auto geliştirme omurgasıdır.

## İlk kurulum
1. Paketi gerçek repo köküne çıkar.
2. `.env.example` → `.env.local` oluştur; gerçek secret'ları commit etme.
3. GitHub Secrets'a Play service-account JSON ve Android signing secret'larını ekle.
4. `scripts/bootstrap.ps1` çalıştır.
5. `scripts/doctor.ps1` çıktısında kritik maddeleri düzelt.
6. Firebase CLI ve Figma MCP OAuth yetkilendirmelerini tamamla.
7. İlk agentı repo kökünde aç ve: **Projeyi başlat.**
8. Agent değiştirirken: **Devam et.**

Production Play publish release pipeline üzerinden açıktır. Firebase Blaze/billing açmak yasaktır.
