# Architecture

Feature-first Flutter app: Riverpod for state, Drift (SQLite) for storage,
go_router for navigation. Layout:

```
lib/
  core/        database, theme, shared widgets, utils, security
  features/
    plants/        plant records and stage changes
    varieties/     tomato variety catalogue
    journal/       entries, photos, timeline
    todos/         tasks
    home_assistant/ REST + WebSocket client, sync, history backfill, grow spaces
    environment/   stage bands, range evaluator, time-in-range, focus line
    today/         the Today screen
    assistant/     bring-your-own-key chat
    settings/
```

## Data flow

```
Home Assistant (REST /api/states, WebSocket state_changed, /api/history/period)
    │ live (debounced)    │ foreground poll      │ backfill on resume (72 h)
    └──────────────┬──────┴──────────────────────┘
                   ▼
   HaEnvironmentSyncService — sanitise, recompute VPD, upsert
                   ▼
   environment_snapshots (Drift)
                   ▼
   latest-reading / window providers
                   ▼
   StageTargetResolver → EnvironmentRangeEvaluator → TimeInRangeCalculator → FocusLineBuilder
                   ▼
   TodayContract → Today screen
```

## Presentation contract

Screens render from an immutable `*Contract` object produced by a provider. The
screen root is the only widget that reads providers; everything below it is a
plain `StatelessWidget`. That keeps widgets testable from a hand-built contract
and keeps business rules out of the widget tree.

## Why no background isolate

iOS will not keep the app alive to poll. Instead of fighting that, each
foreground catches history up from the source that was awake (Home Assistant's
recorder). One recorder per source of truth, no duplicate writers.

## Assistant

The assistant is a streaming chat against the grower's own Anthropic or OpenAI
key. Keys live in secure storage. Each turn sends a short system prompt, a
deterministic context block built from local data (readings, stage band, plants,
recent entries, open tasks), and the last twenty messages. The context block is
visible in the UI so the grower can see exactly what left the device.
