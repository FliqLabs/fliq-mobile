import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../models/payment.dart';
import '../../models/rate.dart';
import '../../services/account_store.dart';
import '../../services/fliq_api.dart';
import '../../utils/amount_input.dart';
import '../../utils/formatters.dart';
import '../../widgets/amount_keypad.dart';
import '../../widgets/circle_icon_button.dart';
import 'quote_screen.dart';

/// "They receive ₦…": how much to pay a bank or mobile-money account.
///
/// Types the local amount by default; a tap switches to dollars.
class PayoutAmountScreen extends StatefulWidget {
  const PayoutAmountScreen({
    required this.account,
    required this.currency,
    this.mobileMoney = false,
    super.key,
  });

  final VerifiedAccount account;

  /// `NGN` or `KES`.
  final String currency;
  final bool mobileMoney;

  @override
  State<PayoutAmountScreen> createState() => _PayoutAmountScreenState();
}

class _PayoutAmountScreenState extends State<PayoutAmountScreen> {
  String _amount = '0';
  bool _typesDollars = false;
  double? _rate;

  String get _symbol => currencySymbol(widget.currency);
  double get _typed => double.tryParse(_amount) ?? 0;
  double get _vault => AccountStore.instance.balanceUsd;

  /// Dollars that would leave the vault, using today's rate as a guide.
  double? get _dollars =>
      _typesDollars ? _typed : (_rate == null ? null : _typed / _rate!);

  /// Local money the recipient gets, using today's rate as a guide.
  double? get _local =>
      _typesDollars ? (_rate == null ? null : _typed * _rate!) : _typed;

  bool get _overVault => (_dollars ?? 0) > _vault;
  bool get _canQuote => _typed > 0 && !_overVault;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  Future<void> _loadRate() async {
    try {
      final Rate rate = await FliqApi.instance.getRate(
        currency: widget.currency.toLowerCase(),
      );
      if (mounted) setState(() => _rate = rate.rate);
    } catch (_) {
      if (mounted && widget.currency == 'NGN') {
        setState(() => _rate = SampleData.usdToNgn);
      }
    }
  }

  void _onKey(String key) {
    setState(
      () => _amount = applyAmountKey(
        _amount,
        key,
        maxDecimals: _typesDollars ? 2 : 0,
        maxLength: _typesDollars ? 8 : 11,
      ),
    );
  }

  void _switchUnit() {
    setState(() {
      final converted = _typesDollars ? _local : _dollars;
      _typesDollars = !_typesDollars;
      _amount = converted == null || converted == 0
          ? '0'
          : converted.toStringAsFixed(_typesDollars ? 2 : 0);
      if (_amount.endsWith('.00')) {
        _amount = _amount.substring(0, _amount.length - 3);
      }
    });
  }

  void _getQuote() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QuoteScreen(
          account: widget.account,
          currency: widget.currency,
          amount: _typed,
          receiveLocal: !_typesDollars,
          mobileMoney: widget.mobileMoney,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final big = _typesDollars
        ? '\$${groupDigits(_typed, decimals: _amount.contains('.') ? 2 : 0)}'
        : '$_symbol${groupDigits(_typed)}';
    final other = _typesDollars
        ? (_local == null ? '' : 'They receive $_symbol${groupDigits(_local!)}')
        : (_dollars == null
              ? ''
              : 'You send \$${groupDigits(_dollars!, decimals: 2)}');

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
                      key: const ValueKey('payout-amount-back'),
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      size: 44,
                      borderColor: const Color(0xFF333333),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _RecipientPill(account: widget.account),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _typesDollars ? 'You send' : 'They receive',
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          big,
                          key: const ValueKey('payout-amount'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 58,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (other.isNotEmpty)
                        TextButton.icon(
                          key: const ValueKey('payout-switch-unit'),
                          onPressed: _rate == null ? null : _switchUnit,
                          icon: const Icon(Icons.swap_vert_rounded, size: 16),
                          label: Text(other),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF151515),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_rate != null)
                        Text(
                          '\$1 = $_symbol${groupDigits(_rate!, decimals: 2)}',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _overVault
                            ? 'More than the \$${groupDigits(_vault, decimals: 2)} in your vault'
                            : 'In your vault \$${groupDigits(_vault, decimals: 2)}',
                        key: const ValueKey('payout-vault-note'),
                        style: TextStyle(
                          color: _overVault
                              ? const Color(0xFFF5A623)
                              : const Color(0xFF8E8E93),
                          fontSize: 13,
                          fontWeight: _overVault
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: AmountKeypad(
                    gridKey: const ValueKey('payout-keypad'),
                    keyPrefix: 'payout-key',
                    onKeyTap: _onKey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      key: const ValueKey('get-quote'),
                      onPressed: _canQuote ? _getQuote : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: const Color(0xFF686868),
                        side: BorderSide(
                          color: _canQuote
                              ? const Color(0xFF777777)
                              : const Color(0xFF333333),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Get quote'),
                    ),
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

class _RecipientPill extends StatelessWidget {
  const _RecipientPill({required this.account});

  final VerifiedAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: Color(0xFFAAAAAA),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              account.accountName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `₦` for NGN, `KSh ` for KES.
String currencySymbol(String currency) => switch (currency.toUpperCase()) {
  'NGN' => '₦',
  'KES' => 'KSh ',
  _ => '${currency.toUpperCase()} ',
};
