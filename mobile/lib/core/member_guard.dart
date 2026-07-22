import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/member_repository.dart';
import '../../models.dart';

/// Pesan jika keanggotaan belum aktif.
String memberInactiveMessage(Member? member) {
  switch (member?.status) {
    case 'pending':
      return 'Keanggotaan masih menunggu verifikasi pengurus.';
    case 'rejected':
      return 'Keanggotaan ditolak. Hubungi pengurus koperasi.';
    case 'inactive':
      return 'Keanggotaan nonaktif. Hubungi pengurus koperasi.';
    case null:
      return 'Lengkapi profil anggota terlebih dahulu.';
    default:
      return 'Keanggotaan belum aktif.';
  }
}

/// Cek anggota aktif; tampilkan snackbar dan return false jika tidak.
Future<bool> ensureMemberActive(BuildContext context, WidgetRef ref) async {
  final member = await ref.read(myMemberProvider.future);
  if (member != null && member.isActive) return true;
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(memberInactiveMessage(member))),
  );
  return false;
}
