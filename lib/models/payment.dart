class Payment {
  final String id;
  final String transactionId; // <-- harus ada!
  final DateTime tanggalPay;
  final int nominal;
  final String metode;

  Payment({
    required this.id,
    required this.transactionId,
    required this.tanggalPay,
    required this.nominal,
    required this.metode,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['\$id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      tanggalPay: DateTime.parse(json['tanggalPay']),
      nominal: json['nominal'] ?? 0,
      metode: json['metode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'tanggalPay': tanggalPay.toIso8601String(),
    'nominal': nominal,
    'metode': metode,
  };
}