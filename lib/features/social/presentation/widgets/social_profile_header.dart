import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../../../shared/widgets/ft/ft_progress_bar.dart';
import '../../../../shared/widgets/ft/ft_progression_xp_style.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../progression/application/progression_provider.dart';
import '../../../progression/presentation/progression_l10n.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_helpers.dart';
import 'social_avatar.dart';

class SocialProfileHeader extends StatefulWidget {
  const SocialProfileHeader({super.key});

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
      builder: (_) => _EditHandleSheet(initialHandle: currentHandle),
    );

    if (next == null) return;
    if (!mounted) return;
    final social = context.read<SocialProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final savedHandle = await social.updateCurrentHandle(next);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          savedHandle == null
              ? 'ID se nepodarilo ulozit: ${social.error ?? 'zkus to znovu'}'
              : 'Social ID ulozeno: @$savedHandle',
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    if (_photoBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    final social = context.read<SocialProvider>();
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
          content: Text('Vyber fotky se nepodaril: $error'),
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
              ? 'Fotku se nepodarilo ulozit: ${social.error ?? 'zkus to znovu'}'
              : 'Profilova fotka ulozena.',
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
                  color: FtTokens.onSurface,
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

        return _HeaderContent(
          displayName: displayName,
          handle: handle,
          photoUrl: photoUrl,
          friendCount: social.friends.length,
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
    required this.onOpenProfile,
    required this.onEditHandle,
    required this.onEditPhoto,
    required this.photoBusy,
  });

  final String displayName;
  final String handle;
  final String? photoUrl;
  final int friendCount;
  final VoidCallback onOpenProfile;
  final VoidCallback onEditHandle;
  final VoidCallback onEditPhoto;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final profile = progression.profile;
    final levelTitle = ProgressionL10n(context.l10n).levelTitle(profile.level);
    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenProfile,
      child: _HeaderFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SocialAvatar(
                      name: displayName,
                      size: 70,
                      photoUrl: photoUrl,
                      radius: 20,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: _RoundMiniButton(
                        icon: Icons.photo_camera_rounded,
                        tooltip: 'Zmenit fotku',
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
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FtTokens.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _HandlePill(
                            handle: handle,
                            onTap: onEditHandle,
                          ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL ${profile.level} - ${levelTitle.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: FtTokens.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      FtProgressBar(
                        value: xpProgress,
                        color: FtProgressionXpStyle.color,
                        glow: FtProgressionXpStyle.glow,
                        height: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${profile.xpIntoLevel} / $xpSpan XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
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

class _HeaderFrame extends StatelessWidget {
  const _HeaderFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: FtTokens.bg,
        borderRadius: BorderRadius.circular(FtTokens.radiusCard),
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
          borderRadius: BorderRadius.circular(FtTokens.radiusCard),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
      message: 'Zmenit ID',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 176),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(99),
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
                    color: FtTokens.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_rounded,
                size: 13,
                color: FtTokens.accent,
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
        color: FtTokens.active.dim,
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: FtTokens.active.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 14,
            color: FtTokens.active.color,
          ),
          const SizedBox(width: 6),
          Text(
            '$friendCount pratel',
            style: TextStyle(
              color: FtTokens.active.color,
              fontSize: 12,
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FtTokens.accent,
            FtTokens.accent.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: FtTokens.accentGlow,
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
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
            color: onTap == null ? FtTokens.onSurfaceFaint : Colors.white,
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
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: FtTokens.accent,
            shape: BoxShape.circle,
            border: Border.all(color: FtTokens.bg, width: 2),
            boxShadow: const [
              BoxShadow(color: FtTokens.accentGlow, blurRadius: 10),
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

class _EditHandleSheet extends StatefulWidget {
  const _EditHandleSheet({required this.initialHandle});

  final String initialHandle;

  @override
  State<_EditHandleSheet> createState() => _EditHandleSheetState();
}

class _EditHandleSheetState extends State<_EditHandleSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHandle);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _save() {
    final normalized = normalizeSocialHandle(_controller.text);
    if (normalized.isEmpty) return;
    Navigator.of(context).pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    final normalized = normalizeSocialHandle(_controller.text);
    final canSave = normalized.isNotEmpty;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Container(
          decoration: BoxDecoration(
            color: FtTokens.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Zmenit Social ID',
                style: TextStyle(
                  color: FtTokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ID slouzi pro vyhledani v social casti.',
                style: TextStyle(
                  color: FtTokens.onSurfaceMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                cursorColor: FtTokens.accent,
                style: const TextStyle(
                  color: FtTokens.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: const TextStyle(
                    color: FtTokens.accent,
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: 'moje_id',
                  hintStyle: const TextStyle(color: FtTokens.onSurfaceFaint),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.045),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: FtTokens.accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                canSave ? '@$normalized' : 'Zadej alespon jeden znak.',
                style: TextStyle(
                  color: canSave ? FtTokens.accent : FtTokens.onSurfaceFaint,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SheetGhostButton(
                      label: 'Zrusit',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetPrimaryButton(
                      label: 'Ulozit',
                      enabled: canSave,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGhostButton extends StatelessWidget {
  const _SheetGhostButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: FtTokens.onSurfaceMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    FtTokens.accent.withValues(alpha: 0.88),
                    FtTokens.accent.withValues(alpha: 0.58),
                  ],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? FtTokens.accent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : FtTokens.onSurfaceFaint,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
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
        color: FtTokens.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FtTokens.accent.withValues(alpha: 0.28)),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: FtTokens.accent,
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
