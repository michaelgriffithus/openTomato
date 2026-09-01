import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/router_extensions.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../contracts/settings_screen_contract.dart';
import '../controllers/settings_screen_controller.dart';

abstract interface class SettingsScreenActions {
  void open(String route);
  void chooseAppearance(AppearanceChoice current);
  void showLicences();
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsScreenView(
      contract: ref.watch(settingsScreenContractProvider),
      actions: _Actions(context, ref),
    );
  }
}

/// Provider-free view.
class SettingsScreenView extends StatelessWidget {
  const SettingsScreenView({
    super.key,
    required this.contract,
    required this.actions,
  });

  final SettingsScreenContract contract;
  final SettingsScreenActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(eyebrow: 'OpenTomato', title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
                children: [
                  const _SectionLabel('Grow'),
                  _Row(
                    icon: Icons.sensors_outlined,
                    title: 'Home Assistant',
                    subtitle: contract.homeAssistantLabel,
                    onTap: () => actions.open('/settings/home-assistant'),
                  ),
                  _Row(
                    icon: Icons.yard_outlined,
                    title: 'Grow spaces',
                    subtitle: 'Map sensors and stage overrides',
                    onTap: () => actions.open('/settings/grow-spaces'),
                  ),
                  _Row(
                    icon: Icons.track_changes_outlined,
                    title: 'Stage targets',
                    subtitle: 'App-wide tomato bands',
                    onTap: () => actions.open('/settings/environment-targets'),
                  ),
                  _Row(
                    icon: Icons.local_florist_outlined,
                    title: 'Plants',
                    subtitle: contract.plantsLabel,
                    onTap: () => actions.open('/plants'),
                  ),
                  const _SectionLabel('Assistant'),
                  _Row(
                    icon: Icons.chat_bubble_outline,
                    title: 'AI provider',
                    subtitle: contract.assistantLabel,
                    onTap: () => actions.open('/settings/ai'),
                  ),
                  const _SectionLabel('App'),
                  _Row(
                    icon: Icons.brightness_6_outlined,
                    title: 'Appearance',
                    subtitle: contract.appearanceLabel,
                    onTap: () => actions.chooseAppearance(contract.appearance),
                  ),
                  _Row(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy',
                    subtitle: 'What stays on the device',
                    onTap: () => actions.open('/settings/privacy'),
                  ),
                  _Row(
                    icon: Icons.description_outlined,
                    title: 'Open-source licences',
                    subtitle: contract.identity.versionLabel,
                    onTap: actions.showLicences,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '${contract.identity.productLabel} · ${contract.identity.versionLabel}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.sectionLabel
            .copyWith(color: context.palette.heroAccent),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.palette.heroAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _Actions implements SettingsScreenActions {
  const _Actions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  static const _shellTabRoutes = {
    '/today',
    '/timeline',
    '/plants',
    '/ask',
    '/settings',
  };

  @override
  void open(String route) {
    // Shell tabs must be switched with go(); pushing one collides on page keys.
    if (_shellTabRoutes.contains(route)) {
      context.go(route);
      return;
    }
    context.pushDeduped(route);
  }

  @override
  Future<void> chooseAppearance(AppearanceChoice current) async {
    final next = await showModalBottomSheet<AppearanceChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: RadioGroup<AppearanceChoice>(
          groupValue: current,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final choice in AppearanceChoice.values)
                RadioListTile<AppearanceChoice>(
                  value: choice,
                  title: Text(appearanceLabel(choice)),
                ),
            ],
          ),
        ),
      ),
    );
    if (next != null) {
      await ref.read(settingsScreenControllerProvider).setAppearance(next);
    }
  }

  @override
  void showLicences() => showLicensePage(
        context: context,
        applicationName: 'OpenTomato',
        applicationLegalese: 'MIT licence · Michael Griffith',
      );
}
