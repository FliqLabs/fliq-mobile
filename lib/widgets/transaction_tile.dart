import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'crypto_icons.dart';

const statusOrange = Color(0xFFF5A623);
const statusGreen = Color(0xFF2EB467);

Color statusColor(TransactionStatus status) => switch (status) {
  TransactionStatus.completed => statusGreen,
  TransactionStatus.pending => const Color(0xFFAAAAAA),
  TransactionStatus.notReceived => statusOrange,
};

/// One transaction row: coin icon, title, time, amount and status.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const TransactionCoinIcon(size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatShortTime(transaction.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.statusLabel,
                  style: TextStyle(
                    color: statusColor(transaction.status),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
