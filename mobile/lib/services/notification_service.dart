import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/supabase.dart';

/// Bungkus Firebase Cloud Messaging. Aman dipanggil walau Firebase belum
/// dikonfigurasi (mis. saat development tanpa google-services.json) - init
/// akan gagal diam-diam dan fitur push tidak aktif.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _ready = false;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Simpan token supaya Edge Function bisa mengirim push.
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
      messaging.onTokenRefresh.listen(_saveToken);

      _ready = true;
    } catch (e) {
      debugPrint('FCM tidak aktif (Firebase belum dikonfigurasi): $e');
    }
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

  bool get isReady => _ready;
}
