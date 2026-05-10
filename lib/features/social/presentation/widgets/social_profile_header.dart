import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_equipped_chip.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_frame_preview.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/presentation/widgets/level_badge.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_avatar.dart';
import 'social_edit_handle_sheet.dart';

class SocialProfileHeader extends StatefulWidget {
  const SocialProfileHeader({
    super.key,
    this.showFriendsPill = true,
  });

  final bool showFriendsPill;

  @override
  State<SocialProfileHeader> createState() => _SocialProfileHeaderState();
}

class _SocialProfileHeaderState extends State<SocialProfileHeader> {
  bool _photoBusy = false;

  Future<void> _editHandle(String currentHandle) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditHandleSheet(initialHandle: currentHandle),
    );

    if (next == null) return;
    if (!mounted) return;
    final social = context.read<SocialProvider>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final savedHandle = await social.updateCurrentHandle(next);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          savedHandle == null
              ? l10n.socialHandleSaveFailed(
                  social.error ?? l10n.socialTryAgain,
                )
              : l10n.socialHandleSaved(savedHandle),
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    if (_photoBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    final social = context.read<SocialProvider>();
    final l10n = context.l10n;
    XFile? image;

    try {
      _preferAndroidPhotoPicker();
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 86,
        requestFullMetadata: false,
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.socialPhotoPickFailed(error.toString())),
        ),
      );
      return;
    }

    if (image == null) return;
    if (!mounted) return;

    setState(() => _photoBusy = true);
    final url = await social.uploadCurrentProfilePhoto(image);
    if (!mounted) return;
    setState(() => _photoBusy = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          url == null
              ? l10n.socialPhotoSaveFailed(
                  social.error ?? l10n.socialTryAgain,
                )
              : l10n.socialPhotoSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final social = context.watch<SocialProvider>();
    final uid = social.currentUid ?? auth.user?.id;

    if (!auth.isSignedIn || uid == null) {
      return _HeaderFrame(
        child: Row(
          children: [
            const _SignedOutAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.l10n.profileNotSignedIn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _HeaderActionIcon(
              icon: Icons.login_rounded,
              tooltip: context.l10n.profileContinueWithGoogle,
              onTap: auth.isBusy ? null : () => auth.signIn(),
            ),
          ],
        ),
      );
    }

    final fallbackHandle = buildDefaultSocialHandle(
      uid: uid,
      email: auth.user?.email ?? '',
      displayName: auth.user?.displayName,
    );

    final stream = social.backendReady && social.isReady
        ? social.watchProfileById(uid)
        : Stream<SocialUserProfile?>.value(null);

    return StreamBuilder<SocialUserProfile?>(
      stream: stream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = _firstNonEmpty([
          profile?.displayName,
          auth.user?.displayName,
          auth.user?.email,
          'Forgetrack',
        ]);
        final handle = _firstNonEmpty([
          profile?.handle,
          fallbackHandle,
        ]);
        final photoUrl =
            _clean(profile?.photoUrl) ?? _clean(auth.user?.photoUrl);

        final cosmetics = context.watch<CosmeticsProvider>();
        final equippedFrame = _resolveEquippedFrame(cosmetics);
        final equippedBackground = _resolveEquippedBackground(cosmetics);

        return _HeaderContent(
          displayName: displayName,
          handle: handle,
          photoUrl: photoUrl,
          friendCount: social.friends.length,
          showFriendsPill: widget.showFriendsPill,
          equippedFrame: equippedFrame,
          equippedBackground: equippedBackground,
          onOpenProfile: () => openUserProfile(
            context,
            uid: uid,
            initialDisplayName: displayName,
            initialPhotoUrl: photoUrl,
          ),
          onEditHandle: () => _editHandle(handle),
          onEditPhoto: _pickProfilePhoto,
          photoBusy: _photoBusy,
        );
      },
    );
  }
}

/// Picks the cosmetic frame to render around the hero avatar.
///
/// Priority:
///   1. The frame the user actually equipped.
///   2. UI-only fallback: if nothing is equipped but `frame_pilgrim` is
///      unlocked (every default user has it), preview it. Lets the user
///      see the cosmetics pipeline working before they touch a collection
///      screen — does NOT mutate persisted state.
///   3. Null — no frame, plain avatar.
CosmeticDefinition? _resolveEquippedFrame(CosmeticsProvider cosmetics) {
  final state = cosmetics.state;
  if (state == null) return null;
  final catalog = cosmetics.service.catalog;

  final equippedId = state.equipped.frameId;
  if (equippedId != null) {
    final def = catalog.byId(equippedId);
    if (def != null && def.isEnabled) return def;
  }

  const fallbackId = 'frame_pilgrim';
  if (state.unlocked.containsKey(fallbackId)) {
    final def = catalog.byId(fallbackId);
    if (def != null && def.isEnabled) return def;
  }
  return null;
}

CosmeticDefinition? _resolveEquippedBackground(CosmeticsProvider cosmetics) {
  final state = cosmetics.state;
  if (state == null) return null;
  final catalog = cosmetics.service.catalog;

  final equippedId = state.equipped.backgroundId;
  if (equippedId != null) {
    final def = catalog.byId(equippedId);
    if (def != null && def.isEnabled) return def;
  }

  const fallbackId = 'background_forest_trail';
  if (state.unlocked.containsKey(fallbackId)) {
    final def = catalog.byId(fallbackId);
    if (def != null && def.isEnabled) return def;
  }
  return null;
}

