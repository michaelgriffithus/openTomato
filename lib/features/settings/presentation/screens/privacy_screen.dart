import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_page_title.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            icon: Icons.phone_iphone_outlined,
            title: 'Local by default',
            body: 'OpenTomato has no account and no server of its own. Plants, '
                'journal entries, photos, tasks, readings, and settings live in '
                'the app\'s own storage on this device. They are included in '
                'your normal device backup.',
          ),
          _Section(
            icon: Icons.sensors_outlined,
            title: 'Home Assistant',
            body: 'The app talks to your Home Assistant over the network you '
                'configure, using a token you create. It only reads sensor '
                'states and history; it never writes to Home Assistant. The '
                'token is stored in the device keychain, not in the database.',
          ),
          _Section(
            icon: Icons.chat_bubble_outline,
            title: 'Assistant',
            body: 'The assistant is optional and uses an API key you paste in. '
                'Before the first message the app shows exactly what it sends: '
                'a short system prompt, a context block built from your plants, '
                'recent entries, and readings, and your messages. Photos are '
                'never sent. Requests go directly to the provider you chose, '
                'billed to your key.',
          ),
          _Section(
            icon: Icons.visibility_off_outlined,
            title: 'No tracking',
            body:
                'No analytics, no advertising identifiers, no crash reporting '
                'service, no purchases. The source code is public.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.palette.heroAccent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
