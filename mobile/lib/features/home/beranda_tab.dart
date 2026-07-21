import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/member_repository.dart';
import '../../data/notification_repository.dart';
import '../../data/savings_repository.dart';
import '../profile/member_card.dart';

class BerandaTab extends ConsumerWidget {
  const BerandaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(myMemberProvider);
    final saldoAsync = ref.watch(totalSaldoProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(memberRefreshProvider.notifier).state++;
          ref.read(dataRefreshProvider.notifier).state++;
        },
        child: memberAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: '$e'),
          data: (member) {
            if (member == null) return const _CompleteProfilePrompt();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MemberCard(member: member, saldo: saldoAsync.value),
                const SizedBox(height: 24),
                Text('Menu Cepat',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.add_card,
                      label: 'Setor',
                      onTap: () => context.push('/notifications'),
                    ),
                    _QuickAction(
                      icon: Icons.request_quote,
                      label: 'Ajukan Pinjaman',
                      onTap: () => context.push('/loan/apply'),
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long,
                      label: 'Riwayat',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SavingsSummary(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavingsSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(myAccountsProvider);
    return accounts.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Gagal memuat simpanan: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian Simpanan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...list.map(
            (a) => Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text('Simpanan ${a.tipe[0].toUpperCase()}${a.tipe.substring(1)}'),
                trailing: Text(
                  formatRupiah(a.saldo),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteProfilePrompt extends StatelessWidget {
  const _CompleteProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.badge_outlined, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Lengkapi Profil Anggota',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Anda belum terdaftar sebagai anggota. Lengkapi data diri untuk mulai.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push('/profile/edit'),
          child: const Text('Lengkapi Sekarang'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Center(child: Text(message, textAlign: TextAlign.center)),
      ],
    );
  }
}
