import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> signIn(String email, String password) async {
    final result = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = result.user;
    if (user == null) return null;
    return getUserData(user.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final row = await _client
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      if (row == null) return null;
      return UserModel.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserData(user.id);
  }

  Future<UserModel> createStudentAccount({
    required String email,
    required String password,
    required String name,
    required String department,
    required String semester,
    required String adminUid,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'name': name.trim(), 'role': 'student'},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to create student account.');
    }

    // Check for duplicate email (Supabase returns a user with empty identities)
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException('An account with this email already exists.');
    }

    final userModel = UserModel(
      uid: user.id,
      email: email.trim(),
      name: name.trim(),
      role: 'student',
      department: department.trim(),
      semester: semester.trim(),
      createdAt: DateTime.now(),
      createdBy: adminUid,
    );

    // After signUp the active session belongs to the new student.
    // Try to insert the user profile row. If RLS blocks it, catch and report.
    try {
      await _client.from('users').upsert(userModel.toMap());
    } catch (e) {
      // Sign out the student session so admin can re-auth cleanly
      await _client.auth.signOut();
      throw Exception(
        'Student auth account created but profile save failed. '
        'Check that the "users" table allows inserts. Error: $e',
      );
    }

    // Sign out the student session so the caller can re-authenticate as admin
    await _client.auth.signOut();
    return userModel;
  }

  Future<UserModel> createAdminAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'name': name.trim(), 'role': 'admin'},
    );

    final user = response.user;

    // If identities is empty, the email is already registered in Supabase Auth.
    if (user == null) {
      throw const AuthException('Unable to create admin account. Please try again.');
    }
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException('An account with this email already exists.');
    }

    final userModel = UserModel(
      uid: user.id,
      email: email.trim(),
      name: name.trim(),
      role: 'admin',
      createdAt: DateTime.now(),
    );

    // Upsert user profile — wrap in try/catch to give a clear error if
    // the 'users' table doesn't exist or RLS is blocking the insert.
    try {
      await _client.from('users').upsert(userModel.toMap());
    } catch (e) {
      // Sign out the orphaned auth user so the user can try again cleanly.
      await _client.auth.signOut();
      throw Exception(
        'Account created in auth but failed to save profile. '
        'Check that the "users" table exists and RLS allows inserts. Error: $e',
      );
    }

    return userModel;
  }

  Future<bool> doesAdminExist() async {
    final rows = await _client
        .from('users')
        .select('uid')
        .eq('role', 'admin')
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> deleteUserDoc(String uid) async {
    await _client.from('users').delete().eq('uid', uid);
  }

  Future<void> updateUser(UserModel user) async {
    await _client.from('users').upsert(user.toMap());
  }
}
