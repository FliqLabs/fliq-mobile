import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../utils/amount_input.dart';
import '../../utils/formatters.dart';
import '../../widgets/amount_keypad.dart';
import '../../widgets/circle_icon_button.dart';

/// "Add money by bank transfer": choose a naira amount, confirm who you are,
/// then (once the API is connected) get a bank account to pay into.
class BankTransferDepositScreen extends StatefulWidget {
  const BankTransferDepositScreen({super.key});

  @override
  State<BankTransferDepositScreen> createState() =>
      _BankTransferDepositScreenState();
}

enum _Step { amount, confirm }

class _BankTransferDepositScreenState extends State<BankTransferDepositScreen> {
  static const _presets = [5000, 10000, 20000, 50000];

  final _contactController = TextEditingController();
  String _amount = '5000';
  _Step _step = _Step.amount;

  int get _naira => int.tryParse(_amount) ?? 0;
  double get _usd => _naira / SampleData.depositNgnPerUsd;

  /// An email, or a Nigerian number like +2348012345678 / 08012345678.
  bool get _contactIsValid {
    final value = _contactController.text.trim().replaceAll(' ', '');
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phone = RegExp(r'^(\+234|0)[789]\d{9}$');
    return email.hasMatch(value) || phone.hasMatch(value);
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (key == '.') return; // Whole naira only.
    setState(() => _amount = applyAmountKey(_amount, key, maxLength: 9));
  }

  void _back() {
    if (_step == _Step.confirm) {
      setState(() => _step = _Step.amount);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _sendCode() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Verification codes will be sent once fliq is connected to its '
            'servers.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: _step == _Step.amount,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _step = _Step.amount);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    key: const ValueKey('bank-deposit-back'),
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    size: 44,
                    borderColor: const Color(0xFF333333),
                    onPressed: _back,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Add money · Nigeria',
                    style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Add money by bank transfer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _StepBar(current: 0),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _step == _Step.amount
                        ? _buildAmountStep()
                        : _buildConfirmStep(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountStep() {
    return Column(
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount in naira',
                style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '₦',
                    style: TextStyle(color: Color(0xFF6E6E73), fontSize: 22),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    groupDigits(_naira),
                    key: const ValueKey('deposit-amount'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _naira == 0
                    ? 'Type an amount'
                    : 'You get about ${formatUsd(_usd)} in your vault',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF9A9A9E),
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'Rate  '),
                    TextSpan(
                      text:
                          '${formatNaira(SampleData.depositNgnPerUsd, decimals: 2)} = \$1.00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Rates move through the day. Yours is fixed when you get your '
                'bank details.',
                style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final preset in _presets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _PresetChip(
                          key: ValueKey('deposit-preset-$preset'),
                          label: formatNaira(preset),
                          selected: _naira == preset,
                          onTap: () =>
                              setState(() => _amount = preset.toString()),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const ValueKey('get-bank-details'),
                  onPressed: _naira > 0
                      ? () => setState(() => _step = _Step.confirm)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF1E1E20),
                    disabledForegroundColor: const Color(0xFF6E6E73),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Get bank details'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Next you get a bank account for this deposit. Pay into it '
                'from any Nigerian bank app.',
                style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: AmountKeypad(
            gridKey: const ValueKey('deposit-keypad'),
            keyPrefix: 'deposit-key',
            onKeyTap: _onKey,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confirm it's you",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A licensed partner turns your Naira into dollars and checks '
              "who's paying once. After that this phone goes straight to "
              'your bank details.',
              style: TextStyle(
                color: Color(0xFF9A9A9E),
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('deposit-contact'),
              controller: _contactController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_contactIsValid) _sendCode();
              },
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Email or +234 phone',
                hintStyle: const TextStyle(color: Color(0xFF6E6E73)),
                filled: true,
                fillColor: const Color(0xFF1A1A1C),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                key: const ValueKey('send-code'),
                onPressed: _contactIsValid ? _sendCode : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF6E6E73),
                  side: const BorderSide(color: Color(0xFF333336)),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});

  final int current;

  static const _labels = ['Amount', 'Pay', 'Receive'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? Colors.white
                        : const Color(0xFF2A2A2C),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _labels[i],
                  style: TextStyle(
                    color: i == current
                        ? Colors.white
                        : const Color(0xFF6E6E73),
                    fontSize: 14,
                    fontWeight: i == current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E1E20)),
      ),
      child: child,
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : const Color(0xFF1E1E20),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
