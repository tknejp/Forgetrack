import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/result/result.dart';
import '../../../shared/domain/rarity.dart';
import '../domain/social_models.dart';
import '../domain/social_presence_repository.dart';

class FirestoreSocialRepository implements SocialPresenceRepository {
  FirestoreSocialRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Wraps a Firestore call in the typed [Result] envelope so callers
  /// pattern-match on [AppError] severity instead of catching `Object`.
  /// Every social-repo method funnels through here — keeps the classify
  /// call site uniform and makes the per-call `endpoint` tag visible
  /// in AppLog dumps (`error=permission|social.sendFriendRequest`).
  Future<Result<T, AppError>> _classify<T>(
    String endpoint,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T, AppError>(await action());
    } catch (error, stackTrace) {
      return Failure<T, AppError>(
        classifyFirebaseError(
          error,
          stackTrace,
          endpoint: 'social.$endpoint',
        ),
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _firestore.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  CollectionReference<Map<String, dynamic>> get _achievementShares =>
      _firestore.collection('achievement_shares');

  CollectionReference<Map<String, dynamic>> get _handles =>
      _firestore.collection('handles');

  CollectionReference<Map<String, dynamic>> _engineNodeCompletions(String uid) =>
      _users.doc(uid).collection('engineNodeCompletions');

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
  Future<Result<List<SocialUserProfile>, AppError>> fetchProfilesByIds(
    Iterable<String> uids,
  ) =>
      _classify('fetchProfilesByIds', () async {
        final ids = uids.toSet().where((uid) => uid.isNotEmpty).toList();
        if (ids.isEmpty) return const <SocialUserProfile>[];

        final profiles = <SocialUserProfile>[];
        for (final chunk in _chunk(ids, 10)) {
          final snapshot =
              await _users.where(FieldPath.documentId, whereIn: chunk).get();
          profiles.addAll(snapshot.docs.map(_mapUserProfile));
        }

        profiles.sort((a, b) => a.displayName.compareTo(b.displayName));
        return profiles;
      });

  @override
  Future<Result<List<SocialUserProfile>, AppError>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  }) =>
      _classify('searchProfilesByHandle', () async {
        final normalized = normalizeSocialHandle(query);
        if (normalized.isEmpty) return const <SocialUserProfile>[];

        final snapshot = await _users
            .where('handleSearchTokens', arrayContains: normalized)
            .limit(limit + 4)
            .get();

        final results = snapshot.docs
            .map(_mapUserProfile)
            .where((profile) =>
                profile.uid != excludeUid && profile.socialEnabled)
            .toList();

        results.sort((a, b) => a.handle.compareTo(b.handle));
        return results.take(limit).toList(growable: false);
      });

