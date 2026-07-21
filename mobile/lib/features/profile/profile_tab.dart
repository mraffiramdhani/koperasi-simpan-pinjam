import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/auth_repository.dart';
import '../../data/member_repository.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _uploadKtp(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    try {
      await ref.read(memberRepositoryProvider).uploadKtp(File(picked.path));
      ref.read(memberRefreshProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto KTP berhasil diunggah')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal unggah: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(myMemberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (member) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 40,
                child: Text(
                  (member?.nama ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(member?.nama ?? '-',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Center(child: Text(member?.noAnggota ?? 'Belum aktif')),
              const SizedBox(height: 24),
              _InfoTile(label: 'NIK', value: member?.nik ?? '-'),
              _InfoTile(label: 'No. HP', value: member?.phone ?? '-'),
              _InfoTile(label: 'Alamat', value: member?.alamat ?? '-'),
              _InfoTile(
                label: 'Foto KTP',
                value: member?.fotoKtpPath != null ? 'Sudah diunggah' : 'Belum ada',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profil'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _uploadKtp(context, ref),
                icon: const Icon(Icons.upload_file),
                label: const Text('Unggah Foto KTP'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(color: Colors.black, fontSize: 15)),
      ),
    );
  }
}
