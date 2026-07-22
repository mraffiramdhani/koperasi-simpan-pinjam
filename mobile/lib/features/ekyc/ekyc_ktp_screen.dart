import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/member_repository.dart';
import '../../widgets/ksp_ui.dart';

enum _EkycStep { intro, camera, preview, uploading, success }

/// Alur e-KYC foto KTP ala aplikasi perbankan.
class EkycKtpScreen extends ConsumerStatefulWidget {
  const EkycKtpScreen({super.key});

  @override
  ConsumerState<EkycKtpScreen> createState() => _EkycKtpScreenState();
}

class _EkycKtpScreenState extends ConsumerState<EkycKtpScreen>
    with WidgetsBindingObserver {
  _EkycStep _step = _EkycStep.intro;
  CameraController? _camera;
  Future<void>? _initCamera;
  XFile? _captured;
  String? _error;
  bool _flashOn = false;

  /// Rasio KTP Indonesia ≈ 85.60 × 53.98 mm
  static const _ktpAspect = 85.6 / 53.98;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && _step == _EkycStep.camera) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _error = null;
      _step = _EkycStep.camera;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Kamera tidak tersedia di perangkat ini');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _camera = controller;
      _initCamera = controller.initialize();
      await _initCamera;
      if (!mounted) return;
      await controller.setFlashMode(FlashMode.off);
      setState(() {});
    } catch (e) {
      setState(() => _error = 'Gagal membuka kamera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    _flashOn = !_flashOn;
    await cam.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || cam.value.isTakingPicture) {
      return;
    }
    try {
      final file = await cam.takePicture();
      if (_flashOn) {
        await cam.setFlashMode(FlashMode.off);
        _flashOn = false;
      }
      setState(() {
        _captured = file;
        _step = _EkycStep.preview;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() {
      _captured = picked;
      _step = _EkycStep.preview;
    });
  }

  Future<void> _retake() async {
    _captured = null;
    await _startCamera();
  }

  Future<void> _submit() async {
    final file = _captured;
    if (file == null) return;
    setState(() {
      _step = _EkycStep.uploading;
      _error = null;
    });
    try {
      await _camera?.dispose();
      _camera = null;
      await ref.read(memberRepositoryProvider).uploadKtp(File(file.path));
      ref.read(memberRefreshProvider.notifier).state++;
      if (!mounted) return;
      setState(() => _step = _EkycStep.success);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _EkycStep.preview;
        _error = 'Gagal mengunggah: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _step == _EkycStep.camera ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      appBar: _step == _EkycStep.camera
          ? null
          : AppBar(
              title: Text(switch (_step) {
                _EkycStep.intro => 'Verifikasi KTP',
                _EkycStep.preview => 'Pratinjau KTP',
                _EkycStep.uploading => 'Mengunggah',
                _EkycStep.success => 'Berhasil',
                _ => 'Verifikasi KTP',
              }),
            ),
      body: switch (_step) {
        _EkycStep.intro => _IntroStep(
            onStartCamera: _startCamera,
            onPickGallery: _pickFromGallery,
          ),
        _EkycStep.camera => _CameraStep(
            controller: _camera,
            initFuture: _initCamera,
            error: _error,
            flashOn: _flashOn,
            ktpAspect: _ktpAspect,
            onClose: () => context.pop(),
            onToggleFlash: _toggleFlash,
            onCapture: _capture,
            onGallery: _pickFromGallery,
            onRetry: _startCamera,
          ),
        _EkycStep.preview => _PreviewStep(
            file: _captured!,
            error: _error,
            ktpAspect: _ktpAspect,
            onRetake: _retake,
            onSubmit: _submit,
          ),
        _EkycStep.uploading => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengunggah foto KTP...'),
              ],
            ),
          ),
        _EkycStep.success => _SuccessStep(
            onDone: () => context.pop(true),
          ),
      },
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.onStartCamera,
    required this.onPickGallery,
  });

  final VoidCallback onStartCamera;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    final tips = [
      ('Gunakan KTP asli', 'Jangan foto fotokopi atau layar HP'),
      ('Cahaya cukup', 'Hindari bayangan dan pantulan kilap'),
      ('Seluruh KTP terlihat', 'Sesuaikan dalam bingkai, tidak terpotong'),
      ('Teks terbaca jelas', 'Pastikan NIK dan nama tidak buram'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kBrandDark, kBrandColor],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.badge_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                'Foto e-KTP Anda',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Untuk verifikasi keanggotaan, seperti di aplikasi perbankan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 18),
              // Ilustrasi bingkai KTP
              AspectRatio(
                aspectRatio: 85.6 / 53.98,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      'KTP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const KspSectionHeader('Panduan foto'),
        ...tips.map(
          (t) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.check_rounded, color: kBrandDark, size: 20),
              ),
              title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t.$2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        KspLoadingButton(
          onPressed: onStartCamera,
          label: 'Ambil Foto dengan Kamera',
          icon: Icons.photo_camera_rounded,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onPickGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Pilih dari Galeri'),
        ),
      ],
    );
  }
}

