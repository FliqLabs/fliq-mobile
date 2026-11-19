import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../widgets/fliq_wordmark.dart';
import '../widgets/receipt_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transfer_action_sheet.dart';
import 'activity_screen.dart';
import 'pay_to_screen.dart';
import 'qr_scanner_screen.dart';
import 'receive/receive_flow.dart';
import 'receive/receive_tokens_sheet.dart';
import 'request_amount_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  int _tab = 0; // 0 = Home, 1 = Activity

  List<Transaction> get _transactions => SampleData.transactions;

  Future<void> _openTransferMenu() async {
    final action = await TransferActionSheet.show(context);
    if (!mounted || action == null) return;

    switch (action) {
      case TransferAction.send:
        await Navigator.of(context)
            .push<void>(MaterialPageRoute(builder: (_) => const PayToScreen()));
      case TransferAction.request:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const RequestAmountScreen()),
        );
      case TransferAction.receive:
        await startReceiveFlow(context);
      case TransferAction.scan:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
        );
    }
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
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.43, 0.78, 1],
              colors: [
                Color(0xFF151515),
                Color(0xFF0D0D0D),
                Color(0xFF050505),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _tab == 0
                      ? _buildHome(context)
                      : ActivityView(
                          transactions: _transactions,
                          onReceive: () => startReceiveFlow(context),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: _HomeNavigation(
                    selectedIndex: _tab,
                    onHome: () => setState(() => _tab = 0),
                    onTransfer: _openTransferMenu,
                    onActivity: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final latest = _transactions.isEmpty
        ? null
        : (List.of(
            _transactions,
          )..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderAction(
                  key: const ValueKey('profile-action'),
                  icon: Icons.person_outline_rounded,
                  tooltip: 'Profile',
                  isCircular: true,
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(scale: 0.76, child: FliqWordmark()),
                ),
                _HeaderAction(
                  key: const ValueKey('qr-action'),
                  icon: Icons.qr_code_2_rounded,
                  tooltip: 'Receive tokens',
                  onPressed: () => ReceiveTokensSheet.show(context),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Vault balance',
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey('toggle-balance'),
                      onPressed: () => setState(
                        () => _isBalanceVisible = !_isBalanceVisible,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFAAAAAA),
                        size: 20,
                      ),
                      tooltip: _isBalanceVisible
                          ? 'Hide balance'
                          : 'Show balance',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      r'$',
                      style: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 31,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isBalanceVisible
                          ? groupDigits(SampleData.vaultBalanceUsd)
                          : '••••',
                      key: const ValueKey('vault-balance-amount'),
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
                const SizedBox(height: 32),
                Container(
                  key: const ValueKey('exchange-quote'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF303030)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: r'$1 = '),
                        TextSpan(
                          text: formatNaira(SampleData.usdToNgn, decimals: 2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${SampleData.rateProviders.length} quoting',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (latest != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _RecentCard(
              transaction: latest,
              onSeeAll: () => setState(() => _tab = 1),
            ),
          ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.transaction, required this.onSeeAll});

  final Transaction transaction;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('recent-card'),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text(
                  'RECENT',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const ValueKey('recent-see-all'),
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8E8E93),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          TransactionTile(
            transaction: transaction,
            onTap: () => ReceiptSheet.show(context, transaction),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isCircular = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isCircular;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCircular ? const Color(0xFF252525) : Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFAAAAAA), size: 23),
        tooltip: tooltip,
      ),
    );
  }
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation({
    required this.selectedIndex,
    required this.onHome,
    required this.onTransfer,
    required this.onActivity,
  });

  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onTransfer;
  final VoidCallback onActivity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('nav-home'),
              label: 'Home',
              icon: Icons.home_outlined,
              selected: selectedIndex == 0,
              onPressed: onHome,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('nav-transfer'),
              label: 'Transfer',
              icon: Icons.swap_vert_rounded,
              onPressed: onTransfer,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('nav-activity'),
              label: 'Activity',
              icon: Icons.history_toggle_off_rounded,
              selected: selectedIndex == 1,
              onPressed: onActivity,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    this.selected = false,
    this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF363636) : Colors.transparent,
      borderRadius: BorderRadius.circular(38),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(38),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
