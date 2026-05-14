import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_log.dart';

/// Lightweight ChangeNotifier mirror of the system connectivity state.
/// Exposes a single [isOnline] boolean so widgets can react to network
/// availability — used by the home overview to surface an offline banner
/// and to suppress data-source "connect" prompts that can't succeed
/// without a working connection.
///
/// Defaults to `true` so the UI doesn't flash an offline banner on cold
/// start before the initial connectivity check resolves.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _initialized = false;

  bool get isOnline => _isOnline;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_subscription != null) return;

    try {
      final initial = await _connectivity.checkConnectivity();
      _setOnline(_compute(initial));
      AppLog.app.info('ConnectivityProvider initial', payload: initial);
    } catch (e) {
      AppLog.app
          .warn('ConnectivityProvider initial check failed', payload: '$e');
    }

    _initialized = true;
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _setOnline(_compute(results)),
      onError: (Object e) {
        AppLog.app.warn('Connectivity stream error', payload: '$e');
      },
    );
  }

  bool _compute(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    AppLog.app.info('Connectivity changed', payload: 'online=$value');
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