class _CameraStep extends StatelessWidget {
  const _CameraStep({
    required this.controller,
    required this.initFuture,
    required this.error,
    required this.flashOn,
    required this.ktpAspect,
    required this.onClose,
    required this.onToggleFlash,
    required this.onCapture,
    required this.onGallery,
    required this.onRetry,
  });

  final CameraController? controller;
  final Future<void>? initFuture;
  final String? error;
  final bool flashOn;
  final double ktpAspect;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (initFuture != null)
          FutureBuilder(
            future: initFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (error != null || controller == null || !controller!.value.isInitialized) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error ?? 'Kamera belum siap',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                );
              }
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.previewSize!.height,
                  height: controller!.value.previewSize!.width,
                  child: CameraPreview(controller!),
                ),
              );
            },
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Overlay bingkai KTP
        CustomPaint(
          painter: _KtpOverlayPainter(aspectRatio: ktpAspect),
          child: const SizedBox.expand(),
        ),

        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onToggleFlash,
                      icon: Icon(
                        flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Posisikan e-KTP di dalam bingkai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Pastikan seluruh kartu terlihat dan teks terbaca',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundCamButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      onTap: onGallery,
                    ),
                    GestureDetector(
                      onTap: onCapture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 56), // balance layout
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundCamButton extends StatelessWidget {
  const _RoundCamButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _KtpOverlayPainter extends CustomPainter {
  _KtpOverlayPainter({required this.aspectRatio});
  final double aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final maxW = size.width * 0.88;
    final maxH = size.height * 0.42;
    var frameW = maxW;
    var frameH = frameW / aspectRatio;
    if (frameH > maxH) {
      frameH = maxH;
      frameW = frameH * aspectRatio;
    }
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2 - 24;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameW, frameH),
      const Radius.circular(14),
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(frame)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(frame, border);

    // Corner accents
    final corner = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const c = 22.0;
    final r = frame.outerRect;
    // TL
    canvas.drawLine(Offset(r.left, r.top + c), Offset(r.left, r.top), corner);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + c, r.top), corner);
    // TR
    canvas.drawLine(Offset(r.right - c, r.top), Offset(r.right, r.top), corner);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + c), corner);
    // BL
    canvas.drawLine(Offset(r.left, r.bottom - c), Offset(r.left, r.bottom), corner);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + c, r.bottom), corner);
    // BR
    canvas.drawLine(Offset(r.right - c, r.bottom), Offset(r.right, r.bottom), corner);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - c), corner);
  }

  @override
  bool shouldRepaint(covariant _KtpOverlayPainter oldDelegate) =>
      oldDelegate.aspectRatio != aspectRatio;
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.file,
    required this.error,
    required this.ktpAspect,
    required this.onRetake,
    required this.onSubmit,
  });

  final XFile file;
  final String? error;
  final double ktpAspect;
  final VoidCallback onRetake;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pastikan foto jelas dan seluruh KTP terlihat sebelum mengirim.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: ktpAspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            KspInfoBanner(
              message: error!,
              color: Theme.of(context).colorScheme.error,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: 16),
          KspLoadingButton(
            onPressed: onSubmit,
            label: 'Gunakan Foto Ini',
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Foto Ulang'),
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Foto KTP berhasil diunggah',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data e-KTP Anda sudah tersimpan untuk keperluan verifikasi keanggotaan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const Spacer(),
          KspLoadingButton(onPressed: onDone, label: 'Selesai'),
          SizedBox(height: math.max(0, MediaQuery.paddingOf(context).bottom)),
        ],
      ),
    );
  }
}
