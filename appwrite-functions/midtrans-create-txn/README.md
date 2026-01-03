# Midtrans Create Transaction Function

Appwrite Function untuk membuat Snap transaction token dari Midtrans.

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
MIDTRANS_ENV=sandbox
```

**Penting:**
- `MIDTRANS_SERVER_KEY`: Ambil dari Midtrans Dashboard > Settings > Access Keys
- `MIDTRANS_ENV`: Set `sandbox` untuk testing, `production` untuk live
- **JANGAN** commit server key ke Git!

### 3. Set Execute Permission

- Di Settings > Permissions:
  - Add role: `Any`
  - Allow execute

### 4. Deploy

- Klik "Deploy" atau auto-deploy jika via Git
- Tunggu build selesai

### 5. Copy Function URL

- Setelah deploy, copy **Function URL**
- Tambahkan ke `.env` Flutter app:
  ```
  MIDTRANS_CREATE_TXN_URL=https://[your-appwrite-domain]/v1/functions/[function-id]/executions
  ```

## Request Format

**Method:** POST  
**Content-Type:** application/json

```json
{
  "userId": "user123",
  "email": "user@example.com",
  "amount": 49000
}
```

## Response Format

**Success (200):**
```json
{
  "success": true,
  "token": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v3/redirection/xxxxx",
  "order_id": "PREMIUM-user123-1735488000000",
  "environment": "sandbox"
}
```

**Error (400/500):**
```json
{
  "error": "Failed to create Midtrans transaction",
  "detail": "..."
}
```

## Testing

### Via curl:
```bash
curl -X POST https://[your-function-url] \
  -H "Content-Type: application/json" \
  -d '{"userId":"test123","email":"test@example.com"}'
```

### Via Flutter app:
- Gunakan `MidtransService.createPremiumTransaction()`
