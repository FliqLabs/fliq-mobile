import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../utils/clipboard_share.dart';
import '../../widgets/crypto_icons.dart';
import '../../widgets/fliq_sheet.dart';
import '../../widgets/qr_code_card.dart';

/// "Your fliq name": a QR code other people scan to pay you.
class FliqNamePage extends StatelessWidget {
  const FliqNamePage({super.key});

  static Future<void> show(BuildContext context) =>
      showFliqSheet<void>(context, builder: (_) => const FliqNamePage());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FliqSheetHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              const Text(
                'Your fliq name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'fliq users pay it instantly, with no fee. Any NEAR wallet '
                'can send USDC to it.',
                style: TextStyle(
                  color: FliqSheetColors.muted,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: FliqSheetColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    FliqQrCode(
                      data: SampleData.nearAccount,
                      size: 230,
                      center: NetworkBadge(network: SampleData.near, size: 30),
                    ),
                    SizedBox(height: 22),
                    Text(
                      '@${SampleData.handle}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'NEAR wallets: ${SampleData.nearAccount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FliqSheetColors.muted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: SheetPrimaryButton(
                  key: const ValueKey('copy-near-address'),
                  label: 'Copy NEAR address',
                  icon: Icons.copy_rounded,
                  onPressed: () => copyWithFeedback(
                    context,
                    SampleData.nearAccount,
                    message: 'NEAR address copied',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SheetRoundButton(
                key: const ValueKey('share-fliq-name'),
                icon: Icons.share_outlined,
                tooltip: 'Share',
                onPressed: () => shareText(
                  'Pay me on fliq: @${SampleData.handle}\n'
                  'NEAR address: ${SampleData.nearAccount}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
