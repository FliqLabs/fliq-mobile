import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/amount_input.dart';
import '../widgets/amount_keypad.dart';
import '../widgets/circle_icon_button.dart';
import 'pay_link_screen.dart';

class RequestAmountScreen extends StatefulWidget {
  const RequestAmountScreen({super.key});

  @override
  State<RequestAmountScreen> createState() => _RequestAmountScreenState();
}

class _RequestAmountScreenState extends State<RequestAmountScreen> {
  final TextEditingController _reasonController = TextEditingController();
  String _amount = '0';
  bool _cashOutToBank = false;

  bool get _hasAmount =>
      double.tryParse(_amount) != null && double.parse(_amount) > 0;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    setState(() => _amount = applyAmountKey(_amount, key));
  }

  Future<void> _createPayLink() async {
    FocusScope.of(context).unfocus();
    final closed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayLinkScreen(
          amountUsd: double.parse(_amount),
          reason: _reasonController.text,
          cashOutOnArrival: _cashOutToBank,
        ),
      ),
    );
    // ✕ on the pay link closes the whole request flow.
    if (closed == true && mounted) Navigator.of(context).pop();
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
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.27, 0.5, 1],
                colors: [
                  Color(0xFF242044),
                  Color(0xFF171522),
                  Color(0xFF090909),
                  Colors.black,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _RequestHeader(
                    onBack: () => Navigator.of(context).pop(),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'You ask for',
                    style: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        r'$',
                        style: TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _amount,
                        key: const ValueKey('request-amount'),
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
                  const SizedBox(height: 24),
                  FractionallySizedBox(
                    widthFactor: 0.8,
                    child: TextField(
                      key: const ValueKey('request-reason'),
                      controller: _reasonController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: InputDecoration(
                        hintText: "What's it for?",
                        hintStyle: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF191919),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(
                            color: Color(0xFF686868),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AmountKeypad(
                      gridKey: const ValueKey('amount-keypad'),
                      keyPrefix: 'amount-key',
                      fontSize: 31,
                      iconSize: 27,
                      onKeyTap: _onKeyTap,
                    ),
                  ),
                  _CashOutToggle(
                    value: _cashOutToBank,
                    onChanged: (value) =>
                        setState(() => _cashOutToBank = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      key: const ValueKey('make-pay-link'),
                      onPressed: _hasAmount ? _createPayLink : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: const Color(0xFF686868),
                        side: BorderSide(
                          color: _hasAmount
                              ? const Color(0xFF777777)
                              : const Color(0xFF393939),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Make a pay link'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.onBack, required this.onClose});

  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Row(
        children: [
          CircleIconButton(
            size: 46,
            borderColor: const Color(0xFF43405A),
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            onPressed: onBack,
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
            size: 46,
            borderColor: const Color(0xFF43405A),
            icon: Icons.close_rounded,
            tooltip: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _CashOutToggle extends StatelessWidget {
  const _CashOutToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Cash out to my bank when it lands',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: const ValueKey('cash-out-toggle'),
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF34C759),
            inactiveTrackColor: const Color(0xFF505050),
            inactiveThumbColor: Colors.white,
            activeThumbColor: Colors.white,
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF34C759)
                  : const Color(0xFF737373),
            ),
          ),
        ],
      ),
    );
  }
}
