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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapFriendRequest).toList());
  }

  @override
  Stream<List<SocialFriendRequest>> watchOutgoingFriendRequests({
    required String uid,
  }) {
    return _friendRequests
        .where('fromUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapFriendRequest).toList());
  }

  @override
  Stream<List<SocialFriendship>> watchFriendships({
    required String uid,
  }) {
    return _friendships
        .where('members', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapFriendship).toList());
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
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      shares.addAll(snapshot.docs.map(_mapAchievementShare));
    }

    shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return shares.take(limit).toList(growable: false);
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
