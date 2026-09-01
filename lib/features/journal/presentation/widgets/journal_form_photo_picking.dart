import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/journal_entry_with_details.dart';

/// Photo picking and removal shared by the entry form.
mixin JournalFormPhotoPicking<T extends StatefulWidget> on State<T> {
  List<String> get newImagePaths;
  List<int> get photoIdsToDelete;
  List<JournalPhotoModel> get existingPhotos;

  Future<void> pickFromCamera() => _pick(ImageSource.camera);

  Future<void> pickFromLibrary() => _pick(ImageSource.gallery);

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        final file = await picker.pickImage(source: source, imageQuality: 90);
        if (file != null) setState(() => newImagePaths.add(file.path));
      } else {
        final files = await picker.pickMultiImage(imageQuality: 90);
        if (files.isNotEmpty) {
          setState(() => newImagePaths.addAll(files.map((f) => f.path)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open photos: $e')),
        );
      }
    }
  }

  /// [index] is into the combined list: kept existing photos, then new ones.
  void removePhoto(int index) {
    final kept =
        existingPhotos.where((p) => !photoIdsToDelete.contains(p.id)).toList();
    setState(() {
      if (index < kept.length) {
        photoIdsToDelete.add(kept[index].id);
      } else {
        newImagePaths.removeAt(index - kept.length);
      }
    });
  }
}
