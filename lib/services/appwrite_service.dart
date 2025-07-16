import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteService {
  late Client client;
  late Databases database;

  AppwriteService() {
    client = Client()
      .setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
      .setProject(dotenv.env['APPWRITE_PROJECT_ID']!);

    database = Databases(client);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await database.listDocuments(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_CUSTOMER']!, // sesuai .env Anda
    );
    return response.documents.map((doc) => doc.data).toList();
  }

  Future<void> addCustomer(Map<String, dynamic> data) async {
    await database.createDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_CUSTOMER']!,
      documentId: 'unique()', // biar auto id
      data: data,
    );
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await database.updateDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_CUSTOMER']!,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteCustomer(String id) async {
    await database.deleteDocument(
      databaseId: dotenv.env['APPWRITE_DATABASE_ID']!,
      collectionId: dotenv.env['APPWRITE_COLLECTION_CUSTOMER']!,
      documentId: id,
    );
  }
}