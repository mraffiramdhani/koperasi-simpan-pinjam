import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/supabase.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Deep link reset password → arahkan ke layar set password baru
  supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      markPasswordRecovery();
      appRouter.go('/reset-password');
    }
  });

  // Inisialisasi push notification (aman jika Firebase belum dikonfigurasi).
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: KoperasiApp()));
}

class KoperasiApp extends StatelessWidget {
  const KoperasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Koperasi Simpan Pinjam',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NotificationService.scaffoldMessengerKey,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
