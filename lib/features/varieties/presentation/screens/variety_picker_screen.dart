import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../providers/varieties_providers.dart';
import '../widgets/variety_list_tile.dart';

class VarietyPickerScreen extends ConsumerStatefulWidget {
  const VarietyPickerScreen({super.key});

  @override
  ConsumerState<VarietyPickerScreen> createState() =>
      _VarietyPickerScreenState();
}

class _VarietyPickerScreenState extends ConsumerState<VarietyPickerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final varietiesAsync = ref.watch(varietySearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const AppPageTitle(pageName: 'Choose a variety'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search varieties…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: varietiesAsync.when(
        data: (varieties) {
          return ListView.builder(
            itemCount: varieties.length + 1,
            itemBuilder: (context, index) {
              if (index == varieties.length) {
                return ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add a custom variety'),
                  onTap: () async {
                    final variety =
                        await context.push<Variety>('/variety/create');
                    if (variety != null && context.mounted) {
                      context.pop(variety);
                    }
                  },
                );
              }
              final variety = varieties[index];
              return VarietyListTile(
                variety: variety,
                onTap: () => context.pop(variety),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load varieties: $error')),
      ),
    );
  }
}
