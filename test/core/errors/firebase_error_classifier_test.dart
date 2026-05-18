import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/core/errors/app_error.dart';
import 'package:forgetrack/core/errors/firebase_error_classifier.dart';

void main() {
  final stack = StackTrace.current;

  FirebaseException fbEx(String code, [String? message]) {
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: code,
      message: message,
    );
  }

  group('classifyFirebaseError', () {
    test('unavailable → transient NetworkError', () {
      final e = classifyFirebaseError(
        fbEx('unavailable'),
        stack,
        endpoint: 'engine.pullEvents',
      );
      expect(e, isA<NetworkError>());
      expect(e.isTransient, isTrue);
      expect((e as NetworkError).endpoint, 'engine.pullEvents');
    });

    test('deadline-exceeded + cancelled + internal → transient NetworkError',
        () {
      for (final code in const [
        'deadline-exceeded',
        'cancelled',
        'internal',
        'aborted',
        'resource-exhausted',
      ]) {
        final e = classifyFirebaseError(fbEx(code), stack);
        expect(e, isA<NetworkError>(),
            reason: 'code=$code should map to NetworkError');
        expect(e.isTransient, isTrue, reason: 'code=$code should be transient');
      }
    });

    test('permission-denied → PermissionError', () {
      final e = classifyFirebaseError(
        fbEx('permission-denied'),
        stack,
        endpoint: 'social.profile',
      );
      expect(e, isA<PermissionError>());
      expect(e.isTransient, isFalse);
      expect((e as PermissionError).scope, 'social.profile');
    });

    test('unauthenticated → PermissionError', () {
      final e = classifyFirebaseError(fbEx('unauthenticated'), stack);
      expect(e, isA<PermissionError>());
      expect(e.isTransient, isFalse);
    });

    test('not-found → NotFoundError', () {
      final e = classifyFirebaseError(
        fbEx('not-found', 'user u1 missing'),
        stack,
        endpoint: 'social.user',
      );
      expect(e, isA<NotFoundError>());
      expect(e.isTransient, isFalse);
      expect((e as NotFoundError).id, 'user u1 missing');
    });

    test(
        'invalid-argument / failed-precondition / out-of-range / already-exists '
        '→ ValidationError', () {
      for (final code in const [
        'invalid-argument',
        'failed-precondition',
        'out-of-range',
        'already-exists',
      ]) {
        final e = classifyFirebaseError(fbEx(code, 'bad'), stack);
        expect(e, isA<ValidationError>(),
            reason: 'code=$code should map to ValidationError');
        expect(e.isTransient, isFalse,
            reason: 'code=$code should be permanent');
      }
    });

    test('unknown code → transient UpstreamError', () {
      final e = classifyFirebaseError(fbEx('weirdo-new-code'), stack);
      expect(e, isA<UpstreamError>());
      expect(e.isTransient, isTrue);
    });

    test('non-Firebase exception → UpstreamError preserving cause', () {
      final boom = StateError('boom');
      final e = classifyFirebaseError(boom, stack, endpoint: 'engine.pull');
      expect(e, isA<UpstreamError>());
      expect(e.originalError, boom);
      expect(e.isTransient, isTrue);
    });

    test('original error + stack trace preserved through classification', () {
      final ex = fbEx('unavailable');
      final e = classifyFirebaseError(ex, stack);
      expect(e.originalError, ex);
      expect(e.stackTrace, stack);
    });
  });
}
