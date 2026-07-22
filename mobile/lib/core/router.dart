import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/supabase.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/ekyc/ekyc_ktp_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_shell.dart';
import '../features/loans/loan_apply_screen.dart';
import '../features/loans/loan_detail_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/edit_profile_screen.dart';

/// Menjembatani Stream auth Supabase ke Listenable untuk GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

bool _isPasswordRecovery = false;

/// Dipanggil dari main saat AuthChangeEvent.passwordRecovery.
void markPasswordRecovery() {
  _isPasswordRecovery = true;
}

void clearPasswordRecovery() {
  _isPasswordRecovery = false;
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final loc = state.matchedLocation;
    final isAuthPage =
        loc == '/login' || loc == '/register' || loc == '/reset-password';

    if (_isPasswordRecovery || loc == '/reset-password') {
      if (loggedIn) return loc == '/reset-password' ? null : '/reset-password';
      return loc == '/login' ? null : '/login';
    }

    if (!loggedIn) return isAuthPage && loc != '/reset-password' ? null : '/login';
    if (loc == '/login' || loc == '/register') return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
    GoRoute(path: '/', builder: (_, __) => const HomeShell()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/ekyc/ktp', builder: (_, __) => const EkycKtpScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/riwayat', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/loan/apply', builder: (_, __) => const LoanApplyScreen()),
    GoRoute(
      path: '/loan/:id',
      builder: (_, state) => LoanDetailScreen(loanId: state.pathParameters['id']!),
    ),
  ],
);
