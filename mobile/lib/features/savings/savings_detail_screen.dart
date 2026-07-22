import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/member_guard.dart';
import '../../core/theme.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../../widgets/ksp_ui.dart';
import 'savings_setor_flow.dart';

final _txnProvider =
    FutureProvider.family<List<SavingsTxn>, String>((ref, accountId) async {
  ref.watch(dataRefreshProvider);
  return ref.read(savingsRepositoryProvider).getTransactions(accountId);
});

class SavingsDetailScreen extends ConsumerWidget {
  const SavingsDetailScreen({super.key, required this.account});
  final SavingsAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(_txnProvider(account.id));
    final tipeLabel =
        'Simpanan ${account.tipe[0].toUpperCase()}${account.tipe.substring(1)}';

    return Scaffold(
      appBar: AppBar(title: Text(tipeLabel)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!await ensureMemberActive(context, ref)) return;
          if (!context.mounted) return;
          await startSavingsSetor(context, ref, account);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Setor'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Colors.white,
                ],
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Saldo Saat Ini',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(account.saldo),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kBrandDark,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mutasi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          Expanded(
            child: txnAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const KspEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return KspListTile(
                      icon: t.isSetor
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      iconColor: t.isSetor
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      title: t.isSetor ? 'Setor' : 'Tarik',
                      subtitle: '${formatTanggalStr(t.createdAt)} · ${t.metode}',
                      trailing: KspAmountText(t.nominal, isCredit: t.isSetor),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
