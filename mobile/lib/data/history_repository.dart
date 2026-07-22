import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'savings_repository.dart';
import 'supabase.dart';

class HistoryItem {
  HistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.nominal,
    required this.createdAt,
    required this.isCredit,
  });

  final String id;
  final String title;
  final String subtitle;
  final num nominal;
  final String createdAt;
  final bool isCredit;
}

class HistoryRepository {
  Future<List<HistoryItem>> getMyHistory({int limit = 50}) async {
    final rows = await supabase
        .from('savings_transactions')
        .select('id, jenis, nominal, metode, keterangan, created_at, savings_accounts(tipe)')
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((e) {
      final raw = e['savings_accounts'];
      String? tipe;
      if (raw is Map) {
        tipe = raw['tipe'] as String?;
      } else if (raw is List && raw.isNotEmpty) {
        tipe = (raw.first as Map)['tipe'] as String?;
      }
      final jenis = e['jenis'] as String;
      final isSetor = jenis == 'setor';
      final tipeLabel = tipe == null
          ? 'Simpanan'
          : 'Simpanan ${tipe[0].toUpperCase()}${tipe.substring(1)}';
      return HistoryItem(
        id: e['id'] as String,
        title: isSetor ? 'Setor $tipeLabel' : 'Tarik $tipeLabel',
        subtitle: [
          e['metode'] as String? ?? '',
          if ((e['keterangan'] as String?)?.isNotEmpty == true) e['keterangan'] as String,
        ].where((s) => s.isNotEmpty).join(' · '),
        nominal: e['nominal'] as num,
        createdAt: e['created_at'] as String,
        isCredit: isSetor,
      );
    }).toList();
  }
}

final historyRepositoryProvider =
    Provider<HistoryRepository>((ref) => HistoryRepository());

final myHistoryProvider = FutureProvider<List<HistoryItem>>((ref) async {
  ref.watch(dataRefreshProvider);
  return ref.read(historyRepositoryProvider).getMyHistory();
});
