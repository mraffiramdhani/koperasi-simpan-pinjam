import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'supabase.dart';

class MemberRepository {
  Future<Member?> getMyMember() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await supabase
        .from('members')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? null : Member.fromJson(row);
  }

  Future<Member> createMember({
    required String nama,
    String? nik,
    String? alamat,
    String? phone,
    String? bankCode,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('members')
        .insert({
          'user_id': uid,
          'nama': nama,
          'nik': nik,
          'alamat': alamat,
          'phone': phone,
          'bank_code': bankCode,
          'account_number': accountNumber,
          'account_holder_name': accountHolderName,
        })
        .select()
        .single();
    return Member.fromJson(row);
  }

  Future<Member> updateMember(
    String id, {
    String? nama,
    String? nik,
    String? alamat,
    String? phone,
    String? bankCode,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    final row = await supabase
        .from('members')
        .update({
          if (nama != null) 'nama': nama,
          if (nik != null) 'nik': nik,
          if (alamat != null) 'alamat': alamat,
          if (phone != null) 'phone': phone,
          if (bankCode != null) 'bank_code': bankCode,
          if (accountNumber != null) 'account_number': accountNumber,
          if (accountHolderName != null) 'account_holder_name': accountHolderName,
        })
        .eq('id', id)
        .select()
        .single();
    return Member.fromJson(row);
  }

  /// Upload foto KTP ke bucket `ktp` dengan path `<uid>/ktp.jpg`.
  Future<String> uploadKtp(File file) async {
    final uid = supabase.auth.currentUser!.id;
    final path = '$uid/ktp.jpg';
    await supabase.storage.from('ktp').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    await supabase
        .from('members')
        .update({'foto_ktp_path': path}).eq('user_id', uid);
    return path;
  }

  Future<String?> signedKtpUrl(String path) async {
    return supabase.storage.from('ktp').createSignedUrl(path, 3600);
  }
}

final memberRepositoryProvider =
    Provider<MemberRepository>((ref) => MemberRepository());

/// Profil anggota milik user yang login.
final myMemberProvider = FutureProvider<Member?>((ref) async {
  ref.watch(memberRefreshProvider);
  return ref.read(memberRepositoryProvider).getMyMember();
});

/// Naikkan nilai untuk memaksa refresh [myMemberProvider].
final memberRefreshProvider = StateProvider<int>((ref) => 0);
