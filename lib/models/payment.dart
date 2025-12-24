class Payment {
  final String id;
  final String userId; // User ID pemilik payment
  final String transactionId;
  final DateTime tanggalPay;
  final int nominal;
  final String metode;

  Payment({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.tanggalPay,
    required this.nominal,
    required this.metode,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      transactionId: json['transactionId'] ?? '',
      tanggalPay: DateTime.parse(json['tanggalPay']),
      nominal: json['nominal'] ?? 0,
      metode: json['metode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'transactionId': transactionId,
    'tanggalPay': tanggalPay.toIso8601String(),
    'nominal': nominal,
    'metode': metode,
  };
}