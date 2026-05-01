part of 'settings_widgets.dart';

class SettingsTileDivider extends StatelessWidget {
  final double indent;

  const SettingsTileDivider({
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
      color: Tokens.divider,
    );
  }
}
