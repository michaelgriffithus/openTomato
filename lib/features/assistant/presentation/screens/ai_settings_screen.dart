import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/providers/anthropic_client.dart';
import '../../data/providers/openai_client.dart';
import '../../domain/cloud_provider_consent.dart';
import '../providers/assistant_providers.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final settings = ref.watch(allAiSettingsProvider).valueOrNull ?? const [];
    AiSetting? rowFor(String provider) =>
        settings.where((s) => s.provider == provider).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'AI provider')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(
            'Bring your own key. Keys are stored in the device keychain and '
            'requests go straight to the provider. One provider is active at a time.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          _ProviderCard(
            provider: 'anthropic',
            suggestedModels: AnthropicClient.suggestedModels,
            defaultModel: AnthropicClient.defaultModel,
            row: rowFor('anthropic'),
            supportsBaseUrl: false,
          ),
          const SizedBox(height: 12),
          _ProviderCard(
            provider: 'openai',
            suggestedModels: OpenAiClient.suggestedModels,
            defaultModel: OpenAiClient.defaultModel,
            row: rowFor('openai'),
            supportsBaseUrl: true,
          ),
          const SizedBox(height: 16),
          Text(
            'The model field is free text so a new release works the day it ships; '
            'the chips are only suggestions.',
            style:
                AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends ConsumerStatefulWidget {
  final String provider;
  final List<String> suggestedModels;
  final String defaultModel;
  final AiSetting? row;
  final bool supportsBaseUrl;

  const _ProviderCard({
    required this.provider,
    required this.suggestedModels,
    required this.defaultModel,
    required this.row,
    required this.supportsBaseUrl,
  });

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  late final _key = TextEditingController();
  late final _model =
      TextEditingController(text: widget.row?.modelName ?? widget.defaultModel);
  late final _baseUrl = TextEditingController(text: widget.row?.baseUrl ?? '');
  late final _prompt =
      TextEditingController(text: widget.row?.systemPromptOverride ?? '');
  bool _hasKey = false;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadKeyState();
  }

  Future<void> _loadKeyState() async {
    final row = widget.row;
    if (row == null) return;
    final has = await ref.read(aiSettingsRepositoryProvider).hasApiKey(row.id);
    if (mounted) setState(() => _hasKey = has);
  }

  @override
  void didUpdateWidget(covariant _ProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row?.id != widget.row?.id) _loadKeyState();
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _baseUrl.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = CloudProviderConsent.providerLabel(widget.provider);
    final isActive = widget.row?.isActive ?? false;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.h4)),
              if (isActive)
                Chip(
                  label: const Text('Active'),
                  backgroundColor: palette.statusOptimalFill,
                  labelStyle: TextStyle(color: palette.statusOptimalText),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _key,
            obscureText: true,
            decoration: InputDecoration(
              labelText:
                  _hasKey ? 'API key (saved; paste to replace)' : 'API key',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _model,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final m in widget.suggestedModels)
                ActionChip(
                  label: Text(m),
                  onPressed: () => setState(() => _model.text = m),
                ),
            ],
          ),
          if (widget.supportsBaseUrl) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _baseUrl,
              decoration: const InputDecoration(
                labelText: 'Base URL (optional, OpenAI-compatible servers)',
                hintText: 'https://api.openai.com/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _prompt,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Extra instructions (optional)',
              hintText: 'e.g. I grow in containers on a balcony in zone 7.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _status!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: palette.textSecondary),
              ),
            ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _validate,
                child: const Text('Validate'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _save(makeActive: true),
                child: const Text('Save & use'),
              ),
              const Spacer(),
              if (widget.row != null)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _effectiveKey() async {
    if (_key.text.trim().isNotEmpty) return _key.text.trim();
    final row = widget.row;
    return row == null
        ? null
        : ref.read(aiSettingsRepositoryProvider).getApiKey(row.id);
  }

  Future<void> _validate() async {
    final key = await _effectiveKey();
    if (key == null || key.isEmpty) {
      setState(() => _status = 'Paste an API key first.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Checking…';
    });
    final client = ref.read(aiProviderClientsProvider)[widget.provider]!;
    final problem = await client.validateApiKey(
      key,
      _model.text.trim(),
      baseUrl: _baseUrl.text.trim().isEmpty ? null : _baseUrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _busy = false;
        _status = problem ?? 'Key and model work.';
      });
    }
  }

  Future<void> _save({required bool makeActive}) async {
    if (!_hasKey && _key.text.trim().isEmpty) {
      setState(() => _status = 'Paste an API key first.');
      return;
    }
    setState(() => _busy = true);
    await ref.read(aiSettingsRepositoryProvider).save(
          provider: widget.provider,
          modelName:
              _model.text.trim().isEmpty ? widget.defaultModel : _model.text,
          apiKey: _key.text,
          baseUrl: widget.supportsBaseUrl ? _baseUrl.text : null,
          systemPromptOverride: _prompt.text,
          makeActive: makeActive,
        );
    if (mounted) {
      setState(() {
        _busy = false;
        _hasKey = true;
        _status = 'Saved.';
      });
      _key.clear();
    }
  }

  Future<void> _remove() async {
    final row = widget.row;
    if (row == null) return;
    await ref.read(aiSettingsRepositoryProvider).delete(row.id);
    if (mounted) setState(() => _hasKey = false);
  }
}
