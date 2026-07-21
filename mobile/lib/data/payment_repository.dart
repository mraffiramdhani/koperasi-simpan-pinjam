import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase.dart';

class PaymentResult {
  PaymentResult({required this.orderId, required this.redirectUrl});
  final String orderId;
  final String redirectUrl;
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
    );
  }

  Future<String> paymentStatus(String orderId) async {
    final row = await supabase
        .from('payments')
        .select('status')
        .eq('order_id', orderId)
        .maybeSingle();
    return (row?['status'] as String?) ?? 'pending';
  }
}

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());
