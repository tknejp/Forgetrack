part of '../profile_settings_widgets.dart';

class ProfileTileDivider extends StatelessWidget {
  final double indent;

  const ProfileTileDivider({
    super.key,
    this.indent = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: 0,
      color: FtTokens.divider,
    );
  }
}
