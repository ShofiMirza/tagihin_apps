class UserProfile {
  final String userId;
  final String plan; // 'free' | 'premium'
  final DateTime? premiumUntil; // null if free
  final int waReminderCount;
  final DateTime waResetDate; // next reset boundary (usually 1st of next month)

  const UserProfile({
    required this.userId,
    required this.plan,
    required this.premiumUntil,
    required this.waReminderCount,
    required this.waResetDate,
  });

  bool get isPremium => plan.toLowerCase() == 'premium' &&
      premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: (map['userId'] ?? '') as String,
      plan: (map['plan'] ?? 'free') as String,
      premiumUntil: map['premiumUntil'] != null && map['premiumUntil'] != ''
          ? DateTime.tryParse(map['premiumUntil'].toString())
          : null,
      waReminderCount: (map['waReminderCount'] ?? 0) as int,
      waResetDate: map['waResetDate'] != null && map['waResetDate'] != ''
          ? DateTime.tryParse(map['waResetDate'].toString()) ?? _defaultNextMonth()
          : _defaultNextMonth(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'plan': plan,
      'premiumUntil': premiumUntil?.toIso8601String(),
      'waReminderCount': waReminderCount,
      'waResetDate': waResetDate.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? plan,
    DateTime? premiumUntil,
    int? waReminderCount,
    DateTime? waResetDate,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      waReminderCount: waReminderCount ?? this.waReminderCount,
      waResetDate: waResetDate ?? this.waResetDate,
    );
  }

  static DateTime _defaultNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }
}
