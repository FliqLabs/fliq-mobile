import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/clipboard_share.dart';
import '../utils/formatters.dart';
import 'crypto_icons.dart';
import 'fliq_sheet.dart';
import 'transaction_tile.dart';

/// Receipt for one transaction, opened from Home or Activity.
class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet({required this.transaction, super.key});

  final Transaction transaction;

  static Future<void> show(BuildContext context, Transaction transaction) {
    return showFliqSheet<void>(
      context,
      heightFactor: 0.9,
      builder: (_) => ReceiptSheet(transaction: transaction),
    );
  }

  String get _shareText =>
      'fliq receipt\n'
      '${transaction.title}: ${transaction.amount}\n'
      'Status: ${transaction.statusLabel}\n'
      'Network: ${transaction.network}\n'
      'Reference: ${transaction.reference}\n'
      '${formatDayAndTime(transaction.createdAt)}';

  @override
  Widget build(BuildContext context) {
    final failed = transaction.status == TransactionStatus.notReceived;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FliqSheetCloseButton(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: TransactionCoinIcon(size: 52)),
                const SizedBox(height: 16),
                Text(
                  transaction.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.amount,
                  key: const ValueKey('receipt-amount'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  formatDayAndTime(transaction.createdAt),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FliqSheetColors.muted,
                    fontSize: 15,
                  ),
                ),
                if (failed) ...[
                  const SizedBox(height: 22),
                  const _NotReceivedCard(),
                ],
                const SizedBox(height: 22),
                _ReceiptRow(
                  label: 'Status',
                  value: transaction.statusLabel,
                  valueColor: statusColor(transaction.status),
                ),
                if (transaction.facts case final facts?) ...[
                  for (final (index, (label, value)) in facts.indexed)
                    if (value.isNotEmpty)
                      _ReceiptRow(
                        label: label,
                        value: label == 'Reference'
                            ? shortenAddress(value, head: 10, tail: 12)
                            : value,
                        showDivider: index < facts.length - 1,
                        onTap: label == 'Reference'
                            ? () => copyWithFeedback(
                                context,
                                value,
                                message: 'Reference copied',
                              )
                            : null,
                      ),
                ] else ...[
                  _ReceiptRow(label: 'Network', value: transaction.network),
                  _ReceiptRow(
                    label: 'Reference',
                    value: shortenAddress(
                      transaction.reference,
                      head: 10,
                      tail: 12,
                    ),
                    onTap: () => copyWithFeedback(
                      context,
                      transaction.reference,
                      message: 'Reference copied',
                    ),
                  ),
                  _ReceiptRow(
                    label: 'Category',
                    value: transaction.category,
                    showDivider: false,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              key: const ValueKey('share-receipt'),
              onPressed: () => shareText(_shareText, subject: 'fliq receipt'),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: const Text('Share receipt'),
              style: FilledButton.styleFrom(
                backgroundColor: FliqSheetColors.card,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotReceivedCard extends StatelessWidget {
  const _NotReceivedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: FliqSheetColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Didn't go through",
                  style: TextStyle(color: FliqSheetColors.muted, fontSize: 15),
                ),
              ),
              Icon(Icons.error_outline_rounded, color: statusOrange, size: 20),
            ],
          ),
          SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, color: statusOrange, size: 8),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not received',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Nothing arrived before this address closed. If you '
                      "sent money, contact us and we'll sort it out.",
                      style: TextStyle(
                        color: FliqSheetColors.muted,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.showDivider = true,
    this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFF2C2C2E)))
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FliqSheetColors.muted,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
