/// Backwards-compatibility shim.
///
/// Phase 17 of the domain refactor renamed `SocialRepository` →
/// [SocialPresenceRepository] (`social_presence_repository.dart`).
/// This file re-exports the new symbol + provides a deprecated
/// typedef so existing consumers (the data-layer implementations
/// `FirestoreSocialRepository` / `DisabledSocialRepository`, the
/// `SocialProvider`, `main.dart` bootstrap) compile unchanged. New
/// code should import the new file directly and reference the new
/// name.
library;

export 'social_presence_repository.dart';

import 'social_presence_repository.dart';

@Deprecated('Renamed to SocialPresenceRepository in Phase 17 of the '
    'domain refactor. Import social_presence_repository.dart and '
    'reference SocialPresenceRepository directly.')
typedef SocialRepository = SocialPresenceRepository;
