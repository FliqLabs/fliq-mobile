import 'package:flutter/material.dart';

import '../models/crypto.dart';
import '../models/transaction.dart';

/// Sample data the app shows until it is connected to the Fliq API.
///
/// Every screen reads from here instead of hard-coding its own values, so
/// when the API is added this is the one place to swap for real responses.
/// The wallet addresses below are placeholders, not real deposit addresses.
abstract final class SampleData {
  // ── Account ──────────────────────────────────────────────────────────
  static const handle = 'olayinka05';
  static const initials = 'OF';
  static const nearAccount = 'olayinka05.fliqaccount.near';

  /// Pay links look like `fliq.cash/pay/olayinka05/3a7c`.
  static const payLinkBase = 'fliq.cash/pay';

  /// Vault balance in US dollars.
  static const vaultBalanceUsd = 0.0;

  // ── Rates ────────────────────────────────────────────────────────────
  /// What $1 is worth in naira after fees (shown on Home and Live rates).
  static const usdToNgn = 1462.95;
  static const usdToNgnBeforeFees = 1463.43;
  static const rateProviders = ['Paycrest'];

  /// Rate used when you add money by bank transfer (₦ per $1).
  static const depositNgnPerUsd = 1452.10;

  // ── Activity ─────────────────────────────────────────────────────────
  static final transactions = <Transaction>[
    Transaction(
      title: 'Received from Bitcoin',
      amount: '0.0001 BTC',
      status: TransactionStatus.notReceived,
      network: 'Bitcoin',
      reference: 'dep_01m7f42x8c0kq3w9qbqt9an1p96f',
      category: 'Deposit',
      createdAt: DateTime(2026, 11, 15, 9, 9),
      source: TransactionSource.mine,
    ),
  ];

  /// fliq names that exist. Anything else shows "No one on fliq has that
  /// name". The API will answer this instead.
  static const knownFliqUsers = <String>{};

  // ── Receiving crypto ─────────────────────────────────────────────────
  static const near = CryptoNetwork(
    name: 'NEAR',
    arrivalTime: '~2s',
    noFee: true,
    color: Color(0xFF00EC97),
    badge: 'N',
  );
  static const monad = CryptoNetwork(
    name: 'Monad',
    arrivalTime: '~25s',
    color: Color(0xFF6E54FF),
    badge: 'M',
  );
  static const base = CryptoNetwork(
    name: 'Base',
    arrivalTime: '~35s',
    color: Color(0xFF0052FF),
    badge: '',
  );
  static const solana = CryptoNetwork(
    name: 'Solana',
    arrivalTime: '~35s',
    color: Color(0xFF14F195),
    badge: 'S',
  );
  static const solanaFast = CryptoNetwork(
    name: 'Solana',
    arrivalTime: '~25s',
    color: Color(0xFF14F195),
    badge: 'S',
  );
  static const arbitrum = CryptoNetwork(
    name: 'Arbitrum',
    arrivalTime: '~35s',
    color: Color(0xFF28A0F0),
    badge: 'A',
  );
  static const polygon = CryptoNetwork(
    name: 'Polygon',
    arrivalTime: '~35s',
    color: Color(0xFF8247E5),
    badge: 'P',
  );
  static const bnb = CryptoNetwork(
    name: 'BNB Smart Chain',
    arrivalTime: '~40s',
    color: Color(0xFFF3BA2F),
    badge: 'B',
  );
  static const tron = CryptoNetwork(
    name: 'Tron',
    arrivalTime: '~1 min',
    color: Color(0xFFEB0029),
    badge: 'T',
  );
  static const ethereum = CryptoNetwork(
    name: 'Ethereum',
    arrivalTime: '~2 min',
    color: Color(0xFF627EEA),
    badge: 'E',
  );
  static const bitcoinNetwork = CryptoNetwork(
    name: 'Bitcoin',
    arrivalTime: '~10 min',
    color: Color(0xFFF7931A),
    badge: '₿',
  );

  static const usdc = CryptoAsset(
    symbol: 'USDC',
    name: 'USDC',
    color: Color(0xFF2775CA),
    icon: Icons.attach_money_rounded,
    networks: [near, monad, base, solana, arbitrum, polygon, bnb, ethereum],
    minimum: {'NEAR': '0.01 USDC'},
  );
  static const usdt = CryptoAsset(
    symbol: 'USDT',
    name: 'Tether USDT',
    color: Color(0xFF26A17B),
    icon: Icons.diamond_outlined,
    networks: [solanaFast, polygon, bnb, tron, ethereum],
    minimum: {},
  );
  static const bitcoin = CryptoAsset(
    symbol: 'BTC',
    name: 'Bitcoin',
    color: Color(0xFFF7931A),
    icon: Icons.currency_bitcoin_rounded,
    networks: [bitcoinNetwork],
    minimum: {'Bitcoin': '0.000098 BTC'},
    arrivesAs: 'USDC in your vault',
  );

  static const bnbCoin = CryptoAsset(
    symbol: 'BNB',
    name: 'BNB',
    color: Color(0xFFF3BA2F),
    icon: Icons.hexagon_outlined,
    networks: [bnb],
    minimum: {'BNB Smart Chain': '0.002 BNB'},
    arrivesAs: 'USDC in your vault',
  );
  static const ether = CryptoAsset(
    symbol: 'ETH',
    name: 'Ether',
    color: Color(0xFF627EEA),
    icon: Icons.diamond_outlined,
    networks: [ethereum],
    minimum: {'Ethereum': '0.0004 ETH'},
    arrivesAs: 'USDC in your vault',
  );
  static const sol = CryptoAsset(
    symbol: 'SOL',
    name: 'Solana',
    color: Color(0xFF14F195),
    icon: Icons.blur_on_rounded,
    networks: [solanaFast],
    minimum: {'Solana': '0.01 SOL'},
    arrivesAs: 'USDC in your vault',
  );

  static const digitalDollars = [usdc, usdt];

  /// Other coins, swapped into USDC as they land.
  static const coins = [bnbCoin, ether, sol];

  /// The token menu on Receive Tokens, in the iPhone app's order.
  static const tokenMenu = [usdc, bnbCoin, bitcoin, ether, sol, usdt];
  static const allAssets = [usdc, usdt, bitcoin, bnbCoin, ether, sol];

  /// Placeholder deposit address for each network.
  static String depositAddress(CryptoNetwork network) {
    return switch (network.name) {
      'NEAR' => nearAccount,
      'Solana' => 'B5aCC2WmQx7sV4kR8nTz3pLd6yHf1JcE9oGu2MWqJi7',
      'Tron' => 'TQ5rN8vKx2mW4hJd7pYc3LsF9gBz6aE1Uo',
      'Bitcoin' => 'bc1q5eln7v3k9x2m4w8hjd6pyc0lsf3gbz9vfs8c',
      _ => '0x92b005c3E1f4A7d9B2c6e8F0a3D5b7C9e1f19d19',
    };
  }

  /// Smallest deposit for a coin on a network.
  static String minimumDeposit(CryptoAsset asset, CryptoNetwork network) {
    return asset.minimum[network.name] ?? '0.10 ${asset.symbol}';
  }

  /// Deposit addresses on other chains expire. NEAR ones don't.
  static Duration? addressLifetime(CryptoNetwork network) {
    if (network.name == 'NEAR') return null;
    if (network.name == 'Bitcoin') return const Duration(minutes: 4380);
    return const Duration(minutes: 4330);
  }
}