  @override
  Future<Result<List<SocialAchievementShare>, AppError>>
      fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) =>
          _classify('fetchRecentAchievementShares', () async {
            final ids =
                actorUids.toSet().where((uid) => uid.isNotEmpty).toList();
            if (ids.isEmpty) return const <SocialAchievementShare>[];

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
          });

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
  Future<Result<void, AppError>> upsertProfile(
    SocialProfileSyncPayload payload,
  ) =>
      _classify('upsertProfile', () async {
        final doc = _users.doc(payload.uid);

        await _firestore.runTransaction((transaction) async {
          final userSnapshot = await transaction.get(doc);
          final existingData = userSnapshot.data();
          final existingHandle =
              normalizeSocialHandle(existingData?['handle'] as String? ?? '');
          final existingPhotoUrl =
              (existingData?['photoUrl'] as String?)?.trim();
          final effectivePhotoUrl = existingPhotoUrl?.isNotEmpty == true
              ? existingPhotoUrl
              : payload.photoUrl;

          final handleReservation = await _reserveHandleInTransaction(
            transaction: transaction,
            uid: payload.uid,
            desiredHandle: payload.handle,
            existingHandle: existingHandle,
          );

          transaction.set(
            handleReservation.ref,
            {
              'uid': payload.uid,
              'handle': handleReservation.handle,
              'baseHandle': normalizeSocialHandle(payload.handle),
              'updatedAt': FieldValue.serverTimestamp(),
              if (!handleReservation.exists)
                'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            doc,
            _profileData(
              payload: payload.copyWith(photoUrl: effectivePhotoUrl),
              handle: handleReservation.handle,
              includeCreatedAt: !userSnapshot.exists,
            ),
            SetOptions(merge: true),
          );
        });
      });

  @override
  Future<Result<String, AppError>> updateProfileHandle({
    required String uid,
    required String desiredHandle,
  }) =>
      _classify('updateProfileHandle', () async {
        final doc = _users.doc(uid);
        final normalizedDesired = normalizeSocialHandle(desiredHandle);
        if (normalizedDesired.isEmpty) {
          throw ArgumentError('Social ID cannot be empty.');
        }

        return _firestore.runTransaction<String>((transaction) async {
      final userSnapshot = await transaction.get(doc);
      final existingData = userSnapshot.data();
      final existingHandle =
          normalizeSocialHandle(existingData?['handle'] as String? ?? '');

      DocumentReference<Map<String, dynamic>>? selectedRef;
      String? selectedHandle;
      var selectedExists = false;

      for (var suffix = 0; suffix < 1000; suffix++) {
        final candidate = buildNumberedSocialHandle(
          baseHandle: normalizedDesired,
          suffix: suffix,
        );
        final candidateRef = _handles.doc(candidate);
        final candidateSnapshot = await transaction.get(candidateRef);
        final reservationUid = candidateSnapshot.data()?['uid'] as String?;

        if (!candidateSnapshot.exists ||
            reservationUid == uid ||
            candidate == existingHandle) {
          selectedRef = candidateRef;
          selectedHandle = candidate;
          selectedExists = candidateSnapshot.exists;
          break;
        }
      }

      if (selectedRef == null || selectedHandle == null) {
        throw StateError(
            'No available social handle for "$normalizedDesired".');
      }

      if (existingHandle.isNotEmpty && existingHandle != selectedHandle) {
        final oldRef = _handles.doc(existingHandle);
        final oldSnapshot = await transaction.get(oldRef);
        if (oldSnapshot.data()?['uid'] == uid) {
          transaction.delete(oldRef);
        }
      }

      transaction.set(
        selectedRef,
        {
          'uid': uid,
          'handle': selectedHandle,
          'baseHandle': normalizedDesired,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!selectedExists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        doc,
        {
          'handle': selectedHandle,
          'handleLower': selectedHandle.toLowerCase(),
          'handleSearchTokens': buildSocialHandleSearchTokens(selectedHandle),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return selectedHandle;
    });
      });

  @override
  Future<Result<void, AppError>> updatePinnedAchievement({
    required String uid,
    required String achievementId,
    required bool pinned,
  }) =>
      _classify('updatePinnedAchievement', () async {
        final normalizedId = achievementId.trim();
        if (normalizedId.isEmpty) return;

        await _users.doc(uid).set(
          {
            'pinnedAchievementIds': pinned
                ? FieldValue.arrayUnion([normalizedId])
                : FieldValue.arrayRemove([normalizedId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

  @override
  Future<Result<void, AppError>> updateStatVisibilityOverrides({
    required String uid,
    required Set<String> statVisibilityOverrides,
  }) =>
      _classify('updateStatVisibilityOverrides', () async {
        await _users.doc(uid).set(
          {
            'statVisibilityOverrides':
                statVisibilityOverrides.toList(growable: false),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

  Future<
      ({
        DocumentReference<Map<String, dynamic>> ref,
        String handle,
        bool exists
      })> _reserveHandleInTransaction({
    required Transaction transaction,
    required String uid,
    required String desiredHandle,
    required String existingHandle,
  }) async {
    final normalizedDesired = normalizeSocialHandle(desiredHandle);
    final baseHandle =
        normalizedDesired.isNotEmpty ? normalizedDesired : 'user';

    if (existingHandle.isNotEmpty) {
      final existingRef = _handles.doc(existingHandle);
      final existingReservation = await transaction.get(existingRef);
      final reservationUid = existingReservation.data()?['uid'] as String?;
      if (!existingReservation.exists || reservationUid == uid) {
        return (
          ref: existingRef,
          handle: existingHandle,
          exists: existingReservation.exists,
        );
      }
    }

    for (var suffix = 0; suffix < 1000; suffix++) {
      final candidate = buildNumberedSocialHandle(
        baseHandle: baseHandle,
        suffix: suffix,
      );
      final candidateRef = _handles.doc(candidate);
      final candidateReservation = await transaction.get(candidateRef);
      final reservationUid = candidateReservation.data()?['uid'] as String?;
      if (!candidateReservation.exists || reservationUid == uid) {
        return (
          ref: candidateRef,
          handle: candidate,
          exists: candidateReservation.exists,
        );
      }
    }

    throw StateError('No available social handle for "$baseHandle".');
  }

  Map<String, dynamic> _profileData({
    required SocialProfileSyncPayload payload,
    required String handle,
    required bool includeCreatedAt,
  }) {
    return {
      'displayName': payload.displayName,
      'email': payload.email,
      'handle': handle,
      'handleLower': handle.toLowerCase(),
      'handleSearchTokens': buildSocialHandleSearchTokens(handle),
      'photoUrl': payload.photoUrl,
      'raceId': payload.raceId,
      'socialEnabled': payload.socialEnabled,
      'equippedCosmetics': {
        'frameId': payload.equippedCosmetics.frameId,
        'relicId': payload.equippedCosmetics.relicId,
        'backgroundId': payload.equippedCosmetics.backgroundId,
        'emblemId': payload.equippedCosmetics.emblemId,
        'companionId': payload.equippedCosmetics.companionId,
        'titleFlairId': payload.equippedCosmetics.titleFlairId,
        'mapEffectId': payload.equippedCosmetics.mapEffectId,
        'skinId': payload.equippedCosmetics.skinId,
        'bannerId': payload.equippedCosmetics.bannerId,
      },
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'stats': {
        'level': payload.stats.level,
        'totalXp': payload.stats.totalXp,
        'unlockedAchievementCount': payload.stats.unlockedAchievementCount,
        'grantedRewardCount': payload.stats.grantedRewardCount,
        'bestStepsStreak': payload.stats.bestStepsStreak,
        'bestNutritionStreak': payload.stats.bestNutritionStreak,
        'updatedAt': FieldValue.serverTimestamp(),
        // Personal-metric cache. Nullable wire entries — older
        // clients reading the doc treat missing fields as unknown
        // and render `—`. Newer clients see the value when present
        // and the owner has not blacklisted the corresponding stat
        // key.
        'stepsLifetime': payload.stats.stepsLifetime,
        'stepsAvg30d': payload.stats.stepsAvg30d,
        'activeDays30d': payload.stats.activeDays30d,
        'avgSleepMinutes7d': payload.stats.avgSleepMinutes7d,
        'avgBedtimeMinutes7d': payload.stats.avgBedtimeMinutes7d,
        'avgWakeMinutes7d': payload.stats.avgWakeMinutes7d,
        'avgDeepMinutes7d': payload.stats.avgDeepMinutes7d,
        'avgRemMinutes7d': payload.stats.avgRemMinutes7d,
        'latestWeightKg': payload.stats.latestWeightKg,
        'latestBodyFatPct': payload.stats.latestBodyFatPct,
        'avgKcal7d': payload.stats.avgKcal7d,
        'avgProteinG7d': payload.stats.avgProteinG7d,
        'avgFatG7d': payload.stats.avgFatG7d,
        'avgCarbsG7d': payload.stats.avgCarbsG7d,
        'cosmeticsUnlocked': payload.stats.cosmeticsUnlocked,
      },
      // NOTE: `hiddenStatKeys` is intentionally NOT written here. It is
      // a user preference, not a projection-derivable cache field;
      // routing it through the upsertProfile rebuild path would let
      // every progression-driven re-publish overwrite the user's
      // visibility choices. The dedicated [updateHiddenStatKeys] write
      // owns the field — `SetOptions(merge: true)` above preserves it
      // across rebuilds.
    };
  }

  @override
  Future<Result<void, AppError>> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) =>
      _classify('sendFriendRequest', () async {
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

          // Duplicate-pending guard. The wider check (`participantsKey`
          // alone) would also catch the case where the OTHER party
          // already sent us a request, but that query isn't rule-safe:
          // the read rule's `fromUid == auth.uid || toUid == auth.uid`
          // disjunction depends on doc data the query doesn't constrain,
          // so Firestore preventively denies the list. Narrowing to our
          // outgoing request via `fromUid == auth.uid` makes the query
          // structurally satisfy the first OR-clause and Firestore lets
          // it through. The counter-party-sent-first case is a UX edge
          // (rare; the user normally accepts the incoming request from
          // their notifications instead of re-requesting), so we accept
          // a possible duplicate pending doc rather than widening the
          // rule.
          final duplicateSnapshot = await _friendRequests
              .where('fromUid', isEqualTo: fromUid)
              .where('toUid', isEqualTo: toUid)
              .where('status',
                  isEqualTo: SocialFriendRequestStatus.pending.name)
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
      });

  @override
  Future<Result<void, AppError>> acceptFriendRequest({
    required String requestId,
  }) =>
      _classify('acceptFriendRequest', () async {
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
      });

  @override
  Future<Result<void, AppError>> declineFriendRequest({
    required String requestId,
  }) =>
      _classify('declineFriendRequest', () async {
        await _friendRequests.doc(requestId).update({
          'status': SocialFriendRequestStatus.declined.name,
          'respondedAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<Result<List<RemoteEngineNodeCompletion>, AppError>>
      fetchEngineNodeCompletions(String uid) =>
          _classify('fetchEngineNodeCompletions', () async {
            final snapshot = await _engineNodeCompletions(uid).get();
            return snapshot.docs
                .map(_mapEngineNodeCompletion)
                .toList(growable: false);
          });

  @override
  Future<Result<void, AppError>> shareAchievement(
    SocialAchievementShare share,
  ) =>
      _classify('shareAchievement', () async {
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
            'rarity': share.achievementSnapshot.rarity.name,
            'domain': share.achievementSnapshot.domain,
          },
        });
      });

  @override
  Future<Result<void, AppError>> deleteAchievementShare({
    required String shareId,
  }) =>
      _classify('deleteAchievementShare', () async {
        await _achievementShares.doc(shareId).delete();
      });

  @override
  Stream<List<RemoteEngineNodeCompletion>> watchEngineNodeCompletions(
    String uid,
  ) {
    return _engineNodeCompletions(uid).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(_mapEngineNodeCompletion).toList(growable: false),
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
    final equipped =
        data['equippedCosmetics'] as Map<String, dynamic>? ?? const {};

    return SocialUserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      raceId: _readNonEmptyString(data['raceId']),
      socialEnabled: data['socialEnabled'] == true,
      pinnedAchievementIds:
          (data['pinnedAchievementIds'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
      statVisibilityOverrides: {
        for (final value
            in (data['statVisibilityOverrides'] as List<dynamic>? ?? const []))
          if (value is String && value.isNotEmpty) value,
      },
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
      equippedCosmetics: SocialEquippedCosmetics(
        frameId: _readNonEmptyString(equipped['frameId']),
        relicId: _readNonEmptyString(equipped['relicId']),
        backgroundId: _readNonEmptyString(equipped['backgroundId']),
        emblemId: _readNonEmptyString(equipped['emblemId']),
        companionId: _readNonEmptyString(equipped['companionId']),
        titleFlairId: _readNonEmptyString(equipped['titleFlairId']),
        mapEffectId: _readNonEmptyString(equipped['mapEffectId']),
        skinId: _readNonEmptyString(equipped['skinId']),
        bannerId: _readNonEmptyString(equipped['bannerId']),
      ),
      stats: SocialUserStats(
        level: _readInt(stats['level']),
        totalXp: _readInt(stats['totalXp']),
        unlockedAchievementCount: _readInt(stats['unlockedAchievementCount']),
        grantedRewardCount: _readInt(stats['grantedRewardCount']),
        bestStepsStreak: _readInt(stats['bestStepsStreak']),
        bestNutritionStreak: _readInt(stats['bestNutritionStreak']),
        updatedAt: _readDateTime(stats['updatedAt']),
        stepsLifetime: _readIntOrNull(stats['stepsLifetime']),
        stepsAvg30d: _readIntOrNull(stats['stepsAvg30d']),
        activeDays30d: _readIntOrNull(stats['activeDays30d']),
        avgSleepMinutes7d: _readIntOrNull(stats['avgSleepMinutes7d']),
        avgBedtimeMinutes7d: _readIntOrNull(stats['avgBedtimeMinutes7d']),
        avgWakeMinutes7d: _readIntOrNull(stats['avgWakeMinutes7d']),
        avgDeepMinutes7d: _readIntOrNull(stats['avgDeepMinutes7d']),
        avgRemMinutes7d: _readIntOrNull(stats['avgRemMinutes7d']),
        latestWeightKg: _readDoubleOrNull(stats['latestWeightKg']),
        latestBodyFatPct: _readDoubleOrNull(stats['latestBodyFatPct']),
        avgKcal7d: _readDoubleOrNull(stats['avgKcal7d']),
        avgProteinG7d: _readDoubleOrNull(stats['avgProteinG7d']),
        avgFatG7d: _readDoubleOrNull(stats['avgFatG7d']),
        avgCarbsG7d: _readDoubleOrNull(stats['avgCarbsG7d']),
        cosmeticsUnlocked: _readIntOrNull(stats['cosmeticsUnlocked']),
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
        rarity: _readRarity(achievementSnapshot['rarity']),
        domain: achievementSnapshot['domain'] as String?,
      ),
      reactions: reactions,
      reactorSnapshots: reactorSnapshots,
    );
  }

  @override
  Future<Result<void, AppError>> removeFriend({
    required String friendshipId,
  }) =>
      _classify('removeFriend', () async {
        await _friendships.doc(friendshipId).delete();
      });

  @override
  Future<Result<void, AppError>> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  }) =>
      _classify('addReaction', () async {
        final shareRef = _achievementShares.doc(shareId);
        final isSelfReaction = actorUid == shareOwnerUid;

        // Batch-set the share's reaction map alongside (when this is
        // a cross-user reaction) a fresh notification doc under the
        // share owner's subcollection. A WriteBatch is enough — the
        // old transaction-with-`get` shape was failing because the
        // existence probe (`transaction.get(notifRef)`) reads a doc
        // owned by the share owner, which the actor isn't allowed to
        // read under the `notifications` rule, so the whole
        // transaction rolled back with permission-denied and the
        // reaction was silently dropped.
        //
        // Side effect of dropping the probe: a re-reaction (player
        // changes their emoji on the same share) now overwrites the
        // existing notification with `read: false` instead of
        // skipping the notification write. That re-badges the owner
        // on every reaction change — matches the "this is fresh
        // activity" intent of the bell and feels closer to other
        // social apps than the silent old behaviour.
        final batch = _firestore.batch();

        batch.update(shareRef, {
          'reactions.$actorUid': emoji,
          'reactorSnapshots.$actorUid': {
            'displayName': actorName,
            'photoUrl': actorPhoto,
          },
        });

        if (!isSelfReaction) {
          final notifRef = _users
              .doc(shareOwnerUid)
              .collection('notifications')
              .doc('${shareId}_$actorUid');
          batch.set(notifRef, {
            'type': 'reaction',
            'actorUid': actorUid,
            'actorName': actorName,
            'actorPhoto': actorPhoto,
            'shareId': shareId,
            'achievementTitle': achievementTitle,
            'emoji': emoji,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        }

        await batch.commit();
      });

  @override
  Future<Result<void, AppError>> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  }) =>
      _classify('removeReaction', () async {
        final shareRef = _achievementShares.doc(shareId);

        await shareRef.update({
          'reactions.$actorUid': FieldValue.delete(),
          'reactorSnapshots.$actorUid': FieldValue.delete(),
        });
      });

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
  Future<Result<void, AppError>> markNotificationsRead(String uid) =>
      _classify('markNotificationsRead', () async {
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
      });

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

  RemoteEngineNodeCompletion _mapEngineNodeCompletion(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RemoteEngineNodeCompletion(
      nodeId: data['nodeId'] as String? ?? '',
      completedAt: _readDateTime(data['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      periodKey: data['periodKey'] as String?,
    );
  }

  Rarity _readRarity(dynamic value) {
    if (value is String && value.isNotEmpty) {
      for (final r in Rarity.values) {
        if (r.name == value) return r;
      }
    }
    return Rarity.common;
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

  int? _readIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  double? _readDoubleOrNull(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }

  String? _readNonEmptyString(dynamic value) {
    final text = (value as String?)?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Iterable<List<T>> _chunk<T>(List<T> values, int size) sync* {
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size < values.length) ? index + size : values.length;
      yield values.sublist(index, end);
    }
  }
}
