import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models.dart';
import 'supabase.dart';

class SavingsRepository {
  Future<List<SavingsAccount>> getMyAccounts() async {
    final rows = await supabase
        .from('savings_accounts')
        .select()
        .order('tipe');
    return rows.map((e) => SavingsAccount.fromJson(e)).toList();
  }

  Future<List<SavingsTxn>> getTransactions(String accountId) async {
    final rows = await supabase
        .from('savings_transactions')
        .select()
        .eq('account_id', accountId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((e) => SavingsTxn.fromJson(e)).toList();
  }
}

final savingsRepositoryProvider =
    Provider<SavingsRepository>((ref) => SavingsRepository());

final myAccountsProvider = FutureProvider<List<SavingsAccount>>((ref) async {
  ref.watch(dataRefreshProvider);
  return ref.read(savingsRepositoryProvider).getMyAccounts();
});

final totalSaldoProvider = FutureProvider<num>((ref) async {
  final accounts = await ref.watch(myAccountsProvider.future);
  return accounts.fold<num>(0, (sum, a) => sum + a.saldo);
});

/// Refresh global untuk data yang berubah setelah transaksi.
final dataRefreshProvider = StateProvider<int>((ref) => 0);
