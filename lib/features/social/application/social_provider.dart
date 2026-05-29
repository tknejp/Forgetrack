import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/result/result.dart';
import '../../auth/application/auth_provider.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart'
    show Achievement;
import '../data/social_firebase_bootstrap.dart';
import '../data/social_firebase_session.dart';
import '../domain/social_models.dart';
import '../domain/social_presence.dart';
import '../domain/social_presence_repository.dart';
import 'profile_photo_precache.dart';
import 'social_profile_projection.dart';

class SocialProvider extends ChangeNotifier {
  SocialProvider({
    required SocialPresenceRepository repository,
    required SocialFirebaseSession session,
    required SocialBackendState backendState,
  })  : _repository = repository,
        _session = session,
        _backendState = backendState {
    _profileProjection = SocialProfileProjection(
      repository: repository,
      inputsGetter: _collectProfileInputs,
    );
  }

  final SocialPresenceRepository _repository;
  final SocialFirebaseSession _session;
  final SocialBackendState _backendState;
  late final SocialProfileProjection _profileProjection;

  AuthProvider? _authProvider;
  ProgressionEngineProvider? _progressionProvider;
  CosmeticsProvider? _cosmeticsProvider;
  FitnessProvider? _fitnessProvider;
  KalorickeTabulkyProvider? _nutritionProvider;

  StreamSubscription<List<SocialFriendRequest>>? _incomingRequestsSubscription;
  StreamSubscription<List<SocialFriendRequest>>? _outgoingRequestsSubscription;
  StreamSubscription<List<SocialFriendship>>? _friendshipsSubscription;
  StreamSubscription<List<SocialUserProfile>>? _friendProfilesSubscription;
  StreamSubscription<List<SocialAchievementShare>>? _recentSharesSubscription;
  StreamSubscription<List<SocialNotification>>? _notificationsSubscription;

  List<SocialFriendRequest> _incomingRequests = const [];
  List<SocialFriendRequest> _outgoingRequests = const [];
  List<SocialFriendship> _friendships = const [];
  List<SocialUserProfile> _friends = const [];
  List<SocialAchievementShare> _recentShares = const [];
  List<SocialUserProfile> _searchResults = const [];
  List<SocialNotification> _notifications = const [];

  bool _isReconcilingSession = false;
  bool _reconcileQueued = false;
  bool _isSyncingProfile = false;
  bool _profileSyncQueued = false;
  bool _isSearching = false;
  bool _isReady = false;

  String? _activeUid;
  String? _error;
  // R.4: typed counterpart to [_error]. UI surfaces continue to read
  // [error] for the existing Czech message strings; consumers that
  // want to pattern-match on severity (transient retry vs permanent
  // banner, scope-specific PermissionError → re-auth prompt) read
  // [lastError] instead.
  AppError? _lastError;
  String? _lastAuthSignature;
  String? _lastProfileSignature;
  String _friendIdsSignature = '';

  // Stream diff tracking.
  // First stream emission is used only as seed, so existing data does not trigger
  // local side effects after app startup/resubscribe.
  bool _requestStreamSeeded = false;
  bool _outgoingRequestStreamSeeded = false;
  bool _notificationStreamSeeded = false;

  Set<String> _knownRequestIds = {};
  Set<String> _knownPendingOutgoingIds = {};
  Set<String> _knownNotificationIds = {};

  bool get backendReady => _backendState.isReady;
  String get backendMessage => _backendState.message;
  bool get isReady => _isReady;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// Typed counterpart to [error]. R.4 (2026-05-19): widgets that want
  /// transient/permanent classification or scope-specific recovery
  /// (re-auth on [PermissionError], re-login banner on KT-equivalent
  /// transient [NetworkError]) read this; the legacy Czech message
  /// surface continues to flow through [error].
  AppError? get lastError => _lastError;

  String? get currentUid => _activeUid;

  List<SocialFriendRequest> get incomingRequests =>
      _incomingRequests.where((r) => r.isPending).toList();

  List<SocialFriendRequest> get outgoingRequests =>
      _outgoingRequests.where((r) => r.isPending).toList();

  List<SocialFriendship> get friendships => _friendships;
  List<SocialUserProfile> get friends => _friends;
  List<SocialAchievementShare> get recentShares => _recentShares;
  List<SocialUserProfile> get searchResults => _searchResults;
  List<SocialNotification> get notifications => _notifications;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;

  /// Aggregated read view of every social state surface for the
  /// signed-in user. Phase 17 of the domain refactor introduces this
  /// as the forward-compatible read shape — widgets can incrementally
  /// migrate from per-getter reads (`socialProvider.friendships`,
  /// `.recentShares`, `.notifications`) to a single
  /// `socialProvider.presence` read. Phase 19 will sweep widgets.
  ///
  /// `ownProfile` is null today because the provider doesn't track
  /// the signed-in user's published profile snapshot locally — it
  /// only *writes* it (`publishProfile`). A follow-up will hydrate
  /// own profile via `watchProfilesByIds([_activeUid])` so the
  /// aggregate can drive the header without an extra round-trip.
  SocialPresence get presence {
    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return SocialPresence.anonymous;
    return SocialPresence(
      uid: uid,
      ownProfile: null,
      incomingRequests: incomingRequests,
      outgoingRequests: outgoingRequests,
      friendships: _friendships,
      friends: _friends,
      recentShares: _recentShares,
      notifications: _notifications,
    );
  }

