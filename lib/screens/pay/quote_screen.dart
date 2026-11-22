import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/payment.dart';
import '../../services/account_store.dart';
import '../../services/api_exception.dart';
import '../../services/fliq_api.dart';
import '../../near/device_key.dart';
import '../../services/payouts.dart';
import '../../services/vault_signer.dart';
import 'payout_result_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/circle_icon_button.dart';
import 'payout_amount_screen.dart';

/// "Confirm": the best after-fee price across providers, held for a short
/// time, before the money leaves the vault.
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({
    required this.account,
    required this.currency,
    required this.amount,
    required this.receiveLocal,
    this.mobileMoney = false,
    super.key,
  });

  final VerifiedAccount account;
  final String currency;

  /// Local money when [receiveLocal], else dollars.
  final double amount;
  final bool receiveLocal;
  final bool mobileMoney;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  Quote? _quote;
  String? _error;
  DateTime? _expiresAt;
  Timer? _timer;
  bool _isConfirming = false;

  String get _symbol => currencySymbol(widget.currency);

  Duration get _left {
    final at = _expiresAt;
    if (at == null) return Duration.zero;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get _expired => _quote != null && _left == Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _quote != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _quote = null;
      _error = null;
    });
    try {
      final quote = AccountStore.instance.isSignedIn
          ? await FliqApi.instance.quote(
              currency: widget.currency,
              amount: widget.amount,
              receiveLocal: widget.receiveLocal,
              mobileMoney: widget.mobileMoney,
            )
          : demoQuote(widget.currency, widget.amount, widget.receiveLocal);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _expiresAt = DateTime.now().add(Duration(seconds: quote.expiresIn));
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _confirm() async {
    final quote = _quote;
    if (quote == null || _isConfirming) return;
    setState(() => _isConfirming = true);
    late final Future<Payout> sending;
    var opened = false;
    void openResult() {
      if (opened || !mounted) return;
      opened = true;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => PayoutResultScreen(
            payout: sending,
            account: widget.account,
            currency: widget.currency,
          ),
        ),
      );
    }

    // Biometrics are asked when the phone signs, inside send().
    sending = Payouts.instance.send(
      quote,
      widget.account,
      onReleased: openResult,
    );
    try {
      await sending;
    } on SigningCancelled {
      // The user backed out of biometrics: nothing moved.
    } on PayoutNotReady catch (error) {
      if (mounted && !opened) _show(error.message);
    } on TransferProblem catch (error) {
      if (mounted && !opened) _show(error.message);
    } on ApiException catch (error) {
      if (mounted && !opened) _show(error.message);
    } on PlatformException {
      if (mounted && !opened) {
        _show('Biometric unlock is unavailable. Please try again.');
      }
    } finally {
      if (mounted && !opened) setState(() => _isConfirming = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleIconButton(
                      key: const ValueKey('quote-back'),
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      size: 44,
                      borderColor: const Color(0xFF333333),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Confirm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                Expanded(
                  child: _error != null
                      ? _Problem(message: _error!, onRetry: _load)
                      : quote == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _details(quote),
                ),
                if (quote != null) _footer(quote),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(Quote quote) {
    final beats = quote.beatsNextBy;
    return ListView(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: Color(0xFFE95D00), size: 10),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${widget.account.accountName} receives',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$_symbol${groupDigits(quote.receive)}',
            key: const ValueKey('quote-receive'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Card(
          children: [
            _Row('You send', '\$${groupDigits(quote.amountUsd, decimals: 2)}'),
            _Row(
              'Rate after fees',
              '\$1 = $_symbol${groupDigits(quote.rate, decimals: 2)}',
            ),
            _Row('Fees', '$_symbol${groupDigits(quote.fees)}'),
            _Row(
              'Route',
              'Best of ${quote.bestOf}',
              extra: beats == null || beats <= 0
                  ? null
                  : '+$_symbol${groupDigits(beats)}',
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Card(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D5AFE),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paid out by ${providerName(quote.provider)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footer(Quote quote) {
    final left = _left;
    final share = quote.expiresIn == 0
        ? 0.0
        : left.inMilliseconds / (quote.expiresIn * 1000);
    final minutes = left.inMinutes;
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _expired ? 'Rate expired' : 'Rate held for',
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
              const Spacer(),
              Text(
                '$minutes:$seconds',
                key: const ValueKey('quote-countdown'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: share.clamp(0, 1),
              minHeight: 3,
              backgroundColor: const Color(0xFF2A2A2A),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              key: ValueKey(_expired ? 'new-quote' : 'confirm-payout'),
              onPressed: _isConfirming ? null : (_expired ? _load : _confirm),
              icon: _expired
                  ? const Icon(Icons.refresh_rounded, size: 20)
                  : const Icon(Icons.fingerprint_rounded, size: 20),
              label: Text(
                _expired ? 'Get a new quote' : 'Confirm with biometrics',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the quote screen shows signed out, built from the canonical
/// example quote (spec/fixtures/quote.usdc-ngn-50.json).
Quote demoQuote(String currency, double amount, bool receiveLocal) {
  const rate = 1376.32;
  final usd = receiveLocal ? (amount + 344) / rate : amount;
  final receive = receiveLocal ? amount : (usd * rate - 344).roundToDouble();
  return Quote(
    quoteId: 'q_demo',
    currency: currency,
    amountUsd: double.parse(usd.toStringAsFixed(2)),
    rate: rate,
    rateBeforeFees: 1383.2,
    feesMinor: 34400,
    receive: receive < 0 ? 0 : receive,
    provider: 'paycrest',
    bestOf: 4,
    expiresIn: 90,
    routes: const [
      QuoteRoute(
        provider: 'paycrest',
        status: 'live',
        routed: true,
        rate: 1376.32,
      ),
      QuoteRoute(
        provider: 'busha',
        status: 'live',
        routed: false,
        rate: 1370.08,
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.extra, this.last = false});

  final String label;
  final String value;
  final String? extra;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (extra != null) ...[
            const SizedBox(width: 6),
            Text(
              extra!,
              style: const TextStyle(
                color: Color(0xFF2EB467),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
