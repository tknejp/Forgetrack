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

  @override
  Future<Result<List<CosmeticEntitlement>, AppError>> loadForUser(
    String uid,
  ) async {
    if (uid.trim().isEmpty) {
      return const Success<List<CosmeticEntitlement>, AppError>(
          <CosmeticEntitlement>[]);
    }

    try {
      final now = _clock();
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cosmeticEntitlements')
          .get();

      final entitlements = <CosmeticEntitlement>[];
      for (final doc in snapshot.docs) {
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

      return Success<List<CosmeticEntitlement>, AppError>(entitlements);
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
