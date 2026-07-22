import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/payment_repository.dart';

/// Menampilkan halaman pembayaran (invoice Xendit) dan memantau statusnya.
/// Pop dengan nilai `true` bila pembayaran sukses.
class PaymentWebViewScreen extends ConsumerStatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.redirectUrl,
    required this.orderId,
    this.testMode = false,
  });

  final String redirectUrl;
  final String orderId;
  final bool testMode;

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  Timer? _pollTimer;
  bool _checking = false;
  bool _pageLoading = true;
  int _loadProgress = 0;
  String? _loadError;
  String _lastStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _pageLoading = true;
              _loadError = null;
              _loadProgress = 0;
            });
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _loadProgress = progress;
              _pageLoading = progress < 100;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _pageLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loadError = error.description;
              _pageLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    if (_checking || !mounted) return;
    await _checkStatus(silent: true);
  }

  Future<void> _simulatePayment() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status = await ref
          .read(paymentRepositoryProvider)
          .paymentStatus(widget.orderId, simulate: true);
      if (!mounted) return;
      _lastStatus = status;
      if (status == 'paid') {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status setelah simulasi: $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simulasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status =
          await ref.read(paymentRepositoryProvider).paymentStatus(widget.orderId);
      if (!mounted) return;
      _lastStatus = status;
      if (status == 'paid') {
        Navigator.of(context).pop(true);
      } else if (status == 'failed' || status == 'expired') {
        if (silent) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pembayaran $status')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status pembayaran: $status')),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status pembayaran: $status')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (_lastStatus != 'pending') return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari pembayaran?'),
        content: const Text('Pembayaran belum selesai, tetap keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tetap di sini')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    return leave ?? false;
  }

  void _reload() {
    setState(() {
      _loadError = null;
      _pageLoading = true;
    });
    _controller.loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          actions: [
            TextButton(
              onPressed: _checking ? null : () => _checkStatus(),
              child: const Text('Cek Status', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_pageLoading)
              LinearProgressIndicator(
                value: _loadProgress > 0 ? _loadProgress / 100 : null,
              ),
            if (widget.testMode)
              Material(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mode test Xendit: scan QRIS di halaman ini tidak otomatis menyelesaikan pembayaran.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _checking ? null : _simulatePayment,
                        child: const Text('Simulasikan Pembayaran QRIS'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loadError != null)
              Material(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gagal memuat halaman: $_loadError',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      TextButton(onPressed: _reload, child: const Text('Muat ulang')),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _loadError != null
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat ulang'),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _checking ? null : () => _checkStatus(),
                  child: _checking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Saya Sudah Bayar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