void _preferAndroidPhotoPicker() {
  final implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.displayName,
    required this.handle,
    required this.photoUrl,
    required this.friendCount,
    required this.showFriendsPill,
    required this.equippedFrame,
    required this.equippedBackground,
    required this.onOpenProfile,
    required this.onEditHandle,
    required this.onEditPhoto,
    required this.photoBusy,
  });

  final String displayName;
  final String handle;
  final String? photoUrl;
  final int friendCount;
  final bool showFriendsPill;
  final CosmeticDefinition? equippedFrame;
  final CosmeticDefinition? equippedBackground;
  final VoidCallback onOpenProfile;
  final VoidCallback onEditHandle;
  final VoidCallback onEditPhoto;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionEngineProvider>();
    final profile = progression.profile;
    final levelDisplay =
        const ProgressionDisplayResolver().levelDisplay(profile.level);
    final levelTitle = levelDisplay.title(context.l10n);
    final levelAccent = levelDisplay.accentColor;
    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenProfile,
      child: _HeaderFrame(
        backgroundDefinition: equippedBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CosmeticFramePreview(
                      definition: equippedFrame,
                      size: 80,
                      borderRadius: BorderRadius.circular(22),
                      frameOverscan: 1.16,
                      child: SocialAvatar(
                        name: displayName,
                        size: 80,
                        photoUrl: photoUrl,
                        radius: 22,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: _RoundMiniButton(
                        icon: Icons.photo_camera_rounded,
                        tooltip: context.l10n.socialEditPhotoTooltip,
                        onTap: onEditPhoto,
                        busy: photoBusy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: Tokens.fontSizeTitle,
                                fontWeight: FontWeight.w900,
                                color: Tokens.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Tokens.spaceSm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _HandlePill(
                            handle: handle,
                            onTap: onEditHandle,
                          ),
                          if (showFriendsPill)
                            _FriendCountPill(friendCount: friendCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _LevelBox(level: profile.level),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.progBadgeLevel(
                          profile.level,
                          levelTitle.toUpperCase(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w900,
                          color: levelAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ProgressBar(
                        value: xpProgress,
                        color: Tokens.xp,
                        glow: Tokens.xpGlow,
                        height: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.progBadgeXpRange(
                          profile.xpIntoLevel,
                          xpSpan,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          color: Color(0xA8FFFFFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _EquippedLoadoutRow extends StatelessWidget {
  const _EquippedLoadoutRow();

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return const SizedBox.shrink();
    final equippedDefs = cosmetics.service.getEquippedDefinitions(state);
    if (equippedDefs.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _LoadoutLabel(),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < equippedDefs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: CosmeticEquippedChip(
                      definition: equippedDefs[i],
                      l10n: l10n,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadoutLabel extends StatelessWidget {
  const _LoadoutLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 12,
          color: Tokens.accent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: Tokens.spaceXs),
        SizedBox(
          width: 56,
          child: Text(
            context.l10n.socialSelectedLoadout,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.15,
              color: Tokens.accent.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderFrame extends StatelessWidget {
  const _HeaderFrame({
    required this.child,
    this.backgroundDefinition,
  });

  final Widget child;
  final CosmeticDefinition? backgroundDefinition;

  @override
  Widget build(BuildContext context) {
    final backgroundPath = CosmeticsConfig.standard().resolveAssetPath(
      backgroundDefinition?.previewAssetKey ?? backgroundDefinition?.assetKey,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x267C6FFF),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.9, -1),
            end: Alignment(1, 1),
            colors: [
              Color(0x267C6FFF),
              Color(0x0B31E6D2),
              Color(0x087C6FFF),
            ],
          ),
          image: backgroundPath == null
              ? null
              : DecorationImage(
                  image: AssetImage(backgroundPath),
                  fit: BoxFit.cover,
                  opacity: 0.62,
                ),
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.30)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 14, 14),
          child: child,
        ),
      ),
    );
  }
}

class _HandlePill extends StatelessWidget {
  const _HandlePill({
    required this.handle,
    required this.onTap,
  });

  final String handle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.socialEditHandleTooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 176),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Tokens.radiusProgress),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '@$handle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Tokens.onSurface,
                    fontSize: Tokens.fontSizeSmall,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_rounded,
                size: 13,
                color: Tokens.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendCountPill extends StatelessWidget {
  const _FriendCountPill({required this.friendCount});

  final int friendCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: Tokens.active.dim,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: Tokens.active.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 14,
            color: Tokens.active.color,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.socialFriendCount(friendCount),
            style: TextStyle(
              color: Tokens.active.color,
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBox extends StatelessWidget {
  const _LevelBox({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final accent =
        const ProgressionDisplayResolver().levelDisplay(level).accentColor;
    return LevelBadge(level: level, accentColor: accent, size: 44);
  }
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.065),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? Tokens.onSurfaceFaint : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RoundMiniButton extends StatelessWidget {
  const _RoundMiniButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Tokens.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Tokens.bg, width: 2),
            boxShadow: const [
              BoxShadow(color: Tokens.accentGlow, blurRadius: 10),
            ],
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}

class _SignedOutAvatar extends StatelessWidget {
  const _SignedOutAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.28)),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: Tokens.accent,
        size: 26,
      ),
    );
  }
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
