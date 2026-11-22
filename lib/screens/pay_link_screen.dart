import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../utils/clipboard_share.dart';
import '../utils/formatters.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/qr_code_card.dart';
import '../services/account_store.dart';

/// Shown after "Create pay link": a QR code and link anyone can pay.
///
/// Pops with `true` when closed with ✕, so the Request screen behind it
/// closes too. Back (`false`/null) returns to Request to edit the amount.
class PayLinkScreen extends StatefulWidget {
  const PayLinkScreen({
    required this.amountUsd,
    this.reason,
    this.linkId,
    super.key,
  });

  final double amountUsd;
  final String? reason;

  /// Short id at the end of the link. The API will create this; for now a
  /// random one is made. Tests pass a fixed value.
  final String? linkId;

  @override
  State<PayLinkScreen> createState() => _PayLinkScreenState();
}

class _PayLinkScreenState extends State<PayLinkScreen> {
  late final String _link =
      '${SampleData.payLinkBase}/${AccountStore.instance.handle}/'
      '${widget.linkId ?? _randomId()}';

  static String _randomId() {
    final random = Random();
    return List.generate(4, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  String get _shareText {
    final reason = widget.reason?.trim();
    final forWhat = reason == null || reason.isEmpty ? '' : ' for $reason';
    return 'Pay me ${formatUsd(widget.amountUsd)}$forWhat on fliq: '
        'https://$_link';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 0.7],
                colors: [Color(0xFF29235A), Color(0xFF110F1C), Colors.black],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A6690),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        key: const ValueKey('pay-link-back'),
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back',
                        size: 46,
                        borderColor: const Color(0xFF43405A),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const Expanded(
                        child: Text(
                          'Request',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CircleIconButton(
                        key: const ValueKey('pay-link-close'),
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        size: 46,
                        borderColor: const Color(0xFF43405A),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    children: [
                      const Text(
                        'Waiting for payment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              r'$',
                              style: TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              groupDigits(widget.amountUsd, decimals: 2),
                              key: const ValueKey('pay-link-amount'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 76,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
                        decoration: BoxDecoration(
                          color: const Color(0x66111118),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2E2C40)),
                        ),
                        child: Column(
                          children: [
                            FliqQrCode(
                              data: 'https://$_link',
                              size: 210,
                              center: const Icon(
                                Icons.link_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              _link,
                              key: const ValueKey('pay-link-url'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 15,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Anyone can pay it from any chain. It lands in '
                              'your vault as dollars.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            key: const ValueKey('copy-pay-link'),
                            onPressed: () => copyWithFeedback(
                              context,
                              'https://$_link',
                              message: 'Link copied',
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            label: const Text('Copy link'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        key: const ValueKey('share-pay-link'),
                        onPressed: () =>
                            shareText(_shareText, subject: 'fliq pay link'),
                        tooltip: 'Share',
                        icon: const Icon(Icons.share_outlined),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF1C1C1E),
                          fixedSize: const Size(56, 56),
                          side: const BorderSide(color: Color(0xFF2E2E30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
