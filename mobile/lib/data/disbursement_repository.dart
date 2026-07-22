import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import 'savings_repository.dart';
import 'supabase.dart';

class DisbursementRepository {
  Future<Disbursement?> getLatestForLoan(String loanId) async {
    final row = await supabase
        .from('disbursements')
        .select()
        .eq('loan_id', loanId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Disbursement.fromJson(row);
  }
}

final disbursementRepositoryProvider =
    Provider<DisbursementRepository>((ref) => DisbursementRepository());

final latestDisbursementProvider =
    FutureProvider.family<Disbursement?, String>((ref, loanId) async {
  ref.watch(dataRefreshProvider);
  return ref.read(disbursementRepositoryProvider).getLatestForLoan(loanId);
});
