import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/router.dart';
import '../data/supabase.dart';

/// Bungkus Firebase Cloud Messaging. Aman dipanggil walau Firebase belum
/// dikonfigurasi (mis. saat development tanpa google-services.json) - init
/// akan gagal diam-diam dan fitur push tidak aktif.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _firebaseReady = false;

  /// Global key untuk menampilkan snackbar saat notifikasi masuk di foreground.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_navigateToNotifications);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _navigateToNotifications(initial);
      }

      await saveTokenForCurrentUser();
    } catch (e) {
      debugPrint('FCM tidak aktif (Firebase belum dikonfigurasi): $e');
    }
  }

  /// Simpan FCM token ke profil anggota. Panggil setelah login/register.
  Future<void> saveTokenForCurrentUser() async {
    if (!_firebaseReady) {
      try {
        await Firebase.initializeApp();
        _firebaseReady = true;
      } catch (_) {
        return;
      }
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('Gagal menyimpan FCM token: $e');
    }
  }

  Future<void> clearTokenForCurrentUser() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabase.from('members').update({'fcm_token': null}).eq('user_id', uid);
    } catch (_) {}
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? '';
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$title${body.isNotEmpty ? ': $body' : ''}'),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: _navigateToNotifications,
        ),
      ),
    );
  }

  void _navigateToNotifications([RemoteMessage? _]) {
    appRouter.go('/notifications');
  }

  Future<void> _saveToken(String token) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabase.from('members').update({'fcm_token': token}).eq('user_id', uid);
    } catch (_) {
      // abaikan bila anggota belum terdaftar
    }
  }

  bool get isReady => _firebaseReady;
}
