import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../../widgets/ksp_ui.dart';
import 'savings_detail_screen.dart';

const _tipeLabel = {
  'pokok': 'Simpanan Pokok',
  'wajib': 'Simpanan Wajib',
  'sukarela': 'Simpanan Sukarela',
};

const _tipeIcon = {
  'pokok': Icons.lock_outline_rounded,
  'wajib': Icons.event_repeat_rounded,
  'sukarela': Icons.volunteer_activism_rounded,
};

class SavingsTab extends ConsumerWidget {
  const SavingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(myAccountsProvider);
    final total = ref.watch(totalSaldoProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Simpanan')),
      body: RefreshIndicator(
        color: kBrandColor,
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: accountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => KspEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            subtitle: '$e',
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const KspEmptyState(
                icon: Icons.savings_outlined,
                title: 'Belum ada rekening simpanan',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Simpanan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(total),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: kBrandDark,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...accounts.map((a) => _AccountCard(account: a)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});
  final SavingsAccount account;

  @override
  Widget build(BuildContext context) {
    return KspListTile(
      icon: _tipeIcon[account.tipe],
      title: _tipeLabel[account.tipe] ?? account.tipe,
      subtitle: 'Saldo tersedia',
      trailing: KspAmountText(account.saldo),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SavingsDetailScreen(account: account),
        ),
      ),
    );
  }
}
