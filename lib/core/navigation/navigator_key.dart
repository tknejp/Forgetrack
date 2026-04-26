import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Hodnota != null signalizuje FtMainShell, aby přepnul na daný tab.
/// Po přepnutí musí FtMainShell hodnotu vynulovat.
final pendingTabSwitch = ValueNotifier<int?>(null);
