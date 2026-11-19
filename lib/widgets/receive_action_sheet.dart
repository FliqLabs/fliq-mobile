import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import 'fliq_symbol.dart';

enum ReceiveMethod { bankTransfer, fliqName, externalWallet }

class ReceiveActionSheet extends StatelessWidget {
  const ReceiveActionSheet({super.key});

  static Future<ReceiveMethod?> show(BuildContext context) {
    return showModalBottomSheet<ReceiveMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB8000000),
      builder: (_) => const ReceiveActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.62),
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF19191B),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0xFF242426)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF777777),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ReceiveRoundButton(
                    key: const ValueKey('receive-back'),
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  _ReceiveRoundButton(
                    key: const ValueKey('receive-close'),
                    icon: Icons.close_rounded,
                    tooltip: 'Close receive options',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.south_rounded,
                color: Color(0xFFC7C7C7),
                size: 36,
              ),
              const SizedBox(height: 18),
              const Text(
                'How do you want to get paid?',
                key: ValueKey('receive-options-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),
              _ReceiveOption(
                key: const ValueKey('receive-bank-transfer'),
                title: 'Bank transfer',
                subtitle: 'Pay in naira from any Nigerian bank',
                icon: Icons.account_balance_outlined,
                iconColor: Colors.white,
                leading: const _NigeriaFlag(),
                onTap: () => Navigator.pop(context, ReceiveMethod.bankTransfer),
              ),
              const SizedBox(height: 8),
              _ReceiveOption(
                key: const ValueKey('receive-fliq-name'),
                title: 'Your fliq name',
                subtitle: 'Share ${SampleData.nearAccount}',
                icon: Icons.north_east_rounded,
                iconColor: const Color(0xFF20D99A),
                leading: const FliqSymbol(
                  key: ValueKey('receive-fliq-symbol'),
                  size: 23,
                ),
                onTap: () => Navigator.pop(context, ReceiveMethod.fliqName),
              ),
              const SizedBox(height: 8),
              _ReceiveOption(
                key: const ValueKey('receive-external-wallet'),
                title: 'External wallet',
                subtitle: 'From any wallet or exchange',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.white,
                onTap: () =>
                    Navigator.pop(context, ReceiveMethod.externalWallet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiveRoundButton extends StatelessWidget {
  const _ReceiveRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD0D0D0),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF353535)),
        ),
        child: Icon(icon, size: 20, semanticLabel: tooltip),
      ),
    );
  }
}

class _ReceiveOption extends StatelessWidget {
  const _ReceiveOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.leading,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF1B1B1D),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          minimumSize: const Size.fromHeight(72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: const BorderSide(color: Color(0xFF303033)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: leading ?? Icon(icon, size: 23, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF777777),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round Nigerian flag (green · white · green).
class _NigeriaFlag extends StatelessWidget {
  const _NigeriaFlag();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 32,
        height: 32,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF008751))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFF008751))),
          ],
        ),
      ),
    );
  }
}
