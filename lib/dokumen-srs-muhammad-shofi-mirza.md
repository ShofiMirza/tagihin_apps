# Dokumen SRS - Aplikasi Tagihin
**Nama**: Muhammad Shofi Mirza  
**NIM**: 221240001244   
**Mata Kuliah**: Pemrograman Mobile  
**Framework**: Flutter + Appwrite  
**Judul Proyek**: Aplikasi Manajemen Nota Tagihan Kredit untuk Toko Material “Tagihin”

---

## 1. Pendahuluan

### 1.1 Latar Belakang
Toko bangunan skala kecil hingga menengah dihadapkan pada kesulitan dalam mencatat transaksi kredit dan pelunasan pelanggan secara manual menggunakan nota kertas. Hal ini mengakibatkan nota tercecer, kesulitan dalam pelacakan riwayat pembayaran, dan proses pengingat yang tidak efisien.

### 1.2 Tujuan
Mengembangkan aplikasi mobile untuk mencatat tagihan kredit, cicilan pembayaran, dan mempermudah proses pelacakan serta pengingat bayar kepada pelanggan.

---

## 2. Ruang Lingkup

Aplikasi ini ditujukan untuk digunakan oleh pemilik toko bangunan yang ingin:
- Mencatat pelanggan dan transaksi kredit
- Mencatat pembayaran cicilan
- Menyimpan dan melihat foto nota
- Mengirim pengingat via WhatsApp
- Melihat laporan sederhana

---

## 3. Fitur MVP

1. **Manajemen Pelanggan**
   - Tambah, ubah, hapus pelanggan
   - Lihat detail dan riwayat transaksi

2. **Pencatatan Transaksi Kredit**
   - Input deskripsi, total, uang muka, upload foto nota
   - Hitung otomatis sisa utang

3. **Input Pembayaran Cicilan**
   - Tambah pembayaran untuk transaksi tertentu
   - Input tanggal, nominal, metode, catatan

4. **Pengingat WhatsApp**
   - Kirim format pengingat otomatis melalui WhatsApp

5. **Riwayat Pembayaran Global**
   - Melihat semua histori pembayaran yang pernah dilakukan

6. **Laporan Ringkas**
   - Total utang aktif
   - Total cicilan masuk
   - Daftar pelanggan menunggak

---

## 4. Arsitektur Sistem

### 4.1 Entitas dan Relasi

#### Customer
| Field     | Tipe    | Keterangan           |
|-----------|---------|----------------------|
| nama      | string  | Nama pelanggan       |
| no_hp     | integer | Nomor WhatsApp       |
| alamat    | string  | Opsional             |
| catatan   | string  | Opsional             |

#### Transaction
| Field           | Tipe     | Keterangan                            |
|-----------------|----------|---------------------------------------|
| customer_id     | string   | Relasi ke Customer                    |
| tanggal_nota    | date     | Tanggal transaksi                     |
| deskripsi       | string   | Barang/jasa                           |
| total           | integer  | Nilai total                           |
| dp              | integer  | Uang muka                             |
| sisa            | integer  | Otomatis dihitung                     |
| status          | enum     | LUNAS / BELUM LUNAS                   |
| foto_nota_url   | string   | URL dari storage foto nota            |

#### Payment
| Field           | Tipe     | Keterangan                            |
|-----------------|----------|---------------------------------------|
| transaction_id  | string   | Relasi ke Transaction                 |
| tanggal_pay     | date     | Tanggal pembayaran                    |
| nominal         | integer  | Jumlah bayar                          |
| metode          | enum     | Cash / Transfer                       |

### 4.2 Relasi

Customer    
├── id   
├── nama    
├── no_hp   
├── alamat  
└── catatan

   │  
   ▼

Transaction    
├── id     
├── customer_id (relasi ke Customer)     
├── tanggal    
├── deskripsi  
├── total   
├── dp   
├── sisa    
├── status (LUNAS / BELUM LUNAS)    
└── foto_nota_url (Appwrite Storage)

   │  
   ▼

Payment  
├── id   
├── transaction_id (relasi ke Transaction)   
├── tanggal_pay   
├── nominal    
└── metode (Cash / Transfer)  

---

## 5. Antarmuka Pengguna (UI Sederhana)

- **Halaman Pelanggan**
  - Daftar nama pelanggan
  - Tombol tambah pelanggan

- **Detail Pelanggan**
  - Daftar transaksi (nota)
  - Tombol tambah transaksi

- **Halaman Transaksi**
  - Data nota: deskripsi, total, sisa, status
  - Daftar pembayaran
  - Tombol tambah pembayaran

- **Halaman Riwayat General**
  - Tampilkan semua pembayaran dari semua pelanggan

- **Laporan**
  - Total utang, total pembayaran, status pelanggan

---

## 6. Batasan Sistem

- Tidak ada login multi-user di versi awal
- Penyimpanan file menggunakan Appwrite bucket
- Tidak ada verifikasi pembayaran otomatis

---

## 7. Teknologi

- **Frontend**: Flutter
- **Backend**: Appwrite (Database, Storage, Functions)
- **Platform**: Android (utama)
