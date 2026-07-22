import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/disbursement_repository.dart';
import '../../data/loan_repository.dart';
import '../../data/payment_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../../widgets/ksp_ui.dart';
import '../payment/payment_webview_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  Future<void> _bayar(
      BuildContext context, WidgetRef ref, Installment inst) async {
    try {
      final result = await ref.read(paymentRepositoryProvider).createPayment(
            purpose: 'angsuran',
            refId: inst.id,
            nominal: inst.total,
          );
      if (!context.mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            redirectUrl: result.redirectUrl,
            orderId: result.orderId,
            testMode: result.testMode,
          ),
        ),
      );
      if (ok == true && context.mounted) {
        ref.read(dataRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran angsuran berhasil')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync = ref.watch(installmentsProvider(loanId));
    final loansAsync = ref.watch(myLoansProvider);
    final disbursementAsync = ref.watch(latestDisbursementProvider(loanId));
    final loan = loansAsync.value?.where((l) => l.id == loanId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pinjaman')),
      body: installmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => KspEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Gagal memuat',
          subtitle: '$e',
        ),
        data: (installments) {
          final lunas = installments.where((i) => i.isLunas).length;
          final showDisbursement =
              loan != null && (loan.status == 'approved' || loan.status == 'active');
          final progress =
              installments.isEmpty ? 0.0 : lunas / installments.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (loan != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatRupiah(loan.pokok),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            KspStatusChip.loan(loan.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tenor ${loan.tenor} bulan · jasa ${loan.jasaPersen}%/bln',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                        ),
                        Text('Tujuan: ${loan.tujuan ?? '-'}'),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: kBrandColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$lunas dari ${installments.length} angsuran lunas',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showDisbursement) ...[
                const SizedBox(height: 8),
                disbursementAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, _) => KspInfoBanner(
                    message: 'Gagal memuat status pencairan: $e',
                    color: scheme.error,
                    icon: Icons.error_outline,
                  ),
                  data: (disbursement) =>
                      _DisbursementCard(disbursement: disbursement),
                ),
              ],
              const SizedBox(height: 16),
              const KspSectionHeader('Jadwal Angsuran'),
              if (installments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Jadwal muncul setelah pinjaman disetujui'),
                  ),
                ),
              ...installments.map(
                (i) => _InstallmentTile(
                  inst: i,
                  onBayar:
                      loan?.status == 'active' ? () => _bayar(context, ref, i) : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DisbursementCard extends StatelessWidget {
  const _DisbursementCard({this.disbursement});
  final Disbursement? disbursement;

  @override
  Widget build(BuildContext context) {
    if (disbursement == null) {
      return const KspInfoBanner(
        message: 'Menunggu pencairan dana oleh pengurus koperasi.',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFF2563EB),
      );
    }

    final (label, color) = switch (disbursement!.status) {
      'pending' => ('Menunggu Pencairan', const Color(0xFFD97706)),
      'processing' => ('Sedang Diproses', const Color(0xFF2563EB)),
      'completed' => ('Berhasil Dicairkan', const Color(0xFF059669)),
      'failed' => ('Pencairan Gagal', const Color(0xFFDC2626)),
      _ => ('Tidak diketahui', const Color(0xFF64748B)),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_rounded, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status Pencairan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                KspStatusChip(label: label, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nominal: ${formatRupiah(disbursement!.amount)}'),
            Text(
              'Rekening: ${disbursement!.bankCode} ${disbursement!.maskedAccount}',
            ),
            Text('Atas nama: ${disbursement!.accountHolderName}'),
            const SizedBox(height: 4),
            Text(
              'Diperbarui: ${formatTanggalStr(disbursement!.createdAt)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.inst, this.onBayar});
  final Installment inst;
  final VoidCallback? onBayar;

  @override
  Widget build(BuildContext context) {
    final overdue =
        !inst.isLunas && DateTime.parse(inst.jatuhTempo).isBefore(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: inst.isLunas
                    ? const Color(0xFF059669).withValues(alpha: 0.12)
                    : (overdue
                        ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                        : scheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${inst.angsuranKe}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: inst.isLunas
                      ? const Color(0xFF059669)
                      : (overdue ? const Color(0xFFDC2626) : scheme.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRupiah(inst.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Jatuh tempo: ${formatTanggalStr(inst.jatuhTempo)}'
                    '${overdue ? ' (menunggak)' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overdue
                              ? const Color(0xFFDC2626)
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (inst.isLunas)
              KspStatusChip.installment('lunas')
            else if (onBayar != null)
              FilledButton(
                onPressed: onBayar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Bayar'),
              )
            else
              const KspStatusChip(label: 'Belum aktif', dense: true),
          ],
        ),
      ),
    );
  }
}
