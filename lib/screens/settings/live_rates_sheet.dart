import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../utils/formatters.dart';

/// "Live rates": the best naira rate for $1 right now, as a sheet.
class LiveRatesSheet extends StatelessWidget {
  const LiveRatesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const LiveRatesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = SampleData.rateProviders;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Live rates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('close-live-rates'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              r'$1 after fees',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '₦',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 24),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    groupDigits(SampleData.usdToNgn, decimals: 2),
                    key: const ValueKey('live-rate'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Best of ${providers.length} quoting · ${providers.join(', ')}',
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  const Text(
                    'Before fees',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    formatNaira(SampleData.usdToNgnBeforeFees, decimals: 2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
