import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/payment.dart';
import '../../services/account_store.dart';
import '../../utils/clipboard_share.dart';
import '../../utils/formatters.dart';
import 'payout_amount_screen.dart';

/// After Confirm: "Sending" while the provider pays the bank, then "Paid"
/// with the bank's own reference, or "Refunded".
class PayoutResultScreen extends StatelessWidget {
  const PayoutResultScreen({
    required this.payout,
    required this.account,
    required this.currency,
    super.key,
  });

  final Future<Payout> payout;
  final VerifiedAccount account;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FutureBuilder<Payout>(
            future: payout,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _Outcome(
                  title: 'Not sent yet',
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFF5A623),
                  headline: '',
                  detail: snapshot.error.toString(),
                  onDone: () => _close(context),
                );
              }
              final result = snapshot.data;
              if (result == null) {
                return _Outcome(
                  title: 'Sending',
                  icon: Icons.north_east_rounded,
                  iconColor: Colors.white,
                  headline: '',
                  detail: 'Left your vault. Usually in minutes · can take up to an hour.',
                  busy: true,
                  onDone: () => _close(context),
                );
              }
              return _paid(context, result);
            },
          ),
        ),
      ),
    );
  }

  Widget _paid(BuildContext context, Payout result) {
    final symbol = currencySymbol(result.currency);
    final amount = '$symbol${groupDigits(result.receive)}';
    if (result.isRefunded) {
      return _Outcome(
        title: 'Refunded',
        icon: Icons.undo_rounded,
        iconColor: const Color(0xFFAAAAAA),
        headline: amount,
        detail:
            "${providerName(result.provider)} couldn't pay out. Your money is "
            'back in your vault · \$${groupDigits(result.amountUsd, decimals: 2)}',
        onDone: () => _close(context),
      );
    }
    if (!result.isPaid) {
      return _Outcome(
        title: result.hasFailed ? 'Not paid' : 'Sending',
        icon: result.hasFailed
            ? Icons.error_outline_rounded
            : Icons.north_east_rounded,
        iconColor: result.hasFailed ? const Color(0xFFF5A623) : Colors.white,
        headline: amount,
        detail: result.hasFailed
            ? 'The payout did not go through. Check Activity for details.'
            : "The bank hasn't confirmed this yet. We're chasing it. "
                  'Usually in minutes · can take up to an hour.',
        onDone: () => _close(context),
      );
    }
    final time = TimeOfDay.now().format(context);
    final facts = [
      ('Sent', '\$${groupDigits(result.amountUsd, decimals: 2)}'),
      (
        'Rate after fees',
        '\$1 = $symbol${groupDigits(result.rate, decimals: 2)}',
      ),
      ('Paid out by', providerName(result.provider)),
      if (result.bankReference != null) ('NIP session', result.bankReference!),
    ];
    return _Outcome(
      title: 'Paid',
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF2EB467),
      headline: amount,
      detail:
          "landed in ${result.accountName}'s ${account.institution} account\n"
          '$time${result.seconds == null ? '' : ' · ${result.seconds} seconds'}',
      facts: facts,
      onShare: () => shareText(
        'fliq receipt\n'
        '$amount paid to ${result.accountName} (${account.institution})\n'
        '${facts.map((f) => '${f.$1}: ${f.$2}').join('\n')}',
        subject: 'fliq receipt',
      ),
      onDone: () => _close(context),
    );
  }

  void _close(BuildContext context) {
    AccountStore.instance.refresh();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// "Sent $5 to @tobi" after paying another fliq user.
class TransferSentScreen extends StatelessWidget {
  const TransferSentScreen({
    required this.dollars,
    required this.person,
    super.key,
  });

  final double dollars;
  final Person person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _Outcome(
          title: 'Sent',
          icon: Icons.check_rounded,
          iconColor: const Color(0xFF2EB467),
          headline: '\$${groupDigits(dollars, decimals: 2)}',
          detail:
              'to ${person.displayName ?? '@${person.handle}'} · instant · no fee',
          onDone: () {
            AccountStore.instance.refresh();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.headline,
    required this.detail,
    required this.onDone,
    this.facts = const [],
    this.onShare,
    this.busy = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String headline;
  final String detail;
  final List<(String, String)> facts;
  final VoidCallback? onShare;
  final VoidCallback onDone;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        key: ValueKey('outcome-$title'),
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('outcome-close'),
                onPressed: onDone,
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(icon, color: iconColor),
                  ),
                ),
                const SizedBox(height: 20),
                if (headline.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      headline,
                      key: const ValueKey('outcome-amount'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9A9A9E),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        for (final (index, (label, value)) in facts.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              border: index == facts.length - 1
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (onShare != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: const ValueKey('outcome-share'),
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share receipt'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF141414),
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              key: const ValueKey('outcome-done'),
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF3A3A3C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
