import '../enums/entry_type.dart';

class JournalCaptureValidationInput {
  const JournalCaptureValidationInput({
    required this.type,
    required this.content,
    required this.photoCount,
    required this.nutrientProductNames,
    required this.hasReadings,
  });

  final EntryType type;
  final String content;
  final int photoCount;
  final List<String> nutrientProductNames;
  final bool hasReadings;
}

class JournalCaptureValidationResult {
  const JournalCaptureValidationResult._(this.message);

  const JournalCaptureValidationResult.valid() : this._(null);
  const JournalCaptureValidationResult.invalid(String message)
      : this._(message);

  final String? message;
  bool get isValid => message == null;
}

JournalCaptureValidationResult validateJournalCapture(
  JournalCaptureValidationInput input,
) {
  final hasContent = input.content.trim().isNotEmpty;
  final hasPhoto = input.photoCount > 0;
  switch (input.type) {
    case EntryType.photo:
      return hasPhoto
          ? const JournalCaptureValidationResult.valid()
          : const JournalCaptureValidationResult.invalid(
              'Attach at least one photo before saving a photo entry.',
            );
    case EntryType.fertilizing:
      final hasProduct =
          input.nutrientProductNames.any((name) => name.trim().isNotEmpty);
      return hasProduct || hasContent
          ? const JournalCaptureValidationResult.valid()
          : const JournalCaptureValidationResult.invalid(
              'Add a product or a note before saving a feeding.',
            );
    case EntryType.stageChange:
      return const JournalCaptureValidationResult.invalid(
        'Use Move stage to change a plant\'s stage.',
      );
    case EntryType.watering:
      return const JournalCaptureValidationResult.valid();
    case EntryType.inspect:
      return hasContent || hasPhoto || input.hasReadings
          ? const JournalCaptureValidationResult.valid()
          : const JournalCaptureValidationResult.invalid(
              'Add a note, a photo, or a reading for this inspection.',
            );
    case EntryType.note:
    case EntryType.pruning:
    case EntryType.staking:
    case EntryType.transplanting:
    case EntryType.pest:
    case EntryType.disease:
    case EntryType.flowering:
    case EntryType.harvest:
      return hasContent || hasPhoto
          ? const JournalCaptureValidationResult.valid()
          : JournalCaptureValidationResult.invalid(
              'Add a note or photo describing this ${input.type.displayName.toLowerCase()}.',
            );
  }
}
