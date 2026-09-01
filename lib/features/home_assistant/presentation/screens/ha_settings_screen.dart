import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../providers/ha_providers.dart';

class HASettingsScreen extends ConsumerStatefulWidget {
  const HASettingsScreen({super.key});

  @override
  ConsumerState<HASettingsScreen> createState() => _HASettingsScreenState();
}

class _HASettingsScreenState extends ConsumerState<HASettingsScreen> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  final _pollInterval = TextEditingController(text: '15');
  final _warn = TextEditingController(text: '5');
  final _stale = TextEditingController(text: '15');
  bool _enabled = true;
  bool _hasStoredToken = false;
  bool _loaded = false;
  bool _testing = false;
  bool _saving = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(haSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    final token = await repo.getAccessToken();
    if (!mounted) return;
    setState(() {
      _url.text = settings?.baseUrl ?? '';
      _enabled = settings?.isEnabled ?? true;
      _pollInterval.text = '${settings?.pollIntervalMinutes ?? 15}';
      _warn.text = '${settings?.liveWarnThresholdMinutes ?? 5}';
      _stale.text = '${settings?.liveStaleThresholdMinutes ?? 15}';
      _hasStoredToken = token != null && token.isNotEmpty;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    _pollInterval.dispose();
    _warn.dispose();
    _stale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final live = ref.watch(haLiveUpdateServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'Home Assistant')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Text(
                  'OpenTomato reads sensors you already have in Home Assistant. '
                  'It never writes to Home Assistant.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _url,
                  labelText: 'Base URL',
                  hintText: 'http://homeassistant.local:8123',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: _token,
                  labelText: _hasStoredToken
                      ? 'Long-lived access token (saved; paste to replace)'
                      : 'Long-lived access token',
                  hintText: 'Profile → Long-lived access tokens → Create',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Test connection'),
                    ),
                    const SizedBox(width: 12),
                    if (_testResult != null)
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _testResult!.startsWith('Connected')
                                ? palette.statusOptimalText
                                : palette.statusOutOfRangeText,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  subtitle: const Text('Read sensors while the app is open'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const SizedBox(height: 8),
                GlassCardLight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timing',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: palette.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GlassTextField(
                              controller: _pollInterval,
                              labelText: 'Poll every (min)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GlassTextField(
                              controller: _warn,
                              labelText: 'Warn after (min)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GlassTextField(
                              controller: _stale,
                              labelText: 'Stale after (min)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.yard_outlined),
                  title: const Text('Grow spaces'),
                  subtitle: const Text('Map temperature and humidity sensors'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/grow-spaces'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sensors),
                  title: Text('Live status: ${live.status.name}'),
                  subtitle: Text(
                    live.failureReason ?? live.activeBaseUrl ?? 'Not connected',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _remove,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Remove connection'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plain http on your home network is fine. An https address with a '
                  'self-signed certificate will fail the handshake.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
    );
  }

  Future<void> _test() async {
    final url = _url.text.trim();
    final token = _token.text.trim().isNotEmpty
        ? _token.text.trim()
        : await ref.read(haSettingsRepositoryProvider).getAccessToken() ?? '';
    if (url.isEmpty || token.isEmpty) {
      setState(() => _testResult = 'Enter a URL and a token first.');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      await ref.read(haServiceProvider).testConnection(url, token);
      if (mounted) setState(() => _testResult = 'Connected to Home Assistant.');
    } catch (e) {
      if (mounted) {
        setState(
          () => _testResult =
              e is AppException ? e.userMessage : 'Connection failed: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    if (!RegExp(r'^https?://[^/\s]+').hasMatch(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a URL like http://homeassistant.local:8123'),
        ),
      );
      return;
    }
    if (!_hasStoredToken && _token.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste a long-lived access token.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(haSettingsRepositoryProvider).saveSettings(
            baseUrl: url,
            accessToken: _token.text,
            isEnabled: _enabled,
            pollIntervalMinutes: int.tryParse(_pollInterval.text.trim()) ?? 15,
            liveWarnThresholdMinutes: int.tryParse(_warn.text.trim()) ?? 5,
            liveStaleThresholdMinutes: int.tryParse(_stale.text.trim()) ?? 15,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Home Assistant settings saved.')),
        );
        setState(
          () => _hasStoredToken =
              _hasStoredToken || _token.text.trim().isNotEmpty,
        );
        _token.clear();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Home Assistant?'),
        content:
            const Text('The URL and token are deleted. Stored readings stay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(haSettingsRepositoryProvider).deleteSettings();
    if (mounted) context.pop();
  }
}
