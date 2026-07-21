import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _tanggal = DateFormat('d MMM yyyy', 'id_ID');

String formatRupiah(num? value) => _rupiah.format(value ?? 0);

String formatTanggal(DateTime? value) => value == null ? '-' : _tanggal.format(value);

String formatTanggalStr(String? value) =>
    value == null ? '-' : _tanggal.format(DateTime.parse(value));
