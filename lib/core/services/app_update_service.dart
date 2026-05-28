import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../build_config.dart';
import '../logging/app_log.dart';
import '../navigation/navigator_key.dart';

/// DIY in-app updater — only active on the `internal` flavor (see
/// [BuildConfig.isInternal]). On `dev` / `prod` every entry point is a
/// no-op so the same Dart code compiles for all flavors.
///
/// Flow:
///   1. [initialize] subscribes the device to the
///      `forgetrack-internal-builds` FCM topic so testers get a push
///      whenever `scripts/release.ps1` uploads a new build.
///   2. [checkForUpdate] (called from `ForgetrackApp.didChangeAppLifecycleState`
///      resumed and from FCM push tap) reads the Firestore manifest doc
///      `app_config/latest_internal`, compares its `buildNumber` against
///      the running build, and — if newer — surfaces an in-app dialog.
///   3. On user accept the APK is streamed from Firebase Storage into the
///      app cache (with a progress indicator), then handed to the
///      `forgetrack/app_update` Kotlin channel which fires the system
///      PackageInstaller intent.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService._();

  static final instance = AppUpdateService._();

  /// FCM broadcast topic name. Mirrored in `scripts/release.ps1` —
  /// keep the two literals in sync.
  static const fcmTopic = 'forgetrack-internal-builds';

  /// Firestore doc that release.ps1 writes after a successful upload.
  static const _manifestDocPath = 'app_config/latest_internal';

  static const _platformChannel = MethodChannel('forgetrack/app_update');

  bool _initialized = false;
  bool _checkInFlight = false;

  UpdateStatus _status = UpdateStatus.idle;
  UpdateStatus get status => _status;

  AppUpdateInfo? _availableUpdate;
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String? _lastError;
  String? get lastError => _lastError;

  /// Subscribe to the FCM topic. Safe to call repeatedly; subsequent calls
  /// are no-ops. On non-internal flavors the method returns immediately.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!BuildConfig.isInternal) {
      AppLog.update.debug(
        'AppUpdateService: skipped initialize (flavor=${BuildConfig.flavor.name})',
      );
      return;
    }

    AppLog.update.info('AppUpdateService: initialize start');

    try {
      await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
      AppLog.update.success(
        'AppUpdateService: subscribed to FCM topic "$fcmTopic"',
      );
    } catch (e, st) {
      AppLog.update.error(
        'AppUpdateService: subscribeToTopic failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Poll the Firestore manifest. If a newer build is available and we are
  /// not already mid-flow, surface the in-app dialog via [navigatorKey].
  Future<void> checkForUpdate() async {
    if (!BuildConfig.isInternal) return;
    if (_checkInFlight) {
      AppLog.update.debug('AppUpdateService: check already in flight, skipping');
      return;
    }
    if (_status == UpdateStatus.downloading ||
        _status == UpdateStatus.installing) {
      AppLog.update.debug(
        'AppUpdateService: skipping check, status=${_status.name}',
      );
      return;
    }

    _checkInFlight = true;
    _setStatus(UpdateStatus.checking);

    try {
      final remote = await _readRemoteManifest();
      if (remote == null) {
        _setStatus(UpdateStatus.idle);
        return;
      }

      final current = await _currentBuildNumber();
      if (remote.buildNumber <= current) {
        AppLog.update.info(
          'AppUpdateService: no newer build '
          '(remote=${remote.buildNumber} <= local=$current)',
        );
        _setStatus(UpdateStatus.idle);
        return;
      }

      AppLog.update.info(
        'AppUpdateService: update available '
        '${remote.version}+${remote.buildNumber} (local=$current)',
      );
      _availableUpdate = remote;
      _setStatus(UpdateStatus.available);

      _showUpdateDialog();
    } catch (e, st) {
      AppLog.update.error(
        'AppUpdateService: checkForUpdate failed',
        err: e,
        stackTrace: st,
      );
      _setStatus(UpdateStatus.idle);
    } finally {
      _checkInFlight = false;
    }
  }

  /// Download + install the available update. Routes back to permission
  /// settings if the user has not granted REQUEST_INSTALL_PACKAGES yet.
  Future<void> downloadAndInstall() async {
    final remote = _availableUpdate;
    if (remote == null) return;

    final canInstall = await _platformChannel
        .invokeMethod<bool>('canRequestInstallPackages');
    if (canInstall != true) {
      AppLog.update.warn(
        'AppUpdateService: REQUEST_INSTALL_PACKAGES not granted, '
        'routing to settings',
      );
      await _platformChannel.invokeMethod<void>('openInstallPermissionSettings');
      return;
    }

    _setStatus(UpdateStatus.downloading);
    _downloadProgress = 0;
    _lastError = null;

    try {
      final apk = await _downloadApk(remote);
      _setStatus(UpdateStatus.installing);
      await _platformChannel.invokeMethod<void>(
        'installApk',
        <String, dynamic>{'path': apk.path},
      );
      AppLog.update.success(
        'AppUpdateService: install intent fired for ${apk.path}',
      );
    } catch (e, st) {
      AppLog.update.error(
        'AppUpdateService: downloadAndInstall failed',
        err: e,
        stackTrace: st,
      );
      _lastError = e.toString();
      _setStatus(UpdateStatus.available);
    }
  }

  Future<AppUpdateInfo?> _readRemoteManifest() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .doc(_manifestDocPath)
          .get(const GetOptions(source: Source.server));
      if (!snapshot.exists) {
        AppLog.update.debug('AppUpdateService: manifest doc missing');
        return null;
      }
      final data = snapshot.data();
      if (data == null) return null;
      return AppUpdateInfo.fromFirestore(data);
    } catch (e, st) {
      AppLog.update.warn(
        'AppUpdateService: manifest read failed',
        payload: e,
      );
      AppLog.update.debug('AppUpdateService: stack trace', payload: st);
      return null;
    }
  }

  Future<int> _currentBuildNumber() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  Future<File> _downloadApk(AppUpdateInfo remote) async {
    final cacheDir = await getApplicationCacheDirectory();
    final updatesDir = Directory('${cacheDir.path}/internal_updates');
    await updatesDir.create(recursive: true);

    // Hygiene: drop any APKs lingering from earlier downloads so we don't
    // accumulate megabytes of stale binaries in app cache.
    for (final entry in updatesDir.listSync()) {
      if (entry is File && entry.path.endsWith('.apk')) {
        try {
          await entry.delete();
        } catch (_) {/* tolerate */}
      }
    }

    final target = File(
      '${updatesDir.path}/forgetrack-${remote.version}-${remote.buildNumber}.apk',
    );

    final ref = FirebaseStorage.instance.ref(remote.apkStoragePath);
    final task = ref.writeToFile(target);

    final completer = Completer<File>();
    final sub = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        _downloadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      }
    });

    try {
      await task;
      _downloadProgress = 1.0;
      notifyListeners();
      AppLog.update.success(
        'AppUpdateService: downloaded ${remote.apkStoragePath} '
        '→ ${target.path} (${await target.length()} bytes)',
      );
      completer.complete(target);
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      await sub.cancel();
    }

    return completer.future;
  }

  void _setStatus(UpdateStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  void _showUpdateDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      AppLog.update.warn(
        'AppUpdateService: navigatorKey context not ready, dialog skipped — '
        'next resumed event will retry',
      );
      return;
    }
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(service: this),
    );
  }
}

