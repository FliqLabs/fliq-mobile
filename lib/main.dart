import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/account_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads the saved session (fast, on the phone) before the first screen.
  await AccountStore.instance.start();
  runApp(const FliqApp());
}
