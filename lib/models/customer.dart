class Customer {
  final String id;
  final String nama;
  final String noHp; // <-- ubah dari int ke String
  final String? alamat;
  final String? catatan;

  Customer({
    required this.id,
    required this.nama,
    required this.noHp, // <-- ubah dari int ke String
    this.alamat,
    this.catatan,
  });

  // Untuk parsing dari JSON (Appwrite response)
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['\$id'] ?? '',
      nama: json['nama'] ?? '',
      noHp: json['no_hp']?.toString() ?? '', // <-- ubah jadi string
      alamat: json['alamat'],
      catatan: json['catatan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'no_hp': noHp, // <-- simpan sebagai string
      'alamat': alamat,
      'catatan': catatan,
    };
  }
}