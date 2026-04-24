import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/social_models.dart';
import '../domain/social_repository.dart';

class FirestoreSocialRepository implements SocialRepository {
  FirestoreSocialRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _firestore.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  CollectionReference<Map<String, dynamic>> get _achievementShares =>
      _firestore.collection('achievement_shares');

  @override
  Stream<List<SocialFriendRequest>> watchIncomingFriendRequests({
    required String uid,
  }) {
    return _friendRequests
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      // Keep live queries index-light; sort in memory instead.
      final requests = snapshot.docs.map(_mapFriendRequest).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Stream<List<SocialFriendRequest>> watchOutgoingFriendRequests({
    required String uid,
  }) {
    return _friendRequests
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map(_mapFriendRequest).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Stream<List<SocialFriendship>> watchFriendships({
    required String uid,
  }) {
    return _friendships
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final friendships = snapshot.docs.map(_mapFriendship).toList();
      friendships.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return friendships;
    });
  }

  @override
  Stream<List<SocialUserProfile>> watchProfilesByIds(Iterable<String> uids) {
    final ids = uids.toSet().where((uid) => uid.isNotEmpty).toList();
    if (ids.isEmpty) {
      return Stream<List<SocialUserProfile>>.value(const []);
    }

    final chunks = _chunk(ids, 10).toList(growable: false);
    if (chunks.length == 1) {
      return _users
          .where(FieldPath.documentId, whereIn: chunks.first)
          .snapshots()
          .map(
        (snapshot) {
          final profiles = snapshot.docs.map(_mapUserProfile).toList();
          profiles.sort((a, b) => a.displayName.compareTo(b.displayName));
          return profiles;
        },
      );
    }

    late StreamController<List<SocialUserProfile>> controller;
    final latestChunks =
        List<List<SocialUserProfile>?>.filled(chunks.length, null);
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitIfReady() {
      if (latestChunks.any((profiles) => profiles == null)) return;
      final merged = <SocialUserProfile>[
        for (final profiles in latestChunks) ...profiles!,
      ];
      merged.sort((a, b) => a.displayName.compareTo(b.displayName));
      controller.add(merged);
    }

    controller = StreamController<List<SocialUserProfile>>(
      onListen: () {
        for (var index = 0; index < chunks.length; index++) {
          final subscription = _users
              .where(FieldPath.documentId, whereIn: chunks[index])
              .snapshots()
              .listen(
            (snapshot) {
              latestChunks[index] = snapshot.docs.map(_mapUserProfile).toList();
              emitIfReady();
            },
            onError: controller.addError,
          );
          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<List<SocialUserProfile>> fetchProfilesByIds(
    Iterable<String> uids,
  ) async {
    final ids = uids.toSet().where((uid) => uid.isNotEmpty).toList();
    if (ids.isEmpty) return const [];

    final profiles = <SocialUserProfile>[];
    for (final chunk in _chunk(ids, 10)) {
      final snapshot =
          await _users.where(FieldPath.documentId, whereIn: chunk).get();
      profiles.addAll(snapshot.docs.map(_mapUserProfile));
    }

    profiles.sort((a, b) => a.displayName.compareTo(b.displayName));
    return profiles;
  }

  @override
  Future<List<SocialUserProfile>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  }) async {
    final normalized = normalizeSocialHandle(query);
    if (normalized.isEmpty) return const [];

    final snapshot = await _users
        .where('handleSearchTokens', arrayContains: normalized)
        .limit(limit + 4)
        .get();

    final results = snapshot.docs
        .map(_mapUserProfile)
        .where((profile) => profile.uid != excludeUid && profile.socialEnabled)
        .toList();

    results.sort((a, b) => a.handle.compareTo(b.handle));
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<List<SocialAchievementShare>> fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) async {
    final ids = actorUids.toSet().where((uid) => uid.isNotEmpty).toList();
    if (ids.isEmpty) return const [];

    final shares = <SocialAchievementShare>[];
    for (final chunk in _chunk(ids, 10)) {
      final snapshot = await _achievementShares
          .where('actorUid', whereIn: chunk)
          .limit(limit)
          .get();
      shares.addAll(snapshot.docs.map(_mapAchievementShare));
    }

    shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return shares.take(limit).toList(growable: false);
  }

  @override
  Stream<List<SocialAchievementShare>> watchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) {
    final ids = actorUids.toSet().where((uid) => uid.isNotEmpty).toList();
    if (ids.isEmpty) {
      return Stream<List<SocialAchievementShare>>.value(const []);
    }

    final chunks = _chunk(ids, 10).toList(growable: false);
    if (chunks.length == 1) {
      return _achievementShares
          .where('actorUid', whereIn: chunks.first)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        final shares = snapshot.docs.map(_mapAchievementShare).toList();
        shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return shares.take(limit).toList(growable: false);
      });
    }