  void bind({
    required AuthProvider authProvider,
    required ProgressionEngineProvider progressionProvider,
    CosmeticsProvider? cosmeticsProvider,
    FitnessProvider? fitnessProvider,
    KalorickeTabulkyProvider? nutritionProvider,
  }) {
    _authProvider = authProvider;
    _progressionProvider = progressionProvider;
    _cosmeticsProvider = cosmeticsProvider;
    _fitnessProvider = fitnessProvider;
    _nutritionProvider = nutritionProvider;

    final authSignature = _buildAuthSignature(authProvider);
    if (authSignature != _lastAuthSignature) {
      _lastAuthSignature = authSignature;
      // Warm the image cache with the Auth photoUrl as soon as the user
      // is known. This URL is the hero header's fallback before the
      // Firestore profile arrives — precaching here means the avatar
      // paints synchronously on first navigate to the home screen.
      precacheProfilePhoto(authProvider.user?.photoUrl);
      unawaited(_reconcileSession());
    }

    unawaited(_syncProfileIfNeeded());
  }

  Future<void> searchUsers(String query) async {
    final uid = _activeUid;

    if (!backendReady || uid == null) {
      _searchResults = const [];
      notifyListeners();
      return;
    }

    final normalized = normalizeSocialHandle(query);
    if (normalized.isEmpty) {
      _searchResults = const [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _clearError();
    notifyListeners();

    final result = await _repository.searchProfilesByHandle(
      normalized,
      excludeUid: uid,
    );
    switch (result) {
      case Success(value: final profiles):
        _searchResults = profiles;
      case Failure(error: final e):
        _searchResults = const [];
        _recordAppError('searchUsers', e);
    }
    _isSearching = false;
    notifyListeners();
  }

  void clearSearchResults() {
    if (_searchResults.isEmpty) return;

    _searchResults = const [];
    notifyListeners();
  }

  /// Friends whose handle or display name match [query] — the "Friends"
  /// section of the search sheet. [query] is normalised the same way
  /// [searchUsers] normalises before hitting Firestore, so a raw text-
  /// field value can be passed straight in. Empty query → no matches.
  ///
  /// Lives here, not in the search sheet, so the widget stays a pure
  /// view: filtering provider-owned collections is application logic
  /// (test/lint/production_scan_test.dart `widget-no-logic`).
  List<SocialUserProfile> friendMatches(String query) {
    final normalised = normalizeSocialHandle(query);
    if (normalised.isEmpty) return const [];
    return _friends
        .where((f) => _profileMatchesQuery(f, normalised))
        .toList(growable: false);
  }

  /// Live [searchResults] minus anyone who is already a friend — the
  /// "People" section of the search sheet. Empty query → empty list.
  List<SocialUserProfile> nonFriendSearchResults(String query) {
    final normalised = normalizeSocialHandle(query);
    if (normalised.isEmpty) return const [];
    final friendIds = <String>{for (final f in _friends) f.uid};
    return _searchResults
        .where((p) => !friendIds.contains(p.uid))
        .toList(growable: false);
  }

  bool _profileMatchesQuery(SocialUserProfile profile, String normalisedQuery) {
    if (profile.handle.contains(normalisedQuery)) return true;
    final normalisedName = normalizeSocialHandle(profile.displayName);
    return normalisedName.contains(normalisedQuery);
  }

  Future<String?> updateCurrentHandle(String desiredHandle) async {
    final uid = _activeUid;
    if (uid == null) return null;

    final result = await _repository.updateProfileHandle(
      uid: uid,
      desiredHandle: desiredHandle,
    );
    switch (result) {
      case Success(value: final handle):
        _lastProfileSignature = null;
        _clearError();
        notifyListeners();
        return handle;
      case Failure(error: final e):
        _recordAppError('updateCurrentHandle', e);
        notifyListeners();
        return null;
    }
  }

  Future<void> sendFriendRequest(String toUid) async {
    final uid = _activeUid;
    if (uid == null) return;

    final result =
        await _repository.sendFriendRequest(fromUid: uid, toUid: toUid);
    switch (result) {
      case Success():
        _clearError();
        clearSearchResults();
      case Failure(error: final e):
        _recordAppError('sendFriendRequest', e);
    }

    notifyListeners();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final result =
        await _repository.acceptFriendRequest(requestId: requestId);
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('acceptFriendRequest', e);
    }

    notifyListeners();
  }

  Future<void> declineFriendRequest(String requestId) async {
    final result =
        await _repository.declineFriendRequest(requestId: requestId);
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('declineFriendRequest', e);
    }

    notifyListeners();
  }

  Future<SocialUserProfile?> fetchProfileById(String uid) async {
    final result = await _repository.fetchProfilesByIds([uid]);
    return switch (result) {
      Success(value: final profiles) => profiles.firstOrNull,
      // Surface the failure on `lastError` so the screen can react;
      // collapse to null so the existing caller keeps its empty-state
      // rendering.
      Failure(error: final e) =>
        () {
          _recordAppError('fetchProfileById', e);
          notifyListeners();
          return null;
        }(),
    };
  }

