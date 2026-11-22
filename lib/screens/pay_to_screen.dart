import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'new_recipient_screen.dart';
import 'qr_scanner_screen.dart';
import 'send_amount_screen.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/flow_exit.dart';
import '../widgets/fliq_symbol.dart';

class PayToScreen extends StatefulWidget {
  const PayToScreen({super.key});

  @override
  State<PayToScreen> createState() => _PayToScreenState();
}

class _PayToScreenState extends State<PayToScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const _filters = ['All', '🇳🇬  NGN', '🇰🇪  KES', 'N  fliq user'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startWalletTransfer() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SendAmountScreen()),
    );
  }

  Future<void> _openNewRecipient() async {
    final currency = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NewRecipientScreen()),
    );
    if (!mounted || currency == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$currency selected.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scanToPay() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted || value == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR code scanned and ready for review.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFliqUserFilter = _selectedFilter == 'N  fliq user';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF1C1C1C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
            ),
            child: Column(
              children: [
                _PayToHeader(
                  onBack: () => Navigator.of(context).pop(FlowExit.back),
                  onClose: () => Navigator.of(context).pop(FlowExit.close),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    height: 52,
                    child: TextField(
                      key: const ValueKey('recipient-search'),
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Name, bank, account number or fliq name',
                        hintStyle: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF777777),
                          size: 21,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF272727),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF686868),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = filter == _selectedFilter;
                      return ChoiceChip(
                        key: ValueKey('recipient-filter-$index'),
                        label: index == 3
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FliqSymbol(
                                    key: ValueKey('fliq-user-filter-symbol'),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text('fliq user'),
                                ],
                              )
                            : Text(filter),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                        backgroundColor: const Color(0xFF272727),
                        selectedColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      _PayToOption(
                        key: const ValueKey('scan-to-pay'),
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan to pay',
                        subtitle: 'A bank QR code or an\naccount number',
                        onPressed: _scanToPay,
                      ),
                      if (_selectedFilter == 'All') ...[
                        const SizedBox(height: 12),
                        _PayToOption(
                          key: const ValueKey('send-to-wallet'),
                          icon: Icons.north_east_rounded,
                          title: 'Send to a wallet',
                          subtitle: 'USDC to any NEAR address',
                          onPressed: _startWalletTransfer,
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF252525),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFliqUserFilter
                                      ? Icons.people_outline_rounded
                                      : Icons.account_balance_outlined,
                                  color: const Color(0xFF777777),
                                  size: 31,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.trim().isEmpty
                                    ? isFliqUserFilter
                                          ? 'No fliq users yet'
                                          : 'No one saved here yet'
                                    : 'No matches found',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.trim().isEmpty
                                    ? isFliqUserFilter
                                          ? 'Search a fliq name to pay someone instantly, with no fee.'
                                          : 'Accounts you pay and save show up here.'
                                    : 'Try a different name, bank or account number.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('new-recipient'),
                      onPressed: _openNewRecipient,
                      icon: const Icon(Icons.add, size: 21),
                      label: const Text('New recipient'),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

class _PayToHeader extends StatelessWidget {
  const _PayToHeader({required this.onBack, required this.onClose});

  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 78,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Back',
              onPressed: onBack,
            ),
            const Expanded(
              child: Text(
                'Pay to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayToOption extends StatelessWidget {
  const _PayToOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 84,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF222222),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Icon(icon, size: 25, color: const Color(0xFFD8D8D8)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF777777),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
