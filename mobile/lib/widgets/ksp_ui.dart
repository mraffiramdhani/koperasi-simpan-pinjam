import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Chip status generik (anggota / pinjaman / angsuran).
class KspStatusChip extends StatelessWidget {
  const KspStatusChip({
    super.key,
    required this.label,
    this.color,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final bool dense;

  factory KspStatusChip.member(String status) {
    final (label, color) = switch (status) {
      'active' => ('Aktif', const Color(0xFF059669)),
      'pending' => ('Menunggu', const Color(0xFFD97706)),
      'inactive' => ('Nonaktif', const Color(0xFF64748B)),
      'rejected' => ('Ditolak', const Color(0xFFDC2626)),
      _ => (status, const Color(0xFF64748B)),
    };
    return KspStatusChip(label: label, color: color);
  }

  factory KspStatusChip.loan(String status) {
    final (label, color) = switch (status) {
      'pengajuan' => ('Menunggu Persetujuan', const Color(0xFFD97706)),
      'approved' => ('Menunggu Pencairan', const Color(0xFF2563EB)),
      'active' => ('Aktif', const Color(0xFF059669)),
      'rejected' => ('Ditolak', const Color(0xFFDC2626)),
      'lunas' => ('Lunas', kBrandColor),
      _ => (status, const Color(0xFF64748B)),
    };
    return KspStatusChip(label: label, color: color);
  }

  factory KspStatusChip.installment(String status) {
    final (label, color) = switch (status) {
      'lunas' => ('Lunas', const Color(0xFF059669)),
      'telat' => ('Telat', const Color(0xFFDC2626)),
      _ => ('Belum', const Color(0xFF64748B)),
    };
    return KspStatusChip(label: label, color: color, dense: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Empty / error state seragam.
class KspEmptyState extends StatelessWidget {
  const KspEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 64, color: scheme.outline),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          Center(child: action),
        ],
      ],
    );
  }
}

/// Nominal rupiah dengan gaya kredit/debit.
class KspAmountText extends StatelessWidget {
  const KspAmountText(
    this.value, {
    super.key,
    this.isCredit,
    this.style,
  });

  final num? value;
  final bool? isCredit;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final credit = isCredit;
    final prefix = credit == null ? '' : (credit ? '+' : '-');
    final color = credit == null
        ? null
        : (credit ? const Color(0xFF059669) : const Color(0xFFDC2626));
    return Text(
      '$prefix${formatRupiah(value)}',
      style: (style ?? Theme.of(context).textTheme.titleSmall)?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Judul seksi di halaman.
class KspSectionHeader extends StatelessWidget {
  const KspSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tombol filled dengan state loading.
class KspLoadingButton extends StatelessWidget {
  const KspLoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : (icon == null
            ? Text(label)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ));

    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}

/// Banner info / peringatan.
class KspInfoBanner extends StatelessWidget {
  const KspInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: c.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu list row modern (ikon + title + subtitle + trailing).
class KspListTile extends StatelessWidget {
  const KspListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (iconColor ?? scheme.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon ?? Icons.circle,
                      color: iconColor ?? scheme.primary,
                      size: 22,
                    ),
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
