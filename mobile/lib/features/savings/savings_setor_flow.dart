import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payment_repository.dart';
import '../../data/savings_repository.dart';
import '../../models.dart';
import '../payment/payment_webview_screen.dart';

Future<void> startSavingsSetor(
  BuildContext context,
  WidgetRef ref,
  SavingsAccount account,
) async {
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
          testMode: result.testMode,
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

Future<void> startSavingsSetorPicker(BuildContext context, WidgetRef ref) async {
  final accounts = await ref.read(myAccountsProvider.future);
  if (!context.mounted) return;

  if (accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Belum ada rekening simpanan')),
    );
    return;
  }

  final account = accounts.length == 1
      ? accounts.first
      : await _pickAccount(context, accounts);
  if (account == null || !context.mounted) return;

  await startSavingsSetor(context, ref, account);
}

Future<SavingsAccount?> _pickAccount(
  BuildContext context,
  List<SavingsAccount> accounts,
) {
  const labels = {
    'pokok': 'Simpanan Pokok',
    'wajib': 'Simpanan Wajib',
    'sukarela': 'Simpanan Sukarela',
  };

  return showModalBottomSheet<SavingsAccount>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pilih Rekening',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...accounts.map(
            (a) => ListTile(
              title: Text(labels[a.tipe] ?? a.tipe),
              onTap: () => Navigator.pop(ctx, a),
            ),
          ),
        ],
      ),
    ),
  );
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
