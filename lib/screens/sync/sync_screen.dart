import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../models/sync_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../services/google_auth_service.dart';
import '../../services/sheets_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _sheetsService = SheetsService();
  SyncRecord? _lastSync;
  bool _syncing = false;

  Future<void> _handleSignIn() async {
    debugPrint('[SyncScreen] _handleSignIn: start');
    await context.read<AuthProvider>().signIn();
    if (!mounted) return;
    final error = context.read<AuthProvider>().error;
    if (error != null) {
      debugPrint('[SyncScreen] _handleSignIn: error=$error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Přihlášení se nezdařilo: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      debugPrint('[SyncScreen] _handleSignIn: success');
    }
  }

  Future<void> _sync() async {
    debugPrint('[SyncScreen] _sync: start');
    // Načti data z providerů PŘED jakýmkoliv await (bezpečné použití BuildContext)
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSignedIn) {
      debugPrint('[SyncScreen] _sync: not signed in, triggering sign-in');
      await authProvider.signIn();
      if (!mounted) return;
      if (!context.read<AuthProvider>().isSignedIn) {
        final error = context.read<AuthProvider>().error;
        debugPrint('[SyncScreen] _sync: sign-in failed, error=$error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error != null
                  ? 'Přihlášení se nezdařilo: $error'
                  : 'Pro synchronizaci je nutné přihlášení.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    // Serializuj data před async mezerou
    final stepsRows = context
        .read<FitnessProvider>()
        .stepsHistory
        .map((s) => s.toSheetRow())
        .toList();
    final activityRows = context
        .read<FitnessProvider>()
        .activities
        .map((a) => a.toSheetRow())
        .toList();
    final calorieRows = context
        .read<CalorieProvider>()
        .log
        .map((e) => e.toSheetRow())
        .toList();

    debugPrint('[SyncScreen] _sync: rows to upload — steps=${stepsRows.length}, activities=${activityRows.length}, calories=${calorieRows.length}');

    setState(() => _syncing = true);

    try {
      debugPrint('[SyncScreen] _sync: fetching auth client');
      final client = await GoogleAuthService.instance.getAuthClient();
      if (!mounted) return;
      if (client == null) throw Exception('Nepodařilo se získat auth token.');
      debugPrint('[SyncScreen] _sync: auth client ok');

      _sheetsService.initialize(client);

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      String? spreadsheetId = prefs.getString(AppConstants.prefSpreadsheetId);
      if (spreadsheetId == null) {
        debugPrint('[SyncScreen] _sync: no spreadsheet found, creating new one');
        spreadsheetId = await _sheetsService.createSpreadsheet();
        await prefs.setString(AppConstants.prefSpreadsheetId, spreadsheetId);
        debugPrint('[SyncScreen] _sync: spreadsheet created id=$spreadsheetId');
      } else {
        debugPrint('[SyncScreen] _sync: using existing spreadsheet id=$spreadsheetId');
      }

      int rows = 0;

      if (stepsRows.isNotEmpty) {
        debugPrint('[SyncScreen] _sync: appending ${stepsRows.length} steps rows');
        await _sheetsService.appendRows(
          spreadsheetId: spreadsheetId,
          sheetName: AppConstants.stepsSheet,
          rows: stepsRows,
        );
        rows += stepsRows.length;
      }

      if (activityRows.isNotEmpty) {
        debugPrint('[SyncScreen] _sync: appending ${activityRows.length} activity rows');
        await _sheetsService.appendRows(
          spreadsheetId: spreadsheetId,
          sheetName: AppConstants.activitiesSheet,
          rows: activityRows,
        );
        rows += activityRows.length;
      }

      if (calorieRows.isNotEmpty) {
        debugPrint('[SyncScreen] _sync: appending ${calorieRows.length} calorie rows');
        await _sheetsService.appendRows(
          spreadsheetId: spreadsheetId,
          sheetName: AppConstants.caloriesSheet,
          rows: calorieRows,
        );
        rows += calorieRows.length;
      }

      debugPrint('[SyncScreen] _sync: done, total rows=$rows');
      if (!mounted) return;
      setState(() {
        _lastSync = SyncRecord(
          timestamp: DateTime.now(),
          status: SyncStatus.success,
          rowsSynced: rows,
        );
      });
    } catch (e, st) {
      debugPrint('[SyncScreen] _sync: error=$e\n$st');
      if (!mounted) return;
      setState(() {
        _lastSync = SyncRecord(
          timestamp: DateTime.now(),
          status: SyncStatus.error,
          errorMessage: e.toString(),
        );
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sync do Google Sheets')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Google účet ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: auth.isSignedIn
                    ? Row(
                        children: [
                          const Icon(Icons.account_circle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.user!.displayName ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(auth.user!.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          ),
                          TextButton(
                              onPressed: auth.signOut,
                              child: const Text('Odhlásit')),
                        ],
                      )
                    : Column(
                        children: [
                          const Text(
                              'Pro synchronizaci se přihlas přes Google.'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: auth.isLoading ? null : _handleSignIn,
                            icon: const Icon(Icons.login),
                            label: const Text('Přihlásit se přes Google'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Co se synchronizuje ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bude synchronizováno',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _SyncItem(
                        icon: Icons.directions_walk,
                        label: 'Kroky (posledních 7 dní)',
                        count: context.watch<FitnessProvider>().stepsHistory.length),
                    _SyncItem(
                        icon: Icons.fitness_center,
                        label: 'Aktivity',
                        count: context.watch<FitnessProvider>().activities.length),
                    _SyncItem(
                        icon: Icons.restaurant,
                        label: 'Kalorické záznamy',
                        count: context.watch<CalorieProvider>().log.length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Sync tlačítko ---
            FilledButton.icon(
              onPressed: (_syncing || !auth.isSignedIn) ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_syncing ? 'Synchronizuji…' : 'Synchronizovat'),
            ),

            // --- Výsledek ---
            if (_lastSync != null) ...[
              const SizedBox(height: 20),
              _SyncResultBanner(record: _lastSync!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SyncItem(
      {required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: Chip(label: Text('$count')),
    );
  }
}

class _SyncResultBanner extends StatelessWidget {
  final SyncRecord record;

  const _SyncResultBanner({required this.record});

  @override
  Widget build(BuildContext context) {
    final isOk = record.isSuccess;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isOk ? Icons.check_circle : Icons.error_outline,
              color: isOk ? cs.onPrimaryContainer : cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOk
                  ? 'Synchronizováno ${record.rowsSynced} řádků.'
                  : record.errorMessage ?? 'Neznámá chyba.',
              style: TextStyle(
                  color: isOk ? cs.onPrimaryContainer : cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
