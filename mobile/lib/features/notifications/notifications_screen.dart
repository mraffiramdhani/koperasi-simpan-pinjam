import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/notification_repository.dart';
import '../../data/savings_repository.dart';

const _tipeIcon = {
  'angsuran': Icons.event_busy,
  'pinjaman': Icons.request_quote,
  'pembayaran': Icons.payments,
  'info': Icons.info_outline,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada notifikasi')),
                ],
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        n.isRead ? Colors.grey.shade100 : Colors.teal.shade50,
                    child: Icon(_tipeIcon[n.tipe] ?? Icons.info_outline,
                        color: n.isRead ? Colors.grey : Colors.teal),
                  ),
                  title: Text(n.judul,
                      style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(n.isi),
                  trailing: Text(formatTanggalStr(n.createdAt),
                      style: const TextStyle(fontSize: 11)),
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markRead(n.id);
                      ref.read(dataRefreshProvider.notifier).state++;
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
