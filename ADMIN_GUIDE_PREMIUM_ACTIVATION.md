# Admin Guide: Manual Premium Activation

## 📋 Daily Checklist untuk Admin

### Setiap Hari (Pagi/Sore):

1. **Login Midtrans Production Dashboard**
   - URL: https://dashboard.midtrans.com
   - Login dengan akun Midtrans production

2. **Cek Transaksi Hari Ini**
   - Menu: **Transactions**
   - Filter: **Status = Settlement**
   - Filter: **Date = Today** (atau custom range)
   - Lihat semua transaksi dengan prefix **PREMIUM-**

3. **Catat Order ID & User ID**
   
   Format Order ID: `PREMIUM-{userId}-{timestamp}`
   
   Contoh: `PREMIUM-6956e54f9781176abd35-1767304079547`
   
   Extract userId: `6956e54f9781176abd35`

4. **Activate Premium di Appwrite**

   **Step-by-step:**
   
   a. Login Appwrite Console: https://cloud.appwrite.io
   
   b. Navigate: **Databases** → `tagihindb123` → Collection `user_profiles`
   
   c. Search document dengan `userId` = userId dari order ID
   
   d. Klik document → **Update document**
   
   e. Edit fields:
      - `plan` → ubah jadi: `premium`
      - `premiumUntil` → isi dengan: `2026-02-03T00:00:00.000Z` (30 hari dari hari ini)
      - `waReminderCount` → ubah jadi: `0`
   
   f. Klik **Update**

5. **Konfirmasi ke User (Optional)**
   - Kirim email/notif bahwa premium sudah aktif
   - Atau biarkan user cek sendiri di app

---

## 🔍 Cara Cek Payment Details

### Di Midtrans Dashboard:

1. Klik transaction → Lihat detail:
   - Order ID
   - Amount (Rp 14.000)
   - Payment Method
   - Customer Email
   - Status (harus Settlement)

2. Screenshot untuk dokumentasi (optional)

---

## 📱 Cara User Cek Status Premium

User bisa cek dengan 2 cara:

### Cara 1: Settings Screen
- Buka **Settings**
- Lihat badge "Premium Aktif" atau "Upgrade ke Premium"

### Cara 2: Premium Screen
- Buka **Settings** → **Upgrade ke Premium**
- Tap tombol **"Saya sudah bayar, cek status"**
- Jika premium aktif → muncul notif hijau + balik ke Settings

---

## 🛠️ Troubleshooting

### Q: User bayar tapi userId tidak ditemukan di database?
**A:** User belum pernah buka app atau login. Tunggu user login pertama kali, baru document `user_profiles` dibuat.

### Q: Berapa lama premium berlaku?
**A:** 30 hari dari tanggal aktivasi. Set `premiumUntil` = tanggal hari ini + 30 hari.

Contoh kalkulator: 
- Hari ini: 3 Jan 2026
- Premium sampai: 2 Feb 2026
- ISO format: `2026-02-02T23:59:59.000Z`

### Q: User minta refund?
**A:** 
1. Proses refund di Midtrans Dashboard
2. Jangan activate premium di Appwrite
3. Atau kalau sudah diactivate, ubah kembali `plan` jadi `free`

---

## 📊 Monitoring

### Metrics untuk Dipantau:
- Jumlah pembayaran per hari
- Jumlah premium user aktif
- Revenue harian/bulanan

### Query Appwrite untuk Count Premium Users:
- Databases → `user_profiles`
- Filter: `plan` equal `premium`
- Count documents

---

## 🚨 Important Notes

1. **Jangan skip verifikasi payment status** - Pastikan status = Settlement
2. **Double check userId** - Salah activate = user lain dapat premium gratis
3. **Set premiumUntil dengan benar** - Format ISO8601 dengan timezone UTC
4. **Backup data** - Export user_profiles collection secara berkala

---

## 📞 Support

Jika ada masalah teknis:
- Email: admin@tagihin.com
- Atau buka issue di GitHub repository

---

## ✅ Setup Checklist untuk Production

**1. Midtrans Production Setup:**
- [ ] Login production dashboard
- [ ] Aktivasi payment channels + submit approval
- [ ] Copy production server key
- [ ] Set notification URL
- [ ] Tunggu approval (3-7 hari)

**2. Update Appwrite Functions:**
- [ ] midtrans-create-txn → Env variables (MIDTRANS_SERVER_KEY, MIDTRANS_ENV=production)
- [ ] midtrans-webhook → Env variables (sama)
- [ ] Tunggu redeploy active

**3. Test Production Payment:**
- [ ] Bayar real dengan kartu real (Rp 14.000)
- [ ] Cek Midtrans Dashboard → status settlement
- [ ] Manual activate di Appwrite
- [ ] User cek status di app → Premium aktif!

**4. Daily Operations:**
- [ ] Baca guide ini
- [ ] Setup daily reminder untuk cek Midtrans
- [ ] Prepare template email konfirmasi (optional)

---

**Last Updated:** 3 Januari 2026
