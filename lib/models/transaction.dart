/// Where a transaction came from, used by the Activity filters.
enum TransactionSource {
  /// Started by you in the app.
  mine,

  /// Started by a connected AI agent.
  agent,

  /// Money coming in from outside (deposits).
  external,
}

enum TransactionStatus { pending, completed, notReceived }

/// One entry in the Activity list and its receipt.
class Transaction {
  const Transaction({
    required this.title,
    required this.amount,
    required this.status,
    required this.network,
    required this.reference,
    required this.category,
    required this.createdAt,
    required this.source,
  });

  /// e.g. "Received from Bitcoin".
  final String title;

  /// Already formatted, e.g. "0.0001 BTC".
  final String amount;
  final TransactionStatus status;
  final String network;
  final String reference;

  /// e.g. "Deposit", "Payout".
  final String category;
  final DateTime createdAt;
  final TransactionSource source;

  String get statusLabel => switch (status) {
    TransactionStatus.pending => 'Pending',
    TransactionStatus.completed => 'Completed',
    TransactionStatus.notReceived => 'Not received',
  };
}
