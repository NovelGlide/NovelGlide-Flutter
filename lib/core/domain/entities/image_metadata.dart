import 'package:equatable/equatable.dart';

class ImageMetadata extends Equatable {
  const ImageMetadata({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  List<Object?> get props => <Object?>[
        width,
        height,
      ];
}
