import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import 'savings_detail_screen.dart';

const _tipeLabel = {
  'pokok': 'Simpanan Pokok',
  'wajib': 'Simpanan Wajib',
  'sukarela': 'Simpanan Sukarela',
};

const _tipeIcon = {
  'pokok': Icons.lock_outline,
  'wajib': Icons.event_repeat,
  'sukarela': Icons.volunteer_activism,
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
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: accountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (accounts) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Total Simpanan'),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(total),
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...accounts.map((a) => _AccountCard(account: a)),
            ],
          ),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_tipeIcon[account.tipe],
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(_tipeLabel[account.tipe] ?? account.tipe),
        subtitle: Text(formatRupiah(account.saldo),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SavingsDetailScreen(account: account),
          ),
        ),
      ),
    );
  }
}
