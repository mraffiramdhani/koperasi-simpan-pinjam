import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/member_guard.dart';
import '../../core/theme.dart';
import '../../data/member_repository.dart';
import '../../data/notification_repository.dart';
import '../../data/savings_repository.dart';
import '../../widgets/ksp_ui.dart';
import '../profile/member_card.dart';
import '../savings/savings_setor_flow.dart';

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kBrandColor,
        onRefresh: () async {
          ref.read(memberRefreshProvider.notifier).state++;
          ref.read(dataRefreshProvider.notifier).state++;
        },
        child: memberAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => KspEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            subtitle: '$e',
          ),
          data: (member) {
            if (member == null) return const _CompleteProfilePrompt();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                MemberCard(member: member, saldo: saldoAsync.value),
                const SizedBox(height: 24),
                const KspSectionHeader('Menu Cepat'),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.add_card_rounded,
                      label: 'Setor',
                      onTap: () async {
                        if (!await ensureMemberActive(context, ref)) return;
                        if (!context.mounted) return;
                        await startSavingsSetorPicker(context, ref);
                      },
                    ),
                    _QuickAction(
                      icon: Icons.request_quote_rounded,
                      label: 'Ajukan\nPinjaman',
                      onTap: () async {
                        if (!await ensureMemberActive(context, ref)) return;
                        if (!context.mounted) return;
                        context.push('/loan/apply');
                      },
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat',
                      onTap: () => context.push('/riwayat'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SavingsSummary(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavingsSummary extends ConsumerWidget {
  const _SavingsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(myAccountsProvider);
    return accounts.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Gagal memuat simpanan: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KspSectionHeader('Rincian Simpanan'),
          ...list.map(
            (a) => KspListTile(
              icon: switch (a.tipe) {
                'pokok' => Icons.lock_outline_rounded,
                'wajib' => Icons.event_repeat_rounded,
                _ => Icons.volunteer_activism_rounded,
              },
              title:
                  'Simpanan ${a.tipe[0].toUpperCase()}${a.tipe.substring(1)}',
              trailing: KspAmountText(a.saldo),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer,
                          scheme.primaryContainer.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: kBrandDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                  ),
                ],
              ),
            ),
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
    return KspEmptyState(
      icon: Icons.badge_outlined,
      title: 'Lengkapi Profil Anggota',
      subtitle:
          'Anda belum terdaftar sebagai anggota. Lengkapi data diri untuk mulai.',
      action: FilledButton(
        onPressed: () => context.push('/profile/edit'),
        child: const Text('Lengkapi Sekarang'),
      ),
    );
  }
}
