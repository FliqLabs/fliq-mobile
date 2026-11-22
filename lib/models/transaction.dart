import '../utils/formatters.dart';

/// Where a transaction came from, used by the Activity filters.
enum TransactionSource {
  /// Started by you in the app.
  mine,

  /// Started by a connected AI agent.
  agent,

  /// Money coming in from outside (deposits).
  external,
}

enum TransactionKind { payout, deposit, transferIn, transferOut, refused }

enum TransactionStatus {
  pending,
  completed,
  notReceived,
  refunded,
  refused,
  failed,
}

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
    this.kind = TransactionKind.deposit,
    this.facts,
  });

  /// Builds a row from one item of `GET /activity`.
  factory Transaction.fromActivity(Map<String, dynamic> json) {
    final kind = switch (json['kind']) {
      'payout' => TransactionKind.payout,
      'transfer_in' => TransactionKind.transferIn,
      'transfer_out' => TransactionKind.transferOut,
      'refused' => TransactionKind.refused,
      _ => TransactionKind.deposit,
    };
    final party = json['party'] as Map<String, dynamic>? ?? const {};
    final partyName = party['name'] as String? ?? '';
    final agent = json['agent'] as Map<String, dynamic>?;
    final agentName = agent?['name'] as String?;
    final provider = _providerName(json['provider'] as String?);
    final usd = json['usd'] as String?;
    final token = json['token'] as String?;
    final reference = json['ref_id'] as String? ?? '';
    final local = json['local'] as Map<String, dynamic>?;
    final localAmount = local == null
        ? null
        : _localMoney(local['amount'] as String, local['currency'] as String);
    final status = _status(json['status'] as String? ?? '', kind);
    final usdText = usd == null ? null : '\$$usd';
    final chain = partyName.startsWith('Received from ')
        ? partyName.substring('Received from '.length)
        : (provider ?? 'NEAR');

    final (title, amount, category, network, facts) = switch (kind) {
      TransactionKind.payout => (
        partyName,
        localAmount ?? usdText ?? '',
        'Cash out',
        provider ?? 'Bank',
        <(String, String)>[
          ('They receive', localAmount ?? ''),
          ('From your vault', usdText ?? ''),
          if (provider != null) ('Paid out by', provider),
          if (party['account_last4'] != null)
            ('Account', '•••• ${party['account_last4']}'),
          if (agentName != null) ('Agent', agentName),
          ('Reference', reference),
        ],
      ),
      TransactionKind.refused => (
        '${agentName ?? 'An agent'} asked to pay $partyName',
        localAmount ?? usdText ?? '',
        'Refused',
        'Agent',
        <(String, String)>[
          ('Asked for', localAmount ?? ''),
          ('Why', _reason(json['reason'] as String?)),
          if (agentName != null) ('Agent', agentName),
          ('Reference', reference),
        ],
      ),
      TransactionKind.transferIn => (
        'Received from $partyName',
        usdText ?? '',
        'Received',
        'NEAR',
        <(String, String)>[
          ('Amount', usdText ?? ''),
          ('From', party['near_account'] as String? ?? partyName),
          ('Reference', reference),
        ],
      ),
      TransactionKind.transferOut => (
        'Sent to $partyName',
        usdText ?? '',
        'Sent',
        'NEAR',
        <(String, String)>[
          ('Amount', usdText ?? ''),
          ('To', party['near_account'] as String? ?? partyName),
          ('Reference', reference),
        ],
      ),
      TransactionKind.deposit => (
        partyName,
        token ?? usdText ?? '',
        'Deposit',
        chain,
        <(String, String)>[
          if (token != null) ('You sent', token),
          if (usd != null && status == TransactionStatus.completed)
            ('Delivered', usdText!),
          ('Network', chain),
          ('Reference', reference),
        ],
      ),
    };

    return Transaction(
      title: title,
      amount: amount,
      status: status,
      network: network,
      reference: reference,
      category: category,
      createdAt: DateTime.parse(json['at'] as String).toLocal(),
      source: agent != null
          ? TransactionSource.agent
          : kind == TransactionKind.deposit
          ? TransactionSource.external
          : TransactionSource.mine,
      kind: kind,
      facts: facts,
    );
  }

  /// e.g. "Received from Bitcoin".
  final String title;

  /// Already formatted, e.g. "0.0001 BTC" or "₦68,816".
  final String amount;
  final TransactionStatus status;
  final String network;
  final String reference;

  /// e.g. "Deposit", "Cash out".
  final String category;
  final DateTime createdAt;
  final TransactionSource source;
  final TransactionKind kind;

  /// Rows for the receipt after "Status". Null uses Network/Reference/Category.
  final List<(String, String)>? facts;

  String get statusLabel => switch (status) {
    TransactionStatus.completed => switch (kind) {
      TransactionKind.deposit || TransactionKind.transferIn => 'Received',
      TransactionKind.transferOut => 'Sent',
      _ => 'Paid',
    },
    TransactionStatus.pending =>
      kind == TransactionKind.deposit ? 'Arriving' : 'Sending',
    TransactionStatus.notReceived => 'Not received',
    TransactionStatus.refunded => 'Refunded',
    TransactionStatus.refused => 'Refused',
    TransactionStatus.failed => 'Failed',
  };

  static TransactionStatus _status(String status, TransactionKind kind) {
    switch (status) {
      case 'paid' ||
          'settled' ||
          'received' ||
          'delivered' ||
          'completed' ||
          'succeeded':
        return TransactionStatus.completed;
      case 'refunded':
        return TransactionStatus.refunded;
      case 'refused':
        return TransactionStatus.refused;
      case 'failed' || 'expired' || 'not_received':
        return kind == TransactionKind.deposit
            ? TransactionStatus.notReceived
            : TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  static String? _providerName(String? id) {
    if (id == null) return null;
    return switch (id) {
      'paycrest' => 'Paycrest',
      'paj' => 'Paj',
      _ => id[0].toUpperCase() + id.substring(1),
    };
  }

  static String _localMoney(String amount, String currency) {
    final value = double.tryParse(amount) ?? 0;
    final symbol = switch (currency.toUpperCase()) {
      'NGN' => '₦',
      'KES' => 'KSh ',
      _ => '$currency ',
    };
    return '$symbol${groupDigits(value)}';
  }

  static String _reason(String? reason) => switch (reason) {
    'over_daily_cap' => 'Over its daily limit',
    'over_payout_cap' => 'Over its per-payment limit',
    'not_saved_account' => 'Not one of your saved accounts',
    'country_not_allowed' => 'Not a country it may pay',
    null => 'Outside its limits',
    _ => reason.replaceAll('_', ' '),
  };
}
