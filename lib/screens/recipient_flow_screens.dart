import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/fliq_symbol.dart';
import 'pay/payout_amount_screen.dart';
import 'send_amount_screen.dart';
import '../models/payment.dart';
import '../services/account_store.dart';
import '../services/api_exception.dart';
import '../services/fliq_api.dart';
import '../near/device_key.dart';
import '../services/payouts.dart';
import '../services/vault_signer.dart';
import 'pay/payout_result_screen.dart';
import '../utils/amount_input.dart';
import '../widgets/amount_keypad.dart';
import '../data/sample_data.dart';

enum RecipientDeliveryType { bankTransfer, mobileMoney, fliqName }

class RecipientDeliveryMethodScreen extends StatelessWidget {
  const RecipientDeliveryMethodScreen({
    required this.currencyCode,
    required this.country,
    required this.countryFlag,
    super.key,
  });

  final String currencyCode;
  final String country;
  final String countryFlag;

  @override
  Widget build(BuildContext context) {
    final methods = <RecipientDeliveryType>[
      RecipientDeliveryType.bankTransfer,
      if (currencyCode == 'KES') RecipientDeliveryType.mobileMoney,
      RecipientDeliveryType.fliqName,
    ];

    return _RecipientFlowShell(
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        children: [
          Text(
            'How do you want to\nsend $currencyCode?',
            key: const ValueKey('delivery-method-title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          for (final method in methods)
            _DeliveryMethodTile(
              method: method,
              country: country,
              onTap: () {
                if (method == RecipientDeliveryType.fliqName) {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const FliqRecipientScreen(),
                    ),
                  );
                  return;
                }

                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RecipientDetailsScreen(
                      currencyCode: currencyCode,
                      country: country,
                      countryFlag: countryFlag,
                      deliveryType: method,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class RecipientDetailsScreen extends StatefulWidget {
  const RecipientDetailsScreen({
    required this.currencyCode,
    required this.country,
    required this.countryFlag,
    required this.deliveryType,
    super.key,
  });

  final String currencyCode;
  final String country;
  final String countryFlag;
  final RecipientDeliveryType deliveryType;

  @override
  State<RecipientDetailsScreen> createState() => _RecipientDetailsScreenState();
}

class _RecipientDetailsScreenState extends State<RecipientDetailsScreen> {
  static const _bankOptions = {
    'NGN': ['GTBank', 'Access Bank', 'First Bank', 'Zenith Bank'],
    'KES': ['Equity Bank', 'KCB Bank', 'Co-operative Bank', 'Absa Bank Kenya'],
  };
  static const _mobileMoneyProviders = ['M-Pesa', 'Airtel Money'];

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fliqNameController = TextEditingController();
  String? _selectedProvider;
  String? _selectedBank;
  bool _saveRecipient = true;

  /// Banks from the server once signed in: name → code.
  Map<String, String>? _serverBanks;
  bool _isChecking = false;
  String? _checkError;

  String get _countryCode => widget.currencyCode == 'KES' ? 'ke' : 'ng';

  @override
  void initState() {
    super.initState();
    if (AccountStore.instance.isSignedIn && _isBankTransfer) _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await FliqApi.instance.institutions(_countryCode);
      if (!mounted || banks.isEmpty) return;
      setState(
        () => _serverBanks = {for (final bank in banks) bank.name: bank.code},
      );
    } on ApiException {
      // Keep the short built-in list.
    }
  }

  bool get _isBankTransfer =>
      widget.deliveryType == RecipientDeliveryType.bankTransfer;
  bool get _isMobileMoney =>
      widget.deliveryType == RecipientDeliveryType.mobileMoney;

  String get _bankName =>
      _selectedBank ??
      (widget.currencyCode == 'KES' ? 'Equity Bank' : 'GTBank');

  bool get _canContinue {
    if (_isBankTransfer) return _accountController.text.length == 10;
    if (_isMobileMoney) {
      return _selectedProvider != null &&
          _phoneController.text.length >= 9 &&
          _phoneController.text.length <= 14;
    }
    return _fliqNameController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _phoneController.dispose();
    _fliqNameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_canContinue || _isChecking) return;
    FocusScope.of(context).unfocus();
    if (_isMobileMoney) {
      final provider = _selectedProvider!;
      _openAmount(
        VerifiedAccount(
          bankCode: provider,
          number: _phoneController.text,
          accountName: _phoneController.text,
          institution: provider,
          nameVerified: false,
        ),
        mobileMoney: true,
      );
      return;
    }
    if (!_isBankTransfer) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SendAmountScreen()),
      );
      return;
    }
    if (!AccountStore.instance.isSignedIn) {
      // Signed out: the canonical example account, so the flow can be seen.
      _openAmount(
        VerifiedAccount(
          bankCode: '058',
          number: _accountController.text,
          accountName: 'DARA OKONKWO',
          institution: _bankName,
        ),
      );
      return;
    }
    final code = _serverBanks?[_bankName];
    if (code == null) {
      setState(
        () =>
            _checkError = "Couldn't load the bank list. Check your connection.",
      );
      return;
    }
    setState(() {
      _isChecking = true;
      _checkError = null;
    });
    try {
      final account = await FliqApi.instance.verifyAccount(
        bankCode: code,
        number: _accountController.text,
        country: _countryCode,
      );
      if (_saveRecipient) {
        unawaited(
          FliqApi.instance
              .saveRecipient(
                bankCode: code,
                number: _accountController.text,
                country: _countryCode,
              )
              .then((_) {}, onError: (_) {}),
        );
      }
      if (mounted) _openAmount(account);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _checkError = error.status == 404
            ? "The bank couldn't find that account. Check the number."
            : error.message,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _openAmount(VerifiedAccount account, {bool mobileMoney = false}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PayoutAmountScreen(
          account: account,
          currency: widget.currencyCode,
          mobileMoney: mobileMoney,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankOptions =
        _serverBanks?.keys.toList() ??
        _bankOptions[widget.currencyCode] ??
        const ['Bank'];

    return _RecipientFlowShell(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('recipient-details-form'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                const Text(
                  'Who are you sending to?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We check the account with the bank before you pay.',
                  style: TextStyle(
                    color: Color(0xFFB4B4B4),
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 20),
                const _FormLabel('Recipient country'),
                const SizedBox(height: 6),
                _FormValue(
                  key: const ValueKey('recipient-country'),
                  leading: Text(
                    widget.countryFlag,
                    style: const TextStyle(fontSize: 19),
                  ),
                  label: widget.country,
                ),
                const SizedBox(height: 16),
                if (_isBankTransfer) ...[
                  const _FormLabel('Bank'),
                  const SizedBox(height: 6),
                  _DropdownField<String>(
                    key: const ValueKey('recipient-bank'),
                    value: _bankName,
                    options: bankOptions,
                    leading: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFFFF9C36),
                      size: 19,
                    ),
                    onChanged: (value) => setState(() => _selectedBank = value),
                  ),
                  const SizedBox(height: 16),
                  const _FormLabel('Account number'),
                  const SizedBox(height: 6),
                  _TextEntryField(
                    key: const ValueKey('recipient-account-number'),
                    controller: _accountController,
                    hintText: 'Enter account number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    onChanged: (_) => setState(() {}),
                  ),
                ] else if (_isMobileMoney) ...[
                  const _FormLabel('Mobile money provider'),
                  const SizedBox(height: 6),
                  _DropdownField<String>(
                    key: const ValueKey('mobile-money-provider'),
                    value: _selectedProvider,
                    hint: 'Choose',
                    options: _mobileMoneyProviders,
                    leading: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFF9C36),
                      size: 19,
                    ),
                    onChanged: (value) =>
                        setState(() => _selectedProvider = value),
                  ),
                  const SizedBox(height: 16),
                  const _FormLabel('Phone number'),
                  const SizedBox(height: 6),
                  _TextEntryField(
                    key: const ValueKey('recipient-phone-number'),
                    controller: _phoneController,
                    hintText: '07XX XXX XXX',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 14,
                    onChanged: (_) => setState(() {}),
                  ),
                ] else ...[
                  const _FormLabel('Fliq name'),
                  const SizedBox(height: 6),
                  _TextEntryField(
                    key: const ValueKey('recipient-fliq-name'),
                    controller: _fliqNameController,
                    hintText: 'Enter fliq name',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                const _RecipientWarning(),
              ],
            ),
          ),
          if (_checkError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                _checkError!,
                key: const ValueKey('recipient-error'),
                style: const TextStyle(color: Color(0xFFE65D66), fontSize: 14),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Save this recipient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      key: const ValueKey('save-recipient-toggle'),
                      value: _saveRecipient,
                      activeTrackColor: const Color(0xFF25C568),
                      activeThumbColor: Colors.white,
                      onChanged: (value) =>
                          setState(() => _saveRecipient = value),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    key: const ValueKey('recipient-continue'),
                    onPressed: _canContinue && !_isChecking ? _continue : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFF343434)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FliqRecipientScreen extends StatefulWidget {
  const FliqRecipientScreen({super.key});

  @override
  State<FliqRecipientScreen> createState() => _FliqRecipientScreenState();
}

class _FliqRecipientScreenState extends State<FliqRecipientScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _amount = '0';

  double get _parsedAmount => double.tryParse(_amount) ?? 0;

  String get _typedName =>
      _nameController.text.trim().replaceFirst('@', '').toLowerCase();

  Timer? _lookupDelay;
  String? _lookedUp;
  Person? _person;
  bool _isLooking = false;
  bool _isPaying = false;

  /// Shown once a name is long enough to look up and nobody has it.
  bool get _nameNotFound =>
      AccountStore.instance.isSignedIn &&
      _typedName.length >= 3 &&
      !_isLooking &&
      _lookedUp == _typedName &&
      _person == null;

  /// Signed out there is nobody to ask, so say so instead of "no one".
  bool get _needsSignIn =>
      !AccountStore.instance.isSignedIn &&
      _typedName.length >= 3 &&
      !_isLooking &&
      _lookedUp == _typedName &&
      _person == null;

  bool get _canPay =>
      _person != null &&
      _parsedAmount > 0 &&
      _parsedAmount <= AccountStore.instance.balanceUsd &&
      !_isPaying;

  void _onNameChanged(String _) {
    _lookupDelay?.cancel();
    setState(() => _person = null);
    final name = _typedName;
    if (name.length < 3) return;
    // Wait for a short pause in typing before asking the server.
    _lookupDelay = Timer(
      const Duration(milliseconds: 350),
      () => _lookup(name),
    );
  }

  Future<void> _lookup(String name) async {
    setState(() => _isLooking = true);
    Person? person;
    if (AccountStore.instance.isSignedIn) {
      try {
        person = await FliqApi.instance.person(name);
      } on ApiException {
        person = null;
      }
    } else if (SampleData.knownFliqUsers.contains(name)) {
      person = Person(nearAccount: '$name.fliq.near', displayName: name);
    }
    if (!mounted || name != _typedName) return;
    setState(() {
      _isLooking = false;
      _lookedUp = name;
      _person = person;
    });
  }

  Future<void> _pay() async {
    final person = _person;
    if (person == null || !_canPay) return;
    setState(() => _isPaying = true);
    String? problem;
    try {
      // Biometrics are asked when the phone signs.
      await Transfers.instance.sendToPerson(person, _parsedAmount);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) =>
              TransferSentScreen(dollars: _parsedAmount, person: person),
        ),
      );
      return;
    } on SigningCancelled {
      // Nothing moved.
    } on PayoutNotReady catch (error) {
      problem = error.message;
    } on TransferProblem catch (error) {
      problem = error.message;
    } on ApiException catch (error) {
      problem = error.message;
    } catch (_) {
      problem = 'Biometric unlock is unavailable. Please try again.';
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(problem), behavior: SnackBarBehavior.floating),
        );
    }
  }

  void _onAmountKeyTap(String key) {
    setState(() => _amount = applyAmountKey(_amount, key));
  }

  @override
  void dispose() {
    _lookupDelay?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFF302B74), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      _BackButton(onPressed: () => Navigator.of(context).pop()),
                      const Expanded(
                        child: Text(
                          'Pay a fliq user',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('fliq-recipient-name'),
                  controller: _nameController,
                  onChanged: _onNameChanged,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '@  name',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: const Color(0x66333344),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_person case final person?)
                  Padding(
                    key: const ValueKey('fliq-person-found'),
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2EB467),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${person.displayName ?? person.handle} · ${person.nearAccount}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_needsSignIn)
                  const Padding(
                    key: ValueKey('fliq-name-needs-sign-in'),
                    padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFFAAAAAA),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sign in to look up fliq names',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_nameNotFound)
                  const Padding(
                    key: ValueKey('fliq-name-not-found'),
                    padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: Color(0xFFF5A623),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'No one on fliq has that name',
                            style: TextStyle(
                              color: Color(0xFFF5A623),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'They receive',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: r'$',
                              style: TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 25,
                              ),
                            ),
                            TextSpan(
                              text: _amount,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                height: 1,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                        key: const ValueKey('fliq-recipient-amount'),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF353535)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'ϟ  Vault to vault · instant · no fee',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'In your vault \$0',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: AmountKeypad(
                          gridKey: const ValueKey('fliq-amount-keypad'),
                          keyPrefix: 'fliq-amount-key',
                          fontSize: 24,
                          iconSize: 21,
                          borderRadius: 30,
                          fallbackAspectRatio: 1.5,
                          onKeyTap: _onAmountKeyTap,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    key: const ValueKey('fliq-recipient-pay'),
                    onPressed: _canPay ? _pay : null,
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: Text(
                      'Pay \$${_parsedAmount.toStringAsFixed(0)} with biometrics',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF666666),
                      side: BorderSide(
                        color: _canPay
                            ? const Color(0xFF777777)
                            : const Color(0xFF393939),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

class _RecipientFlowShell extends StatelessWidget {
  const _RecipientFlowShell({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SizedBox(
                height: 42,
                child: Row(
                  children: [
                    _BackButton(onPressed: onBack),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF626262),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF343434)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          semanticLabel: 'Back',
        ),
      ),
    );
  }
}

class _DeliveryMethodTile extends StatelessWidget {
  const _DeliveryMethodTile({
    required this.method,
    required this.country,
    required this.onTap,
  });

  final RecipientDeliveryType method;
  final String country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, description) = switch (method) {
      RecipientDeliveryType.bankTransfer => (
        Icons.account_balance_outlined,
        'Bank transfer',
        'To any bank account in $country,\nnew or saved',
      ),
      RecipientDeliveryType.mobileMoney => (
        Icons.smartphone_rounded,
        'Mobile money',
        'To M-Pesa or Airtel Money, lands\nin seconds',
      ),
      RecipientDeliveryType.fliqName => (
        Icons.account_balance_wallet_outlined,
        'fliq name',
        'Instantly to another fliq user,\nwith no fee',
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('delivery-method-${method.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 86,
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: method == RecipientDeliveryType.fliqName
                      ? const Center(
                          child: FliqSymbol(
                            key: ValueKey('send-fliq-name-symbol'),
                            size: 28,
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF303A4D),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: const Color(0xFF9AB7EF),
                            size: 23,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 13,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF777777),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FormValue extends StatelessWidget {
  const _FormValue({required this.leading, required this.label, super.key});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.options,
    required this.leading,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final T? value;
  final List<T> options;
  final Widget leading;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF383838)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                key: key,
                value: value,
                hint: hint == null
                    ? null
                    : Text(
                        hint!,
                        style: const TextStyle(color: Color(0xFF888888)),
                      ),
                dropdownColor: const Color(0xFF292929),
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF888888),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: options
                    .map(
                      (option) => DropdownMenuItem<T>(
                        value: option,
                        child: Text(option.toString()),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextEntryField extends StatelessWidget {
  const _TextEntryField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF777777)),
          counterText: '',
          suffix: maxLength == null
              ? null
              : Text(
                  '${controller.text.length}/$maxLength',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
                  ),
                ),
          filled: true,
          fillColor: const Color(0xFF222222),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFF393939)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFF747474)),
          ),
        ),
      ),
    );
  }
}

class _RecipientWarning extends StatelessWidget {
  const _RecipientWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3016),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Color(0xFFE0A52C), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Check the details. A payout to the wrong account can't be pulled back.",
              style: TextStyle(
                color: Color(0xFFE0A52C),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
