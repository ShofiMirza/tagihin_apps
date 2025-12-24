import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  late final Client _client;
  late final Databases _databases;

  PaymentService() {
    _client = Client()
      ..setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
      ..setProject(dotenv.env['APPWRITE_PROJECT_ID']!);
    _databases = Databases(_client);
  }

  Future<List<Document>> getPaymentsByTransaction(String transactionId, String userId) async {
    final response = await _databases.listDocuments(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
      queries: [
        Query.equal('transactionId', transactionId),
        Query.equal('userId', userId), // Filter by userId
      ],
    );
    return response.documents;
  }

  Future<Document> addPayment(Map<String, dynamic> data) async {
    return await _databases.createDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<Document> updatePayment(String id, Map<String, dynamic> data) async {
    return await _databases.updateDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
      documentId: id,
      data: data,
    );
  }

  Future<void> deletePayment(String id) async {
    await _databases.deleteDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
      documentId: id,
    );
  }

  // Method untuk fetch semua payments dengan filter userId
  Future<List<Document>> getAllPayments(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
        collectionId: dotenv.env['APPWRITE_COLLECTION_PAYMENTS']!,
        queries: [
          Query.equal('userId', userId), // Filter by userId
          Query.orderDesc('\$createdAt'),
          Query.limit(1000),
        ],
      );
      return response.documents;
    } catch (e) {
      print('Error getting all payments: $e');
      return [];
    }
  }

  Future<void> deletePaymentsByTransaction(String transactionId, String userId) async {
    try {
      // Get all payments for this transaction
      final payments = await getPaymentsByTransaction(transactionId, userId);

      // Delete each payment
      for (var payment in payments) {
        await deletePayment(payment.$id);
      }
    } catch (e) {
      print('Error deleting payments by transaction: $e');
    }
  }
}