import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../data/member_repository.dart';
import '../../widgets/ksp_ui.dart';

final _ktpPreviewProvider = FutureProvider.autoDispose<String?>((ref) async {
  final member = await ref.watch(myMemberProvider.future);
  final path = member?.fotoKtpPath;
  if (path == null || path.isEmpty) return null;
  return ref.read(memberRepositoryProvider).signedKtpUrl(path);
});

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _openEkyc(BuildContext context, WidgetRef ref) async {
    final ok = await context.push<bool>('/ekyc/ktp');
    if (ok == true) {
      ref.invalidate(_ktpPreviewProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(myMemberProvider);
    final ktpPreview = ref.watch(_ktpPreviewProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => KspEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Gagal memuat',
          subtitle: '$e',
        ),
        data: (member) {
          final initial = (member?.nama ?? '?').substring(0, 1).toUpperCase();
          final hasKtp = member?.fotoKtpPath != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kBrandDark, kBrandColor],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: kBrandColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                member?.nama ?? '-',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    member?.noAnggota ?? 'Belum aktif',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  if (member != null) ...[
                    const SizedBox(width: 8),
                    KspStatusChip.member(member.status),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const KspSectionHeader('Data Diri'),
              _InfoCard(
                items: [
                  ('NIK', member?.nik ?? '-'),
                  ('No. HP', member?.phone ?? '-'),
                  ('Alamat', member?.alamat ?? '-'),
                ],
              ),
              const SizedBox(height: 8),
              const KspSectionHeader('Rekening Pencairan'),
              _InfoCard(
                items: [
                  (
                    'Rekening',
                    member?.hasBankAccount == true
                        ? '${member!.bankCode} · ${member.accountNumber}'
                        : 'Belum diisi'
                  ),
                  ('Nama Pemilik', member?.accountHolderName ?? '-'),
                ],
              ),
              const SizedBox(height: 8),
              const KspSectionHeader('e-KYC / KTP'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasKtp)
                        ktpPreview.when(
                          loading: () => const SizedBox(
                            height: 140,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const KspInfoBanner(
                            message: 'Foto KTP tersimpan, tetapi pratinjau gagal dimuat.',
                          ),
                          data: (url) => url == null
                              ? const SizedBox.shrink()
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 85.6 / 53.98,
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: scheme.surfaceContainerHighest,
                                        alignment: Alignment.center,
                                        child: const Text('Gagal memuat gambar'),
                                      ),
                                    ),
                                  ),
                                ),
                        )
                      else
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.4),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge_outlined,
                                  color: scheme.outline, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada foto e-KTP',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openEkyc(context, ref),
                        icon: Icon(
                          hasKtp
                              ? Icons.cameraswitch_rounded
                              : Icons.photo_camera_rounded,
                        ),
                        label: Text(
                          hasKtp ? 'Foto Ulang e-KTP' : 'Verifikasi e-KTP',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profil'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                ),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              ListTile(
                dense: true,
                title: Text(
                  items[i].$1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
                subtitle: Text(
                  items[i].$2,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (i < items.length - 1) const Divider(indent: 16, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }
}
