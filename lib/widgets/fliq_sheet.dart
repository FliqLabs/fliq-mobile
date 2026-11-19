import 'package:flutter/material.dart';

/// Opens a tall, rounded bottom sheet with its own navigation stack.
///
/// Screens pushed inside the sheet (for example currency → network →
/// address) stay inside it. Use [closeFliqSheet] to dismiss the whole sheet,
/// and [FliqSheetBackButton] to go back one page or close at the first page.
Future<T?> showFliqSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double heightFactor = 0.93,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8000000),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: heightFactor,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: ColoredBox(
          color: FliqSheetColors.background,
          // Own messenger so "Copied" snack bars show on top of the sheet.
          child: ScaffoldMessenger(
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _SheetPage(child: builder(context)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pushes [page] inside the current sheet.
Future<T?> pushInSheet<T>(BuildContext context, Widget page) {
  return Navigator.of(context)
      .push<T>(MaterialPageRoute<T>(builder: (_) => _SheetPage(child: page)));
}

/// Closes the whole sheet, wherever you are inside it.
void closeFliqSheet<T>(BuildContext context, [T? result]) {
  Navigator.of(context, rootNavigator: true).pop<T>(result);
}

abstract final class FliqSheetColors {
  static const background = Color(0xFF1C1C1E);
  static const card = Color(0xFF262628);
  static const cardBorder = Color(0xFF303033);
  static const muted = Color(0xFF9A9A9E);
}

class _SheetPage extends StatelessWidget {
  const _SheetPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FliqSheetColors.background,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF5A5A5E),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Round outlined icon button used in sheet headers.
class SheetRoundButton extends StatelessWidget {
  const SheetRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// White circle with a dark icon (used by "Receive Tokens").
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: filled ? Colors.black : Colors.white,
            backgroundColor: filled ? Colors.white : Colors.transparent,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(
              color: filled ? Colors.white : const Color(0xFF3A3A3D),
            ),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

/// Goes back one page inside a sheet, or closes the sheet on its first page.
class FliqSheetBackButton extends StatelessWidget {
  const FliqSheetBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetRoundButton(
      key: const ValueKey('sheet-back'),
      icon: Icons.arrow_back_ios_new_rounded,
      tooltip: 'Back',
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          closeFliqSheet<void>(context);
        }
      },
    );
  }
}

class FliqSheetCloseButton extends StatelessWidget {
  const FliqSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetRoundButton(
      key: const ValueKey('sheet-close'),
      icon: Icons.close_rounded,
      tooltip: 'Close',
      onPressed: () => closeFliqSheet<void>(context),
    );
  }
}

/// Back button, optional centred title, and an optional trailing button.
class FliqSheetHeader extends StatelessWidget {
  const FliqSheetHeader({this.title, this.trailing, super.key});

  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const FliqSheetBackButton(),
          Expanded(
            child: Text(
              title ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing ?? const FliqSheetCloseButton(),
        ],
      ),
    );
  }
}

/// Full-width white button at the bottom of sheets ("Copy address").
class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      disabledBackgroundColor: const Color(0xFF2A2A2C),
      disabledForegroundColor: const Color(0xFF6A6A6E),
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 19),
            label: Text(label),
          );
  }
}
