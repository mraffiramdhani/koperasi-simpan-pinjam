import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/history_repository.dart';
import '../../data/savings_repository.dart';
import '../../widgets/ksp_ui.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: RefreshIndicator(
        color: kBrandColor,
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => KspEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            subtitle: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const KspEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada riwayat transaksi',
                subtitle: 'Setoran dan penarikan akan muncul di sini.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return KspListTile(
                  icon: item.isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  iconColor: item.isCredit
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  title: item.title,
                  subtitle: [
                    formatTanggalStr(item.createdAt),
                    if (item.subtitle.isNotEmpty) item.subtitle,
                  ].join(' · '),
                  trailing: KspAmountText(item.nominal, isCredit: item.isCredit),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
