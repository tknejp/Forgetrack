import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/core/errors/app_error.dart';
import 'package:forgetrack/core/result/result.dart';

void main() {
  group('Result', () {
    test('Success carries value, isSuccess true', () {
      const Result<int, AppError> r = Success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      switch (r) {
        case Success(value: final v):
          expect(v, 42);
        case Failure():
          fail('expected Success');
      }
    });

    test('Failure carries error, isFailure true', () {
      const err = ValidationError(reason: 'bad input');
      const Result<int, AppError> r = Failure(err);
      expect(r.isFailure, isTrue);
      expect(r.isSuccess, isFalse);
      switch (r) {
        case Success():
          fail('expected Failure');
        case Failure(error: final e):
          expect(e, err);
      }
    });

    test('map transforms success payload, no-op on failure', () {
      const ok = Success<int, AppError>(3);
      final mapped = ok.map((v) => v * 2);
      expect((mapped as Success).value, 6);

      const fail = Failure<int, AppError>(
        ValidationError(reason: 'nope'),
      );
      final mappedFail = fail.map((v) => v * 2);
      expect(mappedFail, isA<Failure<int, AppError>>());
    });

    test('flatMap chains success, short-circuits on failure', () {
      const ok = Success<int, AppError>(3);
      final chained =
          ok.flatMap<String>((v) => Success<String, AppError>('val=$v'));
      expect((chained as Success).value, 'val=3');

      const fail = Failure<int, AppError>(
        NetworkError(isTransient: true),
      );
      final shortCircuited =
          fail.flatMap<String>((v) => Success<String, AppError>('unreachable'));
      expect(shortCircuited, isA<Failure<String, AppError>>());
    });

    test('unwrapOr returns success value, fallback on failure', () {
      const ok = Success<int, AppError>(7);
      expect(ok.unwrapOr(0), 7);

      const fail = Failure<int, AppError>(
        NetworkError(isTransient: false),
      );
      expect(fail.unwrapOr(99), 99);
    });

    test('equality is value-based', () {
      expect(
        const Success<int, AppError>(1),
        equals(const Success<int, AppError>(1)),
      );
      expect(
        const Success<int, AppError>(1),
        isNot(equals(const Success<int, AppError>(2))),
      );
    });
  });

  group('AppError severity', () {
    test('NetworkError defaults transient; explicit false sticks', () {
      expect(const NetworkError().isTransient, isTrue);
      expect(const NetworkError(isTransient: false).isTransient, isFalse);
    });

    test('Validation / Permission / NotFound are permanent', () {
      expect(const ValidationError(reason: 'x').isTransient, isFalse);
      expect(const PermissionError(scope: 'hc.steps').isTransient, isFalse);
      expect(const NotFoundError(entityType: 'user', id: 'u1').isTransient,
          isFalse);
    });

    test('UpstreamError defaults transient', () {
      expect(const UpstreamError().isTransient, isTrue);
      expect(
        const UpstreamError(isTransient: false).isTransient,
        isFalse,
      );
    });

    test('labels are stable for log/devtools display', () {
      expect(
        const NetworkError(endpoint: 'kt.day', statusCode: 401).label,
        'network|kt.day|http=401|transient',
      );
      expect(
        const ValidationError(reason: 'empty handle').label,
        'validation|empty handle',
      );
      expect(
        const PermissionError(scope: 'hc.steps').label,
        'permission|hc.steps',
      );
      expect(
        const NotFoundError(entityType: 'user', id: 'u1').label,
        'not_found|user:u1',
      );
      expect(
        const UpstreamError(context: 'sync push', isTransient: false).label,
        'upstream|sync push|permanent',
      );
    });
  });
}
