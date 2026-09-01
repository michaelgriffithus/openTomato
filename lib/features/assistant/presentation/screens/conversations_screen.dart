import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../providers/assistant_providers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(assistantConversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'Conversations')),
      body: conversations.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No conversations yet.'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final c = list[index];
                  return Dismissible(
                    key: ValueKey('conversation-${c.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Theme.of(context).colorScheme.error,
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        ref.read(assistantDaoProvider).deleteConversation(c.id),
                    child: ListTile(
                      title: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          Text(DateFormat('MMM d, H:mm').format(c.updatedAt)),
                      onTap: () => context.push('/ask/${c.id}'),
                    ),
                  );
                },
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }
}
