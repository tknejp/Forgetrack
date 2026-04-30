import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_log.dart';
import '../../auth/application/auth_provider.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../progression/domain/progression_models.dart';
import '../../progression/application/progression_provider.dart';
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
  CosmeticsProvider? _cosmeticsProvider;

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

  void bind({
    required AuthProvider authProvider,
    required ProgressionProvider progressionProvider,
    CosmeticsProvider? cosmeticsProvider,
  }) {
    _authProvider = authProvider;
    _progressionProvider = progressionProvider;
    _cosmeticsProvider = cosmeticsProvider;

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

  Future<String?> updateCurrentHandle(String desiredHandle) async {
    final uid = _activeUid;
    if (uid == null) return null;

    try {
      final handle = await _repository.updateProfileHandle(
        uid: uid,
        desiredHandle: desiredHandle,
      );
      _lastProfileSignature = null;
      _error = null;
      notifyListeners();
      return handle;
    } catch (error, stackTrace) {
      _recordError('updateCurrentHandle', error, stackTrace);
      notifyListeners();
      return null;
    }
  }

  Future<void> updateCurrentPhotoUrl(String? photoUrl) async {
    final uid = _activeUid;
    if (uid == null) return;

    try {
      await _repository.updateProfilePhotoUrl(
        uid: uid,
        photoUrl: photoUrl,
      );
      _lastProfileSignature = null;
      _error = null;
    } catch (error, stackTrace) {
      _recordError('updateCurrentPhotoUrl', error, stackTrace);
    }

    notifyListeners();
  }

  Future<String?> uploadCurrentProfilePhoto(XFile image) async {
    final uid = _activeUid;
    if (uid == null) return null;
    if (!backendReady) {
      _error = backendMessage;
      notifyListeners();
      return null;
    }

    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('Vybrany obrazek je prazdny.');
      }

      final contentType = _contentTypeForImage(image);
      final extension = _extensionForContentType(contentType);
      final storageUid = _storageSafeId(uid);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('social_profile_photos')
          .child(storageUid)
          .child('profile_$timestamp.$extension');

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public,max-age=604800',
          customMetadata: {
            'uid': uid,
            'source': 'forgetrack_social_profile',
          },
        ),
      );

      final url = await ref.getDownloadURL();
      await _repository.updateProfilePhotoUrl(uid: uid, photoUrl: url);
      _lastProfileSignature = null;
      _error = null;
      notifyListeners();
      return url;
    } catch (error, stackTrace) {
      _recordError('uploadCurrentProfilePhoto', error, stackTrace);
      notifyListeners();
      return null;
    }
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
    return results.firstOrNull;
  }

  Future<List<SocialUnlockedAchievement>> fetchFriendAchievements(String uid) {
    return _repository.fetchUnlockedAchievements(uid);
  }

  Stream<SocialUserProfile?> watchProfileById(String uid) {
    return _repository
        .watchProfilesByIds([uid]).map((profiles) => profiles.firstOrNull);
  }

  Stream<List<SocialUnlockedAchievement>> watchFriendAchievements(String uid) {
    return _repository.watchUnlockedAchievements(uid);
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
      return _repository.fetchProfilesByIds(friendIds);
    });
  }

  Future<void> setCurrentAchievementPinned({
    required String achievementId,
    required bool pinned,
  }) async {
    final uid = _activeUid;
    if (uid == null) return;

    try {
      await _repository.updatePinnedAchievement(
        uid: uid,
        achievementId: achievementId,
        pinned: pinned,
      );
      _error = null;
    } catch (error, stackTrace) {
      _recordError('setCurrentAchievementPinned', error, stackTrace);
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

    try {
      await _repository.removeFriend(friendshipId: friendship.id);
      _error = null;
    } catch (error, stackTrace) {
      _recordError('removeFriend', error, stackTrace);
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

    try {
      await _repository.addReaction(
        shareId: shareId,
        actorUid: uid,
        actorName: actorSnapshot.displayName,
        actorPhoto: actorSnapshot.photoUrl,
        emoji: emoji,
        shareOwnerUid: share.actorUid,
        achievementTitle: share.achievementSnapshot.title,
      );
      _error = null;
    } catch (error, stackTrace) {
      _recordError('addReaction', error, stackTrace);
    }

    notifyListeners();
  }

  Future<void> removeReaction(String shareId) async {
    final uid = _activeUid;
    if (uid == null) return;

    final share = _recentShares.where((s) => s.id == shareId).firstOrNull;
    if (share == null) return;

    try {
      await _repository.removeReaction(
        shareId: shareId,
        actorUid: uid,
        shareOwnerUid: share.actorUid,
      );
      _error = null;
    } catch (error, stackTrace) {
      _recordError('removeReaction', error, stackTrace);
    }

    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    final uid = _activeUid;
    if (uid == null) return;

    try {
      await _repository.markNotificationsRead(uid);
    } catch (error, stackTrace) {
      _recordError('markNotificationsRead', error, stackTrace);
    }
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

    final payload = _buildSyncPayload();
    if (payload == null) return;

    final signature = _buildProfileSignature(payload);
    if (signature == _lastProfileSignature) return;

    _isSyncingProfile = true;

    try {
      await _repository.upsertProfile(payload);

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
        .where((a) => a.unlocked && a.unlockedAt != null)
        .map(
          (a) => SocialUnlockedAchievement(
            achievementId: a.id,
            title: a.title,
            description: a.description,
            difficulty: a.difficulty.name,
            type: a.type.name,
            domain: a.domain?.name,
            ruleId: a.ruleId,
            unlockedAt: a.unlockedAt!,
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
      equippedCosmetics: _buildEquippedCosmeticsSnapshot(),
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
      payload.stats.level.toString(),
      payload.stats.totalXp.toString(),
      payload.stats.unlockedAchievementCount.toString(),
      payload.stats.claimedRewardCount.toString(),
      payload.stats.pendingRewardCount.toString(),
      payload.stats.bestStepsStreak.toString(),
      payload.stats.bestNutritionStreak.toString(),
      payload.equippedCosmetics.frameId ?? '',
      payload.equippedCosmetics.relicId ?? '',
      payload.equippedCosmetics.backgroundId ?? '',
      payload.equippedCosmetics.emblemId ?? '',
      payload.equippedCosmetics.companionId ?? '',
      payload.equippedCosmetics.titleFlairId ?? '',
      payload.equippedCosmetics.mapEffectId ?? '',
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
        _error = null;
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
        _error = null;
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
      final profile = (await _repository.fetchProfilesByIds([uid])).firstOrNull;
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
        case 'canceled':
        case 'cancelled':
          return 'Vyber byl zrusen.';
        case 'unauthorized':
          return 'Profilovou fotku nejde nahrat. Zkontroluj Firebase Storage pravidla.';
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

String _contentTypeForImage(XFile image) {
  final mimeType = image.mimeType?.trim().toLowerCase();
  if (mimeType == 'image/png' ||
      mimeType == 'image/webp' ||
      mimeType == 'image/heic' ||
      mimeType == 'image/heif') {
    return mimeType!;
  }

  final lowerName = image.name.toLowerCase();
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.webp')) return 'image/webp';
  if (lowerName.endsWith('.heic')) return 'image/heic';
  if (lowerName.endsWith('.heif')) return 'image/heif';
  return 'image/jpeg';
}

String _extensionForContentType(String contentType) {
  switch (contentType) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    case 'image/heif':
      return 'heif';
    case 'image/jpeg':
    default:
      return 'jpg';
  }
}

String _storageSafeId(String value) {
  final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  return safe.isEmpty ? 'user' : safe;
}
