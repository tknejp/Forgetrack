import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../logging/app_log.dart';

/// Listens to device connectivity and toggles Firestore's network so the
/// SDK doesn't burn battery retrying gRPC streams when there is no usable
/// network (Android Doze, airplane mode, dead Wi-Fi, …).
///
/// While "offline", Firestore still serves cached reads and queues writes;
/// when connectivity returns we re-enable the network and Firestore syncs.
class FirestoreNetworkGate {
  FirestoreNetworkGate({
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _online;

  Future<void> start() async {
    if (_subscription != null) return;

    AppLog.sync.info('FirestoreNetworkGate starting');

    final initial = await _connectivity.checkConnectivity();
    AppLog.sync.info('Initial connectivity', payload: initial);
    await _apply(_isOnline(initial));

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => unawaited(_apply(_isOnline(results))),
      onError: (Object error, StackTrace stackTrace) {
        AppLog.sync.warn(
          'Connectivity stream error',
          payload: error,
        );
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _apply(bool online) async {
    if (_online == online) return;
    _online = online;
    try {
      if (online) {
        await _firestore.enableNetwork();
        AppLog.sync.info('Firestore network enabled');
      } else {
        await _firestore.disableNetwork();
        AppLog.sync.info('Firestore network disabled (offline)');
      }
    } catch (error, stackTrace) {
      AppLog.sync.warn(
        'Firestore network toggle failed',
        payload: error,
      );
      AppLog.sync.error(
        'Firestore network toggle details',
        err: error,
        stackTrace: stackTrace,
      );
    }
  }
}
