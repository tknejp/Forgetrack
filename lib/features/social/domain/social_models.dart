/// Barrel re-export for Social domain types.
///
/// Phase 17 of the domain refactor split the monolithic
/// `social_models.dart` into per-entity files (handle / friend_request
/// / friendship / achievement_share / social_notification /
/// social_user_profile). This file stays as a barrel so existing
/// consumers (12+ presentation widgets, repository implementations,
/// the social provider) keep importing one path without churn. New
/// code may import the per-entity file directly when it only needs
/// one type — both paths resolve to the same class.
library;

export 'achievement_share.dart';
export 'friend_request.dart';
export 'friendship.dart';
export 'handle.dart';
export 'social_notification.dart';
export 'social_user_profile.dart';
