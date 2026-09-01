import 'package:path/path.dart' as p;

class AppPaths {
  static String? _documentsDir;

  static void init(String documentsDir) {
    _documentsDir = documentsDir;
  }

  static String get documentsDir {
    final dir = _documentsDir;
    if (dir == null) {
      throw StateError('AppPaths not initialized');
    }
    return dir;
  }

  static String toRelativePath(String filePath) {
    if (filePath.isEmpty) {
      return filePath;
    }
    if (!p.isAbsolute(filePath)) {
      return filePath;
    }
    final docsDir = _documentsDir;
    if (docsDir == null) {
      return filePath;
    }
    if (p.isWithin(docsDir, filePath) || p.equals(filePath, docsDir)) {
      return p.relative(filePath, from: docsDir);
    }
    const docsSegment = '/Documents/';
    final index = filePath.indexOf(docsSegment);
    if (index != -1) {
      return filePath.substring(index + docsSegment.length);
    }
    const photosSegment = '/photos/';
    final photosIndex = filePath.indexOf(photosSegment);
    if (photosIndex != -1) {
      return filePath.substring(photosIndex + 1);
    }
    return filePath;
  }

  static String resolveDocumentPath(String storedPath) {
    if (storedPath.isEmpty) {
      return storedPath;
    }
    final docsDir = _documentsDir;
    if (docsDir == null) {
      return storedPath;
    }
    if (p.isAbsolute(storedPath)) {
      const docsSegment = '/Documents/';
      final index = storedPath.indexOf(docsSegment);
      if (index != -1) {
        final relative = storedPath.substring(index + docsSegment.length);
        return p.join(docsDir, relative);
      }
      const photosSegment = '/photos/';
      final photosIndex = storedPath.indexOf(photosSegment);
      if (photosIndex != -1) {
        final relative = storedPath.substring(photosIndex + 1);
        return p.join(docsDir, relative);
      }
      return storedPath;
    }
    return p.join(docsDir, storedPath);
  }
}
