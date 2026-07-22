import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase.dart';

class PaymentResult {
  PaymentResult({
    required this.orderId,
    required this.redirectUrl,
    this.testMode = false,
  });
  final String orderId;
  final String redirectUrl;
  final bool testMode;
}

class PaymentRepository {
  /// Membuat transaksi pembayaran via Edge Function `create-payment`.
  /// [purpose] = 'simpanan' | 'angsuran'.
  /// [refId]   = savings_account_id (simpanan) atau installment_id (angsuran).
  Future<PaymentResult> createPayment({
    required String purpose,
    required String refId,
    required num nominal,
  }) async {
    final res = await supabase.functions.invoke(
      'create-payment',
      body: {
        'purpose': purpose,
        'ref_id': refId,
        'nominal': nominal,
      },
    );

    final data = res.data as Map<String, dynamic>;
    if (data['redirect_url'] == null) {
      throw Exception(data['error'] ?? 'Gagal membuat pembayaran');
    }
    return PaymentResult(
      orderId: data['order_id'] as String,
      redirectUrl: data['redirect_url'] as String,
      testMode: data['test_mode'] == true,
    );
  }

  Future<String> paymentStatus(String orderId, {bool simulate = false}) async {
    final res = await supabase.functions.invoke(
      'check-payment',
      body: {
        'order_id': orderId,
        if (simulate) 'simulate': true,
      },
    );

    final data = res.data as Map<String, dynamic>?;
    if (data == null) return 'pending';
    if (data['error'] != null) {
      throw Exception(data['error']);
    }
    return (data['status'] as String?) ?? 'pending';
  }
}

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());
