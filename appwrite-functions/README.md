# Appwrite Functions - Tagihin Midtrans Integration

Backend functions untuk sistem subscription premium Tagihin menggunakan Midtrans.

## 📁 Structure

```
appwrite-functions/
├── midtrans-create-txn/     # Create Snap transaction token
│   ├── src/
│   │   ├── main.js          # Main function handler
│   │   └── utils.js         # Helper utilities
│   ├── package.json
│   └── README.md
│
└── midtrans-webhook/        # Handle payment notification
    ├── src/
    │   ├── main.js          # Webhook handler
    │   └── utils.js         # Helper utilities
    ├── package.json
    └── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **Appwrite Instance** (Cloud atau Self-hosted)
2. **Midtrans Account** ([Daftar di sini](https://dashboard.midtrans.com/register))
3. **Appwrite Database & Collection**:
   - Database: Sudah ada (dari `.env`)
   - Collection baru: `user_profiles`

### Step 1: Setup Midtrans Account

1. Login ke [Midtrans Dashboard](https://dashboard.sandbox.midtrans.com/)
2. Ambil **Server Key**:
   - Sandbox: Settings > Access Keys > **Server Key**
   - Production: Sama, tapi di dashboard production
3. Catat Server Key untuk nanti

### Step 2: Create Collection `user_profiles`

Di Appwrite Console:

1. Buka **Databases** > Pilih database Anda
2. Klik **Create Collection**
3. Collection ID: `user_profiles`
4. Add Attributes:
   ```
   - userId (string, required, size: 255)
   - plan (string, required, default: "free", size: 50)
   - premiumUntil (string, optional, size: 100)
   - waReminderCount (integer, required, default: 0)
   - waResetDate (string, required, size: 100)
   ```
5. Indexes:
   - Key: `userId` (Type: key, Attribute: userId)
6. Permissions:
   - Document Security: ✅ Enabled
   - Add role: `Users` → Read, Update (user bisa read/update sendiri)
   - Add role: `Any` → Create (auto-create saat first access)

### Step 3: Deploy Function 1 (midtrans-create-txn)

1. Di Appwrite Console > **Functions** > **Create Function**
2. Settings:
   - Name: `midtrans-create-txn`
   - Runtime: **Node.js 18.0**
   - Execute Access: `Any`
3. Upload code:
   - **Manual**: Zip folder `midtrans-create-txn/` → upload
   - **Git**: Connect repository → set path ke folder
4. Environment Variables:
   ```
   MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxx
   MIDTRANS_ENV=sandbox
   ```
5. Klik **Deploy** → tunggu build selesai
6. Copy **Function URL** (setelah deploy)

### Step 4: Deploy Function 2 (midtrans-webhook)

1. Buat function baru: `midtrans-webhook`
2. Runtime: **Node.js 18.0**
3. Execute Access: `Any`
4. Upload code dari folder `midtrans-webhook/`
5. Environment Variables:
   ```
   MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxx
   APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
   APPWRITE_PROJECT_ID=[your_project_id]
   APPWRITE_API_KEY=[your_api_key]
   APPWRITE_DATABASE_ID=[your_database_id]
   APPWRITE_COLLECTION_USER_PROFILES=user_profiles
   ```
   
   **Cara buat API Key:**
   - Appwrite Console > Overview > **API Keys** > **Create API Key**
   - Name: `midtrans-webhook`
   - Scopes: `databases.read`, `databases.write`
   - Copy key → paste ke env

6. Deploy → Copy **Function URL**

### Step 5: Configure Midtrans Dashboard

1. Login ke [Midtrans Dashboard](https://dashboard.sandbox.midtrans.com/)
2. **Settings** > **Configuration**
3. Set:
   - **Payment Notification URL**: Paste webhook function URL
   - **Finish Redirect URL**: (opsional)
   - **Unfinish Redirect URL**: (opsional)
   - **Error Redirect URL**: (opsional)
4. Centang: **HTTP(S) notification / Webhooks**
5. **Save**

### Step 6: Update Flutter `.env`

Tambahkan di file `.env`:

```env
# Existing vars...
APPWRITE_COLLECTION_USER_PROFILES=user_profiles

