class Transaction {
  final String id;
  final String userId; // User ID pemilik transaksi
  final String customerId;
  final DateTime tanggal;
  final String deskripsi;
  final int total;
  final int dp;
  final int sisa;
  final String status; // 'belumlunas' atau 'lunas'
  final String? fotoNotaUrl;

  Transaction({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.tanggal,
    required this.deskripsi,
    required this.total,
    required this.dp,
    required this.sisa,
    required this.status,
    this.fotoNotaUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      customerId: json['customerId'] ?? '',
      tanggal: DateTime.parse(json['tanggal']),
      deskripsi: json['deskripsi'] ?? '',
      total: json['total'] ?? 0,
      dp: json['dp'] ?? 0,
      sisa: json['sisa'] ?? 0,
      status: json['status'] ?? 'belumlunas',
      fotoNotaUrl: json['fotoNotaUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'customerId': customerId,
    'tanggal': tanggal.toIso8601String(),
    'deskripsi': deskripsi,
    'total': total,
    'dp': dp,
    'sisa': sisa,
    'status': status,
    'fotoNotaUrl': fotoNotaUrl,
  };
}