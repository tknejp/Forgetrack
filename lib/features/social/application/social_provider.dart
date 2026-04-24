import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/app_log.dart';
import '../../auth/application/auth_provider.dart';
import '../../progression/domain/progression_models.dart';
import '../../progression/presentation/progression_provider.dart';
import '../data/social_firebase_bootstrap.dart';
import '../data/social_firebase_session.dart';
import '../domain/social_models.dart';
import '../domain/social_repository.dart';

class SocialProvider extends ChangeNotifier {
  SocialProvider({
    required SocialRepository repository,
    required SocialFirebaseSession session,
    required SocialBackendState backendState,
  })  : _repository = repository,
        _session = session,
        _backendState = backendState;

  final SocialRepository _repository;
  final SocialFirebaseSession _session;
  final SocialBackendState _backendState;

  AuthProvider? _authProvider;
  ProgressionProvider? _progressionProvider;

  StreamSubscription<List<SocialFriendRequest>>? _incomingRequestsSubscription;
  StreamSubscription<List<SocialFriendRequest>>? _outgoingRequestsSubscription;
  StreamSubscription<List<SocialFriendship>>? _friendshipsSubscription;
  StreamSubscription<List<SocialUserProfile>>? _friendProfilesSubscription;
  StreamSubscription<List<SocialAchievementShare>>? _recentSharesSubscription;

  List<SocialFriendRequest> _incomingRequests = const [];
  List<SocialFriendRequest> _outgoingRequests = const [];
  List<SocialFriendship> _friendships = const [];
  List<SocialUserProfile> _friends = const [];
  List<SocialAchievementShare> _recentShares = const [];
  List<SocialUserProfile> _searchResults = const [];

  bool _isReconcilingSession = false;
  bool _reconcileQueued = false;
  bool _isSyncingProfile = false;
  bool _profileSyncQueued = false;
  bool _isSearching = false;
  bool _isReady = false;
  String? _activeUid;
  String? _error;
  String? _lastAuthSignature;
  String? _lastProfileSignature;
  String _friendIdsSignature = '';

  bool get backendReady => _backendState.isReady;
  String get backendMessage => _backendState.message;
  bool get isReady => _isReady;
  bool get isSearching => _isSearching;
  String? get error => _error;

  List<SocialFriendRequest> get incomingRequests =>
      _incomingRequests.where((r) => r.isPending).toList();
  List<SocialFriendRequest> get outgoingRequests =>
      _outgoingRequests.where((r) => r.isPending).toList();
  List<SocialFriendship> get friendships => _friendships;
  List<SocialUserProfile> get friends => _friends;
  List<SocialAchievementShare> get recentShares => _recentShares;
  List<SocialUserProfile> get searchResults => _searchResults;

