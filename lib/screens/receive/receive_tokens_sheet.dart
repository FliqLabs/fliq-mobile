import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/crypto.dart';
import '../../models/deposit.dart';
import '../../services/api_exception.dart';
import '../../services/deposit_addresses.dart';
import '../../utils/clipboard_share.dart';
import '../../utils/formatters.dart';
import '../../widgets/crypto_icons.dart';
import '../../widgets/fliq_sheet.dart';
import '../../widgets/qr_code_card.dart';
import '../../services/account_store.dart';

/// Quick deposit sheet opened from the QR icon on Home: pick a token and a
/// network, then share the address.
class ReceiveTokensSheet extends StatefulWidget {
  const ReceiveTokensSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showFliqSheet<void>(context, builder: (_) => const ReceiveTokensSheet());

  @override
  State<ReceiveTokensSheet> createState() => _ReceiveTokensSheetState();
}

class _ReceiveTokensSheetState extends State<ReceiveTokensSheet> {
  // Order matches the token menu in the iPhone app.
  static const _tokens = [SampleData.usdc, SampleData.bitcoin, SampleData.usdt];

  CryptoAsset _token = SampleData.usdc;
  CryptoNetwork _network = SampleData.near;

  DepositAddress? _deposit;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the address for the current token and network. A slow answer
  /// for an old choice is dropped.
  Future<void> _load() async {
    final token = _token;
    final network = _network;
    setState(() {
      _deposit = null;
      _error = null;
    });
    try {
      final deposit = await DepositAddresses.instance.addressFor(
        token,
        network,
      );
      if (!mounted || token != _token || network != _network) return;
      setState(() => _deposit = deposit);
    } on ApiException catch (error) {
      if (!mounted || token != _token || network != _network) return;
      setState(() => _error = error.message);
    }
  }

  void _selectToken(CryptoAsset token) {
    setState(() {
      _token = token;
      // Keep the network if the new token supports it, else use its first.
      _network = token.networks.firstWhere(
        (n) => n.name == _network.name,
        orElse: () => token.networks.first,
      );
    });
    _load();
  }

  void _selectNetwork(CryptoNetwork network) {
    setState(() => _network = network);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final deposit = _deposit;
    final address = deposit?.address ?? '';
    final isNear = _network.name == 'NEAR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive Tokens',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Deposit USDC or USDT to your wallet',
                      style: TextStyle(
                        color: FliqSheetColors.muted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              SheetRoundButton(
                key: const ValueKey('receive-tokens-close'),
                icon: Icons.close_rounded,
                tooltip: 'Close',
                filled: true,
                onPressed: () => closeFliqSheet<void>(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              const _FieldLabel('Token'),
              _MenuField<CryptoAsset>(
                key: const ValueKey('token-picker'),
                leading: AssetIcon(asset: _token, size: 24),
                label: _token.symbol,
                options: _tokens,
                optionLabel: (token) => token.symbol,
                onSelected: _selectToken,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Network'),
              _MenuField<CryptoNetwork>(
                key: const ValueKey('network-picker'),
                leading: NetworkBadge(network: _network, size: 26),
                label: _network.name,
                options: _token.networks,
                optionLabel: (network) => network.name,
                onSelected: _selectNetwork,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2414),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFF5A623),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'To avoid loss of funds, only send ${_token.symbol} '
                        'on ${_network.name} to this address.',
                        key: const ValueKey('receive-tokens-warning'),
                        style: const TextStyle(
                          color: Color(0xFFF5A623),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (deposit?.isDemo ?? false)
                Container(
                  key: const ValueKey('demo-address-warning'),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2414),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Demo address. Don't send real money to it. Sign in to get "
                    'your own.',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Center(
                child: Container(
                  width: 278,
                  height: 278,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: _error != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Try again'),
                            ),
                          ],
                        )
                      : deposit == null
                      ? const CircularProgressIndicator(color: Colors.white)
                      : FliqQrCode(
                          data: address,
                          size: 230,
                          center: NetworkBadge(network: _network, size: 34),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161618),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_network.name.toUpperCase()} ADDRESS',
                            style: const TextStyle(
                              color: FliqSheetColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isNear)
                            Text(
                              '@${AccountStore.instance.handle}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            deposit == null
                                ? '…'
                                : shortenAddress(address, head: 8, tail: 9),
                            style: const TextStyle(
                              color: FliqSheetColors.muted,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SquareIconButton(
                      key: const ValueKey('receive-tokens-copy'),
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy address',
                      onPressed: deposit == null
                          ? null
                          : () => copyWithFeedback(
                              context,
                              address,
                              message: deposit.isDemo
                                  ? 'Demo address copied. Do not send money to it.'
                                  : 'Address copied',
                            ),
                    ),
                    const SizedBox(width: 10),
                    _SquareIconButton(
                      icon: Icons.share_outlined,
                      tooltip: 'Share address',
                      onPressed: deposit == null || deposit.isDemo
                          ? null
                          : () => shareText(
                              'Send ${_token.symbol} on ${_network.name} to: '
                              '$address',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: FliqSheetColors.muted, fontSize: 15),
      ),
    );
  }
}

/// A field that opens a small menu of options when tapped.
class _MenuField<T> extends StatelessWidget {
  const _MenuField({
    required this.leading,
    required this.label,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
    super.key,
  });

  final Widget leading;
  final String label;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      color: const Color(0xFF2A2A2D),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option,
            child: Text(
              optionLabel(option),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
      ],
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FliqSheetColors.cardBorder),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FliqSheetColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF242427),
        fixedSize: const Size(50, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
