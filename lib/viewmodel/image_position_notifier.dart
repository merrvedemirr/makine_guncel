// // Resim konumlandırma için bir state provider
// import 'dart:ui';

// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final imagePositionProvider = StateNotifierProvider<ImagePositionNotifier, ImagePosition>(
//   (ref) => ImagePositionNotifier(),
// );

// class ImagePosition {
//   final Offset position;
//   final double scale;

//   ImagePosition({required this.position, required this.scale});

//   ImagePosition copyWith({Offset? position, double? scale}) {
//     return ImagePosition(
//       position: position ?? this.position,
//       scale: scale ?? this.scale,
//     );
//   }
// }

// class ImagePositionNotifier extends StateNotifier<ImagePosition> {
//   ImagePositionNotifier()
//       : super(ImagePosition(
//           position: Offset.zero,
//           scale: 1.0,
//         ));

//   void updatePosition(Offset newPosition) {
//     state = state.copyWith(position: newPosition);
//   }

//   void updateScale(double newScale) {
//     state = state.copyWith(scale: newScale);
//   }

//   void reset() {
//     state = ImagePosition(position: Offset.zero, scale: 1.0);
//   }
// }