  Future<List<SocialUnlockedAchievement>> fetchFriendAchievements(
    String uid,
  ) async {
    final result = await _repository.fetchEngineNodeCompletions(uid);
    return switch (result) {
      Success(value: final completions) =>
        _buildUnlockedAchievementsFromRemote(completions),
      Failure(error: final e) =>
        () {
          _recordAppError('fetchFriendAchievements', e);
          notifyListeners();
          return const <SocialUnlockedAchievement>[];
        }(),
    };
  }

  Stream<SocialUserProfile?> watchProfileById(String uid) {
    return _repository
        .watchProfilesByIds([uid]).map((profiles) => profiles.firstOrNull);
  }

  Stream<List<SocialUnlockedAchievement>> watchFriendAchievements(String uid) {
    return _repository
        .watchEngineNodeCompletions(uid)
        .map(_buildUnlockedAchievementsFromRemote);
  }

  /// Maps raw V2 ledger completions read from `users/{uid}/engineNodeCompletions`
  /// into the friend-view achievement list.
  ///
  /// Filters to [Achievement] ids — quest / milestone completions are
  /// in the same collection but live elsewhere in the UI. Per-node we
  /// keep the earliest completion timestamp (engine ledger may have
  /// multiple period rows for repeating nodes; achievements are
  /// once-and-done so this is mostly a guard).
  ///
  /// Catalog metadata (rarity, domain) comes from the LOCAL catalog —
  /// every device runs the same compiled app version, so the catalog
  /// is the right source even for someone else's data.
  List<SocialUnlockedAchievement> _buildUnlockedAchievementsFromRemote(
    List<RemoteEngineNodeCompletion> completions,
  ) {
    if (completions.isEmpty) return const [];

    final earliestByNode = <String, DateTime>{};
    final nodes = <String, Achievement>{};
    for (final c in completions) {
      final def = ProgressionEntryCatalog.definitionForId(c.nodeId);
      if (def is! Achievement) continue;
      nodes[c.nodeId] = def;
      final existing = earliestByNode[c.nodeId];
      if (existing == null || c.completedAt.isBefore(existing)) {
        earliestByNode[c.nodeId] = c.completedAt;
      }
    }
    if (earliestByNode.isEmpty) return const [];

    final out = <SocialUnlockedAchievement>[
      for (final entry in earliestByNode.entries)
        SocialUnlockedAchievement(
          achievementId: entry.key,
          title: entry.key,
          description: '',
          rarity: nodes[entry.key]!.rarity,
          domain: _progressionProvider?.domainForNodeId(entry.key).name,
          unlockedAt: entry.value,
        ),
    ]..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return out;
  }

  Stream<List<SocialAchievementShare>> watchProfileShares(
    String uid, {
    int limit = 20,
  }) {
    return _repository.watchRecentAchievementShares(
      actorUids: [uid],
      limit: limit,
    );
  }

  Stream<List<SocialUserProfile>> watchFriendProfilesForUser(String uid) {
    if (!backendReady || uid.isEmpty) {
      return Stream<List<SocialUserProfile>>.value(const []);
    }

    return _repository.watchFriendships(uid: uid).asyncMap((friendships) async {
      final friendIds = friendships
          .map((friendship) => friendship.counterpartFor(uid))
          .where((friendUid) => friendUid.isNotEmpty && friendUid != uid)
          .toSet()
          .toList()
        ..sort();

      if (friendIds.isEmpty) return const <SocialUserProfile>[];
      final result = await _repository.fetchProfilesByIds(friendIds);
      return switch (result) {
        Success(value: final profiles) => profiles,
        // Stream consumer can't easily signal an error mid-flight;
        // record on `lastError` and emit empty so the UI continues to
        // render. The stream resubscribes when friendships change.
        Failure(error: final e) =>
          () {
            _recordAppError('watchFriendProfilesForUser', e);
            notifyListeners();
            return const <SocialUserProfile>[];
          }(),
      };
    });
  }

  Future<void> setCurrentAchievementPinned({
    required String achievementId,
    required bool pinned,
  }) async {
    final uid = _activeUid;
    if (uid == null) return;

    final result = await _repository.updatePinnedAchievement(
      uid: uid,
      achievementId: achievementId,
      pinned: pinned,
    );
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('setCurrentAchievementPinned', e);
    }

