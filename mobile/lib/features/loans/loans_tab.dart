import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/loan_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';

const _statusLabel = {
  'pengajuan': ('Menunggu Persetujuan', Colors.orange),
  'approved': ('Disetujui', Colors.blue),
  'active': ('Aktif', Colors.green),
  'rejected': ('Ditolak', Colors.red),
  'lunas': ('Lunas', Colors.teal),
};

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pinjaman')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/loan/apply'),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(dataRefreshProvider.notifier).state++,
        child: loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (loans) {
            if (loans.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada pinjaman')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
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
    final (label, color) = _statusLabel[loan.status] ?? ('-', Colors.grey);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(formatRupiah(loan.pokok),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Tenor ${loan.tenor} bulan - jasa ${loan.jasaPersen}%/bln'),
            Text(loan.tujuan ?? '-'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/loan/${loan.id}'),
      ),
    );
  }
}
