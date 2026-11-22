import 'package:flutter/material.dart';

import '../../widgets/flow_exit.dart';
import '../../widgets/receive_action_sheet.dart';
import 'bank_transfer_deposit_screen.dart';
import 'external_wallet_pages.dart';
import 'fliq_name_page.dart';

/// Shows "How do you want to get paid?" and opens the chosen option.
/// Back from an option returns here; Back from here returns
/// [FlowExit.back] so the caller can show its own menu again.
Future<FlowExit> startReceiveFlow(BuildContext context) async {
  while (true) {
    final choice = await ReceiveActionSheet.show(context);
    if (!context.mounted) return FlowExit.close;
    if (choice == FlowExit.back) return FlowExit.back;
    if (choice is! ReceiveMethod) return FlowExit.close;

    final left = await _open(context, choice);
    if (!context.mounted || left != FlowExit.back) return FlowExit.close;
  }
}

Future<Object?> _open(BuildContext context, ReceiveMethod method) async {
  switch (method) {
    case ReceiveMethod.bankTransfer:
      // A page: Back, or the phone's back gesture (null), is Back.
      final left = await Navigator.of(context).push<Object>(
        MaterialPageRoute(builder: (_) => const BankTransferDepositScreen()),
      );
      return left ?? FlowExit.back;
    case ReceiveMethod.fliqName:
      return FliqNamePage.show(context);
    case ReceiveMethod.externalWallet:
      return ChooseCurrencyPage.show(context);
  }
}
