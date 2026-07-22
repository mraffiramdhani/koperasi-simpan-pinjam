import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/member_guard.dart';
import '../../core/theme.dart';
import '../../data/loan_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../../widgets/ksp_ui.dart';

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pinjaman')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!await ensureMemberActive(context, ref)) return;
          if (!context.mounted) return;
          context.push('/loan/apply');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajukan'),
      ),
      body: RefreshIndicator(
        color: kBrandColor,
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => KspEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            subtitle: '$e',
          ),
          data: (loans) {
            if (loans.isEmpty) {
              return KspEmptyState(
                icon: Icons.request_quote_outlined,
                title: 'Belum ada pinjaman',
                subtitle: 'Ajukan pinjaman pertama Anda melalui tombol di bawah.',
                action: FilledButton.icon(
                  onPressed: () async {
                    if (!await ensureMemberActive(context, ref)) return;
                    if (!context.mounted) return;
                    context.push('/loan/apply');
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajukan Pinjaman'),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: loans.length,
              itemBuilder: (_, i) => _LoanCard(loan: loans[i]),
            );
          },
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/loan/${loan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatRupiah(loan.pokok),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  KspStatusChip.loan(loan.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tenor ${loan.tenor} bulan · jasa ${loan.jasaPersen}%/bln',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              if ((loan.tujuan ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  loan.tujuan!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text(
                    formatTanggalStr(loan.tanggalPengajuan),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.35)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
