import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.cameraPreview});

  @visibleForTesting
  final Widget? cameraPreview;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  String? _scannedValue;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedValue != null) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;

      setState(() => _scannedValue = value);
      _pauseScanner();
      return;
    }
  }

  Future<void> _pauseScanner() async {
    try {
      await _controller.stop();
    } on MobileScannerException catch (error) {
      debugPrint('Could not pause QR scanner after detection: $error');
    } on PlatformException catch (error) {
      debugPrint('Could not pause QR scanner after detection: $error');
    }
  }

  Future<void> _copyScannedValue() async {
    final value = _scannedValue;
    if (value == null) return;

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanned code copied.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.cameraPreview ??
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  onDetectError: (error, stackTrace) {
                    debugPrint('QR code detection failed: $error');
                  },
                  errorBuilder: (context, error) =>
                      _ScannerError(message: error.errorCode.message),
                ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ScannerButton(
                          key: const ValueKey('scanner-back'),
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, _) => _ScannerButton(
                            key: const ValueKey('scanner-torch'),
                            icon: state.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            tooltip: state.torchState == TorchState.on
                                ? 'Turn flash off'
                                : 'Turn flash on',
                            onPressed: widget.cameraPreview == null
                                ? _controller.toggleTorch
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    key: const ValueKey('qr-scan-window'),
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD9000000),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Point at a bank QR code or an\naccount number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (_scannedValue case final value?)
              _ScannedCodePanel(
                value: value,
                onCopy: _copyScannedValue,
                onClose: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerButton extends StatelessWidget {
  const _ScannerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF555555)),
        ),
        child: Icon(icon, size: 22, semanticLabel: tooltip),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Color(0xFFAAAAAA),
                size: 44,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannedCodePanel extends StatelessWidget {
  const _ScannedCodePanel({
    required this.value,
    required this.onCopy,
    required this.onClose,
  });

  final String value;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB8000000),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR code scanned',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    value,
                    key: const ValueKey('scanned-qr-value'),
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCopy,
                          child: const Text('Copy code'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: onClose,
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