    notifyListeners();
  }

  /// Persists the signed-in user's stat-visibility override set. The
  /// editor widget on the profile screen calls this once on commit
  /// (not per-toggle) so the Firestore write is batched.
  Future<void> setCurrentStatVisibilityOverrides(
    Set<String> statVisibilityOverrides,
  ) async {
    final uid = _activeUid;
    if (uid == null) return;

    final result = await _repository.updateStatVisibilityOverrides(
      uid: uid,
      statVisibilityOverrides: statVisibilityOverrides,
    );
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('setCurrentStatVisibilityOverrides', e);
    }

    notifyListeners();
  }

  SocialAchievementShare? shareById(String id) {
    return _recentShares.where((s) => s.id == id).firstOrNull;
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = _activeUid;
    if (uid == null) {
      AppLog.social.debug('removeFriend skipped: no active uid');
      return;
    }

    AppLog.social.debug(
      'removeFriend',
      payload:
          'uid=$uid friendUid=$friendUid friendships=${_friendships.length}',
    );

    final friendship = _friendships
        .where(
          (f) => f.memberUids.contains(uid) && f.memberUids.contains(friendUid),
        )
        .firstOrNull;

    if (friendship == null) {
      AppLog.social.debug(
        'removeFriend: no friendship found',
        payload: 'uid=$uid friendUid=$friendUid',
      );

      throw StateError(
        'Přátelství nebylo nalezeno (friendships=${_friendships.length}).',
      );
    }

    final result = await _repository.removeFriend(friendshipId: friendship.id);
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('removeFriend', e);
    }

    notifyListeners();
  }

  bool isFriendWith(String uid) {
    final me = _activeUid;
    if (me == null) return false;

    return _friendships.any(
      (f) => f.memberUids.contains(me) && f.memberUids.contains(uid),
    );
  }

  String? getFriendshipId(String uid) {
    final me = _activeUid;
    if (me == null) return null;

    return _friendships
        .where((f) => f.memberUids.contains(me) && f.memberUids.contains(uid))
        .map((f) => f.id)
        .firstOrNull;
  }

  String? getPendingRequestTo(String uid) {
    return _outgoingRequests
        .where((r) => r.toUid == uid && r.isPending)
        .map((r) => r.id)
        .firstOrNull;
  }

  /// Pending friend request the signed-in user has received from
  /// [uid]. Returns the [SocialFriendRequest] so callers can wire
  /// accept / decline directly without a second lookup; null when
  /// there's no live incoming pending request from that user.
  ///
  /// Mirrors [getPendingRequestTo] from the opposite direction so
  /// "Add Friend" surfaces (profile screen, search results) can
  /// short-circuit to an Accept / Decline affordance instead of
  /// letting the player send a second request that would race against
  /// the one already in flight — see
  /// `lib/features/social/data/social_repository_firestore.dart`'s
  /// `sendFriendRequest` duplicate guard for why we can't fully de-
  /// duplicate at the data layer without widening the Firestore read
  /// rule.
  SocialFriendRequest? getIncomingRequestFrom(String uid) {
    return _incomingRequests
        .where((r) => r.fromUid == uid && r.isPending)
        .firstOrNull;
  }

  Future<void> shareAchievement(
    String achievementId, {
    String? message,
    String? resolvedTitle,
    String? resolvedDescription,
  }) async {
    final uid = _activeUid;
    final authProvider = _authProvider;
    final progressionProvider = _progressionProvider;

    if (uid == null ||
        authProvider?.user == null ||
        progressionProvider == null) {
      return;
    }

    final node = progressionProvider.nodeById(achievementId);
    final isUnlockedAchievement = node is Achievement &&
        progressionProvider.completedNodeIds.contains(achievementId);
    if (!isUnlockedAchievement) {
      _error = 'Achievement $achievementId is not unlocked yet.';
      notifyListeners();
      return;
    }
    final achievement = node;

    final user = authProvider!.user!;
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email.split('@').first;
    final actorSnapshot = await _buildCurrentActorSnapshot(
      uid: uid,
      fallbackDisplayName: displayName,
      fallbackPhotoUrl: user.photoUrl,
    );

    final share = SocialAchievementShare(
      id: '',
      actorUid: uid,
      achievementId: achievement.id,
      createdAt: DateTime.now(),
      message: message?.trim().isEmpty ?? true ? null : message!.trim(),
      visibility: SocialShareVisibility.friends,
      actorSnapshot: SocialAchievementActorSnapshot(
        displayName: actorSnapshot.displayName,
        photoUrl: actorSnapshot.photoUrl,
      ),
      achievementSnapshot: SocialAchievementSnapshot(
        title: resolvedTitle ?? achievement.id,
        description: resolvedDescription ?? '',
        rarity: achievement.rarity,
        domain: progressionProvider.domainForNodeId(achievement.id).name,
      ),
    );

    final result = await _repository.shareAchievement(share);
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('shareAchievement', e);
    }

    notifyListeners();
  }

  /// Deletes a previously-shared achievement post. Only the share's
  /// `actorUid` can delete it — callers must enforce ownership at the
  /// UI layer (the repository delegates the final check to Firestore
  /// rules).
  Future<void> deleteAchievementShare(String shareId) async {
    final result = await _repository.deleteAchievementShare(shareId: shareId);
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('deleteAchievementShare', e);
    }
    notifyListeners();
  }

  Future<void> addReaction(String shareId, String emoji) async {
    final uid = _activeUid;
    final authProvider = _authProvider;

    if (uid == null || authProvider?.user == null) return;

    final share = _recentShares.where((s) => s.id == shareId).firstOrNull;
    if (share == null) return;

    final isSelfReaction = share.actorUid == uid;

    if (isSelfReaction) {
      AppLog.social.debug(
        'addReaction: self reaction detected; repository must suppress notification',
        payload: 'shareId=$shareId uid=$uid emoji=$emoji',
      );
    }

    final user = authProvider!.user!;
    final actorName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email.split('@').first;
    final actorSnapshot = await _buildCurrentActorSnapshot(
      uid: uid,
      fallbackDisplayName: actorName,
      fallbackPhotoUrl: user.photoUrl,
    );

    final result = await _repository.addReaction(
      shareId: shareId,
      actorUid: uid,
      actorName: actorSnapshot.displayName,
      actorPhoto: actorSnapshot.photoUrl,
      emoji: emoji,
      shareOwnerUid: share.actorUid,
      achievementTitle: share.achievementSnapshot.title,
    );
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('addReaction', e);
    }

    notifyListeners();
  }

  Future<void> removeReaction(String shareId) async {
    final uid = _activeUid;
    if (uid == null) return;

    final share = _recentShares.where((s) => s.id == shareId).firstOrNull;
    if (share == null) return;

    final result = await _repository.removeReaction(
      shareId: shareId,
      actorUid: uid,
      shareOwnerUid: share.actorUid,
    );
    switch (result) {
      case Success():
        _clearError();
      case Failure(error: final e):
        _recordAppError('removeReaction', e);
    }

    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    final uid = _activeUid;
    if (uid == null) return;

    final result = await _repository.markNotificationsRead(uid);
    if (result case Failure(error: final e)) {
      _recordAppError('markNotificationsRead', e);
    }
  }

  /// Stamps the signed-in user's Firestore profile with an
  /// `onboardingCompleted` flag (dev-facing — surfaces in the Firestore
  /// console). Best-effort: a no-op when no user is bound (the user
  /// finished onboarding without signing in). Does not notify listeners
  /// — nothing in the UI renders off this flag.
  Future<void> markOnboardingCompleted() async {
    final uid = _activeUid;
    if (uid == null) return;

    final result = await _repository.markOnboardingCompleted(uid: uid);
    if (result case Failure(error: final e)) {
      _recordAppError('markOnboardingCompleted', e);
    }
  }

  /// One-shot read of the signed-in user's cloud `onboardingCompleted`
  /// flag. The onboarding flow uses this to detect a *returning* player
  /// on a fresh install / new device (one who already cleared the welcome
  /// flow elsewhere) so it can skip the race pick + welcome celebration
  /// and offer only a quick connection setup.
  ///
  /// Best-effort: returns false when no user is bound, the backend is
  /// disabled (empty list), the profile doc doesn't exist yet, or the
  /// read fails (offline). A false here just means "treat as new" — the
  /// onboarding flow corroborates with the restored cloud race, and the
  /// race-commit guard independently prevents clobbering an existing race.
  Future<bool> fetchOnboardingCompleted() async {
    final uid = _activeUid;
    if (uid == null) return false;

    final result = await _repository.fetchProfilesByIds([uid]);
    return switch (result) {
      Success(value: final profiles) =>
        profiles.firstOrNull?.onboardingCompleted ?? false,
      Failure() => false,
    };
  }

  Future<void> _reconcileSession() async {
    if (_isReconcilingSession) {
      _reconcileQueued = true;
      return;
    }

    _isReconcilingSession = true;

    try {
      final authProvider = _authProvider;

      if (!backendReady || authProvider == null || !authProvider.isSignedIn) {
        await _session.signOut();
        await _clearSessionState();
        return;
      }

      final user = authProvider.user;
      if (user == null) {
        await _clearSessionState();
        return;
      }

      await _session.ensureSignedInWithGoogle(user);

      final uid = user.id;
      final shouldResubscribe = _activeUid != uid;

      _activeUid = uid;
      _isReady = true;
      _clearError();

      if (shouldResubscribe) {
        AppLog.social.info('Subscribing social streams', payload: 'uid=$uid');
        await _subscribe(uid);
      }
    } catch (error, stackTrace) {
      await _clearSessionState();
      _recordError('reconcileSession', error, stackTrace);
    } finally {
      _isReconcilingSession = false;
      notifyListeners();
    }

    if (_reconcileQueued) {
      _reconcileQueued = false;
      unawaited(_reconcileSession());
      return;
    }

    unawaited(_syncProfileIfNeeded());
  }

  Future<void> _syncProfileIfNeeded() async {
    if (_isSyncingProfile) {
      _profileSyncQueued = true;
      return;
    }

    final payload = _profileProjection.buildPayload();
    if (payload == null) return;

    final signature = _buildProfileSignature(payload);
    if (signature == _lastProfileSignature) return;

    _isSyncingProfile = true;

    final result = await _repository.upsertProfile(payload);
    switch (result) {
      case Success():
        _lastProfileSignature = signature;
        _clearError();

        // Once the Firestore profile is the source of truth for the
        // hero header's photoUrl, prime the image cache with it so the
        // first widget mount renders without a placeholder frame.
        precacheProfilePhoto(payload.photoUrl);

        AppLog.social.debug(
          'Profile synced',
          payload: 'uid=${payload.uid} xp=${payload.stats.totalXp}',
        );
      case Failure(error: final e):
        _recordAppError('syncProfile', e);
    }
    _isSyncingProfile = false;
    notifyListeners();

    if (_profileSyncQueued) {
      _profileSyncQueued = false;
      unawaited(_syncProfileIfNeeded());
    }
  }

  /// Assemble the canonical inputs the [SocialProfileProjection]
  /// denormalises into a [SocialProfileSyncPayload].
  ///
  /// Returns null when the social session isn't ready to publish —
  /// the projection treats that as a no-op.
  SocialProfileInputs? _collectProfileInputs() {
    final authProvider = _authProvider;
    final progressionProvider = _progressionProvider;

    if (!backendReady ||
        !_isReady ||
        authProvider == null ||
        progressionProvider == null ||
        !authProvider.isSignedIn ||
        authProvider.user == null) {
      return null;
    }

    final user = authProvider.user!;
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email.split('@').first;
    final handle = buildDefaultSocialHandle(
      uid: user.id,
      email: user.email,
      displayName: user.displayName,
    );

    return SocialProfileInputs(
      uid: user.id,
      displayName: displayName,
      email: user.email,
      handle: handle,
      photoUrl: user.photoUrl,
      raceId: _cosmeticsProvider?.currentRaceId,
      socialEnabled: true,
      engine: progressionProvider,
      equippedCosmetics: _buildEquippedCosmeticsSnapshot(),
      fitness: _fitnessProvider,
      nutrition: _nutritionProvider,
      cosmetics: _cosmeticsProvider,
    );
  }

  SocialEquippedCosmetics _buildEquippedCosmeticsSnapshot() {
    final equipped = _cosmeticsProvider?.state?.equipped;
    if (equipped == null) return const SocialEquippedCosmetics.empty();
    return SocialEquippedCosmetics(
      frameId: equipped.frameId,
      relicId: equipped.relicId,
      backgroundId: equipped.backgroundId,
      emblemId: equipped.emblemId,
      companionId: equipped.companionId,
      titleFlairId: equipped.titleFlairId,
      mapEffectId: equipped.mapEffectId,
      skinId: equipped.skinId,
      bannerId: equipped.bannerId,
    );
  }

  String _buildAuthSignature(AuthProvider authProvider) {
    final user = authProvider.user;

    return [
      authProvider.sessionState.name,
      user?.id ?? '',
      user?.email ?? '',
    ].join('|');
  }

  String _buildProfileSignature(SocialProfileSyncPayload payload) {
    final unlockedIds = payload.unlockedAchievements
        .map(
          (a) => '${a.achievementId}@${a.unlockedAt.millisecondsSinceEpoch}',
        )
        .join(',');

    return [
      payload.uid,
      payload.displayName,
      payload.handle,
      payload.photoUrl ?? '',
      payload.raceId ?? '',
      payload.stats.level.toString(),
      payload.stats.totalXp.toString(),
      payload.stats.unlockedAchievementCount.toString(),
      payload.stats.grantedRewardCount.toString(),
      payload.stats.bestStepsStreak.toString(),
      payload.stats.bestNutritionStreak.toString(),
      payload.stats.stepsLifetime?.toString() ?? '',
      payload.stats.stepsAvg30d?.toString() ?? '',
      payload.stats.activeDays30d?.toString() ?? '',
      payload.stats.avgSleepMinutes7d?.toString() ?? '',
      payload.stats.avgBedtimeMinutes7d?.toString() ?? '',
      payload.stats.avgWakeMinutes7d?.toString() ?? '',
      payload.stats.avgDeepMinutes7d?.toString() ?? '',
      payload.stats.avgRemMinutes7d?.toString() ?? '',
      payload.stats.latestWeightKg?.toStringAsFixed(2) ?? '',
      payload.stats.latestBodyFatPct?.toStringAsFixed(2) ?? '',
      payload.stats.avgKcal7d?.round().toString() ?? '',
      payload.stats.avgProteinG7d?.round().toString() ?? '',
      payload.stats.avgFatG7d?.round().toString() ?? '',
      payload.stats.avgCarbsG7d?.round().toString() ?? '',
      payload.stats.cosmeticsUnlocked?.toString() ?? '',
      payload.equippedCosmetics.frameId ?? '',
      payload.equippedCosmetics.relicId ?? '',
      payload.equippedCosmetics.backgroundId ?? '',
      payload.equippedCosmetics.emblemId ?? '',
      payload.equippedCosmetics.companionId ?? '',
      payload.equippedCosmetics.titleFlairId ?? '',
      payload.equippedCosmetics.mapEffectId ?? '',
      payload.equippedCosmetics.skinId ?? '',
      unlockedIds,
    ].join('|');
  }

  Future<void> _subscribe(String uid) async {
    await _cancelSubscriptions();

    _resetStreamDiffState();

    _incomingRequestsSubscription =
        _repository.watchIncomingFriendRequests(uid: uid).listen(
      (requests) {
        final newPending = _diffIncomingRequests(requests);
        _incomingRequests = requests;

        if (newPending.isNotEmpty) {
          AppLog.social.info(
            'Incoming friend requests updated',
            payload:
                'new=${newPending.length} total=${requests.length} handledBy=FCM',
          );
        }

        notifyListeners();
      },
      onError: (error, stackTrace) {
        _recordError('watchIncomingFriendRequests', error, stackTrace);
      },
    );

    _outgoingRequestsSubscription =
        _repository.watchOutgoingFriendRequests(uid: uid).listen(
      (requests) {
        final newlyAccepted = _diffAcceptedOutgoing(requests);
        _outgoingRequests = requests;

        if (newlyAccepted.isNotEmpty) {
          AppLog.social.info(
            'Outgoing friend requests updated',
            payload:
                'accepted=${newlyAccepted.length} total=${requests.length} handledBy=FCM',
          );
        }

        notifyListeners();
      },
      onError: (error, stackTrace) {
        _recordError('watchOutgoingFriendRequests', error, stackTrace);
      },
    );

    _friendshipsSubscription = _repository.watchFriendships(uid: uid).listen(
      (friendships) {
        _friendships = friendships;
        notifyListeners();
        unawaited(_handleFriendshipsUpdated());
      },
      onError: (error, stackTrace) {
        _recordError('watchFriendships', error, stackTrace);
      },
    );

    _notificationsSubscription = _repository.watchNotifications(uid).listen(
      (notifications) {
        final newUnread = _diffNotifications(notifications);
        _notifications = notifications;

        if (newUnread.isNotEmpty) {
          AppLog.social.info(
            'Social notifications updated',
            payload:
                'new=${newUnread.length} total=${notifications.length} handledBy=FCM',
          );
        }

        notifyListeners();
      },
      onError: (error, stackTrace) {
        _recordError('watchNotifications', error, stackTrace);
      },
    );

    await _handleFriendshipsUpdated();
  }

  Future<void> _handleFriendshipsUpdated() async {
    final uid = _activeUid;
    if (uid == null) return;

    final friendIds = _friendships
        .map((friendship) => friendship.counterpartFor(uid))
        .where((friendUid) => friendUid != uid)
        .toSet()
        .toList()
      ..sort();

    final signature = friendIds.join('|');
    if (signature == _friendIdsSignature) return;

    _friendIdsSignature = signature;

    AppLog.social.debug(
      'Friend list changed',
      payload: 'friendCount=${friendIds.length}',
    );

    await _subscribeFriendProfiles(friendIds);
    await _subscribeRecentShares(friendIds);
  }

  Future<void> _subscribeFriendProfiles(List<String> friendIds) async {
    await _friendProfilesSubscription?.cancel();
    _friendProfilesSubscription = null;

    if (friendIds.isEmpty) {
      _friends = const [];
      notifyListeners();
      return;
    }

    _friendProfilesSubscription =
        _repository.watchProfilesByIds(friendIds).listen(
      (profiles) {
        _friends = profiles;
        _clearError();
        notifyListeners();
      },
      onError: (error, stackTrace) {
        _recordError('watchProfilesByIds', error, stackTrace);
      },
    );
  }

  Future<void> _subscribeRecentShares(List<String> friendIds) async {
    await _recentSharesSubscription?.cancel();
    _recentSharesSubscription = null;

    final uid = _activeUid;
    final actorUids = [
      if (uid != null) uid,
      ...friendIds,
    ];

    if (actorUids.isEmpty) {
      _recentShares = const [];
      notifyListeners();
      return;
    }

    _recentSharesSubscription =
        _repository.watchRecentAchievementShares(actorUids: actorUids).listen(
      (shares) {
        _recentShares = shares;
        _clearError();
        notifyListeners();
      },
      onError: (error, stackTrace) {
        _recordError('watchRecentAchievementShares', error, stackTrace);
      },
    );
  }

  Future<void> _clearSessionState() async {
    _activeUid = null;
    _isReady = false;
    _lastProfileSignature = null;
    _friendIdsSignature = '';

    _incomingRequests = const [];
    _outgoingRequests = const [];
    _friendships = const [];
    _friends = const [];
    _recentShares = const [];
    _searchResults = const [];
    _notifications = const [];

    _resetStreamDiffState();

    await _cancelSubscriptions();
  }

  void _resetStreamDiffState() {
    _requestStreamSeeded = false;
    _outgoingRequestStreamSeeded = false;
    _notificationStreamSeeded = false;

    _knownRequestIds = {};
    _knownPendingOutgoingIds = {};
    _knownNotificationIds = {};
  }

  List<SocialFriendRequest> _diffIncomingRequests(
    List<SocialFriendRequest> requests,
  ) {
    final pendingIds =
        requests.where((r) => r.isPending).map((r) => r.id).toSet();

    if (!_requestStreamSeeded) {
      _requestStreamSeeded = true;
      _knownRequestIds = pendingIds;

      AppLog.social.debug(
        'Incoming request stream seeded',
        payload: 'pending=${pendingIds.length}',
      );

      return const [];
    }

    final newRequests = requests
        .where((r) => r.isPending && !_knownRequestIds.contains(r.id))
        .toList();

    _knownRequestIds = pendingIds;
    return newRequests;
  }

  List<SocialFriendRequest> _diffAcceptedOutgoing(
    List<SocialFriendRequest> requests,
  ) {
    final pendingIds =
        requests.where((r) => r.isPending).map((r) => r.id).toSet();

    if (!_outgoingRequestStreamSeeded) {
      _outgoingRequestStreamSeeded = true;
      _knownPendingOutgoingIds = pendingIds;

      AppLog.social.debug(
        'Outgoing request stream seeded',
        payload: 'pending=${pendingIds.length}',
      );

      return const [];
    }

    final newlyAccepted = requests
        .where((r) => !r.isPending && _knownPendingOutgoingIds.contains(r.id))
        .toList();

    _knownPendingOutgoingIds = pendingIds;
    return newlyAccepted;
  }

  List<SocialNotification> _diffNotifications(
    List<SocialNotification> notifications,
  ) {
    final allIds = notifications.map((n) => n.id).toSet();

    if (!_notificationStreamSeeded) {
      _notificationStreamSeeded = true;
      _knownNotificationIds = allIds;

      AppLog.social.debug(
        'Notification stream seeded',
        payload: 'count=${allIds.length}',
      );

      return const [];
    }

    final newNotifications = notifications
        .where((n) => !_knownNotificationIds.contains(n.id))
        .toList();

    _knownNotificationIds = allIds;
    return newNotifications;
  }

  Future<SocialAchievementActorSnapshot> _buildCurrentActorSnapshot({
    required String uid,
    required String fallbackDisplayName,
    required String? fallbackPhotoUrl,
  }) async {
    try {
      final result = await _repository.fetchProfilesByIds([uid]);
      final profile = switch (result) {
        Success(value: final profiles) => profiles.firstOrNull,
        // Best-effort actor snapshot — the share/react flow falls back
        // to the Auth display name + photo if the Firestore profile
        // lookup fails. Don't surface on lastError to avoid a
        // misleading red banner when the user's own share still
        // succeeds with the fallback identity.
        Failure() => null,
      };
      final displayName = profile?.displayName.trim().isNotEmpty == true
          ? profile!.displayName.trim()
          : fallbackDisplayName;
      final photoUrl = profile?.photoUrl?.trim().isNotEmpty == true
          ? profile!.photoUrl!.trim()
          : fallbackPhotoUrl;

      return SocialAchievementActorSnapshot(
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } catch (_) {
      return SocialAchievementActorSnapshot(
        displayName: fallbackDisplayName,
        photoUrl: fallbackPhotoUrl,
      );
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _incomingRequestsSubscription?.cancel();
    await _outgoingRequestsSubscription?.cancel();
    await _friendshipsSubscription?.cancel();
    await _friendProfilesSubscription?.cancel();
    await _recentSharesSubscription?.cancel();
    await _notificationsSubscription?.cancel();

    _incomingRequestsSubscription = null;
    _outgoingRequestsSubscription = null;
    _friendshipsSubscription = null;
    _friendProfilesSubscription = null;
    _recentSharesSubscription = null;
    _notificationsSubscription = null;
  }

  /// Records a raw exception caught outside of a Result-returning
  /// repository call (Firebase Storage upload, Auth session reconcile,
  /// stream `onError:`). The error is classified into the typed
  /// [AppError] hierarchy so `lastError` stays uniform; the legacy
  /// Czech display string flows through [_describeError] unchanged.
  void _recordError(String operation, Object error, StackTrace stackTrace) {
    final classified = classifyFirebaseError(
      error,
      stackTrace,
      endpoint: 'social.$operation',
    );
    _recordAppError(operation, classified);
  }

  /// Records a typed [AppError] produced by a `Failure` arm of a
  /// `Result`. Preserves the original error + stack trace for AppLog
  /// while still surfacing the Czech display message via
  /// [_describeError] for backwards compatibility with the existing
  /// widget consumers.
  void _recordAppError(String operation, AppError error) {
    _lastError = error;
    final originalForDescribe = error.originalError ?? error;
    _error = _describeError(originalForDescribe);

    AppLog.social.error(
      operation,
      err: error.originalError ?? error,
      stackTrace: error.stackTrace ?? StackTrace.current,
    );
  }

  /// Clears the success/failure state on a successful call. Both the
  /// typed [_lastError] and the legacy Czech [_error] reset.
  void _clearError() {
    _error = null;
    _lastError = null;
  }

  String _describeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'canceled':
        case 'cancelled':
          return 'Výběr byl zrušen.';
        case 'unauthorized':
          return 'Profilovou fotku nejde nahrát. Zkontroluj Firebase Storage pravidla.';
        case 'failed-precondition':
          return 'Sociální data se ještě připravují. Zkus to prosím za chvíli znovu.';
        case 'permission-denied':
          return 'Přístup k sociálním datům byl zamítnut. Zkus se znovu přihlásit.';
        case 'unauthenticated':
          return 'Pro sociální funkce je potřeba být přihlášený.';
        case 'unavailable':
          return 'Sociální backend je dočasně nedostupný. Zkus to prosím později.';
        case 'not-found':
          return 'Požadovaná sociální položka nebyla nalezena.';
        case 'already-exists':
          return 'Tahle položka už v sociální části existuje.';
      }
    }

    final raw = error.toString().toLowerCase();

    if (raw.contains('requires an index') ||
        raw.contains('failed-precondition')) {
      return 'Sociální data se ještě připravují. Zkus to prosím za chvíli znovu.';
    }

    if (raw.contains('permission-denied')) {
      return 'Přístup k sociálním datům byl zamítnut. Zkus se znovu přihlásit.';
    }

    if (raw.contains('unauthenticated')) {
      return 'Pro sociální funkce je potřeba být přihlášený.';
    }

    if (raw.contains('google sign-in did not return an id token')) {
      return 'Google přihlášení se nepodařilo dokončit. Zkus to prosím znovu.';
    }

    if (raw.contains('friend request not found')) {
      return 'Žádost o přátelství už není dostupná.';
    }

    if (raw.contains('payload is empty')) {
      return 'Sociální data dorazila nekompletní. Zkus to prosím znovu.';
    }

    if (raw.contains('a user cannot send a friend request to themselves')) {
      return 'Sám sobě žádost o přátelství poslat nejde.';
    }

    if (error is ArgumentError || error is StateError) {
      final message = error.toString();
      if (message.isNotEmpty) return message;
    }

    return 'V sociální části se něco nepovedlo. Zkus to prosím znovu.';
  }

  @override
  void dispose() {
    unawaited(_cancelSubscriptions());
    super.dispose();
  }
}

