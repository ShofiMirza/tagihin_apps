# 🔧 Panduan Fix Remaining Errors - User Isolation Implementation

## Error Summary
Ada beberapa file yang masih perlu diperbaiki untuk userId implementation:

---

## 📋 File yang Perlu Diperbaiki:

### 1. **lib/screens/customer_transaction_list_screen.dart**

**Error:**
- `fetchTransactions()` perlu 2 arguments (customerId, userId)
- `deleteTransaction()` perlu 3 arguments (id, customerId, userId)  
- `fetchPayments()` perlu 2 arguments (transactionId, userId)

**Fix Pattern:**
```dart
// Get userId dari AuthProvider
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId != null) {
  // Gunakan userId di semua method calls
  await provider.fetchTransactions(widget.customerId, userId);
  await provider.deleteTransaction(id, customerId, userId);
  await provider.fetchPayments(transactionId, userId);
}
```

---

### 2. **lib/screens/add_transaction_screen.dart**

**Error:**
- Transaction constructor perlu parameter `userId`

**Fix:**
```dart
// Import AuthProvider
import '../providers/auth_provider.dart';

// Dalam _submit():
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId == null) {
  // Show error
  return;
}

final trx = Transaction(
  id: widget.editTransaction?.id ?? '',
  userId: userId, // ← TAMBAHKAN INI
  customerId: widget.customerId,
  // ... fields lainnya
);
```

---

### 3. **lib/screens/add_payment_screen.dart**

**Error:**
- Payment constructor perlu parameter `userId`
- `addPayment()` perlu 3 arguments
- `updatePayment()` perlu 2 arguments

**Fix:**
```dart
// Import AuthProvider
import '../providers/auth_provider.dart';

// Dalam _submit():
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId == null) return;

final payment = Payment(
  id: widget.editPayment?.id ?? '',
  userId: userId, // ← TAMBAHKAN INI
  transactionId: widget.transaction.id,
  // ... fields lainnya
);

if (widget.editPayment != null) {
  await provider.updatePayment(payment, userId);
} else {
  await provider.addPayment(payment, context, userId);
}
```

---

### 4. **lib/screens/transaction_detail_screen.dart**

**Error:**
- `fetchPayments()` perlu userId
- `fetchTransactions()` perlu userId
- `deletePayment()` perlu userId
- Customer orElse perlu userId

**Fix:**
```dart
// Di _refresh():
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId != null) {
  await provider.fetchPayments(widget.transaction.id, userId);
  await provider.fetchTransactions(widget.transaction.customerId, userId);
}

// Di deletePayment:
await provider.deletePayment(payment.id, widget.transaction.id, userId);

// Fix orElse:
orElse: () => Customer(
  id: '',
  userId: '', // ← TAMBAHKAN
  nama: 'Customer tidak ditemukan',
  noHp: '',
  alamat: '',
  catatan: '',
),
```

---

### 5. **lib/screens/payment_history_screen.dart**

**Error:**
- `fetchAllPayments()` perlu userId
- `fetchCustomers()` perlu userId
- `fetchAllTransactions()` perlu userId
- Multiple orElse() perlu userId

**Fix:**
```dart
// Di _refresh():
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId != null) {
  await Provider.of<PaymentProvider>(context, listen: false).fetchAllPayments(userId);
  await Provider.of<CustomerProvider>(context, listen: false).fetchCustomers(userId);
  await Provider.of<TransactionProvider>(context, listen: false).fetchAllTransactions(userId);
}

// Fix semua orElse:
orElse: () => Transaction(
  id: '',
  userId: '', // ← TAMBAHKAN
  customerId: '',
  tanggal: DateTime.now(),
  deskripsi: 'Transaksi tidak ditemukan',
  total: 0,
  dp: 0,
  sisa: 0,
  status: '',
),

orElse: () => Customer(
  id: '',
  userId: '', // ← TAMBAHKAN
  nama: 'Customer tidak ditemukan',
  noHp: '',
  alamat: '',
  catatan: '',
),
```

---

### 6. **lib/screens/reports_screen.dart** (Jika Ada)

Perlu fix serupa dengan payment_history_screen.dart

---

### 7. **lib/providers/transaction_provider.dart**

**Error:**
- Line 72: `fetchTransactions()` call perlu userId

**Fix:**
```dart
// Cari line yang memanggil fetchTransactions tanpa userId
// Tambahkan userId parameter
```

---

## 🚀 Quick Fix Commands

Untuk mempercepat, tambahkan import di file yang belum ada:

```dart
import '../providers/auth_provider.dart';
```

Pattern umum untuk semua screen:

```dart
// Di awal method async:
final userId = Provider.of<AuthProvider>(context, listen: false).userId;
if (userId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Error: User tidak terautentikasi')),
  );
  return;
}

// Lalu gunakan userId di semua provider calls
```

---

## ✅ Checklist Setelah Fix

- [ ] `flutter pub get` (jika ada dependency changes)
- [ ] Fix semua compile errors di VS Code
- [ ] Test login dengan 2 akun berbeda
- [ ] Verifikasi data isolation bekerja
- [ ] Test semua CRUD operations

---

**Status Implementation:** 70% Complete
**Remaining Work:** Fix compile errors di 5-7 screen files
**Estimated Time:** 15-20 menit