    late StreamController<List<SocialAchievementShare>> controller;
    final latestChunks =
        List<List<SocialAchievementShare>?>.filled(chunks.length, null);
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitIfReady() {
      if (latestChunks.any((shares) => shares == null)) return;
      final merged = <SocialAchievementShare>[
        for (final shares in latestChunks) ...shares!,
      ];
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(merged.take(limit).toList(growable: false));
    }

    controller = StreamController<List<SocialAchievementShare>>(
      onListen: () {
        for (var index = 0; index < chunks.length; index++) {
          final subscription = _achievementShares
              .where('actorUid', whereIn: chunks[index])
              .limit(limit)
              .snapshots()
              .listen(
            (snapshot) {
              latestChunks[index] =
                  snapshot.docs.map(_mapAchievementShare).toList();
              emitIfReady();
            },
            onError: controller.addError,
          );
          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<void> upsertProfile(SocialProfileSyncPayload payload) async {
    final doc = _users.doc(payload.uid);
    await doc.set({
      'displayName': payload.displayName,
      'email': payload.email,
      'handle': payload.handle,
      'handleLower': payload.handle.toLowerCase(),
      'handleSearchTokens': buildSocialHandleSearchTokens(payload.handle),
      'photoUrl': payload.photoUrl,
      'socialEnabled': payload.socialEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'stats': {
        'level': payload.stats.level,
        'totalXp': payload.stats.totalXp,
        'unlockedAchievementCount': payload.stats.unlockedAchievementCount,
        'claimedRewardCount': payload.stats.claimedRewardCount,
        'pendingRewardCount': payload.stats.pendingRewardCount,
        'bestStepsStreak': payload.stats.bestStepsStreak,
        'bestNutritionStreak': payload.stats.bestNutritionStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<void> replaceUnlockedAchievements({
    required String uid,
    required List<SocialUnlockedAchievement> achievements,
  }) async {
    final collection = _users.doc(uid).collection('achievement_unlocks');
    final existingSnapshot = await collection.get();
    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();
    final newIds =
        achievements.map((achievement) => achievement.achievementId).toSet();

    final batch = _firestore.batch();
    for (final achievement in achievements) {
      batch.set(collection.doc(achievement.achievementId), {
        'achievementId': achievement.achievementId,
        'title': achievement.title,
        'description': achievement.description,
        'difficulty': achievement.difficulty,
        'type': achievement.type,
        'domain': achievement.domain,
        'ruleId': achievement.ruleId,
        'unlockedAt': Timestamp.fromDate(achievement.unlockedAt),
      });
    }

    for (final staleId in existingIds.difference(newIds)) {
      batch.delete(collection.doc(staleId));
    }

    await batch.commit();
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid == toUid) {
      throw ArgumentError(
        'A user cannot send a friend request to themselves.',
      );
    }

    final friendshipId = buildSocialFriendshipId(fromUid, toUid);
    final participantsKey = buildSocialParticipantsKey(fromUid, toUid);
    final friendshipRef = _friendships.doc(friendshipId);

    await _firestore.runTransaction((transaction) async {
      final friendshipSnapshot = await transaction.get(friendshipRef);
      if (friendshipSnapshot.exists) {
        return;
      }

      final duplicateSnapshot = await _friendRequests
          .where('participantsKey', isEqualTo: participantsKey)
          .where('status', isEqualTo: SocialFriendRequestStatus.pending.name)
          .limit(1)
          .get();

      if (duplicateSnapshot.docs.isNotEmpty) {
        return;
      }

      final newRequestRef = _friendRequests.doc();
      transaction.set(newRequestRef, {
        'fromUid': fromUid,
        'toUid': toUid,
        'participantsKey': participantsKey,
        'status': SocialFriendRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
    });
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
  }) async {
    final requestRef = _friendRequests.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw StateError('Friend request not found.');
      }

      final data = requestSnapshot.data();
      if (data == null) {
        throw StateError('Friend request payload is empty.');
      }

      if (data['status'] != SocialFriendRequestStatus.pending.name) {
        return;
      }

      final fromUid = data['fromUid'] as String? ?? '';
      final toUid = data['toUid'] as String? ?? '';
      final friendshipId = buildSocialFriendshipId(fromUid, toUid);

      transaction.set(
          _friendships.doc(friendshipId),
          {
            'members': [fromUid, toUid]..sort(),
            'createdAt': FieldValue.serverTimestamp(),
            'sourceRequestId': requestId,
          },
          SetOptions(merge: true));

      transaction.update(requestRef, {
        'status': SocialFriendRequestStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> declineFriendRequest({
    required String requestId,
  }) async {
    await _friendRequests.doc(requestId).update({
      'status': SocialFriendRequestStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<SocialUnlockedAchievement>> fetchUnlockedAchievements(
    String uid,
  ) async {
    final snapshot =
        await _users.doc(uid).collection('achievement_unlocks').get();
    final list = snapshot.docs
        .map(_mapUnlockedAchievement)
        .toList(growable: true)
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return list;
  }

  @override
  Future<void> shareAchievement(SocialAchievementShare share) async {
    await _achievementShares.add({
      'actorUid': share.actorUid,
      'achievementId': share.achievementId,
      'createdAt': FieldValue.serverTimestamp(),
      'message': share.message,
      'visibility': share.visibility.name,
      'actorSnapshot': {
        'displayName': share.actorSnapshot.displayName,
        'photoUrl': share.actorSnapshot.photoUrl,
      },
      'achievementSnapshot': {
        'title': share.achievementSnapshot.title,
        'description': share.achievementSnapshot.description,
        'difficulty': share.achievementSnapshot.difficulty,
        'type': share.achievementSnapshot.type,
        'domain': share.achievementSnapshot.domain,
      },
    });
  }

  @override
  Stream<List<SocialUnlockedAchievement>> watchUnlockedAchievements(
      String uid) {
    return _users.doc(uid).collection('achievement_unlocks').snapshots().map(
      (snapshot) {
        final achievements = snapshot.docs
            .map(_mapUnlockedAchievement)
            .toList(growable: true)
          ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
        return achievements;
      },
    );
  }

  SocialFriendRequest _mapFriendRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SocialFriendRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      status: _mapFriendRequestStatus(data['status'] as String?),
      createdAt: _readDateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      respondedAt: _readDateTime(data['respondedAt']),
    );
  }

  SocialFriendship _mapFriendship(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SocialFriendship(
      id: doc.id,
      memberUids: (data['members'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      createdAt: _readDateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceRequestId: data['sourceRequestId'] as String?,
    );
  }

  SocialUserProfile _mapUserProfile(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final stats = data['stats'] as Map<String, dynamic>? ?? const {};

    return SocialUserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      socialEnabled: data['socialEnabled'] == true,
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
      stats: SocialUserStats(
        level: _readInt(stats['level']),
        totalXp: _readInt(stats['totalXp']),
        unlockedAchievementCount: _readInt(stats['unlockedAchievementCount']),
        claimedRewardCount: _readInt(stats['claimedRewardCount']),
        pendingRewardCount: _readInt(stats['pendingRewardCount']),
        bestStepsStreak: _readInt(stats['bestStepsStreak']),
        bestNutritionStreak: _readInt(stats['bestNutritionStreak']),
        updatedAt: _readDateTime(stats['updatedAt']),
      ),
    );
  }

  SocialAchievementShare _mapAchievementShare(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final actorSnapshot =
        data['actorSnapshot'] as Map<String, dynamic>? ?? const {};
    final achievementSnapshot =
        data['achievementSnapshot'] as Map<String, dynamic>? ?? const {};
    final reactionsRaw = data['reactions'] as Map<String, dynamic>? ?? const {};
    final reactorSnapshotsRaw =
        data['reactorSnapshots'] as Map<String, dynamic>? ?? const {};

    final reactions = reactionsRaw.map(
      (uid, emoji) => MapEntry(uid, emoji.toString()),
    );
    final reactorSnapshots = reactorSnapshotsRaw.map((uid, raw) {
      final snap = raw as Map<String, dynamic>? ?? const {};
      return MapEntry(
        uid,
        SocialReactionSnapshot(
          displayName: snap['displayName'] as String? ?? '',
          photoUrl: snap['photoUrl'] as String?,
        ),
      );
    });

    return SocialAchievementShare(
      id: doc.id,
      actorUid: data['actorUid'] as String? ?? '',
      achievementId: data['achievementId'] as String? ?? '',
      createdAt: _readDateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      message: data['message'] as String?,
      visibility: _mapVisibility(data['visibility'] as String?),
      actorSnapshot: SocialAchievementActorSnapshot(
        displayName: actorSnapshot['displayName'] as String? ?? '',
        photoUrl: actorSnapshot['photoUrl'] as String?,
      ),
      achievementSnapshot: SocialAchievementSnapshot(
        title: achievementSnapshot['title'] as String? ?? '',
        description: achievementSnapshot['description'] as String? ?? '',
        difficulty: achievementSnapshot['difficulty'] as String? ?? '',
        type: achievementSnapshot['type'] as String? ?? '',
        domain: achievementSnapshot['domain'] as String?,
      ),
      reactions: reactions,
      reactorSnapshots: reactorSnapshots,
    );
  }

  @override
  Future<void> removeFriend({required String friendshipId}) async {
    await _friendships.doc(friendshipId).delete();
  }

  @override
  Future<void> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  }) async {
    final shareRef = _achievementShares.doc(shareId);
    final notifRef = _users
        .doc(shareOwnerUid)
        .collection('notifications')
        .doc('${shareId}_$actorUid');

    final batch = _firestore.batch();
    batch.update(shareRef, {
      'reactions.$actorUid': emoji,
      'reactorSnapshots.$actorUid': {
        'displayName': actorName,
        'photoUrl': actorPhoto,
      },
    });
    batch.set(notifRef, {
      'actorUid': actorUid,
      'actorName': actorName,
      'actorPhoto': actorPhoto,
      'shareId': shareId,
      'achievementTitle': achievementTitle,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await batch.commit();
  }

  @override
  Future<void> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  }) async {
    final shareRef = _achievementShares.doc(shareId);
    final notifRef = _users
        .doc(shareOwnerUid)
        .collection('notifications')
        .doc('${shareId}_$actorUid');

    final batch = _firestore.batch();
    batch.update(shareRef, {
      'reactions.$actorUid': FieldValue.delete(),
      'reactorSnapshots.$actorUid': FieldValue.delete(),
    });
    batch.delete(notifRef);
    await batch.commit();
  }

  @override
  Stream<List<SocialNotification>> watchNotifications(String uid) {
    return _users
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapNotification).toList());
  }

  @override
  Future<void> markNotificationsRead(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  SocialNotification _mapNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SocialNotification(
      id: doc.id,
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorPhoto: data['actorPhoto'] as String?,
      shareId: data['shareId'] as String? ?? '',
      achievementTitle: data['achievementTitle'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '👏',
      createdAt: _readDateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      read: data['read'] == true,
    );
  }

  SocialUnlockedAchievement _mapUnlockedAchievement(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SocialUnlockedAchievement(
      achievementId: data['achievementId'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? '',
      type: data['type'] as String? ?? '',
      domain: data['domain'] as String?,
      ruleId: data['ruleId'] as String?,
      unlockedAt: _readDateTime(data['unlockedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  SocialFriendRequestStatus _mapFriendRequestStatus(String? value) {
    return SocialFriendRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SocialFriendRequestStatus.pending,
    );
  }

  SocialShareVisibility _mapVisibility(String? value) {
    return SocialShareVisibility.values.firstWhere(
      (visibility) => visibility.name == value,
      orElse: () => SocialShareVisibility.friends,
    );
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Iterable<List<T>> _chunk<T>(List<T> values, int size) sync* {
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size < values.length) ? index + size : values.length;
      yield values.sublist(index, end);
    }
  }
}
