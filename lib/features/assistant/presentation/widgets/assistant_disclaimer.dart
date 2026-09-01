import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';

const assistantDisclaimerTitle = 'Before using the assistant';

const assistantDisclaimerBody = [
  'The assistant answers from general plant knowledge plus the context block '
      'you can see in each conversation. It cannot see your plants or photos.',
  'It can be wrong. Check anything that matters, especially pest, disease, '
      'and food-safety decisions, against a trusted source.',
  'Messages and the context block are sent to the provider you configured, '
      'using your own API key, and are subject to that provider\'s terms.',
];

/// Blocks the chat until the grower has read the disclaimer and, for the
/// active provider, seen what is sent.
class AssistantGate extends StatelessWidget {
  final String providerLabel;
  final String contextPreview;
  final VoidCallback onAccept;

  const AssistantGate({
    super.key,
    required this.providerLabel,
    required this.contextPreview,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(assistantDisclaimerTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  for (final line in assistantDisclaimerBody)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(line, style: AppTextStyles.bodyMedium),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'What $providerLabel receives with each message',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.chartSurfaceFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.chartSurfaceBorder),
                    ),
                    child: Text(
                      contextPreview,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAccept,
                    child: Text('I understand, send to $providerLabel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
