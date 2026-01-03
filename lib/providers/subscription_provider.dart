import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';

class SubscriptionProvider with ChangeNotifier {
  final Client _client;
  final Databases _db;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool _loading = false;
  bool get loading => _loading;

  SubscriptionProvider()
      : _client = Client()
            .setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
            .setProject(dotenv.env['APPWRITE_PROJECT_ID']!),
        _db = Databases(Client()
          ..setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
          ..setProject(dotenv.env['APPWRITE_PROJECT_ID']!));

  String get _databaseId => dotenv.env['APPWRITE_DATABASE_ID']!;
  String get _profilesCollectionId => dotenv.env['APPWRITE_COLLECTION_USER_PROFILES'] ?? 'user_profiles';

  Future<void> loadProfile(String userId) async {
    if (userId.isEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      // Try fetch by querying userId (documentId may not equal userId depending on setup)
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _profilesCollectionId,
        queries: [Query.equal('userId', userId)],
      );
      if (response.documents.isEmpty) {
        // Create default free profile
        final created = await _db.createDocument(
          databaseId: _databaseId,
          collectionId: _profilesCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'plan': 'free',
            'premiumUntil': null,
            'waReminderCount': 0,
            'waResetDate': DateTime.now().toIso8601String(),
          },
        );
        _profile = UserProfile.fromMap(created.data);
      } else {
        _profile = UserProfile.fromMap(response.documents.first.data);
      }
    } catch (e) {
      debugPrint('SubscriptionProvider.loadProfile error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile(String userId) async {
    await loadProfile(userId);
  }

  bool get isPremium => _profile?.isPremium == true;

  Future<void> checkPremiumExpiry(String userId) async {
    if (_profile == null) return;
    if (_profile!.plan.toLowerCase() == 'premium' && _profile!.premiumUntil != null) {
      if (DateTime.now().isAfter(_profile!.premiumUntil!)) {
        // Soft downgrade to free
        try {
          final docs = await _db.listDocuments(
            databaseId: _databaseId,
            collectionId: _profilesCollectionId,
            queries: [Query.equal('userId', userId)],
          );
          if (docs.documents.isNotEmpty) {
            await _db.updateDocument(
              databaseId: _databaseId,
              collectionId: _profilesCollectionId,
              documentId: docs.documents.first.$id,
              data: {
                'plan': 'free',
                'premiumUntil': null,
              },
            );
          }
          _profile = _profile!.copyWith(plan: 'free', premiumUntil: null);
          notifyListeners();
        } catch (e) {
          debugPrint('checkPremiumExpiry update error: $e');
        }
      }
    }
  }

  Future<void> ensureWaCounterIntegrity(String userId) async {
    if (_profile == null) return;
    try {
      final now = DateTime.now();
      if (now.isAfter(_profile!.waResetDate)) {
        final docs = await _db.listDocuments(
          databaseId: _databaseId,
          collectionId: _profilesCollectionId,
          queries: [Query.equal('userId', userId)],
        );
        if (docs.documents.isNotEmpty) {
          final nextReset = DateTime(now.year, now.month + 1, 1);
          await _db.updateDocument(
            databaseId: _databaseId,
            collectionId: _profilesCollectionId,
            documentId: docs.documents.first.$id,
            data: {
              'waReminderCount': 0,
              'waResetDate': nextReset.toIso8601String(),
            },
          );
          _profile = _profile!.copyWith(waReminderCount: 0, waResetDate: nextReset);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ensureWaCounterIntegrity error: $e');
    }
  }

  // === LIMIT ENFORCEMENT ===
  
  /// Returns max customer limit based on plan (Free: 3, Premium: unlimited)
  int getCustomerLimit() {
    return isPremium ? 999999 : 3;
  }

  /// Returns max WA reminder limit per month (Free: 5, Premium: unlimited)
  int getWAReminderLimit() {
    return isPremium ? 999999 : 5;
  }

  /// Check if user can add more customers
  bool canAddCustomer(int currentCustomerCount) {
    if (isPremium) return true;
    return currentCustomerCount < getCustomerLimit();
  }

  /// Check if user can send WA reminder
  bool canSendWAReminder() {
    if (isPremium) return true;
    return (_profile?.waReminderCount ?? 0) < getWAReminderLimit();
  }

  /// Increment WA reminder counter after sending
  Future<void> incrementWACount(String userId) async {
    if (_profile == null || isPremium) return; // Premium tidak perlu counter
    
    try {
      final newCount = (_profile!.waReminderCount) + 1;
      final docs = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _profilesCollectionId,
        queries: [Query.equal('userId', userId)],
      );
      if (docs.documents.isNotEmpty) {
        await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _profilesCollectionId,
          documentId: docs.documents.first.$id,
          data: {'waReminderCount': newCount},
        );
        _profile = _profile!.copyWith(waReminderCount: newCount);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('incrementWACount error: $e');
    }
  }
}
