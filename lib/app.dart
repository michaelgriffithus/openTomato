import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/app_scaffold.dart';
import 'features/assistant/presentation/screens/ai_settings_screen.dart';
import 'features/assistant/presentation/screens/assistant_screen.dart';
import 'features/assistant/presentation/screens/conversations_screen.dart';
import 'features/home_assistant/presentation/screens/grow_space_editor_screen.dart';
import 'features/home_assistant/presentation/screens/grow_spaces_screen.dart';
import 'features/home_assistant/presentation/screens/ha_settings_screen.dart';
import 'features/journal/domain/enums/entry_type.dart';
import 'features/journal/presentation/screens/journal_entry_detail_screen.dart';
import 'features/journal/presentation/screens/journal_entry_form_screen.dart';
import 'features/journal/presentation/screens/timeline_screen.dart';
import 'features/journal/presentation/widgets/global_capture_sheet.dart';
import 'features/plants/presentation/screens/plant_detail_screen.dart';
import 'features/plants/presentation/screens/plant_form_screen.dart';
import 'features/plants/presentation/screens/plant_stage_change_screen.dart';
import 'features/plants/presentation/screens/plants_screen.dart';
import 'features/settings/presentation/screens/environment_targets_screen.dart';
import 'features/settings/presentation/screens/privacy_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/today/presentation/screens/today_screen.dart';
import 'features/todos/presentation/screens/todos_screen.dart';
import 'features/varieties/presentation/screens/custom_variety_form_screen.dart';
import 'features/varieties/presentation/screens/variety_picker_screen.dart';

class OpenTomatoApp extends ConsumerWidget {
  const OpenTomatoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'OpenTomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

int? _intParam(GoRouterState state, String key) =>
    int.tryParse(state.uri.queryParameters[key] ?? '');

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppScaffold(
        navigationShell: shell,
        onCapture: () => openGlobalCaptureFlow(context),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timeline',
              builder: (_, __) => const TimelineScreen(),
              routes: [
                GoRoute(path: 'tasks', builder: (_, __) => const TodosScreen()),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/plants', builder: (_, __) => const PlantsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ask',
              builder: (_, __) => const AssistantScreen(),
              routes: [
                GoRoute(
                  path: 'conversations',
                  builder: (_, __) => const ConversationsScreen(),
                ),
                GoRoute(
                  path: ':conversationId',
                  builder: (_, state) => AssistantScreen(
                    conversationId:
                        int.parse(state.pathParameters['conversationId']!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Journal entry routes live outside the shell on purpose: plant detail
    // (also outside the shell) pushes them, and pushing a shell-nested route
    // from a non-shell screen re-creates the shell page and trips the
    // navigator's duplicate-key assertion.
    GoRoute(
      path: '/timeline/new',
      builder: (_, state) => JournalEntryFormScreen(
        initialType: EntryType.fromStorage(state.uri.queryParameters['type']),
        initialPlantId: _intParam(state, 'plantId'),
        initialTitle: state.uri.queryParameters['title'],
        completesTodoId: _intParam(state, 'todoId'),
      ),
    ),
    GoRoute(
      path: '/timeline/edit/:id',
      builder: (_, state) => JournalEntryFormScreen(
        entryId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/timeline/:id',
      builder: (_, state) => JournalEntryDetailScreen(
        entryId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/plants/create',
      builder: (_, __) => const PlantFormScreen(),
    ),
    GoRoute(
      path: '/plants/stage-change',
      builder: (_, state) =>
          PlantStageChangeScreen(initialPlantId: _intParam(state, 'plantId')),
    ),
    GoRoute(
      path: '/plants/:id',
      builder: (_, state) =>
          PlantDetailScreen(plantId: int.parse(state.pathParameters['id']!)),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (_, state) =>
              PlantFormScreen(plantId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    ),
    GoRoute(
      path: '/variety-picker',
      builder: (_, __) => const VarietyPickerScreen(),
    ),
    GoRoute(
      path: '/variety/create',
      builder: (_, __) => const CustomVarietyFormScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'home-assistant',
          builder: (_, __) => const HASettingsScreen(),
        ),
        GoRoute(
          path: 'grow-spaces',
          builder: (_, __) => const GrowSpacesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, __) => const GrowSpaceEditorScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) => GrowSpaceEditorScreen(
                growSpaceId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'environment-targets',
          builder: (_, __) => const EnvironmentTargetsScreen(),
        ),
        GoRoute(path: 'ai', builder: (_, __) => const AiSettingsScreen()),
        GoRoute(path: 'privacy', builder: (_, __) => const PrivacyScreen()),
      ],
    ),
  ],
);
