import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/catalog/engine_catalog_context.dart';
import '../domain/models/engine_evaluation_input.dart';
import '../domain/models/progression_resolution_reason.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'progression_engine.dart';

/// Riverpod-style ChangeNotifier wrapper around [ProgressionEngine].
/// Phase 6 foundation: exposes the canonical [evaluate] / [claim]
/// surface plus state caching so UI consumers can read the latest
/// result without invoking the engine themselves.
///
/// Source plumbing (FitnessProvider / GoalsProvider /
/// KalorickeTabulkyProvider → EngineEvaluationInput) is intentionally
/// not wired here yet; the provider exposes `evaluateWith(input,
/// context)` so a future binder (Phase 6 finish) can build inputs
/// from live sources and call this provider on every relevant change.
///
/// During coexistence the legacy `ProgressionProvider` keeps driving
/// the live UI; this provider runs alongside, populated by devtools
/// or explicit calls until the migration moves consumers over.
class ProgressionEngineProvider extends ChangeNotifier {
  ProgressionEngineProvider({
    required ProgressionEngine engine,
    required ProgressionEngineRepository repository,
  })  : _engine = engine,
        _repository = repository {
    unawaited(_hydrate());
  }

  final ProgressionEngine _engine;
  final ProgressionEngineRepository _repository;

  ProgressionResolutionResult? _lastResult;
  LedgerSnapshot? _ledger;
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _error;

  final List<ProgressionResolutionResult> _pendingCelebrations = [];

  bool get isLoading => _isLoading;
  bool get isEvaluating => _isEvaluating;
  String? get error => _error;
  ProgressionResolutionResult? get lastResult => _lastResult;
  LedgerSnapshot? get ledger => _ledger;

  /// Resolution results that have not yet been consumed by the
  /// celebration overlay host. UI dequeues with [takePendingCelebration].
  List<ProgressionResolutionResult> get pendingCelebrations =>
      List.unmodifiable(_pendingCelebrations);

  ProgressionResolutionResult? takePendingCelebration() {
    if (_pendingCelebrations.isEmpty) return null;
    return _pendingCelebrations.removeAt(0);
  }

  /// Run one evaluation pass with explicit input + context. Phase 6
  /// finish will wrap this with a `bind()` that reads live sources;
  /// today devtools / tests call this directly.
  Future<ProgressionResolutionResult?> evaluateWith({
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
    ProgressionResolutionReason reason =
        ProgressionResolutionReason.liveUpdate,
  }) async {
    if (_isEvaluating) return null;
    _isEvaluating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _engine.evaluate(
        input: input,
        catalogContext: catalogContext,
        reason: reason,
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isEvaluating = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProgressionResolutionResult?> claimNode({
    required String nodeId,
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
  }) async {
    if (_isEvaluating) return null;
    _isEvaluating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _engine.claim(
        nodeId: nodeId,
        input: input,
        catalogContext: catalogContext,
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  /// Devtools — wipe the local ledger. No-op when the bound
  /// repository is not the local Isar variant (e.g. cloud overlay
  /// without a local fallback).
  Future<void> devToolsWipeLedger() async {
    final repo = _repository;
    if (repo is! ProgressionEngineLocalRepository) return;
    _isEvaluating = true;
    notifyListeners();
    try {
      await repo.wipeAll();
      _lastResult = null;
      _pendingCelebrations.clear();
      _ledger = await _repository.loadLedger();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  Future<void> _hydrate() async {
    try {
      _ledger = await _repository.loadLedger();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
