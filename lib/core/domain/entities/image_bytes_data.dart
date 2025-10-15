import 'dart:typed_data';

import 'image_metadata.dart';

class ImageBytesData extends ImageMetadata {
  const ImageBytesData({
    required this.bytes,
    required super.width,
    required super.height,
  });

  final Uint8List bytes;

  @override
  List<Object?> get props => super.props + <Object?>[bytes];
}
