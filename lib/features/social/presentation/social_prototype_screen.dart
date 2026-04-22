import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../features/progression/presentation/progression_provider.dart';
import '../../../screens/profile/widgets/profile_settings_widgets.dart';
import '../../../screens/profile/widgets/profile_section.dart';
import '../application/social_provider.dart';
import '../domain/social_models.dart';

class SocialPrototypeScreen extends StatefulWidget {
  const SocialPrototypeScreen({super.key});

  @override
  State<SocialPrototypeScreen> createState() => _SocialPrototypeScreenState();
}

class _SocialPrototypeScreenState extends State<SocialPrototypeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final progression = context.watch<ProgressionProvider>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;
    final unlockedAchievements = progression.achievements
        .where((achievement) => achievement.unlocked)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Prototype'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ProfileSection(
            title: 'Status',
            child: ProfileSettingsCard(
              children: [
                ProfileSettingsTile(
                  icon: social.backendReady
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  iconColor:
                      social.backendReady ? cs.primary : cs.onSurfaceVariant,
                  label: social.backendReady
                      ? 'Firebase social backend is ready'
                      : 'Firebase social backend is unavailable',
                  subtitle: social.error ?? social.backendMessage,
                ),
                const ProfileTileDivider(),
                ProfileSettingsTile(
                  icon: auth.isSignedIn
                      ? Icons.verified_user_outlined
                      : Icons.person_off_outlined,
                  label: auth.isSignedIn
                      ? 'Signed in as ${user?.email ?? 'unknown'}'
                      : 'Google sign-in required',
                  subtitle: auth.isSignedIn
                      ? 'Social sync will publish your profile, level and unlocked achievements.'
                      : 'Sign in with Google first to test the friends-only prototype.',
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'My Profile',
            child: ProfileSettingsCard(
              children: [
                ProfileSettingsTile(
                  icon: Icons.badge_outlined,
                  label: _resolveDisplayName(user),
                  subtitle:
                      '@${buildDefaultSocialHandle(uid: user?.id ?? 'user', email: user?.email ?? 'user@example.com', displayName: user?.displayName)}',
                  trailingLabel: 'Lv ${progression.profile.level}',
                ),
                const ProfileTileDivider(),
                ProfileSettingsTile(
                  icon: Icons.auto_awesome_outlined,
                  label: '${progression.profile.totalXp} XP',
                  subtitle:
                      '${unlockedAchievements.length} unlocked achievements, ${progression.claimedRewards.length} claimed rewards',
                  trailingLabel: '${social.friends.length} friends',
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Find Friends',
            child: _SearchCard(
              controller: _searchController,
              isSearching: social.isSearching,
              results: social.searchResults,
              onSearch: () async {
                await context
                    .read<SocialProvider>()
                    .searchUsers(_searchController.text);
              },
              onSendRequest: (uid) async {
                await context.read<SocialProvider>().sendFriendRequest(uid);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request sent.')),
                );
              },
            ),
          ),
          ProfileSection(
            title: 'Requests',
            child: ProfileSettingsCard(
              children: _buildRequestTiles(
                context,
                social: social,
              ),
            ),
          ),
          ProfileSection(
            title: 'Leaderboard',
            child: ProfileSettingsCard(
              children: _buildLeaderboardTiles(social.friends),
            ),
          ),
          ProfileSection(
            title: 'Share Achievement',
            child: ProfileSettingsCard(
              children: _buildShareTiles(
                context,
                unlockedAchievements: unlockedAchievements,
              ),
            ),
          ),
          ProfileSection(
            title: 'Friends Feed',
            bottomSpacing: 0,
            child: ProfileSettingsCard(
              children: _buildFeedTiles(social.recentShares),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRequestTiles(
    BuildContext context, {
    required SocialProvider social,
  }) {
    final widgets = <Widget>[];

    if (social.incomingRequests.isEmpty && social.outgoingRequests.isEmpty) {
      widgets.add(
        const ProfileSettingsTile(
          icon: Icons.mark_email_read_outlined,
          label: 'No friend requests yet',
          subtitle: 'Incoming and outgoing requests will show up here.',
        ),
      );
      return widgets;
    }

    if (social.incomingRequests.isNotEmpty) {
      for (final request in social.incomingRequests) {
        widgets.add(
          ProfileSettingsTile(
            icon: Icons.call_received_rounded,
            label: 'Incoming request',
            subtitle: 'From ${request.fromUid}',
            trailing: Wrap(
              spacing: 8,
              children: [
                _InlineActionChip(
                  label: 'Accept',
                  onTap: () => context
                      .read<SocialProvider>()
                      .acceptFriendRequest(request.id),
                ),
                _InlineActionChip(
                  label: 'Decline',
                  onTap: () => context
                      .read<SocialProvider>()
                      .declineFriendRequest(request.id),
                ),
              ],
            ),
          ),
        );
        widgets.add(const ProfileTileDivider());
      }
    }

    if (social.outgoingRequests.isNotEmpty) {
      for (final request in social.outgoingRequests) {
        widgets.add(
          ProfileSettingsTile(
            icon: Icons.call_made_rounded,
            label: 'Outgoing request',
            subtitle: 'Waiting for ${request.toUid}',
            trailingLabel: request.status.name,
          ),
        );
        widgets.add(const ProfileTileDivider());
      }
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets;
  }

  List<Widget> _buildLeaderboardTiles(List<SocialUserProfile> friends) {
    if (friends.isEmpty) {
      return const [
        ProfileSettingsTile(
          icon: Icons.leaderboard_outlined,
          label: 'Leaderboard is empty',
          subtitle: 'Add a friend and their public profile will appear here.',
        ),
      ];
    }

    final ranked = [...friends]..sort((a, b) {
        final xpCompare = b.stats.totalXp.compareTo(a.stats.totalXp);
        if (xpCompare != 0) return xpCompare;
        return b.stats.level.compareTo(a.stats.level);
      });

    final widgets = <Widget>[];
    for (var index = 0; index < ranked.length; index++) {
      final friend = ranked[index];
      widgets.add(
        ProfileSettingsTile(
          icon: Icons.emoji_events_outlined,
          label: '${index + 1}. ${friend.displayName}',
          subtitle:
              'Level ${friend.stats.level} • ${friend.stats.unlockedAchievementCount} achievements',
          trailingLabel: '${friend.stats.totalXp} XP',
        ),
      );
      widgets.add(const ProfileTileDivider());
    }
    widgets.removeLast();
    return widgets;
  }

  List<Widget> _buildShareTiles(
    BuildContext context, {
    required List<dynamic> unlockedAchievements,
  }) {
    if (unlockedAchievements.isEmpty) {
      return const [
        ProfileSettingsTile(
          icon: Icons.workspace_premium_outlined,
          label: 'No unlocked achievements yet',
          subtitle:
              'Unlock something in progression and you can share it here.',
        ),
      ];
    }

    final recent = unlockedAchievements.reversed.take(5).toList();
    final widgets = <Widget>[];
    for (final achievement in recent) {
      widgets.add(
        ProfileSettingsTile(
          icon: Icons.workspace_premium_outlined,
          label: achievement.title as String,
          subtitle: achievement.description as String,
          trailing: _InlineActionChip(
            label: 'Share',
            onTap: () async {
              await context
                  .read<SocialProvider>()
                  .shareAchievement(achievement.id as String);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${achievement.title} shared.')),
              );
            },
          ),
        ),
      );
      widgets.add(const ProfileTileDivider());
    }
    widgets.removeLast();
    return widgets;
  }

  List<Widget> _buildFeedTiles(List<SocialAchievementShare> shares) {
    if (shares.isEmpty) {
      return const [
        ProfileSettingsTile(
          icon: Icons.forum_outlined,
          label: 'Friends feed is empty',
          subtitle: 'Shared achievements from friends will appear here.',
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final share in shares) {
      widgets.add(
        ProfileSettingsTile(
          icon: Icons.campaign_outlined,
          label:
              '${share.actorSnapshot.displayName} shared ${share.achievementSnapshot.title}',
          subtitle: share.message ?? share.achievementSnapshot.description,
        ),
      );
      widgets.add(const ProfileTileDivider());
    }
    widgets.removeLast();
    return widgets;
  }

  String _resolveDisplayName(dynamic user) {
    final displayName = user?.displayName?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return user?.email?.toString() ?? 'Guest';
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.onSearch,
    required this.onSendRequest,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<SocialUserProfile> results;
  final Future<void> Function() onSearch;
  final Future<void> Function(String uid) onSendRequest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  hintText: 'Search by handle',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isSearching ? null : onSearch,
              child: Text(isSearching ? '...' : 'Find'),
            ),
          ],
        ),
      ),
    ];

    if (results.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Try a handle prefix like `tom` or `petr`.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
      );
      return ProfileSettingsCard(children: widgets);
    }

    widgets.add(const ProfileTileDivider(indent: 0));
    for (final result in results) {
      widgets.add(
        ProfileSettingsTile(
          icon: Icons.person_add_alt_1_outlined,
          label: result.displayName,
          subtitle:
              '@${result.handle} • Level ${result.stats.level} • ${result.stats.totalXp} XP',
          trailing: _InlineActionChip(
            label: 'Add',
            onTap: () => onSendRequest(result.uid),
          ),
        ),
      );
      widgets.add(const ProfileTileDivider());
    }
    widgets.removeLast();
    return ProfileSettingsCard(children: widgets);
  }
}

class _InlineActionChip extends StatelessWidget {
  const _InlineActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