  void bind({
    required AuthProvider authProvider,
    required ProgressionProvider progressionProvider,
  }) {
    _authProvider = authProvider;
    _progressionProvider = progressionProvider;

    final authSignature = _buildAuthSignature(authProvider);
    if (authSignature != _lastAuthSignature) {
      _lastAuthSignature = authSignature;
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
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchProfilesByHandle(
        normalized,
        excludeUid: uid,
      );
    } catch (error, stackTrace) {
      _recordError('searchUsers', error, stackTrace);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    if (_searchResults.isEmpty) return;
    _searchResults = const [];
    notifyListeners();
  }

  Future<void> sendFriendRequest(String toUid) async {
    final uid = _activeUid;
    if (uid == null) return;

    try {
      await _repository.sendFriendRequest(fromUid: uid, toUid: toUid);
      _error = null;
      clearSearchResults();
    } catch (error, stackTrace) {
      _recordError('sendFriendRequest', error, stackTrace);
    }
    notifyListeners();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _repository.acceptFriendRequest(requestId: requestId);
      _error = null;
    } catch (error, stackTrace) {
      _recordError('acceptFriendRequest', error, stackTrace);
    }
    notifyListeners();
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _repository.declineFriendRequest(requestId: requestId);
      _error = null;
    } catch (error, stackTrace) {
      _recordError('declineFriendRequest', error, stackTrace);
    }
    notifyListeners();
  }

  Future<SocialUserProfile?> fetchProfileById(String uid) async {
    final results = await _repository.fetchProfilesByIds([uid]);
    return results.isEmpty ? null : results.first;
  }

  Future<List<SocialUnlockedAchievement>> fetchFriendAchievements(
    String uid,
  ) {
    return _repository.fetchUnlockedAchievements(uid);
  }

  Stream<SocialUserProfile?> watchProfileById(String uid) {
    return _repository
        .watchProfilesByIds([uid]).map((profiles) => profiles.firstOrNull);
  }

  Stream<List<SocialUnlockedAchievement>> watchFriendAchievements(String uid) {
    return _repository.watchUnlockedAchievements(uid);
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = _activeUid;
    if (uid == null) {
      AppLog.social.debug('removeFriend: no active uid');
      return;
    }
    AppLog.social.debug('removeFriend',
        payload:
            'friendUid=$friendUid uid=$uid friendships=${_friendships.length}');
    final friendship = _friendships
        .where(
          (f) => f.memberUids.contains(friendUid) && f.memberUids.contains(uid),
        )
        .firstOrNull;
    if (friendship == null) {
      AppLog.social
          .debug('removeFriend: no friendship found for friendUid=$friendUid');
      throw StateError(
          'Přátelství nebylo nalezeno (friendships=${_friendships.length}).');
    }
    try {
      await _repository.removeFriend(friendshipId: friendship.id);
      _error = null;
    } catch (error, stackTrace) {
      _recordError('removeFriend', error, stackTrace);
    }
    notifyListeners();
  }

  Future<void> shareAchievement(
    String achievementId, {
    String? message,
  }) async {
    final uid = _activeUid;
    final authProvider = _authProvider;
    final progressionProvider = _progressionProvider;
    if (uid == null ||
        authProvider?.user == null ||
        progressionProvider == null) {
      return;
    }

    ProgressionAchievement? achievement;
    for (final candidate in progressionProvider.achievements) {
      if (candidate.id == achievementId && candidate.unlocked) {
        achievement = candidate;
        break;
      }
    }

    if (achievement == null) {
      _error = 'Achievement $achievementId is not unlocked yet.';
      notifyListeners();
      return;
    }

    final share = SocialAchievementShare(
      id: '',
      actorUid: uid,
      achievementId: achievement.id,
      createdAt: DateTime.now(),
      message: message?.trim().isEmpty ?? true ? null : message!.trim(),
      visibility: SocialShareVisibility.friends,
      actorSnapshot: SocialAchievementActorSnapshot(
        displayName: authProvider!.user!.displayName?.trim().isNotEmpty == true
            ? authProvider.user!.displayName!.trim()
            : authProvider.user!.email.split('@').first,
        photoUrl: authProvider.user!.photoUrl,
      ),
      achievementSnapshot: SocialAchievementSnapshot(
        title: achievement.title,
        description: achievement.description,
        difficulty: achievement.difficulty.name,
        type: achievement.type.name,
        domain: achievement.domain?.name,
      ),
    );

    try {
      await _repository.shareAchievement(share);
      _error = null;
    } catch (error, stackTrace) {
      _recordError('shareAchievement', error, stackTrace);
    }
    notifyListeners();
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
      _error = null;

      if (shouldResubscribe) {
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

    final payload = _buildSyncPayload();
    if (payload == null) return;

    final signature = _buildProfileSignature(payload);
    if (signature == _lastProfileSignature) {
      return;
    }

    _isSyncingProfile = true;
    try {
      await _repository.upsertProfile(payload);
      await _repository.replaceUnlockedAchievements(
        uid: payload.uid,
        achievements: payload.unlockedAchievements,
      );
      _lastProfileSignature = signature;
      _error = null;
      AppLog.social.debug(
        'Profile synced',
        payload: 'uid=${payload.uid} xp=${payload.stats.totalXp}',
      );
    } catch (error, stackTrace) {
      _recordError('syncProfile', error, stackTrace);
    } finally {
      _isSyncingProfile = false;
      notifyListeners();
    }

    if (_profileSyncQueued) {
      _profileSyncQueued = false;
      unawaited(_syncProfileIfNeeded());
    }
  }

  SocialProfileSyncPayload? _buildSyncPayload() {
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
    final unlockedAchievements = progressionProvider.achievements
        .where(
          (achievement) =>
              achievement.unlocked && achievement.unlockedAt != null,
        )
        .map(
          (achievement) => SocialUnlockedAchievement(
            achievementId: achievement.id,
            title: achievement.title,
            description: achievement.description,
            difficulty: achievement.difficulty.name,
            type: achievement.type.name,
            domain: achievement.domain?.name,
            ruleId: achievement.ruleId,
            unlockedAt: achievement.unlockedAt!,
          ),
        )
        .toList(growable: false);

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email.split('@').first;

    final handle = buildDefaultSocialHandle(
      uid: user.id,
      email: user.email,
      displayName: user.displayName,
    );

    return SocialProfileSyncPayload(
      uid: user.id,
      displayName: displayName,
      email: user.email,
      handle: handle,
      photoUrl: user.photoUrl,
      socialEnabled: true,
      stats: SocialUserStats(
        level: progressionProvider.profile.level,
        totalXp: progressionProvider.profile.totalXp,
        unlockedAchievementCount: unlockedAchievements.length,
        claimedRewardCount: progressionProvider.claimedRewards.length,
        pendingRewardCount: progressionProvider.pendingRewards.length,
        bestStepsStreak:
            progressionProvider.streakForRule('daily_steps').bestStreak,
        bestNutritionStreak: progressionProvider
            .streakForDomain(ProgressionDomain.nutrition)
            .bestStreak,
        updatedAt: progressionProvider.lastEvaluatedAt,
      ),
      unlockedAchievements: unlockedAchievements,
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
          (achievement) =>
              '${achievement.achievementId}@${achievement.unlockedAt.millisecondsSinceEpoch}',
        )
        .join(',');

    return [
      payload.uid,
      payload.displayName,
      payload.handle,
      payload.photoUrl ?? '',
      payload.stats.level.toString(),
      payload.stats.totalXp.toString(),
      payload.stats.unlockedAchievementCount.toString(),
      payload.stats.claimedRewardCount.toString(),
      payload.stats.pendingRewardCount.toString(),
      payload.stats.bestStepsStreak.toString(),
      payload.stats.bestNutritionStreak.toString(),
      unlockedIds,
    ].join('|');
  }

  Future<void> _subscribe(String uid) async {
    await _cancelSubscriptions();

    _incomingRequestsSubscription =
        _repository.watchIncomingFriendRequests(uid: uid).listen(
      (requests) {
        _incomingRequests = requests;
        notifyListeners();
      },
      onError: (error, stackTrace) =>
          _recordError('watchIncomingFriendRequests', error, stackTrace),
    );

    _outgoingRequestsSubscription =
        _repository.watchOutgoingFriendRequests(uid: uid).listen(
      (requests) {
        _outgoingRequests = requests;
        notifyListeners();
      },
      onError: (error, stackTrace) =>
          _recordError('watchOutgoingFriendRequests', error, stackTrace),
    );

    _friendshipsSubscription = _repository.watchFriendships(uid: uid).listen(
      (friendships) {
        _friendships = friendships;
        notifyListeners();
        unawaited(_handleFriendshipsUpdated());
      },
      onError: (error, stackTrace) =>
          _recordError('watchFriendships', error, stackTrace),
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
    if (signature != _friendIdsSignature) {
      _friendIdsSignature = signature;
      await _subscribeFriendProfiles(friendIds);
      await _subscribeRecentShares(friendIds);
    }
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
        _error = null;
        notifyListeners();
      },
      onError: (error, stackTrace) =>
          _recordError('watchProfilesByIds', error, stackTrace),
    );
  }

  Future<void> _subscribeRecentShares(List<String> friendIds) async {
    await _recentSharesSubscription?.cancel();
    _recentSharesSubscription = null;

    if (friendIds.isEmpty) {
      _recentShares = const [];
      notifyListeners();
      return;
    }

    _recentSharesSubscription =
        _repository.watchRecentAchievementShares(actorUids: friendIds).listen(
      (shares) {
        _recentShares = shares;
        _error = null;
        notifyListeners();
      },
      onError: (error, stackTrace) =>
          _recordError('watchRecentAchievementShares', error, stackTrace),
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
    await _cancelSubscriptions();
  }

  Future<void> _cancelSubscriptions() async {
    await _incomingRequestsSubscription?.cancel();
    await _outgoingRequestsSubscription?.cancel();
    await _friendshipsSubscription?.cancel();
    await _friendProfilesSubscription?.cancel();
    await _recentSharesSubscription?.cancel();
    _incomingRequestsSubscription = null;
    _outgoingRequestsSubscription = null;
    _friendshipsSubscription = null;
    _friendProfilesSubscription = null;
    _recentSharesSubscription = null;
  }

  void _recordError(String operation, Object error, StackTrace stackTrace) {
    _error = _describeError(error);
    AppLog.social.error(
      operation,
      err: error,
      stackTrace: stackTrace,
    );
  }

  String _describeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
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
