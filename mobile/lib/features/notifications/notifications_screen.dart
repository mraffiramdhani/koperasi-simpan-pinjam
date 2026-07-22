import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/notification_repository.dart';
import '../../data/savings_repository.dart';
import '../../widgets/ksp_ui.dart';

const _tipeIcon = {
  'angsuran': Icons.event_busy_rounded,
  'pinjaman': Icons.request_quote_rounded,
  'pembayaran': Icons.payments_rounded,
  'info': Icons.info_outline_rounded,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myNotificationsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: RefreshIndicator(
        color: kBrandColor,
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => KspEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            subtitle: '$e',
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KspEmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Belum ada notifikasi',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return Card(
                  color: n.isRead ? Colors.white : scheme.primaryContainer.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      if (!n.isRead) {
                        await ref
                            .read(notificationRepositoryProvider)
                            .markRead(n.id);
                        ref.read(dataRefreshProvider.notifier).state++;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? scheme.surfaceContainerHighest
                                  : scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _tipeIcon[n.tipe] ?? Icons.info_outline_rounded,
                              color: n.isRead ? scheme.outline : kBrandDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.judul,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: n.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      formatTanggalStr(n.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.45),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.isi,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
