import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../widgets/receipt_sheet.dart';
import '../widgets/transaction_tile.dart';

enum ActivityFilter { all, mine, agents }

/// The Activity tab: every transaction, grouped by day, with filters.
///
/// It has no Scaffold of its own because it lives inside [HomeScreen],
/// which keeps the bottom navigation bar visible.
class ActivityView extends StatefulWidget {
  const ActivityView({
    required this.transactions,
    required this.onReceive,
    super.key,
  });

  final List<Transaction> transactions;
  final VoidCallback onReceive;

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  ActivityFilter _filter = ActivityFilter.all;

  List<Transaction> get _visible {
    final items = widget.transactions.where((t) {
      return switch (_filter) {
        ActivityFilter.all => true,
        // Deposits you started count as yours.
        ActivityFilter.mine => t.source != TransactionSource.agent,
        ActivityFilter.agents => t.source == TransactionSource.agent,
      };
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final filter in ActivityFilter.values) ...[
                _FilterChip(
                  key: ValueKey('activity-filter-${filter.name}'),
                  label: switch (filter) {
                    ActivityFilter.all => 'All',
                    ActivityFilter.mine => 'Mine',
                    ActivityFilter.agents => 'Agents',
                  },
                  selected: _filter == filter,
                  onTap: () => setState(() => _filter = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: items.isEmpty
                ? _EmptyActivity(onReceive: widget.onReceive)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: _buildGroups(items),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroups(List<Transaction> items) {
    final widgets = <Widget>[];
    String? currentDay;
    for (final transaction in items) {
      final day = formatDay(transaction.createdAt);
      if (day != currentDay) {
        currentDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10, top: 4),
            child: Text(
              day,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(18),
          ),
          child: TransactionTile(
            transaction: transaction,
            onTap: () => ReceiptSheet.show(context, transaction),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      color: selected ? Colors.white : const Color(0xFF161616),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : const Color(0xFF8E8E93),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onReceive});

  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_toggle_off_rounded,
            color: Color(0xFF6E6E73),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Nothing yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your first receipt lands here.',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            key: const ValueKey('activity-receive'),
            onPressed: onReceive,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF3A3A3C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Receive'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
