import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth;
  AuthService(this._auth);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) => data.session?.user);

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      print(e.message);
      rethrow;
    }
  }

  // Register with email and password
  Future<void> signUp(String name, String email, String password, String phone, String role) async {
    try {
      // The 'data' field is where we pass the metadata for our handle_new_user trigger
      await _auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role,
        },
      );
    } on AuthException catch (e) {
      print(e.message);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}