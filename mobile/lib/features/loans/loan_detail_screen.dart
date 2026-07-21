import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/loan_repository.dart';
import '../../data/payment_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
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
    final loan = loansAsync.value?.where((l) => l.id == loanId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pinjaman')),
      body: installmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (installments) {
          final lunas = installments.where((i) => i.isLunas).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (loan != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatRupiah(loan.pokok),
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Tenor ${loan.tenor} bulan - jasa ${loan.jasaPersen}%/bln'),
                        Text('Tujuan: ${loan.tujuan ?? '-'}'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: installments.isEmpty ? 0 : lunas / installments.length,
                        ),
                        const SizedBox(height: 4),
                        Text('$lunas dari ${installments.length} angsuran lunas'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Jadwal Angsuran',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (installments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('Jadwal muncul setelah pinjaman disetujui')),
                ),
              ...installments.map((i) => _InstallmentTile(
                    inst: i,
                    onBayar: () => _bayar(context, ref, i),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.inst, required this.onBayar});
  final Installment inst;
  final VoidCallback onBayar;

  @override
  Widget build(BuildContext context) {
    final overdue =
        !inst.isLunas && DateTime.parse(inst.jatuhTempo).isBefore(DateTime.now());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: inst.isLunas
              ? Colors.green.shade50
              : (overdue ? Colors.red.shade50 : Colors.grey.shade100),
          child: Text('${inst.angsuranKe}'),
        ),
        title: Text(formatRupiah(inst.total),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Jatuh tempo: ${formatTanggalStr(inst.jatuhTempo)}'
            '${overdue ? ' (menunggak)' : ''}'),
        trailing: inst.isLunas
            ? const Chip(
                label: Text('Lunas'),
                backgroundColor: Color(0xFFE8F5E9),
                labelStyle: TextStyle(color: Colors.green),
              )
            : FilledButton(onPressed: onBayar, child: const Text('Bayar')),
      ),
    );
  }
}
