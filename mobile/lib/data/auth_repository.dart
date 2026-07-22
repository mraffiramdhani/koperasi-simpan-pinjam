import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import 'supabase.dart';

class AuthRepository {
  Future<AuthResponse> signIn(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, {String? nama}) {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: {if (nama != null) 'nama': nama},
    );
  }

  Future<void> signOut() async {
    try {
      await NotificationService.instance.clearTokenForCurrentUser();
    } catch (_) {}
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.koperasi://reset-password',
    );
  }

  User? get currentUser => supabase.auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Emit event setiap kali status login berubah.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// User yang sedang login (null jika belum).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return supabase.auth.currentUser;
});
