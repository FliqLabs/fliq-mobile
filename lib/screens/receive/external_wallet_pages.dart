import 'dart:async';

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

/// Receiving from an external wallet or exchange, in three steps:
/// choose a coin → choose a network → show the deposit address.
/// Bitcoin has one network, so it skips straight to the address.
class ChooseCurrencyPage extends StatelessWidget {
  const ChooseCurrencyPage({super.key});

  static Future<void> show(BuildContext context) =>
      showFliqSheet<void>(context, builder: (_) => const ChooseCurrencyPage());

  void _choose(BuildContext context, CryptoAsset asset) {
    pushInSheet<void>(
      context,
      asset.hasSingleNetwork
          ? ReceiveAddressPage(asset: asset, network: asset.networks.single)
          : ChooseNetworkPage(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FliqSheetHeader(title: 'Choose currency to receive'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              const _GroupLabel('Digital dollars'),
              _OptionGroup(
                children: [
                  for (final asset in SampleData.digitalDollars)
                    _OptionRow(
                      key: ValueKey('currency-${asset.symbol}'),
                      leading: AssetIcon(asset: asset),
                      title: asset.name,
                      onTap: () => _choose(context, asset),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const _GroupLabel('Bitcoin'),
              _OptionGroup(
                children: [
                  _OptionRow(
                    key: const ValueKey('currency-BTC'),
                    leading: const AssetIcon(asset: SampleData.bitcoin),
                    title: SampleData.bitcoin.name,
                    onTap: () => _choose(context, SampleData.bitcoin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChooseNetworkPage extends StatelessWidget {
  const ChooseNetworkPage({required this.asset, super.key});

  final CryptoAsset asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FliqSheetHeader(title: 'Choose network'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Receive ${asset.symbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  AssetIcon(asset: asset, size: 30),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '1 ${asset.symbol} ≈ \$1.00',
                style: const TextStyle(
                  color: FliqSheetColors.muted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFF5A623),
                      size: 22,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your receiving address depends on the coin and '
                        'network.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OptionGroup(
                children: [
                  for (final network in asset.networks)
                    _OptionRow(
                      key: ValueKey('network-${network.name}'),
                      leading: NetworkBadge(network: network, size: 32),
                      title: network.name,
                      subtitle: network.noFee
                          ? '${network.arrivalTime} · no fee'
                          : network.arrivalTime,
                      onTap: () => pushInSheet<void>(
                        context,
                        ReceiveAddressPage(asset: asset, network: network),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The deposit address, its QR code and the deposit rules.
class ReceiveAddressPage extends StatefulWidget {
  const ReceiveAddressPage({
    required this.asset,
    required this.network,
    super.key,
  });

  final CryptoAsset asset;
  final CryptoNetwork network;

  @override
  State<ReceiveAddressPage> createState() => _ReceiveAddressPageState();
}

class _ReceiveAddressPageState extends State<ReceiveAddressPage> {
  Timer? _timer;
  DepositAddress? _deposit;
  String? _error;

  Duration? get _remaining {
    final until = _deposit?.reservedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get _expired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _deposit?.reservedUntil != null) setState(() {});
    });
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() {
      _deposit = null;
      _error = null;
    });
    try {
      final deposit = await DepositAddresses.instance.addressFor(
        widget.asset,
        widget.network,
        fresh: fresh,
      );
      if (mounted) setState(() => _deposit = deposit);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final network = widget.network;
    final canChangeNetwork = !asset.hasSingleNetwork;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FliqSheetHeader(
          trailing: SheetRoundButton(
            key: const ValueKey('share-address'),
            icon: Icons.share_outlined,
            tooltip: 'Share address',
            onPressed: () {
              final deposit = _deposit;
              if (deposit == null || deposit.isDemo) return;
              shareText(
                'Send ${asset.symbol} on ${network.name} to: '
                '${deposit.address}',
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text(
                'Receive ${asset.symbol}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                key: const ValueKey('change-network'),
                // Tapping "on the X network" goes back to the network list.
                onTap: canChangeNetwork
                    ? () => Navigator.of(context).maybePop()
                    : null,
                child: Row(
                  children: [
                    const Text(
                      'on the ',
                      style: TextStyle(
                        color: FliqSheetColors.muted,
                        fontSize: 16,
                      ),
                    ),
                    NetworkBadge(network: network, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${network.name} network',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (canChangeNetwork) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.unfold_more_rounded,
                        color: FliqSheetColors.muted,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_error != null)
                _AddressProblem(
                  message: _error!,
                  onRetry: () => _load(fresh: true),
                )
              else if (_deposit == null)
                const _AddressLoading()
              else ...[
                if (_deposit!.isDemo) const _DemoWarning(),
                _AddressCard(
                  address: _deposit!.address,
                  center: asset.symbol == 'BTC'
                      ? AssetIcon(asset: asset, size: 26)
                      : AssetIcon(asset: asset, size: 22),
                ),
                if (_deposit!.memo != null)
                  _DetailRow(label: 'Memo', value: _deposit!.memo!),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Arrives as',
                  value: asset.arrivesAs ?? '1 ${asset.symbol} ≈ \$1.00',
                ),
                _DetailRow(
                  label: 'Minimum',
                  value: '${_deposit!.minimum} ${asset.symbol}',
                ),
                _DetailRow(
                  label: 'Fees',
                  value: _deposit!.hasFee ? '≈ \$${_deposit!.fee}' : 'None',
                ),
                _DetailRow(label: 'Arrives in', value: network.arrivalTime),
                if (_remaining != null)
                  _DetailRow(
                    key: const ValueKey('address-open-for'),
                    label: 'Address open for',
                    value: _expired ? 'Expired' : formatCountdown(_remaining!),
                  ),
              ],
              InkWell(
                onTap: () => _showDepositInfo(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Learn more about deposits',
                          style: TextStyle(
                            color: FliqSheetColors.muted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: FliqSheetColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _expired
              ? SheetPrimaryButton(
                  key: const ValueKey('new-address'),
                  label: 'Get a new address',
                  onPressed: () => _load(fresh: true),
                )
              : SheetPrimaryButton(
                  key: const ValueKey('copy-address'),
                  label: 'Copy address',
                  onPressed: _deposit == null
                      ? null
                      : () => copyWithFeedback(
                          context,
                          _deposit!.address,
                          message: _deposit!.isDemo
                              ? 'Demo address copied. Do not send money to it.'
                              : 'Address copied',
                        ),
                ),
        ),
      ],
    );
  }

  void _showDepositInfo(BuildContext context) {
    final asset = widget.asset;
    final network = widget.network;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FliqSheetColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About deposits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Only send ${asset.symbol} on the ${network.name} network to '
                'this address. Coins sent on another network, or other coins, '
                'can be lost.\n\n'
                'Less than the minimum, or a transfer that can\'t finish, is '
                'refunded to your NEAR account. fliq charges nothing to '
                'receive.\n\n'
                '${_remaining != null ? 'This address is watched until the timer ends. Get a new one after that.' : 'This address does not expire.'}',
                style: const TextStyle(
                  color: FliqSheetColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.center});

  final String address;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF1D3B2A),
                        child: Text(
                          AccountStore.instance.initials,
                          style: TextStyle(
                            color: Color(0xFF2EB467),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AccountStore.instance.handle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => copyWithFeedback(
                      context,
                      address,
                      message: 'Address copied',
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            shortenAddress(address, head: 9, tail: 5),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FliqSheetColors.muted,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.copy_rounded,
                          color: FliqSheetColors.muted,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          FliqQrCode(data: address, size: 130, center: center),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E))),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: FliqSheetColors.muted, fontSize: 15),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(color: FliqSheetColors.muted, fontSize: 16),
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FliqSheetColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E20)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: subtitle == null ? 14 : 12,
        ),
        child: Row(
          children: [
            SizedBox(width: 34, child: Center(child: leading)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: FliqSheetColors.muted,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6E6E73),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressLoading extends StatelessWidget {
  const _AddressLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('address-loading'),
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Getting your address…',
            style: TextStyle(color: FliqSheetColors.muted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _AddressProblem extends StatelessWidget {
  const _AddressProblem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('address-problem'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Shown on made-up addresses, so nobody sends real money to them.
class _DemoWarning extends StatelessWidget {
  const _DemoWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('demo-address-warning'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2414),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF5A623), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Demo address. Don't send real money to it. Sign in to get "
              'your own.',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
