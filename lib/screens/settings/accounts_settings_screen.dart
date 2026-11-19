import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_widgets.dart';
import '../../data/banks.dart';

class AccountsSettingsScreen extends StatefulWidget {
  const AccountsSettingsScreen({super.key});

  @override
  State<AccountsSettingsScreen> createState() => _AccountsSettingsScreenState();
}

class _AccountsSettingsScreenState extends State<AccountsSettingsScreen> {
  final List<_SavedAccount> _accounts = [];

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Your accounts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'YOURS',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_accounts.isEmpty)
            const InfoCard(
              text: 'Add your own account so cashing out is one tap.',
            )
          else
            for (final account in _accounts)
              SettingsTile(
                title: '${account.bank}\n${account.accountNumber}',
                icon: Icons.account_balance_outlined,
                showDivider: false,
              ),
          const SizedBox(height: 38),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SAVED',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const InfoCard(
            text: 'Accounts you pay with "Save this account" on show up here.',
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('add-account'),
                onPressed: () async {
                  final account = await Navigator.of(context)
                      .push<_SavedAccount>(
                        MaterialPageRoute<_SavedAccount>(
                          builder: (_) => const NewAccountScreen(),
                        ),
                      );
                  if (account != null && mounted) {
                    setState(() => _accounts.add(account));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add account'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(170, 56),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAccount {
  const _SavedAccount({
    required this.bank,
    required this.accountNumber,
    required this.country,
    required this.save,
  });

  final String bank;
  final String accountNumber;
  final String country;
  final bool save;
}

class NewAccountScreen extends StatefulWidget {
  const NewAccountScreen({super.key});

  @override
  State<NewAccountScreen> createState() => _NewAccountScreenState();
}

class _NewAccountScreenState extends State<NewAccountScreen> {
  static const _banksByCountry = Banks.byCountry;

  final _accountController = TextEditingController();
  String _country = 'Nigeria';
  String _bank = 'GTBank';

  int get _maxDigits => Banks.accountNumberLength[_country]!;
  bool _saveAccount = true;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _accountController.text.length;
    // Nigerian NUBAN numbers are exactly 10 digits; Kenyan ones vary.
    final canContinue = _country == 'Nigeria'
        ? length == _maxDigits
        : length >= 10 && length <= _maxDigits;

    return SettingsPage(
      title: 'New account',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountryChip(
                          key: const ValueKey('country-nigeria'),
                          label: 'Nigeria',
                          flag: '🇳🇬',
                          selected: _country == 'Nigeria',
                          onTap: () => _selectCountry('Nigeria'),
                        ),
                        _CountryChip(
                          key: const ValueKey('country-kenya'),
                          label: 'Kenya',
                          flag: '🇰🇪',
                          selected: _country == 'Kenya',
                          onTap: () => _selectCountry('Kenya'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Material(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: const ValueKey('account-bank-picker'),
                    onTap: _showBankPicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          _BankBadge(bank: _bank),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _bank,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFAAAAAA),
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    key: const ValueKey('new-account-number'),
                    controller: _accountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: _maxDigits,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'Account number',
                      hintStyle: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                      suffix: Text(
                        '${_accountController.text.length}/$_maxDigits',
                        key: const ValueKey('account-number-count'),
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 38),
                Material(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Save this account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          key: const ValueKey('save-account-toggle'),
                          value: _saveAccount,
                          activeTrackColor: const Color(0xFF2EB467),
                          onChanged: (value) {
                            setState(() => _saveAccount = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                key: const ValueKey('continue-new-account'),
                onPressed: canContinue ? _continue : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF595959),
                  side: BorderSide(
                    color: canContinue
                        ? const Color(0xFF777777)
                        : const Color(0xFF333333),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCountry(String country) {
    if (_country == country) return;
    setState(() {
      _country = country;
      _bank = _banksByCountry[country]!.first;
      if (_accountController.text.length > _maxDigits) {
        _accountController.text = _accountController.text.substring(
          0,
          _maxDigits,
        );
      }
    });
  }

  Future<void> _showBankPicker() async {
    var searchQuery = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final banks = _banksByCountry[_country]!
              .where(
                (bank) => bank.toLowerCase().contains(
                  searchQuery.trim().toLowerCase(),
                ),
              )
              .toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 20, 14),
                    child: Text(
                      'Choose a bank',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      key: const ValueKey('bank-search'),
                      autofocus: true,
                      onChanged: (value) =>
                          setSheetState(() => searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search banks',
                        hintStyle: const TextStyle(color: Color(0xFF888888)),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFAAAAAA),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF232323),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: banks.isEmpty
                        ? const Center(
                            child: Text(
                              'No banks found',
                              style: TextStyle(color: Color(0xFFAAAAAA)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            itemCount: banks.length,
                            itemBuilder: (context, index) {
                              final bank = banks[index];
                              return SettingsTile(
                                key: ValueKey('bank-option-$bank'),
                                title: bank,
                                icon: Icons.account_balance_outlined,
                                trailing: bank == _bank
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xFF2EB467),
                                      )
                                    : null,
                                showDivider: index < banks.length - 1,
                                onTap: () => Navigator.pop(context, bank),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) setState(() => _bank = selected);
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      _SavedAccount(
        bank: _bank,
        accountNumber: _accountController.text,
        country: _country,
        save: _saveAccount,
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : const Color(0xFFAAAAAA),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankBadge extends StatelessWidget {
  const _BankBadge({required this.bank});

  final String bank;

  @override
  Widget build(BuildContext context) {
    final isGtBank = bank == 'GTBank';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isGtBank ? const Color(0xFFE95D00) : const Color(0xFF30473E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isGtBank ? 'GT' : bank.split(' ').map((word) => word[0]).take(2).join(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
