import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/social/domain/social_models.dart';
import 'package:forgetrack/features/social/domain/social_presence.dart';

void main() {
  group('SocialPresence', () {
    test('anonymous sentinel has empty collections + zero unread', () {
      const presence = SocialPresence.anonymous;
      expect(presence.uid, '');
      expect(presence.ownProfile, isNull);
      expect(presence.incomingRequests, isEmpty);
      expect(presence.outgoingRequests, isEmpty);
      expect(presence.friendships, isEmpty);
      expect(presence.friends, isEmpty);
      expect(presence.recentShares, isEmpty);
      expect(presence.notifications, isEmpty);
      expect(presence.unreadNotificationCount, 0);
      expect(presence.hasPendingIncomingRequests, isFalse);
    });

    test('unreadNotificationCount counts only unread', () {
      final presence = SocialPresence(
        uid: 'u1',
        ownProfile: null,
        incomingRequests: const [],
        outgoingRequests: const [],
        friendships: const [],
        friends: const [],
        recentShares: const [],
        notifications: [
          SocialNotification(
            id: 'n1',
            actorUid: 'a',
            actorName: 'A',
            shareId: 's',
            achievementTitle: 't',
            emoji: 'X',
            createdAt: DateTime(2026, 5, 18),
            read: false,
          ),
          SocialNotification(
            id: 'n2',
            actorUid: 'b',
            actorName: 'B',
            shareId: 's',
            achievementTitle: 't',
            emoji: 'X',
            createdAt: DateTime(2026, 5, 18),
            read: true,
          ),
        ],
      );
      expect(presence.unreadNotificationCount, 1);
    });

    test('hasPendingIncomingRequests is true when at least one is pending', () {
      final presence = SocialPresence(
        uid: 'u1',
        ownProfile: null,
        incomingRequests: [
          SocialFriendRequest(
            id: 'r1',
            fromUid: 'b',
            toUid: 'u1',
            status: SocialFriendRequestStatus.pending,
            createdAt: DateTime(2026, 5, 18),
          ),
        ],
        outgoingRequests: const [],
        friendships: const [],
        friends: const [],
        recentShares: const [],
        notifications: const [],
      );
      expect(presence.hasPendingIncomingRequests, isTrue);
    });

    test('copyWith respects null override for ownProfile sentinel', () {
      final base = SocialPresence(
        uid: 'u1',
        ownProfile: SocialUserProfile(
          uid: 'u1',
          displayName: 'A',
          handle: 'a',
          email: 'a@b',
          socialEnabled: true,
          stats: SocialUserStats(
            level: 1,
            totalXp: 0,
            unlockedAchievementCount: 0,
            grantedRewardCount: 0,
            bestStepsStreak: 0,
            bestNutritionStreak: 0,
          ),
        ),
        incomingRequests: const [],
        outgoingRequests: const [],
        friendships: const [],
        friends: const [],
        recentShares: const [],
        notifications: const [],
      );

      // Default copyWith (no ownProfile arg) keeps existing.
      final preserved = base.copyWith(uid: 'u1');
      expect(preserved.ownProfile, isNotNull);

      // Explicit null clears.
      final cleared = base.copyWith(ownProfile: null);
      expect(cleared.ownProfile, isNull);
    });
  });
}