enum UpdateStatus { idle, checking, available, downloading, installing }

@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkStoragePath,
    this.notes,
  });

  final String version;
  final int buildNumber;
  final String apkStoragePath;
  final String? notes;

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> data) {
    return AppUpdateInfo(
      version: data['version'] as String? ?? '',
      buildNumber: (data['buildNumber'] as num?)?.toInt() ?? 0,
      apkStoragePath: data['apkStoragePath'] as String? ?? '',
      notes: data['notes'] as String?,
    );
  }
}

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.service});

  final AppUpdateService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final remote = service.availableUpdate;
        final status = service.status;

        return AlertDialog(
          icon: Icon(
            Icons.system_update_alt,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Nová verze Forgetracku'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (remote != null)
                  Text(
                    'Verze ${remote.version}  ·  build ${remote.buildNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (remote?.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: Markdown(
                          data: remote!.notes!,
                          shrinkWrap: true,
                          selectable: true,
                          padding: const EdgeInsets.only(right: 8),
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyMedium,
                            h1: theme.textTheme.titleLarge,
                            h2: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            h3: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (status == UpdateStatus.downloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: service.downloadProgress),
                  const SizedBox(height: 6),
                  Text(
                    'Stahuji… ${(service.downloadProgress * 100).round()} %',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (status == UpdateStatus.installing) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Připravuji instalaci…',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ] else if (service.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Chyba: ${service.lastError}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (status == UpdateStatus.available ||
                status == UpdateStatus.idle) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Později'),
              ),
              FilledButton.icon(
                onPressed: () {
                  unawaited(service.downloadAndInstall());
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Stáhnout a nainstalovat'),
              ),
            ] else if (status == UpdateStatus.installing) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zavřít'),
              ),
            ],
          ],
        );
      },
    );
  }
}
