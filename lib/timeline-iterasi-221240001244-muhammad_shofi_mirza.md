# Timeline Iterasi Proyek Akhir – Aplikasi Manajemen Nota "Tagihin"
Nama: Muhammad Shofi Mirza
NIM: 221240001244  
Metode: Agile
Durasi: 4 Minggu

---

## Iterasi 1 – Perencanaan & Setup Awal

- Finalisasi ide aplikasi: "Tagihin" untuk manajemen nota toko bangunan
- Menentukan fitur inti (MVP): pelanggan, nota, pembayaran, pengingat WA
- Menyusun ulang dokumen SRS berdasarkan ide final
- Setup awal proyek Flutter
- Setup backend menggunakan Appwrite
- Membuat koleksi database:  
  - `pelanggan`  
  - `transaksi` (nota)  
  - `pembayaran`  
  - `foto-nota` (menggunakan storage)
- Mendesain relasi antar data dan struktur database awal

---

## Iterasi 2 – Desain UI dan Implementasi Dasar

- Desain UI:
  - Halaman utama pelanggan
  - Tambah pelanggan
  - Detail pelanggan + daftar nota
  - Tambah nota (form transaksi + upload foto)
  - Halaman tambah pembayaran
- Implementasi dasar:
  - CRUD pelanggan
  - Input nota dan upload foto ke Appwrite
  - Tampilkan daftar nota per pelanggan

---

## Iterasi 3 – Integrasi Backend & Fungsi Utama

- Implementasi:
  - Tambah pembayaran & simpan ke database
  - Hitung otomatis sisa utang
  - Status otomatis: lunas / belum lunas
  - Riwayat pembayaran per pelanggan
- Fitur pengingat WA:
  - Format pesan otomatis
  - Tombol pengingat WA di halaman nota

---

## Iterasi 4 – Polishing, Uji Coba & Presentasi

- Penyempurnaan UI/UX
- Validasi input data & error handling ringan
- Menyusun riwayat pembayaran global (optional)
- Dokumentasi GitHub & demo aplikasi
- Perekaman video presentasi (1–5 menit)
- Pengumpulan laporan progres akhir

---

## Alasan Menggunakan Metode Agile

Metode Agile dipilih karena:
- Memungkinkan pengembangan bertahap dengan evaluasi mingguan
- Adaptif terhadap perubahan selama proses belajar dan pengembangan
- Memudahkan pelaporan mingguan & kontrol progres
- Cocok untuk proyek mahasiswa dalam durasi 4 minggu

//   Future<Map<String, dynamic>> addCustomer(Map<String, dynamic> customerData) async {
//     final response = await database.createDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_FUNCTION_CUSTOMER']!,
//       documentId: 'unique()',
//       data: customerData,
//     );
//     return response.data;
//   }

//   Future<Map<String, dynamic>> updateCustomer(String customerId, Map<String, dynamic> customerData) async {
//     final response = await database.updateDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_FUNCTION_CUSTOMER']!,
//       documentId: customerId,
//       data: customerData,
//     );
//     return response.data;
//   }
// }

//   Future<void> deleteCustomer(String customerId) async {
//     await database.deleteDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_FUNCTION_CUSTOMER']!,
//       documentId: customerId,
//     );
//   }
// }

//   Future<Map<String, dynamic>> getCustomerById(String customerId) async {
//     final response = await database.getDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_FUNCTION_CUSTOMER']!,
//       documentId: customerId,
//     );
//     return response.data;
//   }
// }

//   Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
//     final response = await database.listDocuments(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_FUNCTION_CUSTOMER']!,
//       queries: [
//         Query.search('name', query), // Ganti 'name' dengan field yang sesuai
//       ],
//     );
//     return response.documents.map((doc) => doc.data).toList();
//   }
// }

//   Future<List<Map<String, dynamic>>> getTransactions(String customerId) async {
//     final response = await database.listDocuments(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
//       queries: [
//         Query.equal('customerId', customerId), // Ganti 'customerId' dengan field yang sesuai
//       ],
//     );
//     return response.documents.map((doc) => doc.data).toList();
//   }
// }

//   Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> transactionData) async {
//     final response = await database.createDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
//       documentId: 'unique()',
//       data: transactionData,
//     );
//     return response.data;
//   }
// }

//   Future<Map<String, dynamic>> updateTransaction(String transactionId, Map<String, dynamic> transactionData) async {
//     final response = await database.updateDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
//       documentId: transactionId,
//       data: transactionData,
//     );
//     return response.data;
//   }
// }

//   Future<void> deleteTransaction(String transactionId) async {
//     await database.deleteDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
//       documentId: transactionId,
//     );
//   }
// }

//   Future<Map<String, dynamic>> getTransactionById(String transactionId) async {
//     final response = await database.getDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
//       documentId: transactionId,
//     );
//     return response.data;
//   }
// }

//   Future<List<Map<String, dynamic>>> getPayments(String customerId) async {
//     final response = await database.listDocuments(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       queries: [
//         Query.equal('customerId', customerId), // Ganti 'customerId' dengan field yang sesuai
//       ],
//     );
//     return response.documents.map((doc) => doc.data).toList();
//   }
// }

//   Future<Map<String, dynamic>> addPayment(Map<String, dynamic> paymentData) async {
//     final response = await database.createDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       documentId: 'unique()',
//       data: paymentData,
//     );
//     return response.data;
//   }
// }

//   Future<Map<String, dynamic>> updatePayment(String paymentId, Map<String, dynamic> paymentData) async {
//     final response = await database.updateDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       documentId: paymentId,
//       data: paymentData,
//     );
//     return response.data;
//   }
// }

//   Future<void> deletePayment(String paymentId) async {
//     await database.deleteDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       documentId: paymentId,
//     );
//   }
// }

//   Future<Map<String, dynamic>> getPaymentById(String paymentId) async {
//     final response = await database.getDocument(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       documentId: paymentId,
//     );
//     return response.data;
//   }
// }
//   Future<List<Map<String, dynamic>>> searchPayments(String query) async {
//     final response = await database.listDocuments(
//       databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
//       collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
//       queries: [
//         Query.search('description', query), // Ganti 'description' dengan field yang sesuai
//       ],
//     );
//     return response.documents.map((doc) => doc.data).toList();
//   }
// }

//   Future<void> uploadFile(String filePath) async {
//     final storage = Storage(client);
//     await storage.createFile(
//       bucketId: dotenv.env['APPWRITE_BUCKET_ID']!,
//       fileId: 'unique()',
//       file: InputFile.fromPath(path: filePath),
//     );
//   }

//   Future<void> deleteFile(String fileId) async {
//     final storage = Storage(client);
//     await storage.deleteFile(
//       bucketId: dotenv.env['APPWRITE_BUCKET_ID']!,
//       fileId: fileId,
//     );
//   }
// }

//   Future<Map<String, dynamic>> getFile(String fileId) async {
//     final storage = Storage(client);
//     final response = await storage.getFile(
//       bucketId: dotenv.env['APPWRITE_BUCKET_ID']!,
//       fileId: fileId,
//     );
//     return response.data;
//   }
// }