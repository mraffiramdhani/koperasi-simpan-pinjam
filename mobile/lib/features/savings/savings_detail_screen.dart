import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/payment_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../payment/payment_webview_screen.dart';

final _txnProvider =
    FutureProvider.family<List<SavingsTxn>, String>((ref, accountId) async {
  ref.watch(dataRefreshProvider);
  return ref.read(savingsRepositoryProvider).getTransactions(accountId);
});

class SavingsDetailScreen extends ConsumerWidget {
  const SavingsDetailScreen({super.key, required this.account});
  final SavingsAccount account;

  Future<void> _setor(BuildContext context, WidgetRef ref) async {
    final nominal = await _askNominal(context);
    if (nominal == null) return;

    try {
      final result = await ref.read(paymentRepositoryProvider).createPayment(
            purpose: 'simpanan',
            refId: account.id,
            nominal: nominal,
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
          const SnackBar(content: Text('Setoran berhasil')),
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
    final txnAsync = ref.watch(_txnProvider(account.id));

    return Scaffold(
      appBar: AppBar(title: Text('Simpanan ${account.tipe}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _setor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Setor'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                const Text('Saldo Saat Ini'),
                const SizedBox(height: 6),
                Text(formatRupiah(account.saldo),
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: txnAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            t.isSetor ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          t.isSetor ? Icons.arrow_downward : Icons.arrow_upward,
                          color: t.isSetor ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(t.isSetor ? 'Setor' : 'Tarik'),
                      subtitle: Text(
                          '${formatTanggalStr(t.createdAt)} - ${t.metode}'),
                      trailing: Text(
                        '${t.isSetor ? '+' : '-'}${formatRupiah(t.nominal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: t.isSetor ? Colors.green : Colors.red,
                        ),
                      ),
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

Future<num?> _askNominal(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<num>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nominal Setoran'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          prefixText: 'Rp ',
          hintText: '0',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final v = num.tryParse(controller.text.trim());
            if (v != null && v > 0) Navigator.pop(ctx, v);
          },
          child: const Text('Lanjut Bayar'),
        ),
      ],
    ),
  );
}
