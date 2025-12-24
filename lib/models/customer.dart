class Customer {
  final String id;
  final String userId; // User ID pemilik customer
  final String nama;
  final String noHp;
  final String? alamat;
  final String? catatan;

  Customer({
    required this.id,
    required this.userId,
    required this.nama,
    required this.noHp,
    this.alamat,
    this.catatan,
  });

  // Untuk parsing dari JSON (Appwrite response)
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      nama: json['nama'] ?? '',
      noHp: json['no_hp']?.toString() ?? '',
      alamat: json['alamat'],
      catatan: json['catatan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
      'catatan': catatan,
    };
  }
}