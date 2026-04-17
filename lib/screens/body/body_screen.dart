import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_screen.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.screenBody),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(context.l10n.emptyNoData, style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }
}
