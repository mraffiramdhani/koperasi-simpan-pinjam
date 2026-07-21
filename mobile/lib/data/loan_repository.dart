import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import 'savings_repository.dart';
import 'supabase.dart';

class LoanRepository {
  Future<List<Loan>> getMyLoans() async {
    final rows = await supabase
        .from('loans')
        .select()
        .order('created_at', ascending: false);
    return rows.map((e) => Loan.fromJson(e)).toList();
  }

  Future<List<Installment>> getInstallments(String loanId) async {
    final rows = await supabase
        .from('loan_installments')
        .select()
        .eq('loan_id', loanId)
        .order('angsuran_ke');
    return rows.map((e) => Installment.fromJson(e)).toList();
  }

  Future<String> ajukanPinjaman({
    required num pokok,
    required int tenor,
    String? tujuan,
    num jasaPersen = 1.5,
  }) async {
    final id = await supabase.rpc('rpc_ajukan_pinjaman', params: {
      'p_pokok': pokok,
      'p_tenor': tenor,
      'p_tujuan': tujuan,
      'p_jasa_persen': jasaPersen,
    });
    return id as String;
  }
}

final loanRepositoryProvider =
    Provider<LoanRepository>((ref) => LoanRepository());

final myLoansProvider = FutureProvider<List<Loan>>((ref) async {
  ref.watch(dataRefreshProvider);
  return ref.read(loanRepositoryProvider).getMyLoans();
});

final installmentsProvider =
    FutureProvider.family<List<Installment>, String>((ref, loanId) async {
  ref.watch(dataRefreshProvider);
  return ref.read(loanRepositoryProvider).getInstallments(loanId);
});
