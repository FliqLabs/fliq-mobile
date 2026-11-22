import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/amount_input.dart';
import '../utils/formatters.dart';
import '../widgets/amount_keypad.dart';
import '../services/account_store.dart';

class SendAmountScreen extends StatefulWidget {
  const SendAmountScreen({super.key});

  @override
  State<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends State<SendAmountScreen> {
  String _amount = '0';

  double get _parsedAmount => double.tryParse(_amount) ?? 0;

  bool get _isOverVault => _parsedAmount > AccountStore.instance.balanceUsd;

  bool get _canContinue => _parsedAmount > 0 && !_isOverVault;

  void _onKeyTap(String key) {
    setState(() => _amount = applyAmountKey(_amount, key));
  }

  void _continue() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Recipient details will be available soon.'),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _SendHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              r'$',
                              style: TextStyle(
                                color: Color(0xFFB8B8B8),
                                fontSize: 30,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _amount,
                              key: const ValueKey('send-amount'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 62,
                                fontWeight: FontWeight.w300,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_parsedAmount.toStringAsFixed(2)}  USDC',
                          key: const ValueKey('send-amount-usdc'),
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  key: const ValueKey('vault-pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090909),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isOverVault
                          ? const Color(0xFFF5A623)
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: _isOverVault
                              ? const Color(0xFFF5A623)
                              : Colors.white,
                          size: 7,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOverVault ? 'More than your vault' : 'Vault',
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(color: Color(0xFF777777)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatUsd(AccountStore.instance.balanceUsd),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: AmountKeypad(
                    gridKey: const ValueKey('send-keypad'),
                    keyPrefix: 'send-key',
                    onKeyTap: _onKeyTap,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    key: const ValueKey('send-next'),
                    onPressed: _canContinue ? _continue : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF686868),
                      side: BorderSide(
                        color: _canContinue
                            ? const Color(0xFF777777)
                            : const Color(0xFF393939),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Next'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendHeader extends StatelessWidget {
  const _SendHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                side: const BorderSide(color: Color(0xFF303030)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                semanticLabel: 'Back',
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Send',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
