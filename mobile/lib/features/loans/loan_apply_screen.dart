import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/loan_repository.dart';
import '../../data/savings_repository.dart';

class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  final _pokok = TextEditingController();
  final _tujuan = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _tenor = 6;
  final double _jasaPersen = 1.5;
  bool _loading = false;

  @override
  void dispose() {
    _pokok.dispose();
    _tujuan.dispose();
    super.dispose();
  }

  num get _pokokValue => num.tryParse(_pokok.text.trim()) ?? 0;
  num get _angsuranPerBulan =>
      (_pokokValue / _tenor) + (_pokokValue * _jasaPersen / 100);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(loanRepositoryProvider).ajukanPinjaman(
            pokok: _pokokValue,
            tenor: _tenor,
            tujuan: _tujuan.text.trim(),
            jasaPersen: _jasaPersen,
          );
      ref.read(dataRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan pinjaman terkirim')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception:', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Pinjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _pokok,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pinjaman',
                  prefixText: 'Rp ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = num.tryParse(v?.trim() ?? '');
                  if (n == null || n < 100000) return 'Minimal Rp 100.000';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Tenor: $_tenor bulan'),
              Slider(
                value: _tenor.toDouble(),
                min: 3,
                max: 24,
                divisions: 21,
                label: '$_tenor bulan',
                onChanged: (v) => setState(() => _tenor = v.round()),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tujuan,
                decoration: const InputDecoration(labelText: 'Tujuan Pinjaman'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Estimasi Angsuran / Bulan'),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(_pokokValue > 0 ? _angsuranPerBulan : 0),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Jasa flat $_jasaPersen% per bulan',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajukan Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