# Midtrans
MIDTRANS_CREATE_TXN_URL=https://[your-appwrite-domain]/v1/functions/[create-txn-id]/executions
```

Contoh URL lengkap:
```
MIDTRANS_CREATE_TXN_URL=https://cloud.appwrite.io/v1/functions/676abc123def456/executions
```

### Step 7: Test Integration

1. **Run Flutter app**
2. **Navigate ke Premium screen**
3. **Tap "Bayar Sekarang"**
4. **Browser terbuka** → halaman Midtrans
5. **Pilih metode pembayaran** (Gopay/VA/QRIS)
6. **Di Sandbox**: Gunakan simulator payment
   - Gopay: 0812-3456-7890
   - VA BCA: Otomatis di-generate
7. **Complete payment**
8. **Back to app** → tap "Saya sudah bayar, cek status"
9. **Premium activated!** ✅

## 🧪 Testing Payment (Sandbox)

### Gopay Simulator
- Phone: `0812-3456-7890`
- PIN: `123456`

### Virtual Account
- Gunakan nomor VA yang di-generate Midtrans
- Di Midtrans Dashboard > Transactions > Pilih order > **Pay** (simulator)

### QRIS
- Scan QR → gunakan simulator di dashboard

## 📊 Monitoring

### Check Logs

**Function Logs:**
- Appwrite Console > Functions > [pilih function] > **Logs**

**Transaction Logs:**
- Midtrans Dashboard > Transactions

### Check Database

- Appwrite Console > Databases > `user_profiles`
- Cari document dengan `userId` tertentu
- Verify: `plan = 'premium'`, `premiumUntil = [future date]`

## 🔐 Security Checklist

✅ **Server Key** tidak ada di Flutter code  
✅ **Signature verification** aktif di webhook  
✅ **API Key scope** minimal (hanya databases)  
✅ **HTTPS** untuk semua endpoint  
✅ **Document security** aktif di collection  

## 🐛 Troubleshooting

### Problem: "MIDTRANS_CREATE_TXN_URL is not configured"
- ✅ Check `.env` file: pastikan key `MIDTRANS_CREATE_TXN_URL` ada
- ✅ Run `flutter pub get`
- ✅ Restart app

### Problem: "Failed to create Midtrans transaction"
- ✅ Check function logs di Appwrite
- ✅ Verify `MIDTRANS_SERVER_KEY` di env variables
- ✅ Pastikan function ter-deploy dengan status success

### Problem: Webhook tidak dipanggil
- ✅ Check Midtrans dashboard notification URL
- ✅ Pastikan function `midtrans-webhook` execute access = `Any`
- ✅ Test dengan manual curl (lihat webhook README)

### Problem: Premium tidak aktif setelah bayar
- ✅ Check webhook logs
- ✅ Verify signature key sama di kedua function
- ✅ Check collection `user_profiles` permissions
- ✅ Coba manual refresh: tap "Saya sudah bayar, cek status"

## 🚢 Production Deployment

Saat mau launch:

1. **Daftar Midtrans Production**
2. **Update env variables**:
   ```
   MIDTRANS_SERVER_KEY=[production_key]
   MIDTRANS_ENV=production
   ```
3. **Update Midtrans dashboard** (production):
   - Notification URL → webhook function URL
4. **Update Flutter `.env`**:
   - Ganti URL jika berbeda
5. **Test sekali lagi** dengan real payment

## 📞 Support

- **Midtrans Docs**: https://docs.midtrans.com/
- **Appwrite Docs**: https://appwrite.io/docs/functions
- **Tagihin Support**: [Your contact]

## 📝 License

Internal use - Tagihin Apps
