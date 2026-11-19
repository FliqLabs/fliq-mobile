import 'package:flutter/material.dart';

import '../../widgets/receive_action_sheet.dart';
import 'bank_transfer_deposit_screen.dart';
import 'external_wallet_pages.dart';
import 'fliq_name_page.dart';

/// Shows "How do you want to get paid?" and opens the chosen option.
/// Used by Home, the Transfer menu and the Activity tab.
Future<void> startReceiveFlow(BuildContext context) async {
  final method = await ReceiveActionSheet.show(context);
  if (!context.mounted || method == null) return;

  switch (method) {
    case ReceiveMethod.bankTransfer:
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const BankTransferDepositScreen()),
      );
    case ReceiveMethod.fliqName:
      await FliqNamePage.show(context);
    case ReceiveMethod.externalWallet:
      await ChooseCurrencyPage.show(context);
  }
}
