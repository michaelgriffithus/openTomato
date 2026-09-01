import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../domain/cloud_provider_consent.dart';
import '../providers/assistant_providers.dart';
import '../widgets/assistant_disclaimer.dart';
import '../widgets/assistant_message_bubble.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  final int? conversationId;

  const AssistantScreen({super.key, this.conversationId});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int? _conversationId;
  String? _streamingReply;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = ref.watch(activeAiSettingProvider).valueOrNull;
    final gates = ref.watch(assistantGatesProvider).valueOrNull;
    final contextBlock = ref.watch(gardenContextProvider);
    final id = _conversationId;
    final messages = id == null
        ? const <AssistantMessage>[]
        : ref.watch(assistantMessagesProvider(id)).valueOrNull ?? const [];

    Widget body;
    if (active == null) {
      body = AppEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Bring your own key',
        body:
            'Paste an Anthropic or OpenAI API key to ask questions about your garden. '
            'The app sends a short context block you can read; nothing else.',
        actionLabel: 'Set up a provider',
        onAction: () => context.push('/settings/ai'),
      );
    } else if (gates == null) {
      body = const Center(child: CircularProgressIndicator.adaptive());
    } else if (!gates.disclaimer || !gates.consent) {
      body = AssistantGate(
        providerLabel: CloudProviderConsent.providerLabel(active.provider),
        contextPreview: contextBlock,
        onAccept: () => _accept(active.provider),
      );
    } else {
      body = _chat(messages, contextBlock, palette);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: active == null
                  ? 'Assistant'
                  : '${CloudProviderConsent.providerLabel(active.provider)} · ${active.modelName}',
              title: 'Ask',
              leading: widget.conversationId != null
                  ? IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Conversations',
                    onPressed: () => context.push('/ask/conversations'),
                    icon: const Icon(Icons.history),
                  ),
                  IconButton(
                    tooltip: 'New conversation',
                    onPressed: () => setState(() => _conversationId = null),
                    icon: const Icon(Icons.add_comment_outlined),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _chat(
    List<AssistantMessage> messages,
    String contextBlock,
    AppPalette palette,
  ) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty && _streamingReply == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ask about watering, feeding, pruning, or what today\'s readings mean. '
                      'Each message carries the context block for your current grow space.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    for (final m in messages)
                      AssistantMessageBubble(
                        role: m.role,
                        content: m.content,
                        contextBlock: m.contextBlock,
                      ),
                    if (_streamingReply != null)
                      AssistantMessageBubble(
                        role: 'assistant',
                        content: _streamingReply!,
                        streaming: true,
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your tomatoes…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(contextBlock),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : () => _send(contextBlock),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept(String provider) async {
    final settings = ref.read(appSettingsDaoProvider);
    await settings.setBool(CloudProviderConsent.disclaimerKey, true);
    await CloudProviderConsent.accept(settings, provider);
    ref.invalidate(assistantGatesProvider);
  }

  Future<void> _send(String contextBlock) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final service = ref.read(assistantServiceProvider);
    setState(() {
      _sending = true;
      _streamingReply = '';
    });
    _input.clear();
    try {
      _conversationId ??= await service.startConversation(text);
      await for (final partial in service.send(
        conversationId: _conversationId!,
        userText: text,
        contextBlock: contextBlock,
      )) {
        if (!mounted) return;
        setState(() => _streamingReply = partial);
        unawaited(_scrollToEnd());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.userMessage : 'The request failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _streamingReply = null;
        });
      }
    }
  }

  Future<void> _scrollToEnd() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }
}
