import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/social/domain/social_models.dart';

void main() {
  group('social handles', () {
    test('normalizes display names into handle-safe text', () {
      expect(normalizeSocialHandle(' Tom Novak '), 'tom_novak');
      expect(normalizeSocialHandle('Tom---Novak'), 'tom_novak');
    });

    test('builds numbered handles from the normalized base', () {
      expect(
        buildNumberedSocialHandle(baseHandle: 'Tom Novak', suffix: 0),
        'tom_novak',
      );
      expect(
        buildNumberedSocialHandle(baseHandle: 'Tom Novak', suffix: 1),
        'tom_novak_1',
      );
      expect(
        buildNumberedSocialHandle(baseHandle: 'Tom Novak', suffix: 2),
        'tom_novak_2',
      );
    });

    test('falls back to user when the base has no handle-safe characters', () {
      expect(
        buildNumberedSocialHandle(baseHandle: '!!!', suffix: 0),
        'user',
      );
      expect(
        buildNumberedSocialHandle(baseHandle: '!!!', suffix: 1),
        'user_1',
      );
    });
  });
}
