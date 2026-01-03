# Midtrans Webhook Function

Appwrite Function untuk handle payment notification dari Midtrans dan aktivasi premium otomatis.

## Setup

### 1. Deploy Function ke Appwrite

```bash
# Di Appwrite Console:
# 1. Buka Functions
# 2. Klik "Create Function"
# 3. Pilih "Node.js 18.0" runtime
# 4. Upload folder ini atau connect via Git
```

### 2. Set Environment Variables

Di Appwrite Console > Functions > [Function ini] > Settings > Environment Variables:

```
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxx
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_API_KEY=your_api_key
APPWRITE_DATABASE_ID=your_database_id
APPWRITE_COLLECTION_USER_PROFILES=user_profiles
```

**Penting:**
- `MIDTRANS_SERVER_KEY`: Sama dengan yang dipakai di create-txn function
- `APPWRITE_API_KEY`: Buat di Appwrite Console > API Keys dengan scope:
  - `databases.read`
  - `databases.write`
- `APPWRITE_COLLECTION_USER_PROFILES`: Nama collection untuk user profiles

### 3. Set Execute Permission

- Di Settings > Permissions:
  - Add role: `Any`
  - Allow execute
- **Penting:** Function ini harus bisa diakses dari internet (oleh Midtrans)

### 4. Deploy

- Klik "Deploy"
- Tunggu build selesai

### 5. Copy Function URL

- Setelah deploy, copy **Function URL**
- Format: `https://[your-appwrite-domain]/v1/functions/[function-id]/executions`

### 6. Set Notification URL di Midtrans

1. Login ke [Midtrans Dashboard](https://dashboard.sandbox.midtrans.com/)
2. Pilih environment (Sandbox/Production)
3. Buka **Settings > Configuration**
4. Set **Payment Notification URL** ke Function URL dari step 5
5. Pastikan **HTTP(S) notification / Webhooks** dicentang
6. Klik **Save**

## How It Works

1. User bayar di Midtrans
2. Midtrans kirim notification ke webhook ini
3. Function verify signature (keamanan)
4. Jika payment success (`settlement` atau `capture`):
   - Extract `userId` dari `order_id`
   - Update atau create document di collection `user_profiles`
   - Set `plan = 'premium'`
   - Set `premiumUntil = now + 30 hari`
   - Reset `waReminderCount = 0`
5. Return success response

## Notification Format (dari Midtrans)

```json
{
  "order_id": "PREMIUM-user123-1735488000000",
  "status_code": "200",
  "gross_amount": "49000.00",
  "signature_key": "xxxx",
  "transaction_status": "settlement",
  "fraud_status": "accept",
  "payment_type": "gopay",
  "transaction_time": "2025-12-29 10:00:00"
}
```

## Response Format

**Success (200):**
```json
{
  "success": true,
  "message": "Premium activated",
  "userId": "user123",
  "orderId": "PREMIUM-user123-1735488000000",
  "premiumUntil": "2026-01-28T10:00:00.000Z",
  "transactionStatus": "settlement",
  "paymentType": "gopay"
}
```

**Error (401 - Invalid Signature):**
```json
{
  "error": "Invalid signature"
}
```

## Security

✅ **Signature Verification**: Function verify SHA512 hash dari Midtrans  
✅ **Server Key Safety**: Server key hanya ada di environment variable  
✅ **Fraud Detection**: Check `fraud_status` sebelum aktivasi  

## Testing

### Sandbox Testing:
1. Gunakan Sandbox credentials di Midtrans
2. Di payment page, pilih metode pembayaran
3. Untuk simulator:
   - Gopay: Gunakan nomor simulator
   - VA: Gunakan nomor VA yang di-generate
4. Midtrans akan auto-trigger webhook ke function ini

### Manual Testing (curl):
```bash
# JANGAN gunakan di production! Hanya untuk test local
curl -X POST https://[your-function-url] \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "PREMIUM-test123-1735488000000",
    "status_code": "200",
    "gross_amount": "49000.00",
    "signature_key": "[calculated_signature]",
    "transaction_status": "settlement",
    "fraud_status": "accept"
  }'
```

## Logs

Check logs di Appwrite Console > Functions > [Function ini] > Logs untuk monitoring:
- Notification received
- Signature verification
- Database updates
- Errors

## Troubleshooting

**Problem:** Webhook tidak terpanggil
- ✅ Check Midtrans dashboard: Settings > Configuration > Notification URL
- ✅ Check function permissions: harus bisa diakses dari internet
- ✅ Check Appwrite logs untuk error

**Problem:** Signature invalid
- ✅ Pastikan `MIDTRANS_SERVER_KEY` di function sama dengan di dashboard
- ✅ Check environment (sandbox vs production)

**Problem:** Premium tidak aktif
- ✅ Check logs: apakah webhook dipanggil?
- ✅ Check database: apakah document ter-create/update?
- ✅ Check `premiumUntil` format: harus ISO string valid
