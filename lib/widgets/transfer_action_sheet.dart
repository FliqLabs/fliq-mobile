import 'package:flutter/material.dart';

enum TransferAction { send, receive, request, scan }

class TransferActionSheet extends StatelessWidget {
  const TransferActionSheet({super.key});

  static Future<TransferAction?> show(BuildContext context) {
    return showModalBottomSheet<TransferAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB8000000),
      builder: (_) => const TransferActionSheet(),
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
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: const Color(0xFF242424)),
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
                  _RoundActionButton(
                    key: const ValueKey('transfer-scan'),
                    icon: Icons.qr_code_scanner_rounded,
                    tooltip: 'Scan QR code',
                    onPressed: () =>
                        Navigator.pop(context, TransferAction.scan),
                  ),
                  _RoundActionButton(
                    key: const ValueKey('transfer-close'),
                    icon: Icons.close_rounded,
                    tooltip: 'Close transfer menu',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF191919),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFFB7B7B7),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What do you want to do?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TransferOption(
                        key: const ValueKey('transfer-send'),
                        title: 'Send',
                        subtitle: 'Bank, mobile money or fliq',
                        icon: Icons.near_me_outlined,
                        onTap: () =>
                            Navigator.pop(context, TransferAction.send),
                      ),
                      const SizedBox(height: 12),
                      _TransferOption(
                        key: const ValueKey('transfer-receive'),
                        title: 'Receive',
                        subtitle: 'Your name, or any coin',
                        icon: Icons.file_download_outlined,
                        onTap: () =>
                            Navigator.pop(context, TransferAction.receive),
                      ),
                      const SizedBox(height: 12),
                      _TransferOption(
                        key: const ValueKey('transfer-request'),
                        title: 'Request',
                        subtitle: 'A link anyone can pay',
                        icon: Icons.link_rounded,
                        onTap: () =>
                            Navigator.pop(context, TransferAction.request),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
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
      width: 58,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD0D0D0),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF353535)),
        ),
        child: Icon(icon, size: 24, semanticLabel: tooltip),
      ),
    );
  }
}

class _TransferOption extends StatelessWidget {
  const _TransferOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 84,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF191919),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          side: const BorderSide(color: Color(0xFF353535)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Icon(icon, size: 27, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF777777),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
