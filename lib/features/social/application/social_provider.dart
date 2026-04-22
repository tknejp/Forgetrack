import 'dart:async';

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

  bool get backendReady => _backendState.isReady;
  String get backendMessage => _backendState.message;
  bool get isReady => _isReady;
  bool get isSearching => _isSearching;
  String? get error => _error;

  List<SocialFriendRequest> get incomingRequests => _incomingRequests;
  List<SocialFriendRequest> get outgoingRequests => _outgoingRequests;
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
      await _refreshFriendProfilesAndFeed();
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
        _repository.watchIncomingFriendRequests(uid: uid).listen((requests) {
      _incomingRequests = requests;
      notifyListeners();
    });

    _outgoingRequestsSubscription =
        _repository.watchOutgoingFriendRequests(uid: uid).listen((requests) {
      _outgoingRequests = requests;
      notifyListeners();
    });

    _friendshipsSubscription = _repository.watchFriendships(uid: uid).listen(
      (friendships) {
        _friendships = friendships;
        notifyListeners();
        unawaited(_refreshFriendProfilesAndFeed());
      },
    );

    await _refreshFriendProfilesAndFeed();
  }

  Future<void> _refreshFriendProfilesAndFeed() async {
    final uid = _activeUid;
    if (uid == null) return;

    try {
      final friendIds = _friendships
          .map((friendship) => friendship.counterpartFor(uid))
          .where((friendUid) => friendUid != uid)
          .toSet()
          .toList();

      _friends = await _repository.fetchProfilesByIds(friendIds);
      _recentShares = await _repository.fetchRecentAchievementShares(
        actorUids: friendIds,
      );
      _error = null;
    } catch (error, stackTrace) {
      _recordError('refreshFriendProfilesAndFeed', error, stackTrace);
    }
    notifyListeners();
  }

  Future<void> _clearSessionState() async {
    _activeUid = null;
    _isReady = false;
    _lastProfileSignature = null;
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
    _incomingRequestsSubscription = null;
    _outgoingRequestsSubscription = null;
    _friendshipsSubscription = null;
  }

  void _recordError(String operation, Object error, StackTrace stackTrace) {
    _error = error.toString();
    AppLog.social.error(
      operation,
      err: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void dispose() {
    unawaited(_cancelSubscriptions());
    super.dispose();
  }
}
