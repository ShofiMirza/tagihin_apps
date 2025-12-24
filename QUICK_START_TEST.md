# 🚀 Quick Start - Testing User Isolation

## ⚡ Langkah Cepat Testing

### 1️⃣ **Jalankan Aplikasi**
```powershell
flutter run
```

### 2️⃣ **Test dengan 2 Akun**

#### **Akun 1: User A**
```
1. Klik "Daftar" (Register)
2. Email: test-a@example.com
3. Password: password123
4. Name: User A
5. Klik "Daftar"
6. Login dengan kredensial di atas
```

**Tambah Data untuk User A:**
- Tambah Customer: "Toko Maju"
- Tambah Transaksi: Rp 1.000.000, DP 300.000
- Tambah Payment: Rp 200.000

**Hasil untuk User A:**
- 1 Customer
- 1 Transaksi (sisa Rp 500.000)
- 1 Payment

#### **Akun 2: User B**
```
1. Logout dari User A
2. Klik "Daftar" (Register)
3. Email: test-b@example.com
4. Password: password123
5. Name: User B
6. Klik "Daftar"
7. Login dengan kredensial di atas
```

**Tambah Data untuk User B:**
- Tambah Customer: "Warung Sejahtera"
- Tambah Transaksi: Rp 500.000, DP 100.000
- Tambah Payment: Rp 150.000

**Hasil untuk User B:**
- 1 Customer (berbeda dari User A)
- 1 Transaksi (berbeda dari User A)
- 1 Payment (berbeda dari User A)

### 3️⃣ **Verifikasi Data Isolation**

#### **Test 1: Customer List**
```
✅ Login sebagai User A
   → Should see: "Toko Maju"
   → Should NOT see: "Warung Sejahtera"

✅ Logout → Login sebagai User B
   → Should see: "Warung Sejahtera"
   → Should NOT see: "Toko Maju"
```

#### **Test 2: Transaction List**
```
✅ Login sebagai User A
   → Buka "Toko Maju"
   → Should see: 1 transaksi Rp 1.000.000

✅ Login sebagai User B
   → Buka "Warung Sejahtera"
   → Should see: 1 transaksi Rp 500.000
```

#### **Test 3: Payment History**
```
✅ Login sebagai User A
   → Tab "Riwayat"
   → Should see: Total Rp 200.000

✅ Login sebagai User B
   → Tab "Riwayat"
   → Should see: Total Rp 150.000
```

#### **Test 4: Reports**
```
✅ Login sebagai User A
   → Tab "Laporan"
   → Total Utang Aktif: Rp 500.000
   → Total Cicilan Masuk: Rp 200.000

✅ Login sebagai User B
   → Tab "Laporan"
   → Total Utang Aktif: Rp 250.000
   → Total Cicilan Masuk: Rp 150.000
```

---

## ✅ Expected Results

### **PASS (Correct Behavior):**
- ✅ User A hanya melihat data User A
- ✅ User B hanya melihat data User B
- ✅ Tidak ada data yang tercampur
- ✅ Logout/login tetap mempertahankan isolation
- ✅ Tidak ada error saat switch user

### **FAIL (Need to Fix):**
- ❌ User A bisa lihat data User B
- ❌ Data tercampur antar user
- ❌ Error saat add/update/delete
- ❌ Data hilang setelah logout/login
- ❌ Crash saat switch user

---

## 🐛 Troubleshooting

### **Issue: "User tidak terautentikasi"**
**Solution:** Pastikan Anda sudah login. Logout dan login kembali.

### **Issue: Data masih tercampur**
**Solution:** 
1. Cek Appwrite Console → Database
2. Pastikan field `userId` ada di semua collection
3. Pastikan data lama sudah dihapus
4. Restart aplikasi

### **Issue: Error saat create data**
**Solution:**
1. Pastikan sudah login
2. Cek console untuk error message
3. Pastikan Appwrite connection OK

### **Issue: Cannot login after register**
**Solution:**
1. Register berhasil tapi tidak auto-login
2. Kembali ke login screen
3. Login manual dengan email/password yang baru dibuat

---

## 📱 Test Scenarios

### **Scenario 1: Fresh Start**
1. Register 2 akun baru
2. Tambah data di masing-masing akun
3. Verify data isolation

### **Scenario 2: Switch Users**
1. Login User A → Add data
2. Logout → Login User B → Add data
3. Logout → Login User A → Verify data intact
4. Logout → Login User B → Verify data intact

### **Scenario 3: Heavy Usage**
1. Login User A
2. Add 5 customers
3. Add 10 transactions
4. Add 20 payments
5. Logout → Login User B
6. Verify all empty
7. Add 3 customers
8. Logout → Login User A
9. Verify 5 customers still there

---

## 🎯 Success Checklist

- [ ] Bisa register 2 akun berbeda
- [ ] Bisa login dan logout
- [ ] Data User A tidak terlihat oleh User B
- [ ] Data User B tidak terlihat oleh User A
- [ ] Customer list terpisah per user
- [ ] Transaction list terpisah per user
- [ ] Payment history terpisah per user
- [ ] Reports menghitung per user
- [ ] Tidak ada error saat CRUD operations
- [ ] Tidak ada crash saat switch user

---

## 🚨 Emergency: Jika Ada Masalah

### **Reset Database**
1. Login ke Appwrite Console
2. Database → Collections
3. Hapus semua documents di:
   - customers
   - transactions
   - payments
4. Restart aplikasi
5. Test ulang dari awal

### **Check Logs**
```powershell
# Lihat console output saat run app
flutter run -v
```

### **Rebuild App**
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 📞 Support

Jika menemukan issue:
1. Cek error di console
2. Cek Appwrite logs
3. Verify database structure
4. Restart aplikasi

**Happy Testing! 🎉**

