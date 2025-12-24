import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models; // <-- Tambahkan ini
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionService {
  late final Client _client;
  late final Databases _databases;

  TransactionService() {
    _client = Client()
      ..setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
      ..setProject(dotenv.env['APPWRITE_PROJECT_ID']!);
    _databases = Databases(_client);
  }

  Future<List<models.Document>> getTransactionsByCustomer(String customerId, String userId) async {
    final response = await _databases.listDocuments(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
      queries: [
        Query.equal('customerId', customerId),
        Query.equal('userId', userId), // Filter by userId
      ],
    );
    return response.documents;
  }

  Future<models.Document> addTransaction(Map<String, dynamic> data) async {
    return await _databases.createDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<models.Document> updateTransaction(String id, Map<String, dynamic> data) async {
    return await _databases.updateDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _databases.deleteDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
      documentId: id,
    );
  }

  Future<models.Document> getTransactionById(String id) async {
    return await _databases.getDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
      documentId: id,
    );
  }

  // Method untuk fetch semua transactions dengan filter userId
  Future<List<models.Document>> getAllTransactions(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
        collectionId: dotenv.env['APPWRITE_COLLECTION_TRANSACTION']!,
        queries: [
          Query.equal('userId', userId), // Filter by userId
          Query.orderDesc('\$createdAt'),
          Query.limit(1000),
        ],
      );
      return response.documents;
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }
}