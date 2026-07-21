import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/member_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nama = TextEditingController();
  final _nik = TextEditingController();
  final _phone = TextEditingController();
  final _alamat = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nama.dispose();
    _nik.dispose();
    _phone.dispose();
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _submit(String? existingId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = ref.read(memberRepositoryProvider);
    try {
      if (existingId == null) {
        await repo.createMember(
          nama: _nama.text.trim(),
          nik: _nik.text.trim(),
          phone: _phone.text.trim(),
          alamat: _alamat.text.trim(),
        );
      } else {
        await repo.updateMember(
          existingId,
          nama: _nama.text.trim(),
          nik: _nik.text.trim(),
          phone: _phone.text.trim(),
          alamat: _alamat.text.trim(),
        );
      }
      ref.read(memberRefreshProvider.notifier).state++;
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(myMemberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (member) {
          if (!_prefilled && member != null) {
            _nama.text = member.nama;
            _nik.text = member.nik ?? '';
            _phone.text = member.phone ?? '';
            _alamat.text = member.alamat ?? '';
            _prefilled = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nama,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nik,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'NIK'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No. HP'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _alamat,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : () => _submit(member?.id),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
