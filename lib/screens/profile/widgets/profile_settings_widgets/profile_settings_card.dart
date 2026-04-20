part of '../profile_settings_widgets.dart';

class ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
