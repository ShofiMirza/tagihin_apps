import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  late final Client _client;
  late final Account _account;

  models.Session? _session;
  bool _loading = true;
  bool get loading => _loading;

  bool get isLoggedIn => _session != null;

  AuthProvider() {
    _initializeClient();
  }

  void _initializeClient() {
    try {
      final endpoint = dotenv.env['APPWRITE_ENDPOINT'];
      final projectId = dotenv.env['APPWRITE_PROJECT_ID'];
      
      if (endpoint == null || projectId == null) {
        print('Error: APPWRITE_ENDPOINT or APPWRITE_PROJECT_ID not set in .env');
        _loading = false;
        notifyListeners();
        return;
      }

      _client = Client()
        ..setEndpoint(endpoint)
        ..setProject(projectId);
      
      _account = Account(_client);
      checkSession();
    } catch (e) {
      print('Error initializing client: $e');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> checkSession() async {
    try {
      _loading = true;
      notifyListeners();
      
      _session = await _account.getSession(sessionId: 'current');
      print('Session found: user is logged in');
    } catch (e) {
      print('No active session: $e');
      _session = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _session = await _account.createEmailPasswordSession(
        email: email, 
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _session = null;
      notifyListeners();
    }
  }
}