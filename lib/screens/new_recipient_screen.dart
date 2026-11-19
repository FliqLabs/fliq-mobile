import 'package:flutter/material.dart';

import 'recipient_flow_screens.dart';
import 'send_amount_screen.dart';

class NewRecipientScreen extends StatefulWidget {
  const NewRecipientScreen({super.key});

  @override
  State<NewRecipientScreen> createState() => _NewRecipientScreenState();
}

class _NewRecipientScreenState extends State<NewRecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _availableCurrencies = [
    _RecipientCurrency(
      name: 'Naira',
      detail: 'NGN (N)',
      flag: '🇳🇬',
      country: 'Nigeria',
    ),
    _RecipientCurrency(
      name: 'Kenyan Shilling',
      detail: 'KES (KSh)',
      flag: '🇰🇪',
      country: 'Kenya',
    ),
  ];

  static const _stablecoin = _RecipientCurrency(
    name: 'USD Coin, to a NEAR wallet',
    detail: 'USDC (\$)',
    flag: '◎',
    country: 'NEAR',
    isStablecoin: true,
  );

  static const _otherCurrencies = [
    _RecipientCurrency(
      name: 'Brazilian Real',
      detail: 'BRL (R\$)',
      flag: '🇧🇷',
      country: 'Brazil',
    ),
    _RecipientCurrency(
      name: 'British Pound',
      detail: 'GBP (£)',
      flag: '🇬🇧',
      country: 'United Kingdom',
    ),
    _RecipientCurrency(
      name: 'CFA Franc BCEAO',
      detail: 'XOF (CFA)',
      flag: '🇧🇯',
      country: 'Benin',
    ),
    _RecipientCurrency(
      name: 'CFA Franc BEAC',
      detail: 'XAF (FCFA)',
      flag: '🇨🇲',
      country: 'Cameroon',
    ),
    _RecipientCurrency(
      name: 'Egyptian Pound',
      detail: 'EGP (E£)',
      flag: '🇪🇬',
      country: 'Egypt',
    ),
    _RecipientCurrency(
      name: 'Euro',
      detail: 'EUR (€)',
      flag: '🇪🇺',
      country: 'Europe',
    ),
    _RecipientCurrency(
      name: 'Ghanaian Cedi',
      detail: 'GHS (GH¢)',
      flag: '🇬🇭',
      country: 'Ghana',
    ),
    _RecipientCurrency(
      name: 'Indian Rupee',
      detail: 'INR (₹)',
      flag: '🇮🇳',
      country: 'India',
    ),
    _RecipientCurrency(
      name: 'Indonesian Rupiah',
      detail: 'IDR (Rp)',
      flag: '🇮🇩',
      country: 'Indonesia',
    ),
    _RecipientCurrency(
      name: 'Mexican Peso',
      detail: 'MXN (MX\$)',
      flag: '🇲🇽',
      country: 'Mexico',
    ),
    _RecipientCurrency(
      name: 'Philippine Peso',
      detail: 'PHP (₱)',
      flag: '🇵🇭',
      country: 'Philippines',
    ),
    _RecipientCurrency(
      name: 'Rwandan Franc',
      detail: 'RWF (FRw)',
      flag: '🇷🇼',
      country: 'Rwanda',
    ),
    _RecipientCurrency(
      name: 'South African Rand',
      detail: 'ZAR (R)',
      flag: '🇿🇦',
      country: 'South Africa',
    ),
    _RecipientCurrency(
      name: 'Tanzanian Shilling',
      detail: 'TZS (TSh)',
      flag: '🇹🇿',
      country: 'Tanzania',
    ),
    _RecipientCurrency(
      name: 'Ugandan Shilling',
      detail: 'UGX (USh)',
      flag: '🇺🇬',
      country: 'Uganda',
    ),
    _RecipientCurrency(
      name: 'US Dollar, to a US bank',
      detail: 'USD (\$)',
      flag: '🇺🇸',
      country: 'United States',
    ),
    _RecipientCurrency(
      name: 'Zambian Kwacha',
      detail: 'ZMW (ZK)',
      flag: '🇿🇲',
      country: 'Zambia',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(_RecipientCurrency currency) {
    final query = _searchQuery.trim().toLowerCase();
    return query.isEmpty ||
        currency.name.toLowerCase().contains(query) ||
        currency.detail.toLowerCase().contains(query) ||
        currency.country.toLowerCase().contains(query);
  }

  void _selectCurrency(_RecipientCurrency currency) {
    if (currency.detail.startsWith('NGN') ||
        currency.detail.startsWith('KES')) {
      final currencyCode = currency.detail.split(' ').first;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RecipientDeliveryMethodScreen(
            currencyCode: currencyCode,
            country: currency.country,
            countryFlag: currency.flag,
          ),
        ),
      );
      return;
    }

    if (currency.isStablecoin) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SendAmountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableCurrencies.where(_matches).toList();
    final stablecoinMatches = _matches(_stablecoin);
    final otherCurrencies = _otherCurrencies.where(_matches).toList();
    final groupedCurrencies = <String, List<_RecipientCurrency>>{};
    for (final currency in otherCurrencies) {
      final initial = currency.name[0];
      groupedCurrencies.putIfAbsent(initial, () => []).add(currency);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: SizedBox(
                height: 66,
                child: Row(
                  children: [
                    _CurrencyHeaderButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'What currency should\nthey receive?',
                        key: ValueKey('new-recipient-title'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _CurrencyHeaderButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                height: 44,
                child: TextField(
                  key: const ValueKey('currency-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search currency or country',
                    hintStyle: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF858585),
                      size: 19,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF272727),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('recipient-currency-list'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  if (available.isNotEmpty) ...[
                    const _CurrencySectionHeading('Available now'),
                    for (final currency in available)
                      _CurrencyRow(
                        currency: currency,
                        onTap: () => _selectCurrency(currency),
                      ),
                  ],
                  if (stablecoinMatches) ...[
                    const _CurrencySectionHeading('Stablecoin'),
                    _CurrencyRow(
                      currency: _stablecoin,
                      onTap: () => _selectCurrency(_stablecoin),
                    ),
                  ],
                  for (final entry in groupedCurrencies.entries) ...[
                    _CurrencySectionHeading(
                      entry.key,
                      key: ValueKey('currency-section-${entry.key}'),
                    ),
                    for (final currency in entry.value)
                      _CurrencyRow(currency: currency, isComingSoon: true),
                  ],
                  if (available.isEmpty &&
                      !stablecoinMatches &&
                      otherCurrencies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No currencies found',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 15,
                          ),
                        ),
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

class _RecipientCurrency {
  const _RecipientCurrency({
    required this.name,
    required this.detail,
    required this.flag,
    required this.country,
    this.isStablecoin = false,
  });

  final String name;
  final String detail;
  final String flag;
  final String country;
  final bool isStablecoin;
}

class _CurrencyHeaderButton extends StatelessWidget {
  const _CurrencyHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF383838)),
        ),
        child: Icon(icon, size: 19, semanticLabel: tooltip),
      ),
    );
  }
}

class _CurrencySectionHeading extends StatelessWidget {
  const _CurrencySectionHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    this.onTap,
    this.isComingSoon = false,
  });

  final _RecipientCurrency currency;
  final VoidCallback? onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          key: ValueKey('currency-${currency.detail}'),
          onTap: isComingSoon ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _CurrencyFlag(currency: currency),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.detail,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 11,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF666666),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyFlag extends StatelessWidget {
  const _CurrencyFlag({required this.currency});

  final _RecipientCurrency currency;

  @override
  Widget build(BuildContext context) {
    if (currency.isStablecoin) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF1858B8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '\$',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      child: Text(currency.flag, style: const TextStyle(fontSize: 22)),
    );
  }
}
