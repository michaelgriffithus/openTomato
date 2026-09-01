import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/app_paths.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/photo_error_placeholder.dart';

/// Full-screen swipe-and-pinch photo viewer. Paths are stored (relative).
class PhotoCarousel extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;

  const PhotoCarousel({
    super.key,
    required this.photoPaths,
    this.initialIndex = 0,
  });

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        title: AppPageTitle(
          pageName: 'Photo ${_currentIndex + 1} of ${widget.photoPaths.length}',
          brandColor: Colors.white,
          pageColor: Colors.white70,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photoPaths.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final path =
                  AppPaths.resolveDocumentPath(widget.photoPaths[index]);
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const PhotoErrorPlaceholder(
                      size: 64,
                      iconColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.photoPaths.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photoPaths.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void openPhotoCarousel(
  BuildContext context, {
  required List<String> photoPaths,
  int initialIndex = 0,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PhotoCarousel(photoPaths: photoPaths, initialIndex: initialIndex),
    ),
  );
}
