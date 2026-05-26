import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/result/result.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetic_entitlements_source.dart';

class FirestoreCosmeticEntitlementsSource
    implements CosmeticEntitlementsSource {
  FirestoreCosmeticEntitlementsSource({
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('cosmeticEntitlements');

  @override
  Future<Result<List<CosmeticEntitlement>, AppError>> loadForUser(
    String uid,
  ) async {
    if (uid.trim().isEmpty) {
      return const Success<List<CosmeticEntitlement>, AppError>(
          <CosmeticEntitlement>[]);
    }

    try {
      final snapshot = await _collection(uid).get();
      return Success<List<CosmeticEntitlement>, AppError>(
        _mapDocs(snapshot.docs),
      );
    } catch (error, stackTrace) {
      return Failure<List<CosmeticEntitlement>, AppError>(
        classifyFirebaseError(
          error,
          stackTrace,
          endpoint: 'cosmetics.entitlements.loadForUser',
        ),
      );
    }
  }

  @override
  Stream<Result<List<CosmeticEntitlement>, AppError>> watchForUser(
    String uid,
  ) {
    if (uid.trim().isEmpty) {
      return Stream<Result<List<CosmeticEntitlement>, AppError>>.value(
        const Success<List<CosmeticEntitlement>, AppError>(
          <CosmeticEntitlement>[],
        ),
      );
    }

    final transformer = StreamTransformer<
        QuerySnapshot<Map<String, dynamic>>,
        Result<List<CosmeticEntitlement>, AppError>>.fromHandlers(
      handleData: (snapshot, sink) {
        // Synchronous mapping; any unexpected exception (corrupt
        // payload, time-source crash) is converted to a Failure so
        // subscribers never see an uncaught error through the sink.
        try {
          sink.add(
            Success<List<CosmeticEntitlement>, AppError>(
              _mapDocs(snapshot.docs),
            ),
          );
        } catch (error, stackTrace) {
          sink.add(
            Failure<List<CosmeticEntitlement>, AppError>(
              classifyFirebaseError(
                error,
                stackTrace,
                endpoint: 'cosmetics.entitlements.watchForUser.map',
              ),
            ),
          );
        }
      },
      handleError: (error, stackTrace, sink) {
        sink.add(
          Failure<List<CosmeticEntitlement>, AppError>(
            classifyFirebaseError(
              error,
              stackTrace,
              endpoint: 'cosmetics.entitlements.watchForUser',
            ),
          ),
        );
      },
    );

    return _collection(uid).snapshots().transform(transformer);
  }

  List<CosmeticEntitlement> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = _clock();
    final entitlements = <CosmeticEntitlement>[];
    for (final doc in docs) {
      final data = doc.data();
      final active = data['active'];
      if (active is bool && !active) continue;

      final expiresAt = _readDate(data['expiresAt']);
      if (expiresAt != null && !expiresAt.isAfter(now)) continue;

      final cosmeticId = _readNonEmptyString(data['cosmeticId']) ?? doc.id;
      if (cosmeticId.trim().isEmpty) continue;

      entitlements.add(
        CosmeticEntitlement(
          cosmeticId: cosmeticId,
          sourceType: _readNonEmptyString(data['sourceType']) ??
              _readNonEmptyString(data['source']) ??
              CosmeticUnlockSource.promotional.name,
          sourceId: _readNonEmptyString(data['sourceId']) ??
              'firebase_entitlement:${doc.id}',
        ),
      );
    }
    return entitlements;
  }

  static String? _readNonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
