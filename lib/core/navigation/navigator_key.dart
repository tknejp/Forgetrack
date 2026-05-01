import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Hodnota != null signalizuje MainShell, aby přepnul na daný tab.
/// Po přepnutí musí MainShell hodnotu vynulovat.
final pendingTabSwitch = ValueNotifier<int?>(null);
