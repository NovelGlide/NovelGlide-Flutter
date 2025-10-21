import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ImageFile extends Equatable {
  const ImageFile({
    required this.width,
    required this.height,
    this.bytes,
  });

  final double width;
  final double height;
  final Uint8List? bytes;

  @override
  List<Object?> get props => <Object?>[
        width,
        height,
        bytes,
      ];
}
