import 'package:flutter/material.dart';

enum ReadingMode { light, dark, sepia }

class ReadingModeOverlay extends StatelessWidget {
  final ReadingMode mode;
  final Widget child;

  const ReadingModeOverlay({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ReadingMode.light:
        return child;

      case ReadingMode.sepia:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.9, 0.1, 0.0, 0, 15,
            0.0, 0.85, 0.15, 0, 10,
            0.0, 0.1, 0.7, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Container(color: const Color(0xFFF4ECD8), child: child),
        );

      case ReadingMode.dark:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            -1, 0, 0, 0, 255,
            0, -1, 0, 0, 255,
            0, 0, -1, 0, 255,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
    }
  }
}
