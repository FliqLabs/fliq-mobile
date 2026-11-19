import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// White-on-dark QR code with rounded finder squares and an optional logo
/// in the middle, matching the fliq receive screens.
class FliqQrCode extends StatelessWidget {
  const FliqQrCode({
    required this.data,
    this.size = 220,
    this.center,
    super.key,
  });

  final String data;
  final double size;

  /// Small widget drawn in the middle (network or coin logo).
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'QR code',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: data,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.white,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.white,
              ),
            ),
            if (center != null)
              Container(
                width: size * 0.22,
                height: size * 0.22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  shape: BoxShape.circle,
                ),
                child: center,
              ),
          ],
        ),
      ),
    );
  }
}
