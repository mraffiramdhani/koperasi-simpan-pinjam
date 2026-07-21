import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import 'savings_repository.dart';
import 'supabase.dart';

class NotificationRepository {
  Future<List<AppNotification>> getMyNotifications() async {
    final rows = await supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markRead(String id) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

final myNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  ref.watch(dataRefreshProvider);
  return ref.read(notificationRepositoryProvider).getMyNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(myNotificationsProvider.future);
  return list.where((n) => !n.isRead).length;
});
